import Foundation
@testable import EduAccess

@MainActor
final class MockAPIClient: APIClient {
    var loginError: Error?
    var professorsResult: Result<[Professor], Error> = .success([])
    var appointmentsResult: Result<[Appointment], Error> = .success([])
    var bookError: Error?
    var cancelResult: Result<Appointment, Error>?

    private(set) var loginCalls: [(username: String, password: String)] = []
    private(set) var logoutCount = 0
    private(set) var myProfessorsCount = 0
    private(set) var searches: [String] = []
    private(set) var bookings: [(professorID: Int, time: Date, topic: Appointment.Topic)] = []
    private(set) var cancelledIDs: [Int] = []

    func login(username: String, password: String) async throws {
        loginCalls.append((username, password))
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

    func book(professorID: Int, at time: Date, topic: Appointment.Topic) async throws -> Appointment {
        bookings.append((professorID, time, topic))
        if let bookError { throw bookError }
        return Appointment.sample(id: 1, status: .pending)
    }

    func cancel(appointmentID: Int) async throws -> Appointment {
        cancelledIDs.append(appointmentID)
        return try cancelResult!.get()
    }
}

extension Professor {
    static let sample = Professor(id: 3, displayName: "Ashish Gupta", availabilityStatus: .free, cabinLabel: "AB2 FB3 : 106")
}

extension Appointment {
    static func sample(id: Int, status: Status) -> Appointment {
        Appointment(id: id, professorName: "Ashish Gupta", appointmentTime: Date(timeIntervalSince1970: 1_800_000_000), status: status, topic: .doubt)
    }
}
