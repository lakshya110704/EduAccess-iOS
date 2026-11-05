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

        let first = try await student1.book(professorID: professorID, at: time, topic: .doubt)
        let second = try await student2.book(professorID: professorID, at: time, topic: .marks)
        XCTAssertEqual(first.status, .pending)

        let confirmed = try await professor.confirm(appointmentID: first.id)
        XCTAssertEqual(confirmed.status, .confirmed)

        let requests = try await professor.appointments()
        XCTAssertEqual(requests.first { $0.id == second.id }?.status, .cancelled)

        let cancelled = try await professor.cancel(appointmentID: first.id)
        XCTAssertEqual(cancelled.status, .cancelled)
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
