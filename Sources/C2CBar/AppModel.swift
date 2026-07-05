import Foundation
import C2CBarCore

@MainActor
final class MarketStore: ObservableObject {
    @Published var selectedAsset: Stablecoin = .usdt {
        didSet { persistPreferences() }
    }
    @Published var displayMode: DisplayMode = .standard {
        didSet { persistPreferences() }
    }
    @Published var transactionAmount: Decimal = Decimal(10_000) {
        didSet {
            persistPreferences()
            refresh()
        }
    }
    @Published var refreshIntervalSeconds = RefreshIntervalOption.defaultOption.seconds {
        didSet {
            persistPreferences()
            restartRefreshLoop()
        }
    }
    @Published var showUSDT = true {
        didSet {
            ensureSelectedAssetIsVisible()
            persistPreferences()
            refresh()
        }
    }
    @Published var showUSDC = true {
        didSet {
            ensureSelectedAssetIsVisible()
            persistPreferences()
            refresh()
        }
    }
    @Published var startAtLogin = true {
        didSet {
            persistPreferences()
            applyStartupPreference()
        }
    }
    @Published var priceAlertsEnabled = false {
        didSet {
            persistPreferences()
            if PriceAlertAuthorizationPolicy.shouldPromptForAuthorization(
                context: .userChangedSetting,
                priceAlertsEnabled: priceAlertsEnabled,
                wasPriceAlertsEnabled: oldValue
            ) {
                requestNotificationAuthorization()
            }
        }
    }
    @Published var referenceSource: ReferenceRateSource = .wise {
        didSet {
            persistPreferences()
            if oldValue != referenceSource {
                refresh()
            }
        }
    }
    @Published var fiat = FiatCurrency.cny {
        didSet {
            persistPreferences()
            refresh()
        }
    }
    @Published private(set) var visibleExchanges = C2CExchange.liveSupported {
        didSet {
            persistPreferences()
            refresh()
        }
    }
    @Published private(set) var dataState: MarketDataState = .mock
    @Published private(set) var startupStatusText = StartupServiceStatus.disabled.displayText
    @Published private(set) var notificationStatusText = NotificationServiceStatus.notRequested.displayText

    private let preferencesStorage: MarketPreferencesStorage
    private let startupService: StartupServiceManaging
    private let notificationService: PriceAlertNotifying
    private let binanceClient = BinanceP2PClient()
    private let okxClient = OKXP2PClient()
    private let htxClient = HTXP2PClient()
    private let referenceRateClient = ReferenceRateClient()
    private var liveQuotes: [C2CQuote]?
    private var liveReferenceRate: ReferenceRate?
    private var liveRefreshedAt: Date?
    private var priceAlertEvaluator = PriceAlertEvaluator()
    private var refreshTask: Task<Void, Never>?
    private var refreshLoopTask: Task<Void, Never>?

    init(
        preferencesStorage: MarketPreferencesStorage = UserDefaultsMarketPreferencesStorage(),
        startupService: StartupServiceManaging = StartupService(),
        notificationService: PriceAlertNotifying = PriceAlertNotificationService()
    ) {
        self.preferencesStorage = preferencesStorage
        self.startupService = startupService
        self.notificationService = notificationService
        let preferences = preferencesStorage.load()
        selectedAsset = preferences.selectedAsset
        displayMode = preferences.displayMode
        transactionAmount = preferences.transactionAmount
        refreshIntervalSeconds = preferences.refreshIntervalSeconds
        showUSDT = preferences.showUSDT
        showUSDC = preferences.showUSDC
        startAtLogin = preferences.startAtLogin
        priceAlertsEnabled = preferences.priceAlertsEnabled
        referenceSource = preferences.referenceSource
        fiat = preferences.fiat
        visibleExchanges = preferences.visibleExchanges
        ensureSelectedAssetIsVisible()
        refreshStartupStatus()
        applyStartupPreference()
        if PriceAlertAuthorizationPolicy.shouldPromptForAuthorization(
            context: .appLaunch,
            priceAlertsEnabled: priceAlertsEnabled,
            wasPriceAlertsEnabled: priceAlertsEnabled
        ) {
            requestNotificationAuthorization()
        }
        refresh()
        restartRefreshLoop()
    }

