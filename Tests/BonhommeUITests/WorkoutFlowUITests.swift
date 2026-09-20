import XCTest
import UIKit

/// Release journeys: fresh launch, free session entry and local-data navigation.
final class WorkoutFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // A failed XCTest assertion can abort before a previous test's Swift defer.
        // Establish orientation explicitly for each independent journey.
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        // A previous journey persists welcome completion, and the argument-domain
        // string "NO" is not a dependable Bool reset. Force onboarding explicitly.
        // Do NOT terminate+relaunch here: that is the known cause of the
        // welcome.continue flake on b2cc3f8, and scripts/test_contracts.py enforces it.
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US",
                               "-natural.didFinishWelcome", "NO",
                               "-natural.forceWelcome",
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

    /// Most journeys only need to *get past* onboarding; they do not care whether this
    /// particular launch showed it. XCUITest can hand a journey the previous test's
    /// process, already past welcome — CI 35484287585's iPad lane captured exactly that,
    /// with Home on screen and no welcome element anywhere despite -natural.forceWelcome
    /// (the flag cannot help: the state lives in the reused process). Treat an
    /// already-past-onboarding instance as satisfied, and let only the dedicated
    /// onboarding journey require the welcome screen itself.
    private func finishWelcome(requireWelcome: Bool = false) {
        let continueButton = app.descendants(matching: .any)["welcome.continue"]
        let home = app.buttons["home.about"]
        // Cold launch is app start + SwiftData ModelContainer bootstrap + first render.
        let timeout: TimeInterval = name.contains("LargestText") ? 30 : 25
        guard continueButton.waitForExistence(timeout: timeout) else {
            XCTAssertFalse(requireWelcome,
                           "Welcome must launch without a crash or permissions gate")
            XCTAssertTrue(home.waitForExistence(timeout: 10),
                          "Without welcome the journey must already be past onboarding, not stuck")
            return
        }
        capture("Welcome overview")
        for _ in 0..<8 where !continueButton.isHittable { app.swipeUp() }
        XCTAssertTrue(continueButton.isHittable)
        let welcome = XCTAttachment(screenshot: app.screenshot())
        welcome.name = "Welcome"
        welcome.lifetime = .keepAlways
        add(welcome)
        continueButton.tap()
        // The tap is occasionally synthesized but not delivered (CI 35482711331).
        // Re-issue once, then still require Home so a real failure still fails.
        if !home.waitForExistence(timeout: 8) {
            continueButton.tap()
        }
        XCTAssertTrue(home.waitForExistence(timeout: 10),
                      "Continue must leave welcome and show Home")
    }

    private func startSessionFromReady() {
        let begin = app.buttons["Begin Session"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5), "Ready screen must offer Begin Session")
        for _ in 0..<8 where !begin.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(begin.isHittable, "Begin Session must be tappable without a camera/paywall overlay")
        begin.tap()
        // The simulator occasionally synthesizes the tap without delivering it, leaving
        // the ready screen up (CI 35473327818, iPhone). Re-issue once, then require the
        // ready screen to actually dismiss so a genuine start failure still fails here.
        if !begin.waitForNonExistence(timeout: 6) {
            begin.tap()
        }
        XCTAssertTrue(begin.waitForNonExistence(timeout: 8),
                      "Begin Session must start the session and leave the ready screen")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Landscape must use the display-level capture. `app.screenshot()` writes the
    /// portrait-width content into a landscape-sized buffer and clips the overflow:
    /// CI 35481919944 exported 2064x2064 inside 2752x2064, losing the entire right
    /// metrics rail. `XCUIScreen.main.screenshot()` returns the device-native 2064x2752
    /// buffer with the full landscape UI intact; rotate +90 (expand) for a 2752x2064
    /// landscape image. Store assets must come from this path, not from app.screenshot().
    private func captureScreen(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(name) (screen)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testIPadLandscapeKeepsGuideAndControlsReachable() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "iPad landscape journey")
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let landscape = XCTNSPredicateExpectation(
            predicate: NSPredicate { [application = self.app] _, _ in
                guard let application else { return false }
                return application.frame.width > application.frame.height
            }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 8), .completed)
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
        captureScreen("iPad landscape paused guide")
        let end = app.buttons["session.end"]
        XCTAssertTrue(end.isHittable)
        end.tap()
        XCTAssertTrue(app.buttons["summary.done"].waitForExistence(timeout: 8))
        captureScreen("iPad landscape summary")
        app.buttons["summary.done"].tap()
        XCTAssertTrue(app.buttons["home.about"].waitForExistence(timeout: 5))
    }

    func testWelcomeLeadsToFreeSession() {
        finishWelcome(requireWelcome: true)
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
        let content = app.scrollViews["session.content"]
        XCTAssertTrue(content.exists)
        XCTAssertLessThanOrEqual(content.frame.maxY, pause.frame.minY + 1,
                                 "Pinned controls must not cover the guide viewport")
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
