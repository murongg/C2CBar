import Foundation

public enum SegmentedHitTargetLayout {
    public static func segmentWidth(
        containerWidth: Double,
        itemCount: Int,
        spacing: Double,
        horizontalPadding: Double
    ) -> Double {
        guard itemCount > 0, containerWidth.isFinite else { return 0 }

        let totalSpacing = spacing * Double(max(0, itemCount - 1))
        let availableWidth = containerWidth - horizontalPadding * 2 - totalSpacing
        return max(0, availableWidth / Double(itemCount))
    }
}
