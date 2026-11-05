import Foundation
import Observation

@MainActor
@Observable
final class OpenTimeViewModel {
    var start: Date
    var end: Date
    private(set) var windows: [OpenTime] = []
    private(set) var hasLoaded = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient, now: Date = Date()) {
        self.api = api
        start = BookingViewModel.nextQuarterHour(onOrAfter: now)
        end = BookingViewModel.nextQuarterHour(onOrAfter: now).addingTimeInterval(30 * 60)
    }

    func load() async {
        do {
            windows = try await api.openTimes()
            hasLoaded = true
            errorMessage = nil
        } catch where error.isCancellation {
            // The screen went away.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The backend only accepts quarter-hour times, so both ends round up as the booking screen does.
    func add() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let window = try await api.addOpenTime(
                start: BookingViewModel.nextQuarterHour(onOrAfter: start),
                end: BookingViewModel.nextQuarterHour(onOrAfter: end)
            )
            windows = (windows + [window]).sorted { $0.start < $1.start }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(_ window: OpenTime) async {
        do {
            try await api.deleteOpenTime(id: window.id)
            windows.removeAll { $0.id == window.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
