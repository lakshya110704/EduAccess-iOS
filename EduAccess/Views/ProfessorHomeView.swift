import SwiftUI

struct ProfessorHomeView: View {
    let api: any APIClient
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            ContentUnavailableView("Signed In", systemImage: "person.crop.circle.badge.checkmark")
                .navigationTitle("Professor")
                .toolbar {
                    Button("Log Out", action: onLogout)
                }
        }
    }
}
