import XCTest
@testable import EduAccess

@MainActor
final class CabinViewModelTests: XCTestCase {
    private let blocks = [
        CampusBlock(id: 10, number: 1, name: "Academic Block 1", facultyBlocks: [FacultyBlockOption(id: 100, number: 2, floorLabel: "Floor 2")]),
        CampusBlock(id: 20, number: 2, name: "Academic Block 2", facultyBlocks: [
            FacultyBlockOption(id: 200, number: 3, floorLabel: "Floor 1"),
            FacultyBlockOption(id: 201, number: 4, floorLabel: ""),
        ]),
    ]

    private func loaded(_ api: MockAPIClient, label: String = "") async -> CabinViewModel {
        api.campusBlocksResult = .success(blocks)
        let viewModel = CabinViewModel(api: api, currentLabel: label)
        await viewModel.load()
        return viewModel
    }

    func testFacultyOptionsFollowTheAcademicBlock() async {
        let viewModel = await loaded(MockAPIClient())
        XCTAssertTrue(viewModel.facultyOptions.isEmpty)

        viewModel.academicBlockID = 20

        XCTAssertEqual(viewModel.facultyOptions.map(\.id), [200, 201])
    }

    func testChangingAcademicBlockClearsAFacultyBlockNotInIt() async {
        let viewModel = await loaded(MockAPIClient())
        viewModel.academicBlockID = 20
        viewModel.facultyBlockID = 200

        viewModel.academicBlockID = 10

        XCTAssertNil(viewModel.facultyBlockID)
    }

    func testChangingACabinStartsFromTheCurrentOne() async {
        let viewModel = await loaded(MockAPIClient(), label: "AB2 FB4 : G-12")

        XCTAssertEqual(viewModel.academicBlockID, 20)
        XCTAssertEqual(viewModel.facultyBlockID, 201)
        XCTAssertEqual(viewModel.cabin, "G-12")
    }

    func testParseLabelRejectsAnIncompleteCabin() {
        XCTAssertNil(CabinViewModel.parseLabel(""))
        XCTAssertNil(CabinViewModel.parseLabel("106"))
        XCTAssertEqual(CabinViewModel.parseLabel("AB2 FB3 : 106")?.faculty, 3)
    }

    func testSaveSendsChosenBlocksAndTrimmedCabin() async {
        let api = MockAPIClient()
        let viewModel = await loaded(api)
        viewModel.academicBlockID = 20
        viewModel.facultyBlockID = 200
        viewModel.cabin = " 106 "

        let me = await viewModel.save()

        XCTAssertNotNil(me)
        XCTAssertEqual(api.cabinRequests, [CabinRequest(academicBlock: 20, facultyBlock: 200, cabin: "106")])
    }

    func testEveryFieldErrorIsKept() async {
        let api = MockAPIClient()
        api.setCabinError = APIError.validation([
            "cabin": ["Use letters, digits and dashes only."],
            "faculty_block": ["That faculty block is not in Academic Block 2."],
        ])
        let viewModel = await loaded(api)

        let me = await viewModel.save()

        XCTAssertNil(me)
        XCTAssertEqual(viewModel.fieldErrors["cabin"], ["Use letters, digits and dashes only."])
        XCTAssertEqual(viewModel.fieldErrors["faculty_block"], ["That faculty block is not in Academic Block 2."])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAnUnexpectedFieldStillShows() async {
        let api = MockAPIClient()
        api.setCabinError = APIError.validation(["__all__": ["Something else."]])
        let viewModel = await loaded(api)

        _ = await viewModel.save()

        XCTAssertEqual(viewModel.errorMessage, "Something else.")
    }

    func testSaveClearsEarlierErrors() async {
        let api = MockAPIClient()
        api.setCabinError = APIError.validation(["cabin": ["Bad."]])
        let viewModel = await loaded(api)
        _ = await viewModel.save()

        api.setCabinError = nil
        _ = await viewModel.save()

        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
    }

    func testNoBlocksIsAnEmptyLoadedState() async {
        let api = MockAPIClient()
        let viewModel = CabinViewModel(api: api)

        await viewModel.load()

        XCTAssertTrue(viewModel.hasLoaded)
        XCTAssertTrue(viewModel.blocks.isEmpty)
    }
}

@MainActor
final class ProfessorGateViewModelTests: XCTestCase {
    private func me(cabin: String) -> Me {
        Me(displayName: "No Cabin", role: .professor, availabilityStatus: .free, statusNote: nil, cabinLabel: cabin)
    }

    func testNoCabinNeedsOneFirst() async {
        let api = MockAPIClient()
        api.meResult = .success(me(cabin: ""))
        let gate = ProfessorGateViewModel(api: api)
        XCTAssertEqual(gate.state, .checking)

        await gate.check()

        XCTAssertEqual(gate.state, .needsCabin)
    }

    func testAnIncompleteCabinAlsoNeedsOne() async {
        let api = MockAPIClient()
        api.meResult = .success(me(cabin: "106"))
        let gate = ProfessorGateViewModel(api: api)

        await gate.check()

        XCTAssertEqual(gate.state, .needsCabin)
    }

    func testACompleteCabinGoesStraightIn() async {
        let api = MockAPIClient()
        api.meResult = .success(me(cabin: "AB2 FB3 : 106"))
        let gate = ProfessorGateViewModel(api: api)

        await gate.check()

        XCTAssertEqual(gate.state, .ready)
    }

    func testSavingACabinOpensTheDashboard() async {
        let api = MockAPIClient()
        api.meResult = .success(me(cabin: ""))
        let gate = ProfessorGateViewModel(api: api)
        await gate.check()

        gate.cabinSaved()

        XCTAssertEqual(gate.state, .ready)
    }

    func testAFailedCheckDoesNotTrapTheProfessor() async {
        let api = MockAPIClient()
        api.meResult = .failure(APIError.server("Server down"))
        let gate = ProfessorGateViewModel(api: api)

        await gate.check()

        XCTAssertEqual(gate.state, .ready)
    }
}
