import XCTest
import UIKit

/// Release journeys: fresh launch, free session entry and local-data navigation.
final class WorkoutFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // No orientation command here. Every journey below except the iPad
        // landscape one reaches its targets by scrolling and asserting hittability,
        // so it holds in either orientation; pinning bought nothing and added a
        // flaky device command to six journeys. Only the landscape journey, which
        // is actually testing landscape, commands the device — and it asserts the
        // resulting layout rather than trusting the command.
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
    private func finishWelcome(requireWelcome: Bool = false) throws {
        let continueButton = app.descendants(matching: .any)["welcome.continue"]
        let home = app.buttons["home.about"]
        // Cold launch is app start + SwiftData ModelContainer bootstrap + first render.
        let timeout: TimeInterval = name.contains("LargestText") ? 30 : 25
        guard continueButton.waitForExistence(timeout: timeout) else {
            XCTAssertTrue(home.waitForExistence(timeout: 10),
                          "Without welcome the journey must already be past onboarding, not stuck")
            // The onboarding journey needs a pristine first launch. When XCUITest hands it
            // a reused post-welcome process there is nothing to verify, so record that
            // explicitly instead of passing. A skip is visible in the run summary; a silent
            // pass would not be. Durable fixes are a separate UI test target/plan for
            // onboarding, or an audited terminate-and-relaunch exemption — see verification.md.
            if requireWelcome {
                throw XCTSkip("Inherited a post-onboarding process; no welcome screen to verify")
            }
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
        // The tap is occasionally synthesized but not delivered (CI 35482711331),
        // so it is re-issued once — but ONLY while welcome is still on screen.
        // Re-tapping unconditionally is itself a bug: when the first tap landed and
        // Home was merely slow to render, the button is already gone and the retry
        // fails hard with "No matches found" (CI 35496458937, on a docs-only commit).
        // Absence of the button means the tap worked; wait for Home rather than retry.
        if !home.waitForExistence(timeout: 8), continueButton.exists {
            continueButton.tap()
        }
        XCTAssertTrue(home.waitForExistence(timeout: 12),
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
        try finishWelcome()
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

    func testWelcomeLeadsToFreeSession() throws {
        try finishWelcome(requireWelcome: true)
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

    func testLargestTextKeepsWelcomeAndSessionEntryReachable() throws {
        try finishWelcome()
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

    func testSessionCanPauseResumeAndEnd() throws {
        try finishWelcome()
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

    func testActivePoseCanPauseAndFinish() throws {
        try finishWelcome()
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

    func testLocalHistoryAvailableWithoutHealthAuthorization() throws {
        try finishWelcome()
        app.buttons["home.history"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Refresh Health history"].exists)
    }

    func testPrivacyAndHealthControlsAreReachable() throws {
        try finishWelcome()
        app.buttons["home.about"].tap()
        XCTAssertTrue(app.navigationBars["About & Privacy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Choose Health permissions"].exists)
    }

    // MARK: - Measurement only — not a release gate

    /// Measures how long `session.pose.name` actually takes to appear, repeatedly,
    /// to get a distribution rather than a pass/fail. Added to investigate the
    /// ~8% flake on `testActivePoseCanPauseAndFinish` (2 failures in ~24 runs).
    ///
    /// This asserts almost nothing on purpose. It answers three questions the
    /// existing artifacts cannot, because XCTest only attaches intermediate
    /// snapshots on failure, so a passing run records nothing between the welcome
    /// screenshot and the paused-session screenshot ~24s later:
    ///
    ///   1. What is the distribution on runs that pass? If it clusters near 15s the
    ///      bar is not too tight — the app is nearly too slow and the failures are
    ///      the tail of a distribution that was always dangerous.
    ///   2. Is there a first-render cost paid once? Iteration 1 slow and 2..n fast
    ///      is the cold-start signature.
    ///   3. Does it drift upward across iterations, which would suggest accumulation
    ///      rather than a fixed startup cost.
    ///
    /// Delete this once the question is answered; it is not a gate and must never
    /// become one.
    func testMeasureActivePoseRenderLatency() throws {
        try finishWelcome()
        // Fixed CPU work, timed. This is the contention control: it measures how
        // fast THIS runner is right now, so a long wait can be attributed to a slow
        // machine or to the app. Journey durations today spanned 39.9s to 154.0s
        // across 26 lane-runs — nearly 4x — which is runner variance, not app
        // variance, and would otherwise be indistinguishable from render latency.
        func calibrationSeconds() -> Double {
            let began = Date()
            var acc = 0.0
            for i in 1...2_000_000 { acc += (Double(i) * 1.0000001).squareRoot() }
            let elapsed = Date().timeIntervalSince(began)
            XCTAssertGreaterThan(acc, 0)  // keep the compiler from eliding the loop
            return elapsed
        }
        var samples: [Double] = []
        var calibrations: [Double] = []
        // 16 samples cannot see an 8% event — the chance of observing zero failures
        // is ~26%, so the first run's clean result was never decisive. 30 per lane
        // (60 total) puts the chance of seeing none below 1% if the rate holds, which
        // makes the tail either visible or genuinely absent.
        let iterations = 30
        for i in 1...iterations {
            let start = app.buttons["home.start"]
            XCTAssertTrue(start.waitForExistence(timeout: 15), "iteration \(i): home must be reachable")
            for _ in 0..<4 where !start.isHittable { app.swipeUp() }
            start.tap()
            startSessionFromReady()

            // The measurement. Same element and the same generous ceiling the real
            // journey uses, so a sample is comparable to a real wait.
            let calib = calibrationSeconds()
            let began = Date()
            let appeared = app.staticTexts["session.pose.name"].waitForExistence(timeout: 30)
            let waited = Date().timeIntervalSince(began)
            samples.append(appeared ? waited : -1)
            calibrations.append(calib)

            // Leave the session so the next iteration starts from home.
            app.buttons["session.end"].tap()
            if app.buttons["summary.done"].waitForExistence(timeout: 10) {
                app.buttons["summary.done"].tap()
            }
            _ = app.buttons["home.about"].waitForExistence(timeout: 10)
        }
        let ok = samples.filter { $0 >= 0 }
        let report = """
        session.pose.name wait, \(iterations) iterations on \(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")
        samples (s): \(samples.map { String(format: "%.2f", $0) }.joined(separator: ", "))
        n=\(ok.count)  min=\(String(format: "%.2f", ok.min() ?? -1))  max=\(String(format: "%.2f", ok.max() ?? -1))  \
        mean=\(String(format: "%.2f", ok.isEmpty ? -1 : ok.reduce(0,+)/Double(ok.count)))
        first=\(String(format: "%.2f", samples.first ?? -1))  rest_mean=\(String(format: "%.2f", ok.count > 1 ? ok.dropFirst().reduce(0,+)/Double(ok.count-1) : -1))
        timeouts(>=30s): \(samples.filter { $0 < 0 }.count)
        calibration (s, fixed CPU work): \(calibrations.map { String(format: "%.3f", $0) }.joined(separator: ", "))
        calib min=\(String(format: "%.3f", calibrations.min() ?? -1))  max=\(String(format: "%.3f", calibrations.max() ?? -1))  \
        spread=\(String(format: "%.2fx", (calibrations.max() ?? 1) / max(calibrations.min() ?? 1, 0.0001)))
        paired (wait_s, calib_s): \(zip(samples, calibrations).map { "(\(String(format: "%.2f", $0.0)), \(String(format: "%.3f", $0.1)))" }.joined(separator: " "))
        """
        let attachment = XCTAttachment(string: report)
        attachment.name = "poseName latency distribution"
        attachment.lifetime = .keepAlways
        add(attachment)
        print("MEASUREMENT\n\(report)")
        XCTAssertFalse(ok.isEmpty, "measurement produced no samples")
    }
}
