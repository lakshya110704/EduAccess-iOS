import Foundation
import Observation

@MainActor
@Observable
final class BookingViewModel {
    let professor: Professor
    var date = Date()
    var topic = Appointment.Topic.doubt
    var slots = 1
    var details = ""
    private(set) var isBooking = false
    private(set) var didBook = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(professor: Professor, api: any APIClient) {
        self.professor = professor
        self.api = api
    }

    /// The backend only accepts appointments that start on the quarter hour.
    var slotStart: Date {
        Self.nextQuarterHour(onOrAfter: date)
    }

    static func nextQuarterHour(onOrAfter date: Date) -> Date {
        let quarterHour: TimeInterval = 15 * 60
        return Date(timeIntervalSince1970: (date.timeIntervalSince1970 / quarterHour).rounded(.up) * quarterHour)
    }

    func book() async {
        guard !isBooking else { return }
        isBooking = true
        defer { isBooking = false }
        do {
            _ = try await api.book(BookingRequest(
                professor: professor.id,
                appointmentTime: slotStart,
                slots: slots,
                topic: topic,
                details: details.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            errorMessage = nil
            didBook = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
