import Foundation

public enum PriceAlertKind: String, Codable, Equatable, Sendable {
    case sellPremiumAboveThreshold
    case buyPriceBelowThreshold
}

public enum PriceAlertAuthorizationContext: Equatable, Sendable {
    case appLaunch
    case userChangedSetting
    case automaticAlertDelivery
}

public enum PriceAlertAuthorizationPolicy {
    public static func shouldPromptForAuthorization(
        context: PriceAlertAuthorizationContext,
        priceAlertsEnabled: Bool,
        wasPriceAlertsEnabled: Bool
    ) -> Bool {
        switch context {
        case .appLaunch, .automaticAlertDelivery:
            return false
        case .userChangedSetting:
            return priceAlertsEnabled && !wasPriceAlertsEnabled
        }
    }
}

public struct PriceAlertEvent: Equatable, Sendable {
    public let id: String
    public let kind: PriceAlertKind
    public let title: String
    public let body: String

    public init(id: String, kind: PriceAlertKind, title: String, body: String) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
    }
}

public struct PriceAlertRules: Equatable, Sendable {
    public let sellPremiumThreshold: Decimal
    public let buyPriceThreshold: Decimal

    public static let `default` = PriceAlertRules(
        sellPremiumThreshold: Decimal(string: "0.02")!,
        buyPriceThreshold: Decimal(string: "7.25")!
    )

    public init(sellPremiumThreshold: Decimal, buyPriceThreshold: Decimal) {
        self.sellPremiumThreshold = sellPremiumThreshold
        self.buyPriceThreshold = buyPriceThreshold
    }
}

public struct PriceAlertEvaluator: Sendable {
    private let rules: PriceAlertRules
    private let cooldown: TimeInterval
    // Refresh may run every minute; key by event ID so a sustained condition does not notify every cycle.
    private var lastSentAtByEventID: [String: Date]

    public init(
        rules: PriceAlertRules = .default,
        cooldown: TimeInterval = 1_800,
        lastSentAtByEventID: [String: Date] = [:]
    ) {
        self.rules = rules
        self.cooldown = cooldown
        self.lastSentAtByEventID = lastSentAtByEventID
    }

    public mutating func evaluate(snapshot: MarketSnapshot, now: Date = Date()) -> [PriceAlertEvent] {
        candidateEvents(for: snapshot).filter { event in
            guard shouldSend(eventID: event.id, now: now) else {
                return false
            }

            lastSentAtByEventID[event.id] = now
            return true
        }
    }

    private func candidateEvents(for snapshot: MarketSnapshot) -> [PriceAlertEvent] {
        var events: [PriceAlertEvent] = []

        if let sellEvent = sellPremiumEvent(for: snapshot) {
            events.append(sellEvent)
        }

        if let buyEvent = buyPriceEvent(for: snapshot) {
            events.append(buyEvent)
        }

        return events
    }

    private func sellPremiumEvent(for snapshot: MarketSnapshot) -> PriceAlertEvent? {
        guard let bestSell = snapshot.bestSell else { return nil }

        let premium = StableFormat.premium(price: bestSell.price, referenceRate: snapshot.referenceRate)
        guard premium >= rules.sellPremiumThreshold else { return nil }

        return PriceAlertEvent(
            id: "\(PriceAlertKind.sellPremiumAboveThreshold.rawValue)-\(snapshot.asset.rawValue)-\(bestSell.exchange.rawValue)",
            kind: .sellPremiumAboveThreshold,
            title: "\(snapshot.asset.rawValue) 出金溢价超过 2%",
            body: "\(bestSell.exchange.rawValue) 出金 \(StableFormat.price(bestSell.price))，高于基准 \(StableFormat.percent(premium))"
        )
    }

    private func buyPriceEvent(for snapshot: MarketSnapshot) -> PriceAlertEvent? {
        guard let bestBuy = snapshot.bestBuy else { return nil }
        guard bestBuy.price < rules.buyPriceThreshold else { return nil }

        return PriceAlertEvent(
            id: "\(PriceAlertKind.buyPriceBelowThreshold.rawValue)-\(snapshot.asset.rawValue)-\(bestBuy.exchange.rawValue)",
            kind: .buyPriceBelowThreshold,
            title: "\(bestBuy.exchange.rawValue) 入金低于 \(StableFormat.price(rules.buyPriceThreshold, fractionDigits: 2))",
            body: "\(snapshot.asset.rawValue) 入金 \(StableFormat.price(bestBuy.price))，低于提醒价 \(StableFormat.price(rules.buyPriceThreshold))"
        )
    }

    private func shouldSend(eventID: String, now: Date) -> Bool {
        guard let lastSentAt = lastSentAtByEventID[eventID] else {
            return true
        }

        return now.timeIntervalSince(lastSentAt) >= cooldown
    }
}
