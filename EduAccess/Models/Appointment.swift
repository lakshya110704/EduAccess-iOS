import Foundation

struct BookingRequest: Encodable, Equatable {
    let professor: Int
    let appointmentTime: Date
    /// Each slot is 15 minutes. The backend accepts one or two.
    let slots: Int
    let topic: Appointment.Topic
    let details: String
}

struct Appointment: Codable, Identifiable, Equatable {
    enum Status: String, Codable {
        case pending = "Pending"
        case confirmed = "Confirmed"
        case cancelled = "Cancelled"
    }

    enum Topic: String, Codable, CaseIterable, Identifiable {
        case doubt = "Doubt"
        case project = "Project"
        case attendance = "Attendance"
        case marks = "Marks"
        case other = "Other"

        var id: Self { self }
    }

    let id: Int
    let studentName: String
    let professorName: String
    let appointmentTime: Date
    let status: Status
    let topic: Topic
    let details: String
}