    deinit {
        refreshTask?.cancel()
        refreshLoopTask?.cancel()
    }

    var snapshot: MarketSnapshot {
        let quotes = (liveQuotes ?? MockMarket.quotes).filter { quote in
            visibleExchanges.contains(quote.exchange)
        }

        return MarketSnapshot(
            asset: selectedAsset,
            fiat: fiat,
            referenceRate: liveReferenceRate?.rate ?? MockMarket.referenceRate,
            quotes: quotes,
            transactionAmount: transactionAmount,
            refreshedAt: liveRefreshedAt ?? MockMarket.refreshedAt
        )
    }

    var dataSourceText: String {
        switch dataState {
        case .mock:
            "模拟数据"
        case .loading:
            liveQuotes == nil ? "加载中" : "更新中"
        case .live:
            liveSourceText
        case .failed:
            liveQuotes == nil ? "模拟数据" : "上次实时"
        }
    }

    var referenceSourceText: String {
        if let liveReferenceRate {
            return liveReferenceRate.source.displayName
        }

        switch dataState {
        case .loading:
            return referenceSource.displayName
        default:
            return "模拟"
        }
    }

    private var liveSourceText: String {
        let exchanges = Set((liveQuotes ?? []).map(\.exchange))
        let names = C2CExchange.allCases
            .filter { exchanges.contains($0) }
            .map(\.rawValue)

        return names.isEmpty ? "实时数据" : "\(names.joined(separator: "/")) 实时"
    }

    var menuTitle: String {
        switch displayMode {
        case .standard:
            return snapshot.menuTitle
        case .compact:
            guard let bestSell = snapshot.bestSell else {
                return selectedAsset.rawValue
            }
            return "\(selectedAsset.rawValue) \(StableFormat.price(bestSell.price))"
        case .minimal:
            return selectedAsset.rawValue
        }
    }

    var visibleAssets: [Stablecoin] {
        Stablecoin.allCases.filter { asset in
            switch asset {
            case .usdt:
                showUSDT
            case .usdc:
                showUSDC
            }
        }
    }

    var refreshIntervalText: String {
        RefreshIntervalOption.option(seconds: refreshIntervalSeconds).displayName
    }

    func select(_ asset: Stablecoin) {
        selectedAsset = asset
    }

    func isExchangeVisible(_ exchange: C2CExchange) -> Bool {
        visibleExchanges.contains(exchange)
    }

