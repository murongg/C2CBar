import Foundation

public protocol MarketPreferencesStorage {
    func load() -> MarketPreferences
    func save(_ preferences: MarketPreferences)
}

public final class UserDefaultsMarketPreferencesStorage: MarketPreferencesStorage {
    private let userDefaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        userDefaults: UserDefaults = .standard,
        key: String = "C2CBar.marketPreferences.v1"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func load() -> MarketPreferences {
        guard
            let data = userDefaults.data(forKey: key),
            let preferences = try? decoder.decode(MarketPreferences.self, from: data)
        else {
            return .default
        }

        return preferences
    }

    public func save(_ preferences: MarketPreferences) {
        guard let data = try? encoder.encode(preferences) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }
}
