import XCTest
@testable import EduAccess

@MainActor
final class SignupViewModelTests: XCTestCase {
    func testPromptsFollowTheRole() async {
        let api = MockAPIClient()
        api.signupOptionsResult = .success(SignupOptions(emailDomains: ["student": "student.test", "professor": "staff.test"]))
        let viewModel = SignupViewModel(api: api)
        XCTAssertEqual(viewModel.emailPrompt, "College email")

        await viewModel.loadOptions()
        XCTAssertEqual(viewModel.emailPrompt, "College email (@student.test)")
        XCTAssertEqual(viewModel.collegeIdPrompt, "Roll number")

        viewModel.role = .professor
        XCTAssertEqual(viewModel.emailPrompt, "College email (@staff.test)")
        XCTAssertEqual(viewModel.collegeIdPrompt, "Employee ID")
    }

    func testFormStillWorksWithoutTheEmailHint() async {
        let api = MockAPIClient()
        api.signupOptionsResult = .failure(APIError.server("Server down"))
        let viewModel = SignupViewModel(api: api)

        await viewModel.loadOptions()

        XCTAssertEqual(viewModel.emailPrompt, "College email")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSubmitSendsEveryFieldAndClearsPasswords() async {
        let api = MockAPIClient()
        let viewModel = SignupViewModel(api: api)
        viewModel.role = .professor
        viewModel.username = "neha"
        viewModel.firstName = "Neha"
        viewModel.middleName = "K"
        viewModel.lastName = "Iyer"
        viewModel.email = "neha@staff.test"
        viewModel.collegeId = "E1"
        viewModel.password1 = "pass one"
        viewModel.password2 = "pass one"

        await viewModel.submit()

        XCTAssertEqual(api.signups, [SignupRequest(role: .professor, username: "neha", firstName: "Neha", middleName: "K", lastName: "Iyer", email: "neha@staff.test", collegeId: "E1", password1: "pass one", password2: "pass one")])
        XCTAssertTrue(viewModel.didSubmit)
        XCTAssertEqual(viewModel.password1, "")
        XCTAssertEqual(viewModel.password2, "")
    }

    func testEveryFieldErrorAndMessageIsKept() async {
        let api = MockAPIClient()
        api.signupError = APIError.validation([
            "email": ["Students must register with their college email."],
            "password2": ["Too short.", "Too common."],
        ])
        let viewModel = SignupViewModel(api: api)

        await viewModel.submit()

        XCTAssertFalse(viewModel.didSubmit)
        XCTAssertEqual(viewModel.fieldErrors["email"], ["Students must register with their college email."])
        XCTAssertEqual(viewModel.fieldErrors["password2"], ["Too short.", "Too common."])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAnErrorOutsideTheFormFieldsStillShows() async {
        let api = MockAPIClient()
        api.signupError = APIError.validation(["__all__": ["Something else."]])
        let viewModel = SignupViewModel(api: api)

        await viewModel.submit()

        XCTAssertEqual(viewModel.errorMessage, "Something else.")
    }

    func testARefusalShowsItsMessage() async {
        let api = MockAPIClient()
        api.signupError = APIError.server("You are already logged in.")
        let viewModel = SignupViewModel(api: api)

        await viewModel.submit()

        XCTAssertFalse(viewModel.didSubmit)
        XCTAssertEqual(viewModel.errorMessage, "You are already logged in.")
    }

    func testResubmittingClearsEarlierErrors() async {
        let api = MockAPIClient()
        api.signupError = APIError.validation(["email": ["Bad."]])
        let viewModel = SignupViewModel(api: api)
        await viewModel.submit()

        api.signupError = nil
        await viewModel.submit()

        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        XCTAssertTrue(viewModel.didSubmit)
    }

    func testAFailedSubmitKeepsWhatWasTyped() async {
        let api = MockAPIClient()
        api.signupError = APIError.validation(["email": ["Bad."]])
        let viewModel = SignupViewModel(api: api)
        viewModel.username = "neha"
        viewModel.password1 = "pass one"

        await viewModel.submit()

        XCTAssertEqual(viewModel.username, "neha")
        XCTAssertEqual(viewModel.password1, "pass one")
    }
}
