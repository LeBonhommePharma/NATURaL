import XCTest

/// The TV display must be reachable from inside an active session.
///
/// Share-to-TV is offered in exactly one place — the session toolbar — so if the
/// sheet cannot present while a session is up, the feature is unreachable. That
/// was the shipped behaviour: the sheet is anchored on the app root while the
/// session runs inside a `.fullScreenCover`, and a sheet anchored above an
/// active cover never appears. Documented in `Docs/AppStore/tv-sheet-unreachable.md`.
///
/// This asserts presentation positively. It is deliberately not an absence
/// assertion: "no pairing controls are visible" is satisfied just as well by a
/// sheet that never opened, which is how the existing coverage passed while the
/// feature was broken.
final class TVDisplayInSessionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        // Deliberately true, unlike the sibling journeys. This test asserts
        // mid-session; aborting at the first failure would abandon a live
        // workout, and the app persists session state for crash recovery, so an
        // abandoned session outlives the process and relaunches into whatever
        // runs next. Continuing lets tearDown close the session down.
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
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

    /// Leave no session behind, whatever the assertions did.
    override func tearDownWithError() throws {
        guard app != nil, app.state == .runningForeground else { return }
        // The sheet's confirmationAction is labelled "Done" (WorkoutFlowView.swift:685);
        // it carries no accessibility identifier, so it is matched by label.
        let sheetDone = app.navigationBars["TV display"].buttons["Done"]
        if sheetDone.exists, sheetDone.isHittable { sheetDone.tap() }
        let end = app.buttons["session.end"]
        if end.waitForExistence(timeout: 2), end.isHittable {
            end.tap()
            let done = app.buttons["summary.done"]
            if done.waitForExistence(timeout: 5), done.isHittable { done.tap() }
        }
    }

    private func finishWelcome() {
        let continueButton = app.descendants(matching: .any)["welcome.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 12),
                      "Welcome must launch without a crash or permissions gate")
        for _ in 0..<8 where !continueButton.isHittable { app.swipeUp() }
        continueButton.tap()
        XCTAssertTrue(app.buttons["home.about"].waitForExistence(timeout: 8))
    }

    private func startSessionFromReady() {
        let begin = app.buttons["Begin Session"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5), "Ready screen must offer Begin Session")
        for _ in 0..<8 where !begin.isHittable { app.swipeUp() }
        begin.tap()
    }

    func testTVDisplaySheetOpensDuringActiveSession() {
        finishWelcome()
        app.buttons["home.start"].tap()
        startSessionFromReady()
        // Wait on session chrome, not on the pose title. session.pose.name is a text
        // node inside a continuously re-rendering pose view; on the iPad lane it can
        // lag past the point where the session is genuinely up, which failed this
        // precondition while every sibling journey on that same lane passed.
        // session.pauseResume is the running-session HUD control and is the stabler
        // signal that a session is actually live.
        XCTAssertTrue(app.buttons["session.pauseResume"].waitForExistence(timeout: 30),
                      "Session must be running before the toolbar is exercised")
        app.tap() // Dispatch any pending system permission alert to the monitor.

        let tvButton = app.buttons["session.tvDisplay"]
        XCTAssertTrue(tvButton.waitForExistence(timeout: 5),
                      "The session toolbar must offer the TV display control")
        XCTAssertTrue(tvButton.isHittable, "The TV display control must be tappable")
        tvButton.tap()

        // The assertion this test exists for.
        XCTAssertTrue(app.navigationBars["TV display"].waitForExistence(timeout: 5),
                      "Tapping TV display during an active session must present the TV sheet")
        XCTAssertTrue(app.switches["tv.shareSession"].waitForExistence(timeout: 3),
                      "The presented sheet must carry the share-to-TV control")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "TV sheet over an active session"
        shot.lifetime = .keepAlways
        add(shot)

        // The sheet must not have torn down the session underneath it.
        XCTAssertTrue(app.buttons["session.pauseResume"].exists,
                      "Presenting the TV sheet must not dismiss the session beneath it")
    }
}
