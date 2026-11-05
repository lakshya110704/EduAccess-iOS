import Foundation

struct OpenWindow: Codable, Hashable {
    let start: Date
    let end: Date
}

struct Professor: Codable, Identifiable, Hashable {
    let id: Int
    let displayName: String
    let availabilityStatus: AvailabilityStatus
    let statusNote: StatusNote?
    let cabinLabel: String
    let directionsUrl: String
    let isMine: Bool
    let openToday: [OpenWindow]

    /// What the professor told students, for example "Lunch, Back soon, back at 14:00".
    var noteSummary: String? {
        guard let statusNote else { return nil }
        var parts = [statusNote.pick, statusNote.text].filter { !$0.isEmpty }
        if let until = statusNote.until {
            let back = availabilityStatus == .busy
                ? until.formatted(date: .omitted, time: .shortened)
                : until.formatted(date: .abbreviated, time: .omitted)
            parts.append("back \(availabilityStatus == .busy ? "at" : "on") \(back)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    var openTodaySummary: String? {
        guard !openToday.isEmpty else { return nil }
        let windows = openToday.map {
            "\($0.start.formatted(date: .omitted, time: .shortened)) to \($0.end.formatted(date: .omitted, time: .shortened))"
        }
        return "Walk in today: \(windows.joined(separator: ", "))"
    }
}
