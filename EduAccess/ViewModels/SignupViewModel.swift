import Foundation
import Observation

@MainActor
@Observable
final class SignupViewModel {
    var role = UserRole.student
    var username = ""
    var firstName = ""
    var middleName = ""
    var lastName = ""
    var email = ""
    var collegeId = ""
    var password1 = ""
    var password2 = ""
    private(set) var emailDomains: [String: String] = [:]
    private(set) var isSubmitting = false
    private(set) var didSubmit = false
    private(set) var fieldErrors: [String: [String]] = [:]
    private(set) var errorMessage: String?

    private static let formFields: Set = [
        "role", "username", "first_name", "middle_name", "last_name", "email", "college_id", "password1", "password2",
    ]

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    var emailPrompt: String {
        emailDomains[role.rawValue].map { "College email (@\($0))" } ?? "College email"
    }

    var collegeIdPrompt: String {
        role == .student ? "Roll number" : "Employee ID"
    }

    /// Only for the email hint, so the form still works without it.
    func loadOptions() async {
        emailDomains = (try? await api.signupOptions().emailDomains) ?? [:]
    }

    func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        fieldErrors = [:]
        errorMessage = nil
        do {
            _ = try await api.signup(SignupRequest(
                role: role,
                username: username,
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                email: email,
                collegeId: collegeId,
                password1: password1,
                password2: password2
            ))
            password1 = ""
            password2 = ""
            didSubmit = true
        } catch APIError.validation(let errors) {
            fieldErrors = errors.filter { Self.formFields.contains($0.key) }
            let other = errors.filter { !Self.formFields.contains($0.key) }.values.flatMap { $0 }
            errorMessage = other.isEmpty ? nil : other.joined(separator: " ")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
