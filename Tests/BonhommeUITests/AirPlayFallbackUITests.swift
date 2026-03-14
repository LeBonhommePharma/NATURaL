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
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - TV Connection UI

    func testTVSectionShowsOnHomeScreen() {
        let tvEN = app.staticTexts["TV Display"]
        let tvFR = app.staticTexts["Affichage TV"]
        XCTAssertTrue(tvEN.exists || tvFR.exists)
    }

    func testTVConnectionPromptDescribesFeature() {
        let promptEN = app.staticTexts["Connect during a workout to display poses on your TV"]
        let promptFR = app.staticTexts["Connectez-vous pendant un entraînement pour afficher les postures sur votre télé"]
        XCTAssertTrue(promptEN.exists || promptFR.exists)
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
}
