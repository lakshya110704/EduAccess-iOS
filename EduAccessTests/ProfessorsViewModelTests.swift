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
