import XCTest
@testable import WishExplorer

final class CommunicationDrawerTests: XCTestCase {
    func testUpwardDragFollowsFingerFromCollapsedHeight() {
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 44, translation: -120, expandedHeight: 600), 164)
    }

    func testDownwardDragFollowsFingerFromExpandedHeight() {
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 600, translation: 120, expandedHeight: 600), 480)
    }

    func testDraggingCannotOvershootEitherEndpoint() {
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 44, translation: 200, expandedHeight: 600), 44)
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 600, translation: -200, expandedHeight: 600), 600)
    }

    func testSnapUsesProjectedEndPositionInBothDirections() {
        XCTAssertTrue(CommunicationDrawerGeometry.shouldExpand(startHeight: 44, predictedEndTranslation: -400, expandedHeight: 600))
        XCTAssertFalse(CommunicationDrawerGeometry.shouldExpand(startHeight: 600, predictedEndTranslation: 400, expandedHeight: 600))
    }

    func testShortSlowDragReturnsToCurrentEndpoint() {
        XCTAssertFalse(CommunicationDrawerGeometry.shouldExpand(startHeight: 44, predictedEndTranslation: -40, expandedHeight: 600))
        XCTAssertTrue(CommunicationDrawerGeometry.shouldExpand(startHeight: 600, predictedEndTranslation: 40, expandedHeight: 600))
    }

    func testCompactContainerKeepsAValidHandleHeight() {
        XCTAssertEqual(CommunicationDrawerGeometry.clampedHeight(200, expandedHeight: 20), 44)
        XCTAssertFalse(CommunicationDrawerGeometry.shouldExpand(startHeight: 44, predictedEndTranslation: -400, expandedHeight: 20))
    }
}
