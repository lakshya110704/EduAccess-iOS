import XCTest

/// Drives the real app against a local backend with seed_demo data. Skipped unless the password is
/// supplied: TEST_RUNNER_EDUACCESS_TEST_PASSWORD=... xcodebuild test ...
/// The launch argument makes the app refuse any host but localhost, so this cannot write to a deployed backend.
final class AppFlowUITests: XCTestCase {
    private var password = ""
    private var app = XCUIApplication()
    private let timeout: TimeInterval = 60

    override func setUpWithError() throws {
        let supplied = ProcessInfo.processInfo.environment["EDUACCESS_TEST_PASSWORD"]
        try XCTSkipIf(supplied == nil, "No EDUACCESS_TEST_PASSWORD")
        password = supplied ?? ""
        continueAfterFailure = false
        app.launchArguments = ["-requireLocalBackend"]
        app.launch()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Under load a field can take a while to get focus after a tap, and typing before then fails.
    private func type(_ text: String, into field: XCUIElement) {
        let focused = NSPredicate(format: "hasKeyboardFocus == true")
        for _ in 0..<5 where !focused.evaluate(with: field) {
            field.tap()
            _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: focused, object: field)], timeout: 10)
        }
        field.typeText(text)
    }

    private func logIn(_ username: String, role: String) {
        XCTAssertTrue(app.buttons[role].waitForExistence(timeout: timeout))
        app.buttons[role].tap()
        let usernameField = app.textFields["Username"]
        type(username, into: usernameField)
        let passwordField = app.secureTextFields["Password"]
        type(password, into: passwordField)
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

    private func tapUntil(_ element: XCUIElement, reveals next: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        for _ in 0..<4 where !next.exists {
            element.tap()
            _ = next.waitForExistence(timeout: 15)
        }
        XCTAssertTrue(next.exists)
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
        type("AB2", into: search)
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
        tapUntil(app.buttons["Request Appointment"], reveals: app.alerts["Request Sent"])
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: timeout))

        openTab("Appointments")
        waitForText(containing: "· Pending")
        attachScreenshot("student-appointments")

        tapUntil(app.buttons["Edit"].firstMatch, reveals: app.buttons["Save"])
        attachScreenshot("student-edit-reason")
        type("Question 2", into: app.textFields["Details (optional)"])
        app.buttons["Save"].tap()
        waitForText(containing: "Question 2")

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
        type("Back soon\n", into: app.textFields["Add a short note (optional)"])
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
        // A tap during the alert's entrance can be dropped, so retry until the alert closes.
        for _ in 0..<4 where app.alerts.firstMatch.exists {
            app.alerts.buttons["Cancel Appointment"].tap()
            _ = app.alerts.firstMatch.waitForNonExistence(timeout: 5)
        }
        let confirmedGone = NSPredicate(format: "exists == false")
        let confirmed = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "· Confirmed")).firstMatch
        expectation(for: confirmedGone, evaluatedWith: confirmed)
        waitForExpectations(timeout: timeout)

        openTab("Notifications")
        waitForText(containing: "New appointment request")
        attachScreenshot("professor-notifications")

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
