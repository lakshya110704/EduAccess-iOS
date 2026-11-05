import Foundation

/// A professor's own walk-in window, from /api/open-times/.
struct OpenTime: Codable, Identifiable, Equatable {
    let id: Int
    let start: Date
    let end: Date
}
