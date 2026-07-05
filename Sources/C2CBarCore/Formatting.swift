import Foundation

public enum StableFormat {
    public static func price(_ value: Decimal, fractionDigits: Int = 3) -> String {
        decimal(value, fractionDigits: fractionDigits)
    }

    public static func amount(_ value: Decimal, fractionDigits: Int = 0) -> String {
        decimal(value, fractionDigits: fractionDigits)
    }

    public static func premium(price: Decimal, referenceRate: Decimal) -> Decimal {
        guard referenceRate != 0 else { return 0 }

        let priceNumber = NSDecimalNumber(decimal: price)
        let referenceNumber = NSDecimalNumber(decimal: referenceRate)
        let ratio = priceNumber.dividing(by: referenceNumber).subtracting(1)
        return ratio.decimalValue
    }

    public static func premiumText(price: Decimal, referenceRate: Decimal) -> String {
        percent(premium(price: price, referenceRate: referenceRate))
    }

    public static func premiumIndicator(price: Decimal, referenceRate: Decimal) -> PremiumIndicator {
        let ratio = premium(price: price, referenceRate: referenceRate)
        return PremiumIndicator(ratio: ratio, percentText: percentText(for: ratio))
    }

    public static func percent(_ ratio: Decimal, fractionDigits: Int = 2) -> String {
        percentText(for: ratio, fractionDigits: fractionDigits)
    }

    private static func decimal(_ value: Decimal, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits

        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }

    private static func percentText(for ratio: Decimal, fractionDigits: Int = 2) -> String {
        let percentValue = NSDecimalNumber(decimal: ratio)
            .multiplying(by: 100)
            .decimalValue
        let text = decimal(percentValue, fractionDigits: fractionDigits)
        return "\(percentValue >= 0 ? "+" : "")\(text)%"
    }
}

public enum PremiumDirection: Equatable, Sendable {
    case aboveReference
    case belowReference
    case atReference

    public var systemImageName: String {
        switch self {
        case .aboveReference:
            "arrow.up.right"
        case .belowReference:
            "arrow.down.right"
        case .atReference:
            "minus"
        }
    }

    public var shortLabel: String {
        switch self {
        case .aboveReference:
            "高"
        case .belowReference:
            "低"
        case .atReference:
            "平"
        }
    }
}

public struct PremiumIndicator: Equatable, Sendable {
    public let direction: PremiumDirection
    public let percentText: String

    public var systemImageName: String {
        direction.systemImageName
    }

    public var shortText: String {
        let text = direction == .atReference && percentText.hasPrefix("+")
            ? String(percentText.dropFirst())
            : percentText
        return "\(direction.shortLabel) \(text)"
    }

    public init(ratio: Decimal, percentText: String) {
        if ratio > 0 {
            direction = .aboveReference
        } else if ratio < 0 {
            direction = .belowReference
        } else {
            direction = .atReference
        }

        self.percentText = percentText
    }
}
