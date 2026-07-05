import Foundation

public struct BinanceP2PClient: Sendable {
    public enum Error: Swift.Error, Equatable {
        case invalidResponse
        case apiError(code: String)
    }

    private let endpoint = URL(string: "https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search")!
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchQuotes(
        assets: [Stablecoin],
        fiat: FiatCurrency,
        transactionAmount: Decimal,
        rows: Int = 20
    ) async throws -> [C2CQuote] {
        var quotes: [C2CQuote] = []

        for asset in assets {
            for side in UserTradeSide.allCases {
                quotes += try await fetchQuotes(
                    asset: asset,
                    fiat: fiat,
                    side: side,
                    transactionAmount: transactionAmount,
                    rows: rows
                )
            }
        }

        return quotes
    }

    public func fetchQuotes(
        asset: Stablecoin,
        fiat: FiatCurrency,
        side: UserTradeSide,
        transactionAmount: Decimal,
        rows: Int = 20
    ) async throws -> [C2CQuote] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("C2CBar/0.1", forHTTPHeaderField: "user-agent")
        request.httpBody = try JSONEncoder().encode(
            BinanceP2PRequest(
                asset: asset.rawValue,
                fiat: fiat.rawValue,
                tradeType: side.binanceTradeType,
                page: 1,
                rows: rows,
                transAmount: StableFormat.price(transactionAmount)
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw Error.invalidResponse
        }

        return try Self.decodeQuotes(
            from: data,
            asset: asset,
            fiat: fiat,
            side: side,
            receivedAt: Date()
        )
    }

    public static func decodeQuotes(
        from data: Data,
        asset: Stablecoin,
        fiat: FiatCurrency,
        side: UserTradeSide,
        receivedAt: Date
    ) throws -> [C2CQuote] {
        let response = try JSONDecoder().decode(BinanceP2PResponse.self, from: data)
        guard response.code == "000000" else {
            throw Error.apiError(code: response.code)
        }

        return response.data.compactMap { item in
            guard let price = Decimal(string: item.adv.price) else {
                return nil
            }

            return C2CQuote(
                id: "binance-\(asset.rawValue.lowercased())-\(side.rawValue)-\(item.adv.advNo)",
                exchange: .binance,
                asset: asset,
                fiat: fiat,
                side: side,
                price: price,
                availableAssetAmount: decimal(item.adv.tradableQuantity ?? item.adv.surplusAmount),
                minFiatAmount: decimal(item.adv.minSingleTransAmount),
                maxFiatAmount: decimal(item.adv.maxSingleTransAmount),
                merchantName: item.advertiser?.nickName,
                completedOrders: nil,
                completionRate: nil,
                paymentMethods: item.adv.tradeMethods.compactMap(\.tradeMethodName),
                updatedAt: receivedAt
            )
        }
    }

    private static func decimal(_ value: String?) -> Decimal? {
        guard let value, !value.isEmpty else { return nil }
        return Decimal(string: value)
    }
}

private struct BinanceP2PRequest: Encodable {
    let asset: String
    let fiat: String
    let tradeType: String
    let page: Int
    let rows: Int
    let transAmount: String
    let payTypes: [String] = []
    let countries: [String] = []
    let publisherType: String? = nil
}

private struct BinanceP2PResponse: Decodable {
    let code: String
    let data: [BinanceP2PItem]
}

private struct BinanceP2PItem: Decodable {
    let adv: BinanceP2PAdvertisement
    let advertiser: BinanceP2PAdvertiser?
}

private struct BinanceP2PAdvertisement: Decodable {
    let advNo: String
    let price: String
    let surplusAmount: String?
    let tradableQuantity: String?
    let minSingleTransAmount: String?
    let maxSingleTransAmount: String?
    let tradeMethods: [BinanceP2PPaymentMethod]
}

private struct BinanceP2PAdvertiser: Decodable {
    let nickName: String?
}

private struct BinanceP2PPaymentMethod: Decodable {
    let tradeMethodName: String?
}

private extension UserTradeSide {
    var binanceTradeType: String {
        switch self {
        case .buyStablecoin:
            return "BUY"
        case .sellStablecoin:
            return "SELL"
        }
    }
}
