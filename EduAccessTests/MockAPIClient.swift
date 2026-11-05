import Foundation
@testable import EduAccess

@MainActor
final class MockAPIClient: APIClient {
    var loginError: Error?
    var professorsResult: Result<[Professor], Error> = .success([])
    var appointmentsResult: Result<[Appointment], Error> = .success([])
    var bookError: Error?
    var cancelResult: Result<Appointment, Error>?
    var confirmError: Error?
    var meResult: Result<Me, Error> = .success(.sample)
    var updateError: Error?
    var saveError: Error?
    var openTimesResult: Result<[OpenTime], Error> = .success([])
    var addOpenTimeError: Error?
    var deleteOpenTimeError: Error?

    private(set) var loginCalls: [(username: String, password: String, role: UserRole)] = []
    private(set) var logoutCount = 0
    private(set) var myProfessorsCount = 0
    private(set) var searches: [String] = []
    private(set) var bookings: [BookingRequest] = []
    private(set) var savedCalls: [(saved: Bool, professorID: Int)] = []
    private(set) var addedOpenTimes: [(start: Date, end: Date)] = []
    private(set) var deletedOpenTimeIDs: [Int] = []
    private(set) var cancelledIDs: [Int] = []
    private(set) var confirmedIDs: [Int] = []
    private(set) var updates: [AvailabilityUpdate] = []

    func login(username: String, password: String, role: UserRole) async throws {
        loginCalls.append((username, password, role))
        if let loginError { throw loginError }
    }

    func logout() async throws {
        logoutCount += 1
    }

    func myProfessors() async throws -> [Professor] {
        myProfessorsCount += 1
        return try professorsResult.get()
    }

    func searchProfessors(_ query: String) async throws -> [Professor] {
        searches.append(query)
        return try professorsResult.get()
    }

    func appointments() async throws -> [Appointment] {
        try appointmentsResult.get()
    }

    func book(_ request: BookingRequest) async throws -> Appointment {
        bookings.append(request)
        if let bookError { throw bookError }
        return Appointment.sample(id: 1, status: .pending)
    }

    func cancel(appointmentID: Int) async throws -> Appointment {
        cancelledIDs.append(appointmentID)
        return try cancelResult!.get()
    }

    func confirm(appointmentID: Int) async throws -> Appointment {
        confirmedIDs.append(appointmentID)
        if let confirmError { throw confirmError }
        return Appointment.sample(id: appointmentID, status: .confirmed)
    }

    func setSaved(_ saved: Bool, professorID: Int) async throws -> Professor {
        savedCalls.append((saved, professorID))
        if let saveError { throw saveError }
        return Professor.sample(isMine: saved)
    }

    func openTimes() async throws -> [OpenTime] {
        try openTimesResult.get()
    }

    func addOpenTime(start: Date, end: Date) async throws -> OpenTime {
        addedOpenTimes.append((start, end))
        if let addOpenTimeError { throw addOpenTimeError }
        return OpenTime(id: 9, start: start, end: end)
    }

    func deleteOpenTime(id: Int) async throws {
        deletedOpenTimeIDs.append(id)
        if let deleteOpenTimeError { throw deleteOpenTimeError }
    }

    func me() async throws -> Me {
        try meResult.get()
    }

    func updateAvailability(_ update: AvailabilityUpdate) async throws -> Me {
        updates.append(update)
        if let updateError { throw updateError }
        return Me(
            displayName: "Ashish Gupta",
            availabilityStatus: update.availabilityStatus,
            statusNote: nil,
            cabinLabel: "AB2 FB3 : 106"
        )
    }

    nonisolated func webURL(_ path: String) -> URL {
        URL(string: "http://example.test/\(path)")!
    }
}

extension Professor {
    static let sample = sample(isMine: false)

    static func sample(isMine: Bool, status: AvailabilityStatus = .free, note: StatusNote? = nil, openToday: [OpenWindow] = []) -> Professor {
        Professor(
            id: 3,
            displayName: "Ashish Gupta",
            availabilityStatus: status,
            statusNote: note,
            cabinLabel: "AB2 FB3 : 106",
            directionsUrl: "/go/AB2/FB3/106/",
            isMine: isMine,
            openToday: openToday
        )
    }
}

extension Me {
    static let sample = Me(displayName: "Ashish Gupta", availabilityStatus: .free, statusNote: nil, cabinLabel: "AB2 FB3 : 106")
}

extension Appointment {
    static func sample(id: Int, status: Status) -> Appointment {
        Appointment(id: id, studentName: "Riya Sharma", professorName: "Ashish Gupta", appointmentTime: Date(timeIntervalSince1970: 1_800_000_000), status: status, topic: .doubt, details: "")
    }
}
