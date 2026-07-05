import AppKit
import C2CBarCore
import SwiftUI
import UserNotifications

final class C2CBarAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard AppRuntimePolicy.supportsUserNotifications(bundleURL: Bundle.main.bundleURL) else {
            return
        }

        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}

@main
struct C2CBarApp: App {
    @NSApplicationDelegateAdaptor(C2CBarAppDelegate.self) private var appDelegate
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
