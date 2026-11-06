import Foundation

struct StatusNote: Codable, Equatable, Hashable {
    let pick: String
    let text: String
    let until: Date?
}

/// The logged-in user, from GET /api/me/.
struct Me: Decodable, Equatable {
    let displayName: String
    let role: UserRole
    let availabilityStatus: AvailabilityStatus
    let statusNote: StatusNote?
    let cabinLabel: String
}

/// The body of PATCH /api/me/. Always sends every field, because the backend keeps any note field left out.
struct AvailabilityUpdate: Encodable, Equatable {
    let availabilityStatus: AvailabilityStatus
    let statusPick: String
    let statusText: String
    let statusUntil: Date?

    private enum CodingKeys: String, CodingKey {
        case availabilityStatus, statusPick, statusText, statusUntil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(availabilityStatus, forKey: .availabilityStatus)
        try container.encode(statusPick, forKey: .statusPick)
        try container.encode(statusText, forKey: .statusText)
        // Synthesized coding would drop a nil here, and the old "back" time would stay.
        try container.encode(statusUntil, forKey: .statusUntil)
    }
}
