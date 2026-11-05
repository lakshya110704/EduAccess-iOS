import XCTest
@testable import EduAccess

@MainActor
final class BookingViewModelTests: XCTestCase {
    private let quarterHour = Date(timeIntervalSince1970: 1_800_000_000 - 1_800_000_000.truncatingRemainder(dividingBy: 900))

    func testTimeOnTheQuarterHourStaysTheSame() {
        XCTAssertEqual(BookingViewModel.nextQuarterHour(onOrAfter: quarterHour), quarterHour)
    }

    func testTimeBetweenQuartersRoundsUp() {
        let oneMinuteIn = quarterHour.addingTimeInterval(60)
        XCTAssertEqual(BookingViewModel.nextQuarterHour(onOrAfter: oneMinuteIn), quarterHour.addingTimeInterval(900))
    }

    func testBookSendsRoundedTimeProfessorAndTopic() async {
        let api = MockAPIClient()
        let viewModel = BookingViewModel(professor: .sample, api: api)
        viewModel.date = quarterHour.addingTimeInterval(1)
        viewModel.topic = .marks

        await viewModel.book()

        XCTAssertEqual(api.bookings.count, 1)
        XCTAssertEqual(api.bookings.first?.professor, Professor.sample.id)
        XCTAssertEqual(api.bookings.first?.appointmentTime, quarterHour.addingTimeInterval(900))
        XCTAssertEqual(api.bookings.first?.topic, .marks)
        XCTAssertEqual(api.bookings.first?.slots, 1)
        XCTAssertEqual(api.bookings.first?.details, "")
        XCTAssertTrue(viewModel.didBook)
        XCTAssertFalse(viewModel.isBooking)
    }

    func testBookSendsLengthAndTrimmedDetails() async {
        let api = MockAPIClient()
        let viewModel = BookingViewModel(professor: .sample, api: api)
        viewModel.slots = 2
        viewModel.details = "  Chapter 3 "

        await viewModel.book()

        XCTAssertEqual(api.bookings.first?.slots, 2)
        XCTAssertEqual(api.bookings.first?.details, "Chapter 3")
    }

    func testServerRefusalShowsItsMessage() async {
        let api = MockAPIClient()
        api.bookError = APIError.server("That time is already booked. Pick another slot.")
        let viewModel = BookingViewModel(professor: .sample, api: api)

        await viewModel.book()

        XCTAssertFalse(viewModel.didBook)
        XCTAssertEqual(viewModel.errorMessage, "That time is already booked. Pick another slot.")
    }
}
