struct Professor: Codable, Identifiable, Hashable {
    let id: Int
    let displayName: String
    let availabilityStatus: AvailabilityStatus
    let cabinLabel: String
}
