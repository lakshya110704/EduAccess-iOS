import SwiftUI

enum AvailabilityStatus: String, Codable {
    case free = "Free"
    case busy = "Busy"
    case unavailable = "Unavailable"

    var color: Color {
        switch self {
        case .free: .green
        case .busy: .orange
        case .unavailable: .red
        }
    }
}
