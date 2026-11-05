import Foundation
import Observation

@MainActor
@Observable
final class AppointmentsViewModel {
    private(set) var appointments: [Appointment] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            appointments = try await api.appointments()
            errorMessage = nil
        } catch where error.isCancellation {
            // The screen went away or a refresh replaced this request.
        } catch {
            errorMessage = error.localizedDescription
        }
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

    func cancel(_ appointment: Appointment) async {
        do {
            let updated = try await api.cancel(appointmentID: appointment.id)
            if let index = appointments.firstIndex(where: { $0.id == updated.id }) {
                appointments[index] = updated
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension Appointment {
    var canCancel: Bool { status != .cancelled }
    var canConfirm: Bool { status == .pending }
}
