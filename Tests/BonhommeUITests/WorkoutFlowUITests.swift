import XCTest
import UIKit

/// Release journeys: fresh launch, free session entry and local-data navigation.
final class WorkoutFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-natural.didFinishWelcome", "NO",
                               "-natural.motionCoachHeroDismissed", "NO"]
        // Apply Dynamic Type before the first launch. Terminate+relaunch on CI
        // can miss welcome.continue (PR journeys flake on b2cc3f8).
        if name.contains("LargestText") {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
            ]
        }
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
        let continueButton = app.descendants(matching: .any)["welcome.continue"]
        let timeout: TimeInterval = name.contains("LargestText") ? 20 : 12
        XCTAssertTrue(continueButton.waitForExistence(timeout: timeout), "Welcome must launch without a crash or permissions gate")
        for _ in 0..<8 where !continueButton.isHittable { app.swipeUp() }
        XCTAssertTrue(continueButton.isHittable)
        let welcome = XCTAttachment(screenshot: app.screenshot())
        welcome.name = "Welcome"
        welcome.lifetime = .keepAlways
        add(welcome)
        continueButton.tap()
        XCTAssertTrue(app.buttons["home.about"].waitForExistence(timeout: 8))
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

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testIPadLandscapeKeepsGuideAndControlsReachable() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad landscape journey")
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        finishWelcome()
        let start = app.buttons["home.start"]
        for _ in 0..<8 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        start.tap()
        startSessionFromReady()
        XCTAssertTrue(app.staticTexts["session.pose.name"].waitForExistence(timeout: 15))
        app.tap()
        let pause = app.buttons["session.pauseResume"]
        XCTAssertTrue(pause.isHittable)
        pause.tap()
        XCTAssertTrue(pause.label.contains("Resume"))
        capture("iPad landscape paused guide")
        let end = app.buttons["session.end"]
        XCTAssertTrue(end.isHittable)
        end.tap()
        XCTAssertTrue(app.buttons["summary.done"].waitForExistence(timeout: 8))
        capture("iPad landscape summary")
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.buttons["home.about"].waitForExistence(timeout: 5))
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
        capture("Session preparation")
    }

    func testLargestTextKeepsWelcomeAndSessionEntryReachable() {
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
