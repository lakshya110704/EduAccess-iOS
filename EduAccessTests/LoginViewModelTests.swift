import XCTest
@testable import EduAccess

@MainActor
final class LoginViewModelTests: XCTestCase {
    func testCannotSubmitWithEmptyFields() {
        let viewModel = LoginViewModel(api: MockAPIClient())
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.username = "   "
        viewModel.password = "secret"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.username = "student1"
        XCTAssertTrue(viewModel.canSubmit)
    }

    func testEmptyFieldsDoNotCallTheAPI() async {
        let api = MockAPIClient()
        await LoginViewModel(api: api).login()
        XCTAssertTrue(api.loginCalls.isEmpty)
    }

    func testSuccessTrimsUsernameKeepsPasswordExactAndClearsIt() async {
        let api = MockAPIClient()
        let viewModel = LoginViewModel(api: api)
        viewModel.username = " student1 "
        viewModel.password = " pass word "

        await viewModel.login()

        XCTAssertEqual(api.loginCalls.first?.username, "student1")
        XCTAssertEqual(api.loginCalls.first?.password, " pass word ")
        XCTAssertEqual(viewModel.loggedInRole, .student)
        XCTAssertEqual(viewModel.password, "")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFailureShowsTheErrorAndStaysLoggedOut() async {
        let api = MockAPIClient()
        api.loginError = APIError.invalidCredentials
        let viewModel = LoginViewModel(api: api)
        viewModel.username = "student1"
        viewModel.password = "wrong"

        await viewModel.login()

        XCTAssertNil(viewModel.loggedInRole)
        XCTAssertEqual(viewModel.errorMessage, "Incorrect username or password.")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLogoutReturnsToLogin() async {
        let api = MockAPIClient()
        let viewModel = LoginViewModel(api: api)
        viewModel.username = "student1"
        viewModel.password = "secret"
        await viewModel.login()

        await viewModel.logout()

        XCTAssertEqual(api.logoutCount, 1)
        XCTAssertNil(viewModel.loggedInRole)
        XCTAssertEqual(viewModel.username, "")
    }

    func testExpiredSessionReturnsToLoginWithAMessage() async {
        let viewModel = LoginViewModel(api: MockAPIClient())
        viewModel.username = "student1"
        viewModel.password = "secret"
        await viewModel.login()

        viewModel.sessionExpired()

        XCTAssertNil(viewModel.loggedInRole)
        XCTAssertEqual(viewModel.errorMessage, "Your session has ended. Please log in again.")
    }

    func testExpiryWhileLoggedOutShowsNoMessage() {
        let viewModel = LoginViewModel(api: MockAPIClient())

        viewModel.sessionExpired()

        XCTAssertNil(viewModel.errorMessage)
    }

    func testSelectedRoleIsSentAndRemembered() async {
        let api = MockAPIClient()
        let viewModel = LoginViewModel(api: api)
        viewModel.username = "prof1"
        viewModel.password = "secret"
        viewModel.role = .professor

        await viewModel.login()

        XCTAssertEqual(api.loginCalls.first?.role, .professor)
        XCTAssertEqual(viewModel.loggedInRole, .professor)
    }
}
