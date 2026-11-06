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
    let endTime: Date
    let status: Status
    let topic: Topic
    let details: String

    /// For example "Nov 7, 2026 at 15:30 to 16:00", so a 30 minute booking looks different from a 15 minute one.
    var timeRange: String {
        "\(appointmentTime.formatted(date: .abbreviated, time: .shortened)) to \(endTime.formatted(date: .omitted, time: .shortened))"
    }
}
