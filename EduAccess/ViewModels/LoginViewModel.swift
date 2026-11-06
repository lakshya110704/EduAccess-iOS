import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var username = ""
    var password = ""
    var role = UserRole.student
    private(set) var loggedInRole: UserRole?
    private(set) var isRestoring = true
    private(set) var displayName: String?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }

    /// Picks up a session kept from an earlier launch. Without one, or offline, this is the login screen.
    func restoreSession() async {
        defer { isRestoring = false }
        if let me = try? await api.me() {
            displayName = me.displayName
            loggedInRole = me.role
        }
    }

    func login() async {
        guard canSubmit else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await api.login(username: username.trimmingCharacters(in: .whitespaces), password: password, role: role)
            password = ""
            errorMessage = nil
            // Only for the welcome line, so failing to fetch it must not fail the login.
            displayName = (try? await api.me())?.displayName
            loggedInRole = role
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Ignored when already logged out, because a request in flight during logout can be refused too.
    func sessionExpired() {
        guard loggedInRole != nil else { return }
        loggedInRole = nil
        displayName = nil
        username = ""
        errorMessage = APIError.sessionExpired.localizedDescription
    }

    func logout() async {
        // Back to the login screen even if the request fails: logging in again replaces the session.
        try? await api.logout()
        loggedInRole = nil
        displayName = nil
        username = ""
    }
}
