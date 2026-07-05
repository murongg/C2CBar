import Foundation

public struct HTXP2PClient: Sendable {
    public enum Error: Swift.Error, Equatable {
        case invalidURL
        case invalidResponse
        case unsupportedAsset(Stablecoin)
        case apiError(code: Int)
    }

    private let endpoint = URL(string: "https://otc-api.trygofast.com/v1/data/trade-market")!
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchQuotes(
        assets: [Stablecoin],
        fiat: FiatCurrency,
        transactionAmount: Decimal,
        rows: Int = 10
    ) async throws -> [C2CQuote] {
        var quotes: [C2CQuote] = []

        for asset in assets {
            guard asset.htxCoinId != nil else {
                continue
            }

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
        rows: Int = 10
    ) async throws -> [C2CQuote] {
        guard let coinId = asset.htxCoinId else {
            throw Error.unsupportedAsset(asset)
        }

        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw Error.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "coinId", value: "\(coinId)"),
            URLQueryItem(name: "currency", value: "\(fiat.htxCurrencyId)"),
            URLQueryItem(name: "tradeType", value: side.htxTradeType),
            URLQueryItem(name: "currPage", value: "1"),
            URLQueryItem(name: "pageSize", value: "\(rows)"),
            URLQueryItem(name: "amount", value: StableFormat.price(transactionAmount)),
            URLQueryItem(name: "payMethod", value: "0"),
            URLQueryItem(name: "acceptOrder", value: "-1"),
            URLQueryItem(name: "country", value: ""),
            URLQueryItem(name: "blockType", value: "general"),
            URLQueryItem(name: "online", value: "1"),
            URLQueryItem(name: "range", value: "0")
        ]

        guard let url = components.url else {
            throw Error.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("C2CBar/0.1", forHTTPHeaderField: "user-agent")

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
        let response = try JSONDecoder().decode(HTXP2PResponse.self, from: data)
        guard response.success, response.code == 200 else {
            throw Error.apiError(code: response.code)
        }

        return response.data.compactMap { item in
            guard let price = Decimal(string: item.price) else {
                return nil
            }

            return C2CQuote(
                id: "htx-\(asset.rawValue.lowercased())-\(side.rawValue)-\(item.id)",
                exchange: .htx,
                asset: asset,
                fiat: fiat,
                side: side,
                price: price,
                availableAssetAmount: decimal(item.tradeCount),
                minFiatAmount: decimal(item.minTradeLimit),
                maxFiatAmount: decimal(item.maxTradeLimit),
                merchantName: item.userName,
                completedOrders: item.totalTradeOrderCount ?? item.tradeMonthTimes,
                completionRate: decimal(item.orderCompleteRate),
                paymentMethods: item.payMethods?.compactMap(\.name) ?? [],
                updatedAt: receivedAt
            )
        }
    }

    private static func decimal(_ value: String?) -> Decimal? {
        guard let value, !value.isEmpty else { return nil }
        return Decimal(string: value)
    }
}

private struct HTXP2PResponse: Decodable {
    let code: Int
    let success: Bool
    let data: [HTXP2PAdvertisement]
}

private struct HTXP2PAdvertisement: Decodable {
    let id: Int64
    let userName: String?
    let price: String
    let tradeCount: String?
    let minTradeLimit: String?
    let maxTradeLimit: String?
    let tradeMonthTimes: Int?
    let orderCompleteRate: String?
    let totalTradeOrderCount: Int?
    let payMethods: [HTXPaymentMethod]?
}

private struct HTXPaymentMethod: Decodable {
    let name: String?
}

private extension Stablecoin {
    var htxCoinId: Int? {
        switch self {
        case .usdt:
            return 2
        case .usdc:
            return nil
        }
    }
}

private extension FiatCurrency {
    var htxCurrencyId: Int {
        switch self {
        case .cny:
            // HTX's public OTC API exposes the CNY/CNH book under currency id 172.
            return 172
        }
    }
}

private extension UserTradeSide {
    var htxTradeType: String {
        switch self {
        case .buyStablecoin:
            return "buy"
        case .sellStablecoin:
            return "sell"
        }
    }
}
