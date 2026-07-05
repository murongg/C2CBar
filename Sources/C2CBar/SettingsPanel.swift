import C2CBarCore
import SwiftUI

struct SettingsPanel: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置")
                    .font(.system(size: 22, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 14)

            Divider()

            Form {
                Section("显示") {
                    Toggle("USDT", isOn: $store.showUSDT)
                    Toggle("USDC", isOn: $store.showUSDC)

                    Picker("显示模式", selection: $store.displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    ForEach(C2CExchange.liveSupported) { exchange in
                        Toggle(
                            exchange.rawValue,
                            isOn: Binding(
                                get: { store.isExchangeVisible(exchange) },
                                set: { store.setExchange(exchange, isVisible: $0) }
                            )
                        )
                    }
                }

                Section("刷新") {
                    Picker("更新频率", selection: $store.refreshIntervalSeconds) {
                        ForEach(RefreshIntervalOption.allCases) { option in
                            Text(option.displayName).tag(option.seconds)
                        }
                    }
                }

                Section("基准") {
                    Picker("汇率来源", selection: $store.referenceSource) {
                        ForEach(ReferenceRateSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }

                    Picker("货币对", selection: $store.fiat) {
                        Text("CNY").tag(FiatCurrency.cny)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 380, height: 460)
    }
}
