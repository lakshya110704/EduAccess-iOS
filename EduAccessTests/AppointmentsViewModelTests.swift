import XCTest
@testable import EduAccess

@MainActor
final class AppointmentsViewModelTests: XCTestCase {
    func testLoadShowsAppointments() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending)])
        let viewModel = AppointmentsViewModel(api: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.appointments, [.sample(id: 1, status: .pending)])
    }

    func testCancelReplacesOnlyThatAppointment() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending), .sample(id: 2, status: .confirmed)])
        api.cancelResult = .success(.sample(id: 2, status: .cancelled))
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        await viewModel.cancel(.sample(id: 2, status: .confirmed))

        XCTAssertEqual(api.cancelledIDs, [2])
        XCTAssertEqual(viewModel.appointments.map(\.status), [.pending, .cancelled])
    }

    func testCancelFailureKeepsStatusAndShowsError() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending)])
        api.cancelResult = .failure(APIError.server("This appointment is already cancelled."))
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        await viewModel.cancel(.sample(id: 1, status: .pending))

        XCTAssertEqual(viewModel.appointments.first?.status, .pending)
        XCTAssertEqual(viewModel.errorMessage, "This appointment is already cancelled.")
    }

    func testConfirmReloadsBecauseOverlappingRequestsMayHaveChanged() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending), .sample(id: 2, status: .pending)])
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        api.appointmentsResult = .success([.sample(id: 1, status: .confirmed), .sample(id: 2, status: .cancelled)])
        await viewModel.confirm(.sample(id: 1, status: .pending))

        XCTAssertEqual(api.confirmedIDs, [1])
        XCTAssertEqual(viewModel.appointments.map(\.status), [.confirmed, .cancelled])
    }

    func testConfirmRefusalShowsItsMessage() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending)])
        api.confirmError = APIError.server("This overlaps another confirmed appointment.")
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        await viewModel.confirm(.sample(id: 1, status: .pending))

        XCTAssertEqual(viewModel.errorMessage, "This overlaps another confirmed appointment.")
        XCTAssertEqual(viewModel.appointments.first?.status, .pending)
    }

    func testOnlyPendingAppointmentsCanBeConfirmed() {
        XCTAssertTrue(Appointment.sample(id: 1, status: .pending).canConfirm)
        XCTAssertFalse(Appointment.sample(id: 1, status: .confirmed).canConfirm)
        XCTAssertFalse(Appointment.sample(id: 1, status: .cancelled).canConfirm)
    }

    func testOnlyActiveAppointmentsCanBeCancelled() {
        XCTAssertTrue(Appointment.sample(id: 1, status: .pending).canCancel)
        XCTAssertTrue(Appointment.sample(id: 1, status: .confirmed).canCancel)
        XCTAssertFalse(Appointment.sample(id: 1, status: .cancelled).canCancel)
    }
}
