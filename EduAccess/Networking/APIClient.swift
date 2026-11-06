import Foundation

protocol APIClient: Sendable {
    func login(username: String, password: String, role: UserRole) async throws
    func logout() async throws
    func myProfessors() async throws -> [Professor]
    func searchProfessors(_ query: String) async throws -> [Professor]
    func appointments() async throws -> [Appointment]
    func book(_ request: BookingRequest) async throws -> Appointment
    func cancel(appointmentID: Int) async throws -> Appointment
    func confirm(appointmentID: Int) async throws -> Appointment
    func updateReason(appointmentID: Int, topic: Appointment.Topic, details: String) async throws -> Appointment
    func setSaved(_ saved: Bool, professorID: Int) async throws -> Professor
    func openTimes() async throws -> [OpenTime]
    func addOpenTime(start: Date, end: Date) async throws -> OpenTime
    func deleteOpenTime(id: Int) async throws
    func notifications() async throws -> [AppNotification]
    func campusBlocks() async throws -> [CampusBlock]
    func setCabin(_ request: CabinRequest) async throws -> Me
    func me() async throws -> Me
    func updateAvailability(_ update: AvailabilityUpdate) async throws -> Me
    /// A page of the web app, for the things only it can do.
    func webURL(_ path: String) -> URL
}

extension Notification.Name {
    /// Posted when the backend says the session is gone, so the whole app can return to login from any screen.
    static let sessionExpired = Notification.Name("EduAccessSessionExpired")
}

enum APIError: LocalizedError, Equatable {
    case invalidCredentials
    case roleMismatch
    case sessionExpired
    case server(String)
    /// A form's errors by field. Several fields can fail at once and each can have several messages.
    case validation([String: [String]])

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: "Incorrect username or password."
        case .roleMismatch: "This account does not match the selected role, or is not active yet."
        case .sessionExpired: "Your session has ended. Please log in again."
        case .server(let message): message
        case .validation(let errors): errors.sorted { $0.key < $1.key }.flatMap(\.value).joined(separator: " ")
        }
    }

    /// Reads a form error body, {"field": ["..."]}, keeping every message.
    static func validation(body: Data) -> APIError {
        let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        let errors = (json ?? [:]).compactMapValues { $0 as? [String] }
        return errors.isEmpty ? server(body: body) : .validation(errors)
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
