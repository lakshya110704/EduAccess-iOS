import XCTest
@testable import EduAccess

@MainActor
final class OpenTimeViewModelTests: XCTestCase {
    private let quarterHour = Date(timeIntervalSince1970: 1_800_000_000 - 1_800_000_000.truncatingRemainder(dividingBy: 900))

    func testStartsAtTheNextQuarterHourForHalfAnHour() {
        let viewModel = OpenTimeViewModel(api: MockAPIClient(), now: quarterHour.addingTimeInterval(60))

        XCTAssertEqual(viewModel.start, quarterHour.addingTimeInterval(900))
        XCTAssertEqual(viewModel.end, quarterHour.addingTimeInterval(900 + 1800))
    }

    func testAddRoundsBothEndsAndKeepsWindowsInOrder() async {
        let api = MockAPIClient()
        api.openTimesResult = .success([OpenTime(id: 1, start: quarterHour.addingTimeInterval(7200), end: quarterHour.addingTimeInterval(9000))])
        let viewModel = OpenTimeViewModel(api: api, now: quarterHour)
        await viewModel.load()
        viewModel.start = quarterHour.addingTimeInterval(1)
        viewModel.end = quarterHour.addingTimeInterval(901)

        await viewModel.add()

        XCTAssertEqual(api.addedOpenTimes.first?.start, quarterHour.addingTimeInterval(900))
        XCTAssertEqual(api.addedOpenTimes.first?.end, quarterHour.addingTimeInterval(1800))
        XCTAssertEqual(viewModel.windows.map(\.id), [9, 1])
    }

    func testAddRefusalShowsItsMessage() async {
        let api = MockAPIClient()
        api.addOpenTimeError = APIError.server("This overlaps open time you already set.")
        let viewModel = OpenTimeViewModel(api: api, now: quarterHour)

        await viewModel.add()

        XCTAssertTrue(viewModel.windows.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "This overlaps open time you already set.")
    }

    func testRemoveDropsTheWindow() async {
        let api = MockAPIClient()
        let window = OpenTime(id: 1, start: quarterHour, end: quarterHour.addingTimeInterval(1800))
        api.openTimesResult = .success([window])
        let viewModel = OpenTimeViewModel(api: api, now: quarterHour)
        await viewModel.load()

        await viewModel.remove(window)

        XCTAssertEqual(api.deletedOpenTimeIDs, [1])
        XCTAssertTrue(viewModel.windows.isEmpty)
    }

    func testRemoveFailureKeepsTheWindow() async {
        let api = MockAPIClient()
        let window = OpenTime(id: 1, start: quarterHour, end: quarterHour.addingTimeInterval(1800))
        api.openTimesResult = .success([window])
        api.deleteOpenTimeError = APIError.server("Set your cabin location first.")
        let viewModel = OpenTimeViewModel(api: api, now: quarterHour)
        await viewModel.load()

        await viewModel.remove(window)

        XCTAssertEqual(viewModel.windows, [window])
        XCTAssertEqual(viewModel.errorMessage, "Set your cabin location first.")
    }
}
