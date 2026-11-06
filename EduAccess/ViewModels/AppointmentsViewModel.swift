import Foundation
import Observation

@MainActor
@Observable
final class AppointmentsViewModel {
    private(set) var appointments: [Appointment] = []
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func load() async {
        do {
            appointments = try await api.appointments()
            hasLoaded = true
            errorMessage = nil
        } catch where error.isCancellation {
            // The screen went away or a refresh replaced this request.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func autoRefresh(every interval: Duration = .dashboardRefresh) async {
        await repeatEvery(interval) { await load() }
    }

    func confirm(_ appointment: Appointment) async {
        do {
            _ = try await api.confirm(appointmentID: appointment.id)
            // Confirming declines overlapping requests on the backend, so other rows may have changed too.
            appointments = try await api.appointments()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns whether it saved, so the edit screen knows whether to close.
    func saveReason(_ appointment: Appointment, topic: Appointment.Topic, details: String) async -> Bool {
        do {
            let updated = try await api.updateReason(
                appointmentID: appointment.id,
                topic: topic,
                details: details.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            replace(updated)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func cancel(_ appointment: Appointment) async {
        do {
            replace(try await api.cancel(appointmentID: appointment.id))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func replace(_ updated: Appointment) {
        if let index = appointments.firstIndex(where: { $0.id == updated.id }) {
            appointments[index] = updated
        }
    }
}

extension Appointment {
    var canCancel: Bool { status != .cancelled }
    var canConfirm: Bool { status == .pending }
    /// The backend only lets a student change the reason while the request is pending.
    var canEditReason: Bool { status == .pending }
}
