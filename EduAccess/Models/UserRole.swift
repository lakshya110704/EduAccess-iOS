enum UserRole: String, Codable, CaseIterable, Identifiable {
    case student
    case professor

    var id: Self { self }

    var title: String {
        switch self {
        case .student: "Student"
        case .professor: "Professor"
        }
    }
}
