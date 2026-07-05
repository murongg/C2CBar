import Foundation

public enum AppRuntimePolicy {
    public static func supportsUserNotifications(bundleURL: URL) -> Bool {
        bundleURL.pathExtension == "app"
    }
}
