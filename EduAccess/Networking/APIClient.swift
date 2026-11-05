import Foundation

protocol APIClient: Sendable {
    func login(username: String, password: String, role: UserRole) async throws
    func logout() async throws
    func myProfessors() async throws -> [Professor]
    func searchProfessors(_ query: String) async throws -> [Professor]
    func appointments() async throws -> [Appointment]
    func book(professorID: Int, at time: Date, topic: Appointment.Topic) async throws -> Appointment
    func cancel(appointmentID: Int) async throws -> Appointment
    func confirm(appointmentID: Int) async throws -> Appointment
    func me() async throws -> Me
    func updateAvailability(_ update: AvailabilityUpdate) async throws -> Me
    /// A page of the web app, for the things only it can do.
    func webURL(_ path: String) -> URL
}

enum APIError: LocalizedError, Equatable {
    case invalidCredentials
    case roleMismatch
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: "Incorrect username or password."
        case .roleMismatch: "This account does not match the selected role, or is not active yet."
        case .server(let message): message
        }
    }

    /// Reads a Django REST Framework error body: {"detail": "..."} or {"field": ["..."]}.
    static func server(body: Data) -> APIError {
        let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        let values = json?.sorted { $0.key < $1.key }.map(\.value) ?? []
        for value in values {
            if let text = value as? String { return .server(text) }
            if let text = (value as? [String])?.first { return .server(text) }
        }
        return .server("Something went wrong. Please try again.")
    }
}
