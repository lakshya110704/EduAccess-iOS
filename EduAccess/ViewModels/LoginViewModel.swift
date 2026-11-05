import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var username = ""
    var password = ""
    var role = UserRole.student
    private(set) var loggedInRole: UserRole?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }

    func login() async {
        guard canSubmit else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.login(username: username.trimmingCharacters(in: .whitespaces), password: password, role: role)
            password = ""
            errorMessage = nil
            loggedInRole = role
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        // Back to the login screen even if the request fails: logging in again replaces the session.
        try? await api.logout()
        loggedInRole = nil
    }
}
