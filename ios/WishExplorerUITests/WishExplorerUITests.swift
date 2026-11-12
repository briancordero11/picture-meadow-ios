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
    func testGrownUpSettingsExposePrivacyAndAppInformationThroughTheReadingGate() throws {
        let app = XCUIApplication()
        app.launch()
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()

        let prefix = "Code in words: "
        let challenge = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(challenge.waitForExistence(timeout: 5))
        let names = String(challenge.label.dropFirst(prefix.count)).components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let digits = ["zero": "0", "one": "1", "two": "2", "three": "3", "four": "4",
                      "five": "5", "six": "6", "seven": "7", "eight": "8", "nine": "9"]
        let answer = names.compactMap { digits[$0] }
        XCTAssertEqual(names.count, 4)
        let code = try XCTUnwrap(answer.count == 4 ? answer.joined() : nil)
        let input = app.textFields["Enter the four-digit code"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText(code)
        XCTAssertEqual(input.value as? String, code, "The visible reading-check answer must be entered before continuing.")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.navigationBars["For grown-ups"].waitForExistence(timeout: 10),
                      "The real reading check must open grown-up settings.\n\(app.debugDescription)")
        // NavigationLink's AX type can vary; its explicit identifier stays stable.
        let privacy = app.descendants(matching: .any).matching(identifier: "grownup-privacy-data").firstMatch
        let information = app.descendants(matching: .any).matching(identifier: "grownup-app-information").firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(information.waitForExistence(timeout: 5), app.debugDescription)
        privacy.tap()
        let remember = app.switches["Remember choices on this iPad"]
        XCTAssertTrue(remember.waitForExistence(timeout: 5))
        XCTAssertTrue(remember.isHittable)
        app.navigationBars["Privacy & Data"].buttons.firstMatch.tap()

        XCTAssertTrue(information.waitForExistence(timeout: 5))
        information.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Version")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Build")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Publisher details are not configured in this prototype."].waitForExistence(timeout: 5))
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
