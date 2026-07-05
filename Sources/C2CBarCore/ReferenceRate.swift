import Foundation

public enum ReferenceRateSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case wise = "Wise"
    case ecb = "ECB"

    public var id: String { rawValue }

    public var displayName: String { rawValue }
}

public struct ReferenceRate: Equatable, Sendable {
    public let baseCurrencyCode: String
    public let fiat: FiatCurrency
    public let rate: Decimal
    public let source: ReferenceRateSource
    public let sourceDateText: String
    public let fetchedAt: Date

    public init(
        baseCurrencyCode: String,
        fiat: FiatCurrency,
        rate: Decimal,
        source: ReferenceRateSource,
        sourceDateText: String,
        fetchedAt: Date
    ) {
        self.baseCurrencyCode = baseCurrencyCode
        self.fiat = fiat
        self.rate = rate
        self.source = source
        self.sourceDateText = sourceDateText
        self.fetchedAt = fetchedAt
    }
}
