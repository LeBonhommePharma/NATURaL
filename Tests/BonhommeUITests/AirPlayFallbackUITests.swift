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

    // MARK: - Apple TV app deferred from 1.0 (20 September 2026)

    /// The pairing section must be gone, and — the assertion that actually protects
    /// something — the sharing toggle and the AirPlay row must survive. The toggle
    /// governs `coordinator.displayEnabled`, which the AirPlay path also reads, so
    /// hiding it along with the section would break AirPlay while an absence-only
    /// test still passed.
    func testTVSheetHidesApplePairingButKeepsAirPlayAndSharingToggle() throws {
        for _ in 0..<8 where !app.staticTexts["TV Display"].isHittable {
            app.scrollViews["home.content"].swipeUp()
        }
        app.buttons["home.start"].tap()
        let tvButton = app.buttons["session.tvDisplay"]
        XCTAssertTrue(tvButton.waitForExistence(timeout: 15), "session must offer the TV sheet")
        tvButton.tap()

        // Survives: sharing toggle, which AirPlay depends on.
        XCTAssertTrue(app.switches["tv.shareSession"].waitForExistence(timeout: 8),
                      "the sharing toggle must survive; AirPlay reads the same displayEnabled flag")
        // Survives: the AirPlay/HDMI row. Deferring the tvOS app must not touch it.
        XCTAssertTrue(app.descendants(matching: .any)["tv.externalDisplay"].exists,
                      "the AirPlay/HDMI row must survive the tvOS deferral")
        // Gone: everything that tells the user to open an app they cannot install.
        XCTAssertFalse(app.secureTextFields["tv.pairingKey"].exists,
                       "pairing key field must be hidden while the Apple TV app is unpublished")
        XCTAssertFalse(app.buttons["tv.confirmPairing"].exists,
                       "pairing confirmation must be hidden while the Apple TV app is unpublished")
        XCTAssertFalse(app.staticTexts["NATURaL on Apple TV"].exists,
                       "the pairing section header must be hidden")

        let sheet = XCTAttachment(screenshot: app.screenshot())
        sheet.name = "TV sheet with Apple TV app deferred"
        sheet.lifetime = .keepAlways
        add(sheet)
    }
}
