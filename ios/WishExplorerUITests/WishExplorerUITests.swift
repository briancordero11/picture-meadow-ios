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
        assertBoardIsClosed(open: open, word: want)

        open.tap()
        assertBoardIsOpen(close: close, word: want)
        close.tap()
        assertBoardIsClosed(open: open, word: want)

        let distance = app.frame.height * 0.6
        let lowerHandle = open.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        lowerHandle.press(forDuration: 0.1, thenDragTo: lowerHandle.withOffset(CGVector(dx: 0, dy: -distance)))
        assertBoardIsOpen(close: close, word: want)

        let upperHandle = close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        upperHandle.press(forDuration: 0.1, thenDragTo: upperHandle.withOffset(CGVector(dx: 0, dy: distance)))
        assertBoardIsClosed(open: open, word: want)
    }

    @MainActor
    private func assertBoardIsOpen(close: XCUIElement, word: XCUIElement) {
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        let usable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: word)
        XCTAssertEqual(XCTWaiter.wait(for: [usable], timeout: 5), .completed,
                       "An open board must expose a usable word tile.")
    }

    @MainActor
    private func assertBoardIsClosed(open: XCUIElement, word: XCUIElement) {
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        // Mounted offscreen content can still exist in XCUI's hierarchy.
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == false"), object: word)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 5), .completed,
                       "A closed board must keep word tiles out of touch navigation.")
    }

}
