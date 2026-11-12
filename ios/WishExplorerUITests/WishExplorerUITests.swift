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
        XCTAssertTrue(app.buttons["What are your favorites?"].waitForExistence(timeout: 5))
        recordVisualProof("01-home-grid", app: app)

        open.tap()
        assertBoardIsOpen(close: close, word: want)
        recordVisualProof("02-talking-board-open", app: app)
        close.tap()
        assertBoardIsClosed(open: open, word: want)

        let distance = app.frame.height * 0.6
        let lowerHandle = open.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        lowerHandle.press(forDuration: 0.1, thenDragTo: lowerHandle.withOffset(CGVector(dx: 0, dy: -distance)))
        assertBoardIsOpen(close: close, word: want)

        let upperHandle = close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        upperHandle.press(forDuration: 0.1, thenDragTo: upperHandle.withOffset(CGVector(dx: 0, dy: distance)))
        assertBoardIsClosed(open: open, word: want)

        app.buttons["What are your favorites?"].tap()
        let blue = app.buttons["Blue"]
        XCTAssertTrue(blue.waitForExistence(timeout: 5))
        blue.tap()
        XCTAssertTrue(blue.isSelected)
        recordVisualProof("03-favorites-intake", app: app)
        let saveFavorites = app.buttons["Save favorites"]
        reveal(saveFavorites, in: app.scrollViews.firstMatch)
        recordVisualProof("04-favorites-save-footer", app: app)
        saveFavorites.tap()

        let athlete = app.buttons["Athlete"]
        XCTAssertTrue(athlete.waitForExistence(timeout: 5))
        athlete.tap()
        XCTAssertTrue(app.staticTexts["What would you like to do?"].waitForExistence(timeout: 5))
        app.buttons["Meet an athlete"].tap()
        recordVisualProof("05-athlete-actions", app: app)
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Choose a place or thing"].waitForExistence(timeout: 5))
        app.buttons["On a field"].tap()
        recordVisualProof("06-athlete-setting", app: app)
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["What matters most?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Blue"].exists, "The intake favorite must reach the most-important part.")
        app.buttons["Meet an athlete"].tap()
        recordVisualProof("07-athlete-most-important", app: app)
        app.buttons["See my wish picture"].tap()
        XCTAssertTrue(app.staticTexts["My wish picture"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "I like blue.")).firstMatch.exists,
                      "The wish picture must describe the intake favorite.")
        recordVisualProof("08-postcard", app: app)
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
        recordVisualProof("09-grown-up-reading-check", app: app)
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

        XCTAssertTrue(app.staticTexts["grownup-settings-title"].waitForExistence(timeout: 10),
                      "The real reading check must open grown-up settings.\n\(app.debugDescription)")
        recordVisualProof("10-grown-up-settings", app: app)
        // NavigationLink's AX type can vary; its explicit identifier stays stable.
        let voice = app.descendants(matching: .any).matching(identifier: "grownup-voice-preference").firstMatch
        let privacy = app.descendants(matching: .any).matching(identifier: "grownup-privacy-data").firstMatch
        let information = app.descendants(matching: .any).matching(identifier: "grownup-app-information").firstMatch
        XCTAssertTrue(voice.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(privacy.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(information.waitForExistence(timeout: 5), app.debugDescription)
        voice.tap()
        assertSettingsPage("Voice preference", app: app)
        for label in ["Boy voice", "Girl voice", "Man voice", "Woman voice"] {
            XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 5), label)
        }
        recordVisualProof("11-voice-preference", app: app)
        returnToSettings(app)

        privacy.tap()
        assertSettingsPage("Privacy & Data", app: app)
        let remember = app.switches["Remember choices on this iPad"]
        XCTAssertTrue(remember.waitForExistence(timeout: 5))
        XCTAssertTrue(remember.isHittable)
        recordVisualProof("12-privacy-data", app: app)
        returnToSettings(app)

        XCTAssertTrue(information.waitForExistence(timeout: 5))
        information.tap()
        assertSettingsPage("App information & help", app: app)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Version")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Build")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Publisher details are not configured in this prototype."].waitForExistence(timeout: 5))
        recordVisualProof("13-app-information", app: app)
    }

    @MainActor
    private func recordVisualProof(_ name: String, app: XCUIApplication) {
        XCTContext.runActivity(named: "Visual proof: \(name)") { activity in
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }

    @MainActor
    private func assertSettingsPage(_ title: String, app: XCUIApplication) {
        let heading = app.staticTexts["grownup-page-title"]
        XCTAssertTrue(heading.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(heading.label, title)
    }

    @MainActor
    private func returnToSettings(_ app: XCUIApplication) {
        let back = app.buttons["Back to settings"]
        let page = app.scrollViews.containing(.staticText, identifier: "grownup-page-title").firstMatch
        reveal(back, in: page)
        back.tap()
        XCTAssertTrue(app.staticTexts["grownup-settings-title"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in scrollView: XCUIElement) {
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            scrollView.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "A real scroll must reveal the requested control.\n\(element)")
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
