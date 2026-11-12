import Foundation

enum CommunicationDrawerGeometry {
    static let collapsedHeight: CGFloat = 44

    static func clampedHeight(_ height: CGFloat, expandedHeight: CGFloat) -> CGFloat {
        min(max(height, collapsedHeight), max(collapsedHeight, expandedHeight))
    }

    static func height(startHeight: CGFloat, translation: CGFloat, expandedHeight: CGFloat) -> CGFloat {
        clampedHeight(startHeight - translation, expandedHeight: expandedHeight)
    }

    static func shouldExpand(startHeight: CGFloat, predictedEndTranslation: CGFloat, expandedHeight: CGFloat) -> Bool {
        guard expandedHeight > collapsedHeight else { return false }
        let projectedHeight = height(
            startHeight: startHeight,
            translation: predictedEndTranslation,
            expandedHeight: expandedHeight
        )
        return projectedHeight >= (collapsedHeight + expandedHeight) / 2
    }
}
