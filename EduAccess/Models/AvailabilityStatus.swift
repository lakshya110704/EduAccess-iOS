import SwiftUI

enum AvailabilityStatus: String, Codable, CaseIterable, Identifiable {
    case free = "Free"
    case busy = "Busy"
    case unavailable = "Unavailable"

    var id: Self { self }

    var color: Color {
        switch self {
        case .free: .green
        case .busy: .orange
        case .unavailable: .red
        }
    }

    /// Quick picks the backend accepts for a status note. A Free professor has no note.
    var notePicks: [String] {
        switch self {
        case .free: []
        case .busy: ["In class", "In a meeting", "Lunch"]
        case .unavailable: ["On leave", "Conference", "Out of campus"]
        }
    }
}
