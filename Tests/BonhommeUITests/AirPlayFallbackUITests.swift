import XCTest

/// UI tests for the tvOS → AirPlay 2 fallback flow.
///
/// These tests verify the TV connection indicator behavior in the iOS app.
/// For full AirPlay testing, use:
///   - Xcode Simulator > I/O > External Displays to simulate an external screen
///   - A physical Apple TV on the same network
final class AirPlayFallbackUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // No orientation command here. These journeys locate the TV card by
        // scrolling and assert on it, so they hold in either orientation, and
        // commanding device orientation is itself flaky in the simulator —
        // "Failed to set device orientation: Timed out waiting for confirmation"
        // failed this file at CI 35486372872 before the assertions even ran.
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-natural.didFinishWelcome", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - TV Connection UI

    private func revealTVCard() {
        let content = app.scrollViews["home.content"]
        XCTAssertTrue(content.waitForExistence(timeout: 8))
        for _ in 0..<8 where !app.staticTexts["TV Display"].isHittable { content.swipeUp() }
    }

    func testTVSectionShowsOnHomeScreen() {
        revealTVCard()
        let tvEN = app.staticTexts["TV Display"]
        let tvFR = app.staticTexts["Affichage TV"]
        XCTAssertTrue(tvEN.exists || tvFR.exists)
    }

    func testTVConnectionPromptDescribesFeature() {
        revealTVCard()
        let promptEN = app.staticTexts["Connect during a workout to display poses on your TV"]
        let promptFR = app.staticTexts["Connectez-vous pendant un entraînement pour afficher les postures sur votre télé"]
        XCTAssertTrue(promptEN.exists || promptFR.exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Home TV guidance"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - External Display Simulation

    /// This test validates that the app handles external display connections.
    /// To test AirPlay second-screen in the simulator:
    ///   1. Run this test on an iOS Simulator
    ///   2. In the Simulator menu: I/O > External Displays > 1920x1080
    ///   3. The ExternalDisplaySceneDelegate should activate
    ///
    /// Note: Automated external display testing requires manual simulator setup.
    func testAppLaunchesWithoutCrash() {
        // Verify the app doesn't crash on launch (baseline stability test)
        XCTAssertTrue(app.staticTexts["NATURaL"].waitForExistence(timeout: 5))
    }


    // MARK: - Diagnostic — records an answer, is not a gate

    /// DIAGNOSTIC. Answers one question by demonstration rather than by reading
    /// the view hierarchy: during an ACTIVE session, does tapping the toolbar TV
    /// button actually surface the TV sheet?
    ///
    /// Why it is in doubt. The sheet is declared as `.sheet` on the root `Group`
    /// in `BonhommeApp.swift:45`, bound to `appState.showsTVDisplay`. The session
    /// is presented as `.fullScreenCover` from `HomeView.swift:23` and
    /// `StyleDetailView.swift:38`. The button at `WorkoutFlowView.swift:115` sets
    /// that flag from *inside* the cover. If SwiftUI will not present the root's
    /// sheet while a descendant's full-screen cover is up, the share-to-TV flow is
    /// unreachable exactly when a user would want it.
    ///
    /// The stake beyond this branch: the tvOS gating work adds absence assertions
    /// against this same sheet. Those assertions are only meaningful if the sheet
    /// opens. If it does not, they pass by asserting the absence of controls in a
    /// sheet that never appeared — which is vacuous, not green.
    ///
    /// This records the current behaviour either way. It is not an endorsement of
    /// what it finds and must be rewritten into a real gate once the disposition
    /// is decided.
    func testDiagnosticDoesTheTVSheetOpenDuringAnActiveSession() throws {
        // setUpWithError already launches past onboarding.
        let start = app.buttons["home.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 20), "home must be reachable")
        for _ in 0..<8 where !start.isHittable { app.swipeUp() }
        start.tap()

        let begin = app.buttons["Begin Session"]
        XCTAssertTrue(begin.waitForExistence(timeout: 10), "ready screen must offer Begin Session")
        for _ in 0..<8 where !begin.isHittable { app.swipeUp() }
        begin.tap()
        if !begin.waitForNonExistence(timeout: 6) { begin.tap() }
        XCTAssertTrue(begin.waitForNonExistence(timeout: 10),
                      "Begin Session must start the session and leave the ready screen")

        // Anchor on the session actually being up. Without this, a failure below
        // could not distinguish "the sheet will not open" from "we never got into
        // a session at all" — the same conflation that made the old pose-name wait
        // untrustworthy.
        let pause = app.buttons["session.pauseResume"]
        XCTAssertTrue(pause.waitForExistence(timeout: 20),
                      "the session must be active before the TV button means anything")

        let tvButton = app.buttons["session.tvDisplay"]
        XCTAssertTrue(tvButton.waitForExistence(timeout: 10),
                      "the toolbar TV button must exist inside the session")
        tvButton.tap()

        let opened = app.navigationBars["TV display"].waitForExistence(timeout: 10)
        let toggleVisible = app.switches["tv.shareSession"].exists
        let report = """
        TV sheet reachability from an ACTIVE session
        navigationBar "TV display" appeared:  \(opened)
        switch tv.shareSession visible:       \(toggleVisible)
        session still present (pauseResume):  \(pause.exists)
        """
        let text = XCTAttachment(string: report)
        text.name = "TV sheet reachability"
        text.lifetime = .keepAlways
        add(text)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "After tapping session.tvDisplay"
        shot.lifetime = .keepAlways
        add(shot)
        print("DIAGNOSTIC\n\(report)")

        XCTAssertTrue(opened, """
        PRODUCT BUG, not a test failure: tapping session.tvDisplay during an active \
        session did not surface the TV sheet within 10s. The sheet is attached to the \
        root Group (BonhommeApp.swift:45) while the session is a fullScreenCover \
        (HomeView.swift:23), so the share-to-TV flow would be unreachable from inside \
        a session — which is the only place it is offered.
        """)
    }
}
