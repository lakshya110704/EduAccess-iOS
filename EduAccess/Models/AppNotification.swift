import Foundation

struct AppNotification: Decodable, Identifiable, Equatable {
    let id: Int
    let message: String
    let sentAt: Date
}
