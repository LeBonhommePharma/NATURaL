import XCTest

/// Release journeys: fresh launch, free session entry and local-data navigation.
final class WorkoutFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-natural.didFinishWelcome", "NO",
                               "-natural.motionCoachHeroDismissed", "NO"]
        app.launch()
        addUIInterruptionMonitor(withDescription: "Optional media permissions") { alert in
            for label in ["Don’t Allow", "Don't Allow", "Not Now"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
    }

    private func finishWelcome() {
        let continueButton = app.buttons["welcome.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10), "Welcome must launch without a crash or permissions gate")
        for _ in 0..<5 where !continueButton.isHittable { app.swipeUp() }
        XCTAssertTrue(continueButton.isHittable)
        let welcome = XCTAttachment(screenshot: app.screenshot())
        welcome.name = "Welcome"
        welcome.lifetime = .keepAlways
        add(welcome)
        continueButton.tap()
        XCTAssertTrue(app.buttons["home.about"].waitForExistence(timeout: 5))
    }

    private func startSessionFromReady() {
        let begin = app.buttons["Begin Session"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5), "Ready screen must offer Begin Session")
        for _ in 0..<8 where !begin.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(begin.isHittable, "Begin Session must be tappable without a camera/paywall overlay")
        begin.tap()
    }

    func testWelcomeLeadsToFreeSession() {
        finishWelcome()
        let start = app.buttons["home.start"]
        for _ in 0..<4 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "Home"
        home.lifetime = .keepAlways
        add(home)
        start.tap()
        XCTAssertTrue(app.buttons["Begin Session"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Subscribe"].exists)
    }

    func testLargestTextKeepsWelcomeAndSessionEntryReachable() {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        finishWelcome()
        let start = app.buttons["home.start"]
        for _ in 0..<8 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        start.tap()
        let begin = app.buttons["Begin Session"]
        for _ in 0..<8 where !begin.isHittable { app.swipeUp() }
        XCTAssertTrue(begin.isHittable)
        let preview = XCTAttachment(screenshot: app.screenshot())
        preview.name = "Session entry at largest text size"
        preview.lifetime = .keepAlways
        add(preview)
    }

    func testSessionCanPauseResumeAndEnd() {
        finishWelcome()
        app.buttons["home.start"].tap()
        startSessionFromReady()
        let control = app.buttons["session.pauseResume"]
        XCTAssertTrue(control.waitForExistence(timeout: 8))
        control.tap()
        XCTAssertTrue(control.label.contains("Resume"))
        control.tap()
        XCTAssertTrue(control.label.contains("Pause"))
        // End during countdown: this must remain responsive without sensor permissions.
        addUIInterruptionMonitor(withDescription: "Optional music access") { alert in
            if alert.buttons["Don’t Allow"].exists { alert.buttons["Don’t Allow"].tap(); return true }
            if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
            return false
        }
        app.buttons["session.end"].tap()
        XCTAssertTrue(app.buttons["summary.done"].waitForExistence(timeout: 8))
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.buttons["home.about"].waitForExistence(timeout: 5))
    }

    func testActivePoseCanPauseAndFinish() {
        finishWelcome()
        app.buttons["home.start"].tap()
        startSessionFromReady()
        XCTAssertTrue(app.staticTexts["session.pose.name"].waitForExistence(timeout: 15))
        app.tap() // Dispatch an optional system permission interruption to its monitor.
        let pause = app.buttons["session.pauseResume"]
        pause.tap()
        XCTAssertTrue(pause.label.contains("Resume"))
        let preview = XCTAttachment(screenshot: app.screenshot())
        preview.name = "Paused guided session"
        preview.lifetime = .keepAlways
        add(preview)
        pause.tap()
        app.buttons["session.end"].tap()
        XCTAssertTrue(app.buttons["summary.done"].waitForExistence(timeout: 8))
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.buttons["home.history"].waitForExistence(timeout: 5))
    }

    func testLocalHistoryAvailableWithoutHealthAuthorization() {
        finishWelcome()
        app.buttons["home.history"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Refresh Health history"].exists)
    }

    func testPrivacyAndHealthControlsAreReachable() {
        finishWelcome()
        app.buttons["home.about"].tap()
        XCTAssertTrue(app.navigationBars["About & Privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Choose Health permissions"].exists)
    }
}
