import AppKit
import C2CBarCore
import SwiftUI

@main
struct C2CBarApp: App {
    @StateObject private var store = MarketStore()

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(store: store)
                .frame(width: panelWidth, alignment: .top)
        } label: {
            Label(store.menuTitle, systemImage: "dollarsign.circle.fill")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsPanel(store: store)
        }
    }

    private var panelWidth: CGFloat {
        CGFloat(MenuPanelWindowLayout.width)
    }

}
