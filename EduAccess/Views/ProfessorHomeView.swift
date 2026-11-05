import SwiftUI

struct ProfessorHomeView: View {
    let api: any APIClient
    let onLogout: () -> Void

    var body: some View {
        TabView {
            ProfessorStatusView(api: api, onLogout: onLogout)
                .tabItem { Label("My Status", systemImage: "person.crop.circle") }
            AppointmentsView(api: api, role: .professor)
                .tabItem { Label("Requests", systemImage: "calendar") }
        }
    }
}
