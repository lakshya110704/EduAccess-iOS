import XCTest
@testable import EduAccess

@MainActor
final class NotificationsViewModelTests: XCTestCase {
    private let note = AppNotification(id: 1, message: "Your appointment is now Confirmed.", sentAt: Date(timeIntervalSince1970: 1_800_000_000))

    func testLoadShowsNotifications() async {
        let api = MockAPIClient()
        api.notificationsResult = .success([note])
        let viewModel = NotificationsViewModel(api: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.notifications, [note])
        XCTAssertTrue(viewModel.hasLoaded)
    }

    func testEmptyStateWaitsForTheFirstLoad() {
        XCTAssertFalse(NotificationsViewModel(api: MockAPIClient()).hasLoaded)
    }

    func testFailedRefreshKeepsRowsAndShowsTheError() async {
        let api = MockAPIClient()
        api.notificationsResult = .success([note])
        let viewModel = NotificationsViewModel(api: api)
        await viewModel.load()

        api.notificationsResult = .failure(APIError.server("Server down"))
        await viewModel.load()

        XCTAssertEqual(viewModel.notifications, [note])
        XCTAssertEqual(viewModel.errorMessage, "Server down")
    }

    func testAutoRefreshPicksUpANewNotification() async throws {
        let api = MockAPIClient()
        let viewModel = NotificationsViewModel(api: api)
        await viewModel.load()

        api.notificationsResult = .success([note])
        let refresh = Task { await viewModel.autoRefresh(every: .milliseconds(5)) }
        for _ in 0..<500 where viewModel.notifications.isEmpty {
            try await Task.sleep(for: .milliseconds(5))
        }
        refresh.cancel()
        await refresh.value

        XCTAssertEqual(viewModel.notifications, [note])
    }
}
