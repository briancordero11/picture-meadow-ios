import XCTest
@testable import WishExplorer

final class CommunicationDrawerTests: XCTestCase {
    func testUpwardDragFollowsFingerFromCollapsedHeight() {
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 48, translation: -120, expandedHeight: 600), 168)
    }

    func testDownwardDragFollowsFingerFromExpandedHeight() {
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 600, translation: 120, expandedHeight: 600), 480)
    }

    func testDraggingCannotOvershootEitherEndpoint() {
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 48, translation: 200, expandedHeight: 600), 48)
        XCTAssertEqual(CommunicationDrawerGeometry.height(startHeight: 600, translation: -200, expandedHeight: 600), 600)
    }

    func testSnapUsesProjectedEndPositionInBothDirections() {
        XCTAssertTrue(CommunicationDrawerGeometry.shouldExpand(startHeight: 48, predictedEndTranslation: -400, expandedHeight: 600))
        XCTAssertFalse(CommunicationDrawerGeometry.shouldExpand(startHeight: 600, predictedEndTranslation: 400, expandedHeight: 600))
    }

    func testShortSlowDragReturnsToCurrentEndpoint() {
        XCTAssertFalse(CommunicationDrawerGeometry.shouldExpand(startHeight: 48, predictedEndTranslation: -40, expandedHeight: 600))
        XCTAssertTrue(CommunicationDrawerGeometry.shouldExpand(startHeight: 600, predictedEndTranslation: 40, expandedHeight: 600))
    }

    func testCompactContainerKeepsAValidHandleHeight() {
        XCTAssertEqual(CommunicationDrawerGeometry.clampedHeight(200, expandedHeight: 20), 48)
        XCTAssertFalse(CommunicationDrawerGeometry.shouldExpand(startHeight: 48, predictedEndTranslation: -400, expandedHeight: 20))
    }
}
