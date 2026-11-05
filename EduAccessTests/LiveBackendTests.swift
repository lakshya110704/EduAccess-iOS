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

    private func loggedIn(_ username: String, as role: UserRole) async throws -> LiveAPIClient {
        let client = LiveAPIClient()
        try await client.login(username: username, password: password, role: role)
        return client
    }

    func testProfessorLogsInAsProfessor() async throws {
        _ = try await loggedIn("prof1", as: .professor)
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
