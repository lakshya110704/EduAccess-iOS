import XCTest
@testable import EduAccess

@MainActor
final class ProfessorsViewModelTests: XCTestCase {
    func testEmptyQueryLoadsSavedProfessors() async {
        let api = MockAPIClient()
        api.professorsResult = .success([.sample])
        let viewModel = ProfessorsViewModel(api: api)

        await viewModel.load()

        XCTAssertEqual(api.myProfessorsCount, 1)
        XCTAssertTrue(api.searches.isEmpty)
        XCTAssertEqual(viewModel.professors, [.sample])
    }

    func testOneCharacterDoesNotSearch() async {
        let api = MockAPIClient()
        let viewModel = ProfessorsViewModel(api: api)
        viewModel.query = "g "

        await viewModel.load()

        XCTAssertTrue(api.searches.isEmpty)
        XCTAssertEqual(api.myProfessorsCount, 1)
    }

    func testTwoCharactersSearchWithTrimmedQuery() async {
        let api = MockAPIClient()
        let viewModel = ProfessorsViewModel(api: api)
        viewModel.query = " gu "

        await viewModel.load()

        XCTAssertEqual(api.searches, ["gu"])
        XCTAssertEqual(api.myProfessorsCount, 0)
    }

    func testFailureShowsErrorAndKeepsPreviousList() async {
        let api = MockAPIClient()
        api.professorsResult = .success([.sample])
        let viewModel = ProfessorsViewModel(api: api)
        await viewModel.load()

        api.professorsResult = .failure(APIError.server("Server down"))
        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, "Server down")
        XCTAssertEqual(viewModel.professors, [.sample])
    }

    func testCancelledRequestShowsNoError() async {
        let api = MockAPIClient()
        api.professorsResult = .failure(URLError(.cancelled))
        let viewModel = ProfessorsViewModel(api: api)

        await viewModel.load()

        XCTAssertNil(viewModel.errorMessage)
    }

    func testUnsavingInTheSavedListRemovesTheRow() async {
        let api = MockAPIClient()
        api.professorsResult = .success([.sample(isMine: true)])
        let viewModel = ProfessorsViewModel(api: api)
        await viewModel.load()

        await viewModel.toggleSaved(.sample(isMine: true))

        XCTAssertEqual(api.savedCalls.first?.saved, false)
        XCTAssertTrue(viewModel.professors.isEmpty)
    }

    func testSavingInSearchResultsKeepsTheRowWithNewState() async {
        let api = MockAPIClient()
        api.professorsResult = .success([.sample(isMine: false)])
        let viewModel = ProfessorsViewModel(api: api)
        viewModel.query = "gu"
        await viewModel.load()

        await viewModel.toggleSaved(.sample(isMine: false))

        XCTAssertEqual(api.savedCalls.first?.saved, true)
        XCTAssertEqual(viewModel.professors.map(\.isMine), [true])
    }

    func testUnsavingInSearchResultsKeepsTheRow() async {
        let api = MockAPIClient()
        api.professorsResult = .success([.sample(isMine: true)])
        let viewModel = ProfessorsViewModel(api: api)
        viewModel.query = "gu"
        await viewModel.load()

        await viewModel.toggleSaved(.sample(isMine: true))

        XCTAssertEqual(viewModel.professors.map(\.isMine), [false])
    }

    func testSaveFailureLeavesTheListAndShowsTheError() async {
        let api = MockAPIClient()
        api.professorsResult = .success([.sample(isMine: true)])
        api.saveError = APIError.server("Only students have a list.")
        let viewModel = ProfessorsViewModel(api: api)
        await viewModel.load()

        await viewModel.toggleSaved(.sample(isMine: true))

        XCTAssertEqual(viewModel.professors.count, 1)
        XCTAssertEqual(viewModel.errorMessage, "Only students have a list.")
    }

    func testAutoRefreshKeepsLoadingUntilCancelled() async throws {
        let api = MockAPIClient()
        let viewModel = ProfessorsViewModel(api: api)

        let refresh = Task { await viewModel.autoRefresh(every: .milliseconds(5)) }
        for _ in 0..<500 where api.myProfessorsCount < 3 {
            try await Task.sleep(for: .milliseconds(5))
        }
        XCTAssertGreaterThanOrEqual(api.myProfessorsCount, 3)

        refresh.cancel()
        await refresh.value
        let countAfterCancel = api.myProfessorsCount
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(api.myProfessorsCount, countAfterCancel)
    }

    func testAutoRefreshPicksUpAStatusChange() async throws {
        let api = MockAPIClient()
        api.professorsResult = .success([.sample(isMine: true, status: .free)])
        let viewModel = ProfessorsViewModel(api: api)
        await viewModel.load()

        api.professorsResult = .success([.sample(isMine: true, status: .busy)])
        let refresh = Task { await viewModel.autoRefresh(every: .milliseconds(5)) }
        for _ in 0..<500 where viewModel.professors.first?.availabilityStatus != .busy {
            try await Task.sleep(for: .milliseconds(5))
        }
        refresh.cancel()
        await refresh.value

        XCTAssertEqual(viewModel.professors.first?.availabilityStatus, .busy)
    }

    func testEmptyStateWaitsForTheFirstLoad() async {
        let viewModel = ProfessorsViewModel(api: MockAPIClient())
        XCTAssertFalse(viewModel.hasLoaded)

        await viewModel.load()

        XCTAssertTrue(viewModel.hasLoaded)
    }

    func testSuccessClearsAnEarlierError() async {
        let api = MockAPIClient()
        api.professorsResult = .failure(APIError.server("Server down"))
        let viewModel = ProfessorsViewModel(api: api)
        await viewModel.load()

        api.professorsResult = .success([])
        await viewModel.load()

        XCTAssertNil(viewModel.errorMessage)
    }
}
