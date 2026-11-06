struct SignupRequest: Encodable, Equatable {
    let role: UserRole
    let username: String
    let firstName: String
    let middleName: String
    let lastName: String
    let email: String
    let collegeId: String
    let password1: String
    let password2: String
}

struct SignupResult: Decodable, Equatable {
    let username: String
    let isActive: Bool
}

struct SignupOptions: Decodable, Equatable {
    /// The email domain each role must register with, keyed by role.
    let emailDomains: [String: String]
}
