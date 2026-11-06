import SwiftUI

@main
struct EduAccessApp: App {
    private let api: any APIClient = LiveAPIClient()

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
        switch login.loggedInRole {
        case .student:
            TabView {
                ProfessorsView(api: api, onLogout: logout)
                    .tabItem { Label("Professors", systemImage: "person.2") }
                AppointmentsView(api: api, role: .student)
                    .tabItem { Label("Appointments", systemImage: "calendar") }
                NotificationsView(api: api)
                    .tabItem { Label("Notifications", systemImage: "bell") }
            }
        case .professor:
            ProfessorHomeView(api: api, onLogout: logout)
        case nil:
            LoginView(viewModel: login)
        }
    }

    private func logout() {
        Task { await login.logout() }
    }
}
