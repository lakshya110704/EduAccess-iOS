import Foundation
import Observation

@MainActor
@Observable
final class NotificationsViewModel {
    private(set) var notifications: [AppNotification] = []
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func load() async {
        do {
            notifications = try await api.notifications()
            hasLoaded = true
            errorMessage = nil
        } catch where error.isCancellation {
            // The screen went away.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func autoRefresh(every interval: Duration = .dashboardRefresh) async {
        await repeatEvery(interval) { await load() }
    }
}
