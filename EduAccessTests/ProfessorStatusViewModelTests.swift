import XCTest
@testable import EduAccess

@MainActor
final class ProfessorStatusViewModelTests: XCTestCase {
    func testLoadFillsInCurrentStatusNoteAndCabin() async {
        let api = MockAPIClient()
        let back = Date(timeIntervalSince1970: 1_800_000_000)
        api.meResult = .success(Me(
            displayName: "Ashish Gupta",
            role: .professor,
            availabilityStatus: .busy,
            statusNote: StatusNote(pick: "Lunch", text: "Back soon", until: back),
            cabinLabel: "AB2 FB3 : 106"
        ))
        let viewModel = ProfessorStatusViewModel(api: api)

        await viewModel.load()

        XCTAssertEqual(viewModel.status, .busy)
        XCTAssertEqual(viewModel.pick, "Lunch")
        XCTAssertEqual(viewModel.text, "Back soon")
        XCTAssertTrue(viewModel.hasUntil)
        XCTAssertEqual(viewModel.until, back)
        XCTAssertEqual(viewModel.cabinLabel, "AB2 FB3 : 106")
    }

    func testFreeClearsTheWholeNote() {
        let viewModel = ProfessorStatusViewModel(api: MockAPIClient())
        viewModel.status = .busy
        viewModel.pick = "Lunch"
        viewModel.text = "Back soon"
        viewModel.hasUntil = true

        viewModel.status = .free

        XCTAssertEqual(viewModel.update, AvailabilityUpdate(availabilityStatus: .free, statusPick: "", statusText: "", statusUntil: nil))
    }

    func testChangingStatusDropsAPickTheNewStatusDoesNotAllow() {
        let viewModel = ProfessorStatusViewModel(api: MockAPIClient())
        viewModel.status = .busy
        viewModel.pick = "Lunch"

        viewModel.status = .unavailable

        XCTAssertEqual(viewModel.pick, "")
    }

    func testUnavailableBackDateStartsAtTheStartOfThatDay() {
        let viewModel = ProfessorStatusViewModel(api: MockAPIClient())
        viewModel.status = .unavailable
        viewModel.hasUntil = true
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        viewModel.until = noon

        XCTAssertEqual(viewModel.update.statusUntil, Calendar.current.startOfDay(for: noon))
    }

    func testBusyBackTimeIsSentAsChosenAndTextIsTrimmed() {
        let viewModel = ProfessorStatusViewModel(api: MockAPIClient())
        viewModel.status = .busy
        viewModel.text = "  Back soon "
        viewModel.hasUntil = true
        let time = Date().addingTimeInterval(600)
        viewModel.until = time

        XCTAssertEqual(viewModel.update.statusText, "Back soon")
        XCTAssertEqual(viewModel.update.statusUntil, time)
    }

    func testNoBackTimeIsSentAsNil() {
        let viewModel = ProfessorStatusViewModel(api: MockAPIClient())
        viewModel.status = .busy

        XCTAssertNil(viewModel.update.statusUntil)
    }

    func testSaveSendsTheUpdateAndReportsSuccess() async {
        let api = MockAPIClient()
        let viewModel = ProfessorStatusViewModel(api: api)
        viewModel.status = .free

        await viewModel.save()

        XCTAssertEqual(api.updates.count, 1)
        XCTAssertTrue(viewModel.didSave)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testHasNoChangesUntilLoadedOrEdited() async {
        let api = MockAPIClient()
        api.meResult = .success(Me(
            displayName: "Ashish Gupta",
            role: .professor,
            availabilityStatus: .busy,
            statusNote: StatusNote(pick: "Lunch", text: "Back soon", until: Date(timeIntervalSince1970: 1_800_000_000)),
            cabinLabel: "AB2 FB3 : 106"
        ))
        let viewModel = ProfessorStatusViewModel(api: api)
        viewModel.status = .busy
        XCTAssertFalse(viewModel.hasChanges, "Nothing to compare with before loading")

        await viewModel.load()

        XCTAssertFalse(viewModel.hasChanges)
    }

    func testChangingStatusOrNoteCountsAsAChangeAndUndoingItDoesNot() async {
        let viewModel = ProfessorStatusViewModel(api: MockAPIClient())
        await viewModel.load()
        let original = viewModel.status

        viewModel.status = original == .busy ? .free : .busy
        XCTAssertTrue(viewModel.hasChanges)
        viewModel.status = original
        XCTAssertFalse(viewModel.hasChanges)

        viewModel.status = .busy
        await viewModel.save()
        XCTAssertFalse(viewModel.hasChanges)
        viewModel.pick = "Lunch"
        XCTAssertTrue(viewModel.hasChanges)
        viewModel.pick = ""
        viewModel.text = "  "
        XCTAssertFalse(viewModel.hasChanges, "Spaces alone aren't a note")
        viewModel.text = "Back soon"
        XCTAssertTrue(viewModel.hasChanges)
    }

    func testSavingClearsChangesButAFailedSaveKeepsThem() async {
        let api = MockAPIClient()
        let viewModel = ProfessorStatusViewModel(api: api)
        await viewModel.load()
        viewModel.status = viewModel.status == .busy ? .free : .busy

        api.updateError = APIError.server("Nope")
        await viewModel.save()
        XCTAssertTrue(viewModel.hasChanges)

        api.updateError = nil
        await viewModel.save()
        XCTAssertFalse(viewModel.hasChanges)
    }

    func testCabinGateRefusalShowsTheBackendMessage() async {
        let api = MockAPIClient()
        api.updateError = APIError.server("Set your cabin location first.")
        let viewModel = ProfessorStatusViewModel(api: api)

        await viewModel.save()

        XCTAssertFalse(viewModel.didSave)
        XCTAssertEqual(viewModel.errorMessage, "Set your cabin location first.")
    }
}
