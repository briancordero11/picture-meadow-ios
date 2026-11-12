import CoreGraphics
import XCTest

final class WishExplorerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTalkingBoardTapAndDrag() {
        let app = XCUIApplication()
        app.launch()

        let open = app.buttons["Open talking board"]
        let close = app.buttons["Close talking board"]
        let want = app.buttons["Want"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        XCTAssertFalse(want.exists, "Words must stay hidden while the board is closed.")

        open.tap()
        assertBoardIsOpen(close: close, word: want)
        close.tap()
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        XCTAssertFalse(want.exists)

        let distance = app.frame.height * 0.6
        let lowerHandle = open.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        lowerHandle.press(forDuration: 0.1, thenDragTo: lowerHandle.withOffset(CGVector(dx: 0, dy: -distance)))
        assertBoardIsOpen(close: close, word: want)

        let upperHandle = close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        upperHandle.press(forDuration: 0.1, thenDragTo: upperHandle.withOffset(CGVector(dx: 0, dy: distance)))
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        XCTAssertFalse(want.exists, "Closing must hide the words from accessibility and touch navigation.")
    }

    @MainActor
    private func assertBoardIsOpen(close: XCUIElement, word: XCUIElement) {
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        XCTAssertTrue(word.isHittable, "An open board must expose a usable word tile.")
    }

}