    func setExchange(_ exchange: C2CExchange, isVisible: Bool) {
        guard C2CExchange.liveSupported.contains(exchange) else { return }

        var next = visibleExchanges
        if isVisible {
            if !next.contains(exchange) {
                next.append(exchange)
            }
        } else {
            next.removeAll { $0 == exchange }
            if next.isEmpty {
                return
            }
        }

        visibleExchanges = C2CExchange.liveSupported.filter { next.contains($0) }
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.refreshLiveData()
        }
    }

    private func refreshLiveData() async {
        let selectedReferenceSource = referenceSource
        dataState = .loading

        async let quotesResult: Result<[C2CQuote], Error> = providerResult {
            try await fetchProviderQuotes()
        }
        async let referenceRateResult: Result<ReferenceRate, Error> = providerResult {
            try await referenceRateClient.fetchUSDCNY(source: selectedReferenceSource)
        }

        let (quotesFetch, referenceRateFetch) = await (quotesResult, referenceRateResult)

        if case let .success(referenceRate) = referenceRateFetch {
            liveReferenceRate = referenceRate
        }

        do {
            let quotes = try quotesFetch.get()
            guard !quotes.isEmpty else {
                throw MarketDataError.emptyQuotes
            }

            let refreshedAt = Date()
            liveQuotes = quotes
            liveRefreshedAt = refreshedAt
            dataState = .live(refreshedAt)
            await deliverPriceAlertsIfNeeded(now: refreshedAt)
        } catch {
            dataState = .failed(String(describing: error))
        }
    }

    private func fetchProviderQuotes() async throws -> [C2CQuote] {
        async let binanceResult: Result<[C2CQuote], Error> = visibleProviderResult(.binance) {
            try await binanceClient.fetchQuotes(
                assets: visibleAssets,
                fiat: fiat,
                transactionAmount: transactionAmount
            )
        }
        async let okxResult: Result<[C2CQuote], Error> = visibleProviderResult(.okx) {
            try await okxClient.fetchQuotes(
                assets: visibleAssets,
                fiat: fiat
            )
        }
        async let htxResult: Result<[C2CQuote], Error> = visibleProviderResult(.htx) {
            try await htxClient.fetchQuotes(
                assets: visibleAssets,
                fiat: fiat,
                transactionAmount: transactionAmount
            )
        }

        let results = await [binanceResult, okxResult, htxResult]
        let quotes = results.flatMap { result -> [C2CQuote] in
            switch result {
            case let .success(quotes):
                return quotes
            case .failure:
                return []
            }
        }

        if quotes.isEmpty {
            throw MarketDataError.emptyQuotes
        }

        return quotes
    }

    private func visibleProviderResult(
        _ exchange: C2CExchange,
        _ operation: @Sendable () async throws -> [C2CQuote]
    ) async -> Result<[C2CQuote], Error> {
        guard visibleExchanges.contains(exchange) else {
            return .success([])
        }

        return await providerResult(operation)
    }

    private func providerResult<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async -> Result<Value, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }

    private func restartRefreshLoop() {
        refreshLoopTask?.cancel()
        let interval = UInt64(RefreshIntervalOption.option(seconds: refreshIntervalSeconds).seconds)
        refreshLoopTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval * 1_000_000_000)
                guard !Task.isCancelled else { return }
                self?.refresh()
            }
        }
    }

    private func persistPreferences() {
        preferencesStorage.save(
            MarketPreferences(
                selectedAsset: selectedAsset,
                displayMode: displayMode,
                transactionAmount: transactionAmount,
                refreshIntervalSeconds: refreshIntervalSeconds,
                showUSDT: showUSDT,
                showUSDC: showUSDC,
                startAtLogin: startAtLogin,
                priceAlertsEnabled: priceAlertsEnabled,
                referenceSource: referenceSource,
                fiat: fiat,
                visibleExchanges: visibleExchanges
            )
        )
    }

    private func ensureSelectedAssetIsVisible() {
        guard !visibleAssets.contains(selectedAsset), let fallbackAsset = visibleAssets.first else {
            return
        }

        selectedAsset = fallbackAsset
    }

    private func applyStartupPreference() {
        do {
            try startupService.setEnabled(startAtLogin)
            refreshStartupStatus()
        } catch {
            startupStatusText = StartupServiceStatus.failed(error.localizedDescription).displayText
        }
    }

    private func refreshStartupStatus() {
        startupStatusText = startupService.status.displayText
    }

    private func requestNotificationAuthorization() {
        Task { [weak self] in
            guard let self else { return }
            let status = await notificationService.requestAuthorization()
            await MainActor.run {
                self.notificationStatusText = status.displayText
            }
        }
    }

    private func deliverPriceAlertsIfNeeded(now: Date) async {
        guard priceAlertsEnabled else { return }

        let events = priceAlertEvaluator.evaluate(snapshot: snapshot, now: now)
        for event in events {
            let status = await notificationService.deliver(event)
            notificationStatusText = status.displayText
        }
    }
}

enum MarketDataState: Equatable {
    case mock
    case loading
    case live(Date)
    case failed(String)

    var isLive: Bool {
        if case .live = self {
            return true
        }

        return false
    }
}

private enum MarketDataError: Error {
    case emptyQuotes
}
