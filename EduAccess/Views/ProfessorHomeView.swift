import SwiftUI

struct ProfessorHomeView: View {
    let api: any APIClient
    let welcomeName: String?
    let onLogout: () -> Void

    var body: some View {
        TabView {
            ProfessorStatusView(api: api, welcomeName: welcomeName, onLogout: onLogout)
                .tabItem { Label("My Status", systemImage: "person.crop.circle") }
            AppointmentsView(api: api, role: .professor)
                .tabItem { Label("Requests", systemImage: "calendar") }
            OpenTimeView(api: api)
                .tabItem { Label("Walk-In", systemImage: "door.left.hand.open") }
            NotificationsView(api: api)
                .tabItem { Label("Notifications", systemImage: "bell") }
        }
    }
}
