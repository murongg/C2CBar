import C2CBarAssets
import C2CBarCore
import AppKit
import SwiftUI

struct MenuPanel: View {
    @ObservedObject var store: MarketStore
    @State private var panelMode: MenuPanelMode = .market
    @State private var measuredContentHeight: CGFloat?

    private var snapshot: MarketSnapshot {
        store.snapshot
    }

    var body: some View {
        let targetSize = measuredContentHeight.map {
            MenuPanelWindowLayout.windowSize(measuredContentHeight: Double($0))
        }

        VStack(spacing: 0) {
            HeaderBar(
                store: store,
                mode: panelMode,
                onToggleSettings: {
                    panelMode.toggleSettings()
                }
            )
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()
                .overlay(Color(nsColor: .separatorColor))

            Group {
                if panelMode == .market {
                    PanelContent(store: store, snapshot: snapshot)
                } else {
                    MenuSettingsPanel(store: store)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(width: CGFloat(MenuPanelWindowLayout.width), alignment: .top)
        .background(MenuPanelHeightReader())
        .onPreferenceChange(MenuPanelHeightPreferenceKey.self) { height in
            guard height > 0, abs((measuredContentHeight ?? 0) - height) > 0.5 else {
                return
            }

            measuredContentHeight = height
        }
        .background(PanelBackground())
        .overlay {
            WindowContentSizeSynchronizer(targetSize: targetSize)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .foregroundStyle(.primary)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

private struct MenuPanelHeightReader: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: MenuPanelHeightPreferenceKey.self,
                value: proxy.size.height
            )
        }
    }
}

private struct MenuPanelHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct WindowContentSizeSynchronizer: NSViewRepresentable {
    let targetSize: MenuPanelWindowSize?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WindowSizingProbeView {
        let view = WindowSizingProbeView()
        view.onWindowChange = { [weak view, weak coordinator = context.coordinator] in
            guard let view else { return }
            coordinator?.synchronizeWindow(for: view)
        }
        return view
    }

    func updateNSView(_ view: WindowSizingProbeView, context: Context) {
        context.coordinator.targetSize = targetSize
        context.coordinator.synchronizeWindow(for: view)
    }

    @MainActor
    final class Coordinator {
        var targetSize: MenuPanelWindowSize?

        func synchronizeWindow(for view: NSView) {
            guard let targetSize, let window = view.window else {
                return
            }

            let currentSize = window.contentView?.bounds.size ?? window.contentLayoutRect.size
            let current = MenuPanelWindowSize(
                width: Double(currentSize.width),
                height: Double(currentSize.height)
            )

            guard let request = MenuPanelWindowResizeRequest.request(
                current: current,
                target: targetSize
            ) else {
                return
            }

            let targetContentSize = NSSize(
                width: request.targetSize.width,
                height: request.targetSize.height
            )
            let targetFrameSize = window.frameRect(
                forContentRect: NSRect(origin: .zero, size: targetContentSize)
            ).size
            var targetFrame = window.frame
            targetFrame.origin.y = window.frame.maxY - targetFrameSize.height
            targetFrame.size = targetFrameSize

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0
                context.allowsImplicitAnimation = false
                // Keep height flexible; locking max height here prevents later mode changes from measuring taller content.
                window.contentMinSize = NSSize(width: targetContentSize.width, height: 1)
                window.contentMaxSize = NSSize(width: targetContentSize.width, height: 10_000)
                window.setFrame(targetFrame, display: true, animate: false)
            }
        }
    }
}

@MainActor
private final class WindowSizingProbeView: NSView {
    var onWindowChange: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChange?()
    }
}

private struct PanelContent: View {
    @ObservedObject var store: MarketStore
    let snapshot: MarketSnapshot

