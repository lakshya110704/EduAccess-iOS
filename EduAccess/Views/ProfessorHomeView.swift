import SwiftUI

struct ProfessorHomeView: View {
    let api: any APIClient
    let welcomeName: String?
    let onLogout: () -> Void
    @State private var gate: ProfessorGateViewModel

    init(api: any APIClient, welcomeName: String?, onLogout: @escaping () -> Void) {
        self.api = api
        self.welcomeName = welcomeName
        self.onLogout = onLogout
        _gate = State(initialValue: ProfessorGateViewModel(api: api))
    }

    var body: some View {
        Group {
            switch gate.state {
            case .checking:
                ProgressView()
            case .needsCabin:
                CabinView(api: api, currentLabel: "", isFirstTime: true, onSaved: { _ in gate.cabinSaved() }, onLogout: onLogout)
            case .ready:
                tabs
            }
        }
        .task { await gate.check() }
    }

    private var tabs: some View {
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
