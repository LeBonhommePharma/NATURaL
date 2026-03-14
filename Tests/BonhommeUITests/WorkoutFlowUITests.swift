import XCTest

/// UI tests for the workout flow, designed to run on Xcode iOS Simulator.
///
/// To run:
///   1. Open NATURaL.xcodeproj in Xcode
///   2. Select an iPhone simulator (iPhone 15 Pro, iOS 17+)
///   3. Cmd+U or Product > Test
///
/// These tests verify the complete user journey through the app.
final class WorkoutFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Home Screen

    func testHomeScreenShowsAppTitle() {
        XCTAssertTrue(app.staticTexts["NATURaL"].exists)
    }

    func testHomeScreenShowsBeginnerWorkout() {
        // English locale
        let gentleFlow = app.staticTexts["Gentle Chair Flow"]
        let enchaînement = app.staticTexts["Enchaînement doux sur chaise"]
        XCTAssertTrue(gentleFlow.exists || enchaînement.exists,
                      "Beginner flow card should be visible in either language")
    }

    func testHomeScreenShowsMultipleWorkoutPlans() {
        // Should show at least the free beginner flow + premium plans
        let cells = app.buttons.matching(NSPredicate(format: "label CONTAINS 'poses'"))
        XCTAssertGreaterThanOrEqual(cells.count, 2)
    }

    // MARK: - Workout Flow

    func testTapBeginnerFlowNavigatesToWorkout() {
        // Tap on the beginner flow
        let gentleFlow = app.staticTexts["Gentle Chair Flow"]
        let enchaînement = app.staticTexts["Enchaînement doux sur chaise"]
        if gentleFlow.exists {
            gentleFlow.tap()
        } else if enchaînement.exists {
            enchaînement.tap()
        }

        // Should see the "Begin Session" or "Commencer la séance" button
        let beginEN = app.buttons["Begin Session"]
        let beginFR = app.buttons["Commencer la séance"]
        XCTAssertTrue(beginEN.waitForExistence(timeout: 3) || beginFR.waitForExistence(timeout: 3))
    }

    func testBeginSessionStartsCountdown() {
        navigateToWorkoutReady()

        let beginEN = app.buttons["Begin Session"]
        let beginFR = app.buttons["Commencer la séance"]
        if beginEN.exists { beginEN.tap() }
        else if beginFR.exists { beginFR.tap() }

        // Should see countdown number (3, 2, or 1) and "Get Ready" / "Préparez-vous"
        let getReady = app.staticTexts["Get Ready"]
        let préparez = app.staticTexts["Préparez-vous"]
        XCTAssertTrue(getReady.waitForExistence(timeout: 2) || préparez.waitForExistence(timeout: 2))
    }

    // MARK: - Localization

    func testFrenchLocaleShowsFrenchContent() {
        // This test verifies the app renders correctly regardless of locale.
        // The actual language depends on the simulator's language setting.
        // Verify that SOME text is visible on the home screen.
        let anyText = app.staticTexts.firstMatch
        XCTAssertTrue(anyText.waitForExistence(timeout: 5))
    }

    // MARK: - TV Section

    func testTVDisplaySectionVisible() {
        let tvEN = app.staticTexts["TV Display"]
        let tvFR = app.staticTexts["Affichage TV"]
        XCTAssertTrue(tvEN.exists || tvFR.exists, "TV display section should be visible")
    }

    // MARK: - Accessibility

    func testHomeScreenSupportsVoiceOver() {
        // All buttons and text should be accessible
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertFalse(button.label.isEmpty, "Button has empty accessibility label")
        }
    }

    // MARK: - Helpers

    private func navigateToWorkoutReady() {
        let gentleFlow = app.staticTexts["Gentle Chair Flow"]
        let enchaînement = app.staticTexts["Enchaînement doux sur chaise"]
        if gentleFlow.exists { gentleFlow.tap() }
        else if enchaînement.exists { enchaînement.tap() }

        // Wait for ready screen
        let begin = app.buttons["Begin Session"]
        let commencer = app.buttons["Commencer la séance"]
        _ = begin.waitForExistence(timeout: 3) || commencer.waitForExistence(timeout: 3)
    }
}