    var body: some View {
        let policy = MenuPanelContentPolicy(displayMode: store.displayMode)

        VStack(spacing: store.displayMode.contentSpacing) {
            SummaryGrid(snapshot: snapshot, isDense: store.displayMode != .standard)

            if policy.showsReferenceRate {
                ReferenceStrip(snapshot: snapshot, source: store.referenceSourceText)
            }

            if policy.showsPlatformTable && !policy.showsCompactPlatformTable {
                PlatformTable(
                    snapshot: snapshot,
                    rowLimit: store.displayMode.visibleRowCount,
                    visibleExchanges: store.visibleExchanges
                )
            } else if policy.showsPlatformTable {
                CompactTable(
                    snapshot: snapshot,
                    rowLimit: store.displayMode.visibleRowCount,
                    visibleExchanges: store.visibleExchanges
                )
            }

            if policy.showsAlertPreview {
                AlertPreview()
            }

            if policy.showsFooter {
                FooterBar(store: store)
            }
        }
        .padding(store.displayMode.contentPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

private struct MenuSettingsPanel: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                SettingsSectionTitle("显示设置")

                SettingsRow(title: "显示币种") {
                    HStack(spacing: 18) {
                        Toggle("USDT", isOn: $store.showUSDT)
                        Toggle("USDC", isOn: $store.showUSDC)
                    }
                    .toggleStyle(.checkbox)
                }

                SettingsRow(title: "显示模式") {
                    SettingsMenuControl {
                        Picker("显示模式", selection: $store.displayMode) {
                            ForEach(DisplayMode.allCases) { mode in
                                Text("\(mode.rawValue)模式").tag(mode)
                            }
                        }
                    }
                }

                SettingsRow(title: "显示平台") {
                    ExchangeVisibilityToggles(store: store)
                }

                SettingsDivider()

                SettingsSectionTitle("价格更新")

                SettingsRow(title: "更新频率") {
                    SettingsMenuControl {
                        Picker("更新频率", selection: $store.refreshIntervalSeconds) {
                            ForEach(RefreshIntervalOption.allCases) { option in
                                Text(option.displayName).tag(option.seconds)
                            }
                        }
                    }
                }

                SettingsRow(title: "开机启动") {
                    HStack(spacing: 8) {
                        Text(store.startupStatusText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                        Toggle("", isOn: $store.startAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                SettingsRow(title: "价格提醒") {
                    HStack(spacing: 8) {
                        Text(store.notificationStatusText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                        Toggle("", isOn: $store.priceAlertsEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                SettingsDivider()

                SettingsSectionTitle("其他")

                SettingsRow(title: "基准汇率来源") {
                    SettingsMenuControl {
                        Picker("基准汇率来源", selection: $store.referenceSource) {
                            ForEach(ReferenceRateSource.allCases) { source in
                                Text(source.displayName).tag(source)
                            }
                        }
                    }
                }

                SettingsRow(title: "货币对") {
                    SettingsMenuControl {
                        Picker("货币对", selection: $store.fiat) {
                            Text("CNY").tag(FiatCurrency.cny)
                        }
                    }
                }

                SettingsDivider()

                SettingsAboutRow()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(SettingsCardBackground())
        }
        .font(.system(size: 13))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

private struct SettingsSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.primary.opacity(0.88))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
            .padding(.bottom, 6)
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.secondary)
                .frame(width: CGFloat(SettingsPanelLayout.labelWidth), alignment: .leading)

            Spacer(minLength: 12)

            content()
                .frame(
                    width: CGFloat(SettingsPanelLayout.controlColumnWidth),
                    alignment: .trailing
                )
        }
        .frame(height: 34)
    }
}

private struct ExchangeVisibilityToggles: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        HStack(spacing: 10) {
            ForEach(C2CExchange.liveSupported) { exchange in
                Toggle(
                    exchange.rawValue,
                    isOn: Binding(
                        get: { store.isExchangeVisible(exchange) },
                        set: { store.setExchange(exchange, isVisible: $0) }
                    )
                )
                .fixedSize()
            }
        }
        .font(.system(size: 12, weight: .medium))
        .toggleStyle(.checkbox)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.65))
            .frame(height: 1)
            .padding(.vertical, 7)
    }
}

private struct SettingsMenuControl<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.large)
            .frame(width: CGFloat(SettingsPanelLayout.menuControlWidth), alignment: .trailing)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.42))
            }
    }
}

private struct SettingsAboutRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("关于 C2CBar")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.secondary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
        .frame(height: 36)
    }
}

private struct SettingsCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 1)
            }
    }
}

private struct HeaderBar: View {
    @ObservedObject var store: MarketStore
    let mode: MenuPanelMode
    let onToggleSettings: () -> Void

    var body: some View {
        let tabWidth: CGFloat = store.displayMode == .minimal ? 150 : 180

        HStack(spacing: 10) {
            if mode.showsMarketControls {
                AssetTabs(
                    assets: store.visibleAssets,
                    selectedAsset: store.selectedAsset,
                    width: tabWidth,
                    onSelect: store.select
                )

                Spacer(minLength: 8)

                Button {
                    store.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(IconButtonStyle())
                .help("刷新")
            } else {
                Text(mode.title ?? "")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.primary)

                Spacer()
            }

            Button(action: onToggleSettings) {
                Image(systemName: mode.trailingSystemImageName)
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(IconButtonStyle())
            .help(mode == .settings ? "关闭设置" : "设置")
        }
        .frame(height: 38)
    }
}

private struct AssetTabs: View {
    private let spacing: CGFloat = 3
    private let horizontalPadding: CGFloat = 3

    let assets: [Stablecoin]
    let selectedAsset: Stablecoin
    let width: CGFloat
    let onSelect: (Stablecoin) -> Void

