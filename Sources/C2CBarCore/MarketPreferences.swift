import Foundation

public struct MarketPreferences: Codable, Equatable, Sendable {
    public let selectedAsset: Stablecoin
    public let displayMode: DisplayMode
    public let transactionAmount: Decimal
    public let refreshIntervalSeconds: Int
    public let showUSDT: Bool
    public let showUSDC: Bool
    public let referenceSource: ReferenceRateSource
    public let fiat: FiatCurrency
    public let visibleExchanges: [C2CExchange]

    public static let `default` = MarketPreferences(
        selectedAsset: .usdt,
        displayMode: .standard,
        transactionAmount: Decimal(10_000),
        refreshIntervalSeconds: RefreshIntervalOption.defaultOption.seconds,
        showUSDT: true,
        showUSDC: true,
        referenceSource: .wise,
        fiat: .cny,
        visibleExchanges: C2CExchange.liveSupported
    )

    public init(
        selectedAsset: Stablecoin,
        displayMode: DisplayMode,
        transactionAmount: Decimal,
        refreshIntervalSeconds: Int,
        showUSDT: Bool,
        showUSDC: Bool,
        referenceSource: ReferenceRateSource,
        fiat: FiatCurrency,
        visibleExchanges: [C2CExchange]
    ) {
        self.selectedAsset = selectedAsset
        self.displayMode = displayMode
        self.transactionAmount = transactionAmount
        self.refreshIntervalSeconds = RefreshIntervalOption.option(seconds: refreshIntervalSeconds).seconds
        self.showUSDT = showUSDT
        self.showUSDC = showUSDC
        self.referenceSource = referenceSource
        self.fiat = fiat
        // Only persist exchanges backed by live clients, so legacy or unsupported values do not reappear in settings.
        self.visibleExchanges = C2CExchange.liveSupported.filter { visibleExchanges.contains($0) }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = MarketPreferences.default

        self.init(
            selectedAsset: try container.decodeIfPresent(Stablecoin.self, forKey: .selectedAsset) ?? fallback.selectedAsset,
            displayMode: try container.decodeIfPresent(DisplayMode.self, forKey: .displayMode) ?? fallback.displayMode,
            transactionAmount: try container.decodeIfPresent(Decimal.self, forKey: .transactionAmount) ?? fallback.transactionAmount,
            refreshIntervalSeconds: try container.decodeIfPresent(Int.self, forKey: .refreshIntervalSeconds) ?? fallback.refreshIntervalSeconds,
            showUSDT: try container.decodeIfPresent(Bool.self, forKey: .showUSDT) ?? fallback.showUSDT,
            showUSDC: try container.decodeIfPresent(Bool.self, forKey: .showUSDC) ?? fallback.showUSDC,
            referenceSource: try container.decodeIfPresent(ReferenceRateSource.self, forKey: .referenceSource) ?? fallback.referenceSource,
            fiat: try container.decodeIfPresent(FiatCurrency.self, forKey: .fiat) ?? fallback.fiat,
            visibleExchanges: try container.decodeIfPresent([C2CExchange].self, forKey: .visibleExchanges) ?? fallback.visibleExchanges
        )
    }
}
