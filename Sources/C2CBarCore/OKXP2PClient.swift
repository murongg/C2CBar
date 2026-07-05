import Foundation

public struct OKXP2PClient: Sendable {
    public enum Error: Swift.Error, Equatable {
        case invalidURL
        case invalidResponse
        case apiError(code: Int)
    }

    private let endpoint = URL(string: "https://www.okx.com/v3/c2c/tradingOrders/books")!
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchQuotes(
        assets: [Stablecoin],
        fiat: FiatCurrency
    ) async throws -> [C2CQuote] {
        var quotes: [C2CQuote] = []

        for asset in assets {
            for side in UserTradeSide.allCases {
                quotes += try await fetchQuotes(asset: asset, fiat: fiat, side: side)
            }
        }

        return quotes
    }

    public func fetchQuotes(
        asset: Stablecoin,
        fiat: FiatCurrency,
        side: UserTradeSide
    ) async throws -> [C2CQuote] {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw Error.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "side", value: side.okxBookSide),
            URLQueryItem(name: "baseCurrency", value: asset.rawValue.lowercased()),
            URLQueryItem(name: "quoteCurrency", value: fiat.rawValue.lowercased()),
            URLQueryItem(name: "userType", value: "all"),
            URLQueryItem(name: "paymentMethod", value: "all"),
            URLQueryItem(name: "t", value: "\(Int(Date().timeIntervalSince1970 * 1000))")
        ]

        guard let url = components.url else {
            throw Error.invalidURL
        }

        var request = URLRequest(url: url)
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
        let response = try JSONDecoder().decode(OKXP2PResponse.self, from: data)
        guard response.code == 0 else {
            throw Error.apiError(code: response.code)
        }

        return response.data.items(for: side).compactMap { item in
            guard let price = Decimal(string: item.price) else {
                return nil
            }

            return C2CQuote(
                id: "okx-\(asset.rawValue.lowercased())-\(side.rawValue)-\(item.id)",
                exchange: .okx,
                asset: asset,
                fiat: fiat,
                side: side,
                price: price,
                availableAssetAmount: decimal(item.availableAmount),
                minFiatAmount: decimal(item.quoteMinAmountPerOrder),
                maxFiatAmount: decimal(item.quoteMaxAmountPerOrder),
                merchantName: item.nickName,
                completedOrders: item.completedOrderQuantity,
                completionRate: decimal(item.completedRate),
                paymentMethods: item.paymentMethods,
                updatedAt: receivedAt
            )
        }
    }

    private static func decimal(_ value: String?) -> Decimal? {
        guard let value, !value.isEmpty else { return nil }
        return Decimal(string: value)
    }
}

private struct OKXP2PResponse: Decodable {
    let code: Int
    let data: OKXP2PBooks
}

private struct OKXP2PBooks: Decodable {
    let buy: [OKXP2PAdvertisement]
    let sell: [OKXP2PAdvertisement]

    func items(for side: UserTradeSide) -> [OKXP2PAdvertisement] {
        switch side {
        case .buyStablecoin:
            sell
        case .sellStablecoin:
            buy
        }
    }
}

private struct OKXP2PAdvertisement: Decodable {
    let id: String
    let availableAmount: String?
    let completedOrderQuantity: Int?
    let completedRate: String?
    let nickName: String?
    let paymentMethods: [String]
    let price: String
    let quoteMaxAmountPerOrder: String?
    let quoteMinAmountPerOrder: String?
}

private extension UserTradeSide {
    var okxBookSide: String {
        switch self {
        case .buyStablecoin:
            return "sell"
        case .sellStablecoin:
            return "buy"
        }
    }
}