    var body: some View {
        let segmentWidth = CGFloat(
            SegmentedHitTargetLayout.segmentWidth(
                containerWidth: Double(width),
                itemCount: assets.count,
                spacing: Double(spacing),
                horizontalPadding: Double(horizontalPadding)
            )
        )

        HStack(spacing: spacing) {
            ForEach(assets) { asset in
                Button {
                    onSelect(asset)
                } label: {
                    HStack(spacing: 5) {
                        TokenBadge(stablecoin: asset, size: 17)

                        Text(asset.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(asset == selectedAsset ? Color.accentColor : Color.primary)
                    .frame(width: segmentWidth, height: 32)
                    .background {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(asset == selectedAsset ? Color.accentColor.opacity(0.22) : Color.clear)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(horizontalPadding)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.ultraThinMaterial)
                .background {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.24))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.7), lineWidth: 1)
                }
        }
        .frame(width: width, height: 38)
    }
}

private struct TokenBadge: View {
    let stablecoin: Stablecoin
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
                .overlay {
                    Circle()
                        .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 0.5)
                }

            if let image = TokenLogoResource.image(for: stablecoin) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
            } else {
                Text(String(stablecoin.rawValue.prefix(1)))
                    .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(Text(stablecoin.rawValue))
    }
}

private struct SummaryGrid: View {
    let snapshot: MarketSnapshot
    let isDense: Bool

    var body: some View {
        HStack(spacing: 12) {
            SummaryMetric(
                title: "入金最低",
                subtitle: "买入",
                quote: snapshot.bestBuy,
                tint: .green,
                premiumIndicator: snapshot.bestBuy.map {
                    StableFormat.premiumIndicator(price: $0.price, referenceRate: snapshot.referenceRate)
                },
                isDense: isDense
            )

            SummaryMetric(
                title: "出金最高",
                subtitle: "卖出",
                quote: snapshot.bestSell,
                tint: .red,
                premiumIndicator: snapshot.bestSell.map {
                    StableFormat.premiumIndicator(price: $0.price, referenceRate: snapshot.referenceRate)
                },
                isDense: isDense
            )
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let subtitle: String
    let quote: C2CQuote?
    let tint: Color
    let premiumIndicator: PremiumIndicator?
    let isDense: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isDense ? 6 : 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Text("(\(subtitle))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.72))
            }

            Text(quote.map { StableFormat.price($0.price) } ?? "--")
                .font(.system(size: isDense ? 25 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 7) {
                ExchangeBadge(exchange: quote?.exchange, size: 22)

                Text(quote?.exchange.rawValue ?? "暂无")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .layoutPriority(1)

                Spacer(minLength: 2)

                PremiumPill(indicator: premiumIndicator)
            }
        }
        .padding(isDense ? 12 : 13)
        .frame(maxWidth: .infinity, minHeight: isDense ? 100 : 112, alignment: .leading)
        .background(CardBackground())
    }
}

private struct PremiumPill: View {
    let indicator: PremiumIndicator?

