import Foundation

public struct ReferenceRateClient: Sendable {
    public enum Error: Swift.Error, Equatable {
        case invalidURL
        case invalidResponse
        case unexpectedCurrencyPair
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchUSDCNY(source: ReferenceRateSource = .wise) async throws -> ReferenceRate {
        try await fetchRate(baseCurrencyCode: "USD", fiat: .cny, source: source)
    }

    public func fetchRate(
        baseCurrencyCode: String,
        fiat: FiatCurrency,
        source: ReferenceRateSource
    ) async throws -> ReferenceRate {
        switch source {
        case .wise:
            return try await fetchWiseRate(baseCurrencyCode: baseCurrencyCode, fiat: fiat)
        case .ecb:
            return try await fetchFrankfurterRate(baseCurrencyCode: baseCurrencyCode, fiat: fiat)
        }
    }

    public static func decodeWiseRate(
        from data: Data,
        fiat: FiatCurrency,
        fetchedAt: Date
    ) throws -> ReferenceRate {
        let response = try JSONDecoder().decode(WiseRateResponse.self, from: data)
        guard response.source == "USD", response.target == fiat.rawValue else {
            throw Error.unexpectedCurrencyPair
        }

        return ReferenceRate(
            baseCurrencyCode: response.source,
            fiat: fiat,
            rate: response.value,
            source: .wise,
            sourceDateText: dayText(milliseconds: response.time, fallback: fetchedAt),
            fetchedAt: fetchedAt
        )
    }

    public static func decodeFrankfurterRate(
        from data: Data,
        fiat: FiatCurrency,
        fetchedAt: Date
    ) throws -> ReferenceRate {
        let response = try JSONDecoder().decode(FrankfurterRateResponse.self, from: data)
        guard response.base == "USD", response.quote == fiat.rawValue else {
            throw Error.unexpectedCurrencyPair
        }

        return ReferenceRate(
            baseCurrencyCode: response.base,
            fiat: fiat,
            rate: response.rate,
            source: .ecb,
            sourceDateText: response.date,
            fetchedAt: fetchedAt
        )
    }

    private func fetchWiseRate(baseCurrencyCode: String, fiat: FiatCurrency) async throws -> ReferenceRate {
        // Wise's documented rates API requires partner auth, so this keeps C2CBar keyless via the public web rate JSON.
        guard var components = URLComponents(string: "https://wise.com/rates/live") else {
            throw Error.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "source", value: baseCurrencyCode),
            URLQueryItem(name: "target", value: fiat.rawValue)
        ]

        guard let url = components.url else {
            throw Error.invalidURL
        }

        let data = try await fetchData(from: url)
        return try Self.decodeWiseRate(from: data, fiat: fiat, fetchedAt: Date())
    }

    private func fetchFrankfurterRate(baseCurrencyCode: String, fiat: FiatCurrency) async throws -> ReferenceRate {
        // Pin Frankfurter to ECB so C2C premiums compare against a consistent official reference source.
        guard var components = URLComponents(
            string: "https://api.frankfurter.dev/v2/rate/\(baseCurrencyCode)/\(fiat.rawValue)"
        ) else {
            throw Error.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "providers", value: "ECB")
        ]

        guard let url = components.url else {
            throw Error.invalidURL
        }

        let data = try await fetchData(from: url)
        return try Self.decodeFrankfurterRate(from: data, fiat: fiat, fetchedAt: Date())
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("C2CBar/0.1", forHTTPHeaderField: "user-agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw Error.invalidResponse
        }

        return data
    }

    private static func dayText(milliseconds: Int64?, fallback: Date) -> String {
        let date = milliseconds.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) } ?? fallback
        return utcDayText(from: date)
    }

    private static func utcDayText(from date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

private struct WiseRateResponse: Decodable {
    let source: String
    let target: String
    let value: Decimal
    let time: Int64?
}

private struct FrankfurterRateResponse: Decodable {
    let date: String
    let base: String
    let quote: String
    let rate: Decimal
}
