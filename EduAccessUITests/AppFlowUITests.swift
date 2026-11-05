import XCTest

/// Drives the real app against a local backend with seed_demo data. Skipped unless the password is
/// supplied: TEST_RUNNER_EDUACCESS_TEST_PASSWORD=... xcodebuild test ...
/// The app's default address is the local server, so this cannot write to a deployed backend.
final class AppFlowUITests: XCTestCase {
    private var password = ""
    private var app = XCUIApplication()
    private let timeout: TimeInterval = 60

    override func setUpWithError() throws {
        let supplied = ProcessInfo.processInfo.environment["EDUACCESS_TEST_PASSWORD"]
        try XCTSkipIf(supplied == nil, "No EDUACCESS_TEST_PASSWORD")
        password = supplied ?? ""
        continueAfterFailure = false
        app.launch()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func logIn(_ username: String, role: String) {
        XCTAssertTrue(app.buttons[role].waitForExistence(timeout: timeout))
        app.buttons[role].tap()
        let usernameField = app.textFields["Username"]
        usernameField.tap()
        usernameField.typeText(username)
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(password)
        app.buttons["Log In"].tap()
    }

    /// A tap during a push or pop transition can be dropped, so keep going until the tab is selected.
    private func openTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        for _ in 0..<10 where !tab.isSelected {
            tab.tap()
            _ = tab.wait(for: \.isSelected, toEqual: true, timeout: 5)
        }
        XCTAssertTrue(tab.isSelected, "Tab \(name) did not open")
    }

    private func text(containing fragment: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
    }

    private func waitForText(containing fragment: String) {
        let element = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "No text containing \(fragment)")
    }

    func testStudentRequestsAndProfessorConfirmsThenCancels() {
        logIn("student1", role: "Student")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: timeout))
        search.tap()
        search.typeText("AB2")
        waitForText(containing: "Ashish Gupta")
        XCTAssertTrue(app.buttons["Save Ashish Gupta"].waitForExistence(timeout: timeout))
        app.buttons["Save Ashish Gupta"].tap()
        XCTAssertTrue(app.buttons["Remove Ashish Gupta from saved"].waitForExistence(timeout: timeout))
        attachScreenshot("student-search")
        app.buttons["Remove Ashish Gupta from saved"].tap()
        XCTAssertTrue(app.buttons["Save Ashish Gupta"].waitForExistence(timeout: timeout))

        text(containing: "Ashish Gupta").tap()
        XCTAssertTrue(app.buttons["Request Appointment"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.links["Directions to Cabin"].exists || app.buttons["Directions to Cabin"].exists)
        attachScreenshot("student-booking")
        app.buttons["Request Appointment"].tap()
        XCTAssertTrue(app.alerts["Request Sent"].waitForExistence(timeout: timeout))
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: timeout))

        openTab("Appointments")
        waitForText(containing: "· Pending")
        attachScreenshot("student-appointments")

        openTab("Professors")
        // Log Out is hidden while the search bar is active.
        for _ in 0..<6 where !app.buttons["Log Out"].waitForExistence(timeout: 5) {
            if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        }
        XCTAssertTrue(app.buttons["Log Out"].waitForExistence(timeout: timeout))
        app.buttons["Log Out"].tap()

        logIn("prof1", role: "Professor")
        XCTAssertTrue(app.buttons["Update Status"].waitForExistence(timeout: timeout))
        app.buttons["Busy"].tap()
        XCTAssertTrue(app.textFields["Add a short note (optional)"].waitForExistence(timeout: timeout))
        app.textFields["Add a short note (optional)"].tap()
        app.textFields["Add a short note (optional)"].typeText("Back soon\n")
        app.buttons["Update Status"].tap()
        waitForText(containing: "Status updated")
        attachScreenshot("professor-status")

        openTab("Requests")
        waitForText(containing: "Riya Sharma")
        attachScreenshot("professor-requests")
        // A tap can be dropped while a tab is still settling, so retry until the row changes.
        for _ in 0..<4 where !text(containing: "· Confirmed").exists {
            app.buttons["Confirm"].firstMatch.tap()
            _ = text(containing: "· Confirmed").waitForExistence(timeout: 15)
        }
        waitForText(containing: "· Confirmed")
        attachScreenshot("professor-confirmed")

        app.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.alerts.buttons["Cancel Appointment"].waitForExistence(timeout: timeout))
        app.alerts.buttons["Cancel Appointment"].tap()
        let confirmedGone = NSPredicate(format: "exists == false")
        let confirmed = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "· Confirmed")).firstMatch
        expectation(for: confirmedGone, evaluatedWith: confirmed)
        waitForExpectations(timeout: timeout)

        openTab("Walk-In")
        XCTAssertTrue(app.buttons["Add Walk-In Time"].waitForExistence(timeout: timeout))
        attachScreenshot("professor-walk-in")

        openTab("My Status")
        app.buttons["Free"].tap()
        app.buttons["Update Status"].tap()
        waitForText(containing: "Status updated")
        app.buttons["Log Out"].tap()
        XCTAssertTrue(app.buttons["Log In"].waitForExistence(timeout: timeout))
    }

    func testWrongRoleShowsAnError() {
        logIn("student1", role: "Professor")
        waitForText(containing: "does not match the selected role")
        attachScreenshot("wrong-role")
    }
}