    var body: some View {
        HStack(spacing: 4) {
            if let indicator {
                Image(systemName: indicator.systemImageName)
                    .font(.system(size: 11, weight: .bold))

                Text(indicator.shortText)
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
            } else {
                Text("--")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(accessibilityText)
    }

    private var tint: Color {
        switch indicator?.direction {
        case .aboveReference:
            Color.green
        case .belowReference:
            Color.red
        case .atReference:
            Color.secondary
        case nil:
            Color.secondary
        }
    }

    private var accessibilityText: Text {
        guard let indicator else {
            return Text("暂无溢价")
        }

        switch indicator.direction {
        case .aboveReference:
            return Text("高于基准 \(indicator.percentText)")
        case .belowReference:
            return Text("低于基准 \(indicator.percentText)")
        case .atReference:
            return Text("等于基准")
        }
    }
}

private struct ReferenceStrip: View {
    let snapshot: MarketSnapshot
    let source: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("USD/CNY")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
                Text(StableFormat.price(snapshot.referenceRate))
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(source)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                Text("入 \(snapshot.buyPremiumText)  出 \(snapshot.sellPremiumText)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(CardBackground())
    }
}

private struct PlatformTable: View {
    let snapshot: MarketSnapshot
    let rowLimit: Int
    let visibleExchanges: [C2CExchange]

    private var rows: [PlatformQuoteRow] {
        snapshot.platformRows(limit: rowLimit, visibleExchanges: visibleExchanges)
    }

    private var placeholderCount: Int {
        max(0, snapshot.platformRowCapacity(limit: rowLimit, visibleExchanges: visibleExchanges) - rows.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("平台")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("入金")
                    .frame(width: 70, alignment: .trailing)
                Text("出金")
                    .frame(width: 70, alignment: .trailing)
                Text("溢价")
                    .frame(width: 54, alignment: .trailing)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            ForEach(rows, id: \.exchange) { row in
                PlatformRow(
                    exchange: row.exchange,
                    buy: row.buy,
                    sell: row.sell,
                    referenceRate: snapshot.referenceRate
                )
            }

            ForEach(0..<placeholderCount, id: \.self) { _ in
                PlatformRow(
                    exchange: .binance,
                    buy: nil,
                    sell: nil,
                    referenceRate: snapshot.referenceRate
                )
                .hidden()
                .accessibilityHidden(true)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(CardBackground())
    }
}

private struct PlatformRow: View {
    let exchange: C2CExchange
    let buy: C2CQuote?
    let sell: C2CQuote?
    let referenceRate: Decimal

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ExchangeBadge(exchange: exchange, size: 20)
                Text(exchange.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(priceText(buy))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)

            Text(priceText(sell))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.red)
                .monospacedDigit()
                .frame(width: 70, alignment: .trailing)

            Text(premiumText(sell ?? buy))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.green)
                .monospacedDigit()
                .frame(width: 54, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func priceText(_ quote: C2CQuote?) -> String {
        quote.map { StableFormat.price($0.price) } ?? "--"
    }

    private func premiumText(_ quote: C2CQuote?) -> String {
        guard let quote else { return "--" }
        return StableFormat.premiumText(price: quote.price, referenceRate: referenceRate)
    }
}

private struct CompactTable: View {
    let snapshot: MarketSnapshot
    let rowLimit: Int
    let visibleExchanges: [C2CExchange]

    private var rows: [PlatformQuoteRow] {
        snapshot.platformRows(limit: rowLimit, visibleExchanges: visibleExchanges)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows, id: \.exchange) { row in
                CompactPlatformRow(row: row, priceText: priceText)
            }
        }
        .background(CardBackground())
    }

    private func priceText(_ quote: C2CQuote?) -> String {
        quote.map { StableFormat.price($0.price) } ?? "--"
    }
}

private struct CompactPlatformRow: View {
    let row: PlatformQuoteRow
    let priceText: (C2CQuote?) -> String

    var body: some View {
        HStack(spacing: 10) {
            ExchangeBadge(exchange: row.exchange, size: 22)
            Text(row.exchange.rawValue)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(priceText(row.buy))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(row.buy == nil ? Color.secondary : Color.green)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct AlertPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("价格提醒")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)

            HStack(spacing: 10) {
                AlertCard(
                    icon: "bell.fill",
                    tint: .green,
                    title: "USDT 出金溢价超过 2%",
                    subtitle: "当前出金溢价 +1.99%"
                )

                AlertCard(
                    icon: "bell.fill",
                    tint: .red,
                    title: "入金低于 7.25",
                    subtitle: "当前入金价 7.246"
                )
            }
        }
    }
}

private struct AlertCard: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 26, height: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(CardBackground())
    }
}

private struct FooterBar: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        HStack(spacing: 10) {
            Label("\(store.refreshIntervalText)更新", systemImage: "clock")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)

            Spacer()

            Text(store.dataSourceText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(store.dataState.isLive ? Color.green : Color.secondary)
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.16), value: store.dataSourceText)

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.accentColor)
        }
    }
}

private struct ExchangeBadge: View {
    let exchange: C2CExchange?
    let size: CGFloat

    var body: some View {
        ZStack {
            logoOrFallback
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var logoOrFallback: some View {
        if let exchange, let image = ExchangeLogoResource.image(for: exchange) {
            Circle()
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.82))
                .overlay {
                    Circle()
                        .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 0.5)
                }

            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding(logoPadding)
                .accessibilityLabel(Text(exchange.rawValue))
        } else {
            Circle()
                .fill(color)

            Text(initial)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var logoPadding: CGFloat {
        switch exchange {
        case .binance, .gate, .mexc:
            size * 0.18
        case .okx:
            size * 0.17
        case .bybit, .bitget, .htx:
            size * 0.10
        case nil:
            0
        }
    }

    private var initial: String {
        guard let exchange else { return "-" }

        switch exchange {
        case .binance:
            return "B"
        case .okx:
            return "O"
        case .htx:
            return "H"
        case .gate:
            return "G"
        case .mexc:
            return "M"
        case .bybit:
            return "Y"
        case .bitget:
            return "T"
        }
    }

    private var color: Color {
        guard let exchange else { return .gray }

        switch exchange {
        case .binance:
            return .yellow
        case .okx:
            return .secondary
        case .htx:
            return .cyan
        case .gate:
            return .blue
        case .mexc:
            return .mint
        case .bybit:
            return .orange
        case .bitget:
            return .teal
        }
    }
}

private extension DisplayMode {
    var contentPadding: CGFloat {
        switch self {
        case .standard:
            14
        case .compact, .minimal:
            12
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .standard:
            10
        case .compact, .minimal:
            8
        }
    }
}
