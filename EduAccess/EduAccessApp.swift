import Combine
import SwiftUI

@main
struct EduAccessApp: App {
    private let api: any APIClient = LiveAPIClient.forApp()

    var body: some Scene {
        WindowGroup {
            RootView(api: api)
        }
    }
}

private struct RootView: View {
    let api: any APIClient
    @State private var login: LoginViewModel

    init(api: any APIClient) {
        self.api = api
        _login = State(initialValue: LoginViewModel(api: api))
    }

    var body: some View {
        content
            .task { await login.restoreSession() }
            .onReceive(NotificationCenter.default.publisher(for: .sessionExpired).receive(on: RunLoop.main)) { _ in
                login.sessionExpired()
            }
    }

    @ViewBuilder
    private var content: some View {
        if login.isRestoring {
            ProgressView()
        } else {
            home
        }
    }

    @ViewBuilder
    private var home: some View {
        switch login.loggedInRole {
        case .student:
            TabView {
                ProfessorsView(api: api, welcomeName: login.displayName, onLogout: logout)
                    .tabItem { Label("Professors", systemImage: "person.2") }
                AppointmentsView(api: api, role: .student)
                    .tabItem { Label("Appointments", systemImage: "calendar") }
                NotificationsView(api: api)
                    .tabItem { Label("Notifications", systemImage: "bell") }
            }
        case .professor:
            ProfessorHomeView(api: api, welcomeName: login.displayName, onLogout: logout)
        case nil:
            LoginView(viewModel: login, api: api)
        }
    }

    private func logout() {
        Task { await login.logout() }
    }
}
