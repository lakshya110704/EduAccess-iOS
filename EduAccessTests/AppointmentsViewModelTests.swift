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

    func testAutoRefreshPicksUpAProfessorsDecision() async throws {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending)])
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        api.appointmentsResult = .success([.sample(id: 1, status: .confirmed)])
        let refresh = Task { await viewModel.autoRefresh(every: .milliseconds(5)) }
        for _ in 0..<500 where viewModel.appointments.first?.status != .confirmed {
            try await Task.sleep(for: .milliseconds(5))
        }
        refresh.cancel()
        await refresh.value

        XCTAssertEqual(viewModel.appointments.first?.status, .confirmed)
    }

    func testFailedRefreshKeepsTheRowsAndShowsTheError() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending)])
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        api.appointmentsResult = .failure(APIError.server("Server down"))
        await viewModel.load()

        XCTAssertEqual(viewModel.appointments.count, 1)
        XCTAssertEqual(viewModel.errorMessage, "Server down")
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

    func testSaveReasonSendsTrimmedDetailsAndUpdatesTheRow() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending), .sample(id: 2, status: .pending)])
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        let saved = await viewModel.saveReason(.sample(id: 2, status: .pending), topic: .marks, details: "  Question 2 ")

        XCTAssertTrue(saved)
        XCTAssertEqual(api.reasonUpdates.first?.details, "Question 2")
        XCTAssertEqual(viewModel.appointments[1].topic, .marks)
        XCTAssertEqual(viewModel.appointments[1].details, "Question 2")
        XCTAssertEqual(viewModel.appointments[0].details, "")
    }

    func testSaveReasonRefusalReportsFailureAndKeepsTheRow() async {
        let api = MockAPIClient()
        api.appointmentsResult = .success([.sample(id: 1, status: .pending)])
        api.updateReasonError = APIError.server("The reason can only be changed while the request is pending.")
        let viewModel = AppointmentsViewModel(api: api)
        await viewModel.load()

        let saved = await viewModel.saveReason(.sample(id: 1, status: .pending), topic: .marks, details: "")

        XCTAssertFalse(saved)
        XCTAssertEqual(viewModel.appointments.first?.topic, .doubt)
        XCTAssertEqual(viewModel.errorMessage, "The reason can only be changed while the request is pending.")
    }

    func testTimeRangeShowsTheStartDateAndBothTimes() {
        let appointment = Appointment.sample(id: 1, status: .pending)

        XCTAssertTrue(appointment.timeRange.hasPrefix(appointment.appointmentTime.formatted(date: .abbreviated, time: .shortened)))
        XCTAssertTrue(appointment.timeRange.hasSuffix(" to \(appointment.endTime.formatted(date: .omitted, time: .shortened))"))
    }

    func testOnlyPendingReasonsCanBeEdited() {
        XCTAssertTrue(Appointment.sample(id: 1, status: .pending).canEditReason)
        XCTAssertFalse(Appointment.sample(id: 1, status: .confirmed).canEditReason)
        XCTAssertFalse(Appointment.sample(id: 1, status: .cancelled).canEditReason)
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
