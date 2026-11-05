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
        if login.isLoggedIn {
            TabView {
                ProfessorsView(api: api, onLogout: { Task { await login.logout() } })
                    .tabItem { Label("Professors", systemImage: "person.2") }
                AppointmentsView(api: api)
                    .tabItem { Label("Appointments", systemImage: "calendar") }
            }
        } else {
            LoginView(viewModel: login)
        }
    }
}
