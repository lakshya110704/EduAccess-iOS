import XCTest
@testable import EduAccess

/// Runs the real client against a local backend with seed_demo data. Skipped unless the password is
/// supplied: TEST_RUNNER_EDUACCESS_TEST_PASSWORD=... xcodebuild test ...
/// Refuses anything but localhost, so these writes can never reach a deployed backend.
final class LiveBackendTests: XCTestCase {
    private var password = ""

    override func setUpWithError() throws {
        let client = LiveAPIClient()
        try XCTSkipUnless(client.baseURL.host() == "127.0.0.1", "Local backend only")
        let supplied = ProcessInfo.processInfo.environment["EDUACCESS_TEST_PASSWORD"]
        try XCTSkipIf(supplied == nil, "No EDUACCESS_TEST_PASSWORD")
        password = supplied ?? ""
    }

    /// A quarter hour years ahead, so runs against the same database don't collide.
    private func randomFutureSlot() -> Date {
        let quarters = Int(Date().timeIntervalSince1970 / 900) + Int.random(in: 100_000...400_000)
        return Date(timeIntervalSince1970: Double(quarters) * 900)
    }

    private func loggedIn(_ username: String, as role: UserRole) async throws -> LiveAPIClient {
        let client = LiveAPIClient()
        try await client.login(username: username, password: password, role: role)
        return client
    }

    func testProfessorLogsInAsProfessor() async throws {
        _ = try await loggedIn("prof1", as: .professor)
    }

    func testProfessorSetsAndClearsAStatusNote() async throws {
        let client = try await loggedIn("prof2", as: .professor)
        let back = Date().addingTimeInterval(10 * 60)
        let busy = AvailabilityUpdate(availabilityStatus: .busy, statusPick: "Lunch", statusText: "Back soon", statusUntil: back)

        var me = try await client.updateAvailability(busy)
        XCTAssertEqual(me.availabilityStatus, .busy)
        XCTAssertEqual(me.statusNote?.pick, "Lunch")
        XCTAssertEqual(me.statusNote?.text, "Back soon")
        XCTAssertNotNil(me.statusNote?.until)

        me = try await client.updateAvailability(AvailabilityUpdate(availabilityStatus: .free, statusPick: "", statusText: "", statusUntil: nil))
        XCTAssertEqual(me.availabilityStatus, .free)
        XCTAssertNil(me.statusNote)
    }

    func testProfessorConfirmsARequestAndOverlappingOneIsDeclined() async throws {
        let student1 = try await loggedIn("student1", as: .student)
        let student2 = try await loggedIn("student2", as: .student)
        let professor = try await loggedIn("prof2", as: .professor)
        let professorID = try await student1.searchProfessors("Iyer")[0].id
        let time = randomFutureSlot()

        let first = try await student1.book(BookingRequest(professor: professorID, appointmentTime: time, slots: 2, topic: .doubt, details: "Chapter 3"))
        let second = try await student2.book(BookingRequest(professor: professorID, appointmentTime: time, slots: 1, topic: .marks, details: ""))
        XCTAssertEqual(first.details, "Chapter 3")
        XCTAssertEqual(first.status, .pending)

        let confirmed = try await professor.confirm(appointmentID: first.id)
        XCTAssertEqual(confirmed.status, .confirmed)

        let requests = try await professor.appointments()
        XCTAssertEqual(requests.first { $0.id == second.id }?.status, .cancelled)

        let cancelled = try await professor.cancel(appointmentID: first.id)
        XCTAssertEqual(cancelled.status, .cancelled)
    }

    @MainActor
    func testStudentSeesAProfessorsDecisionWithoutReloading() async throws {
        let student = try await loggedIn("student2", as: .student)
        let professor = try await loggedIn("prof2", as: .professor)
        let professorID = try await student.searchProfessors("Iyer")[0].id
        let request = try await student.book(BookingRequest(professor: professorID, appointmentTime: randomFutureSlot(), slots: 1, topic: .doubt, details: ""))
        let viewModel = AppointmentsViewModel(api: student)
        await viewModel.load()
        let refresh = Task { await viewModel.autoRefresh(every: .milliseconds(200)) }

        _ = try await professor.confirm(appointmentID: request.id)
        for _ in 0..<100 where viewModel.appointments.first(where: { $0.id == request.id })?.status != .confirmed {
            try await Task.sleep(for: .milliseconds(100))
        }
        refresh.cancel()
        await refresh.value

        XCTAssertEqual(viewModel.appointments.first { $0.id == request.id }?.status, .confirmed)
        _ = try await professor.cancel(appointmentID: request.id)
    }

    func testStudentSavesAndUnsavesAProfessor() async throws {
        let student = try await loggedIn("student2", as: .student)
        let professor = try await student.searchProfessors("Gupta")[0]

        let saved = try await student.setSaved(true, professorID: professor.id)
        XCTAssertTrue(saved.isMine)
        var list = try await student.myProfessors()
        XCTAssertTrue(list.contains { $0.id == professor.id })

        let unsaved = try await student.setSaved(false, professorID: professor.id)
        XCTAssertFalse(unsaved.isMine)
        list = try await student.myProfessors()
        XCTAssertFalse(list.contains { $0.id == professor.id })
    }

    func testWalkInWindowReachesStudentsAndCanBeRemoved() async throws {
        let professor = try await loggedIn("prof2", as: .professor)
        let student = try await loggedIn("student2", as: .student)

        // Late today, so it stays within "today" and clear of other windows from earlier runs.
        let calendar = Calendar(identifier: .gregorian)
        var kolkata = calendar
        kolkata.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let start = kolkata.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
        let window = try await professor.addOpenTime(start: start, end: start.addingTimeInterval(30 * 60))
        var seen = try await student.searchProfessors("Iyer")[0]
        XCTAssertTrue(seen.openToday.contains { $0.start == start })

        try await professor.deleteOpenTime(id: window.id)
        seen = try await student.searchProfessors("Iyer")[0]
        XCTAssertFalse(seen.openToday.contains { $0.start == start })
    }

    func testAccountsAreRefusedUnderTheWrongRole() async throws {
        for (username, role) in [("student1", UserRole.professor), ("prof1", UserRole.student)] {
            do {
                _ = try await loggedIn(username, as: role)
                XCTFail("\(username) logged in as \(role)")
            } catch {
                XCTAssertEqual(error as? APIError, .roleMismatch)
            }
        }
    }
}
