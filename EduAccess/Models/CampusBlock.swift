struct FacultyBlockOption: Decodable, Identifiable, Equatable {
    let id: Int
    let number: Int
    let floorLabel: String

    var title: String {
        floorLabel.isEmpty ? "Faculty Block \(number)" : "Faculty Block \(number), \(floorLabel)"
    }
}

/// An academic block a professor's cabin can be in, from GET /api/campus-blocks/.
struct CampusBlock: Decodable, Identifiable, Equatable {
    let id: Int
    let number: Int
    let name: String
    let facultyBlocks: [FacultyBlockOption]
}

/// The body of PUT /api/me/cabin/. A block not chosen yet is left out, and the backend says it is required.
struct CabinRequest: Encodable, Equatable {
    let academicBlock: Int?
    let facultyBlock: Int?
    let cabin: String
}
