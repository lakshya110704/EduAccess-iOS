import Foundation
import Observation

@MainActor
@Observable
final class CabinViewModel {
    var academicBlockID: Int? {
        didSet {
            if !facultyOptions.contains(where: { $0.id == facultyBlockID }) { facultyBlockID = nil }
        }
    }
    var facultyBlockID: Int?
    var cabin = ""
    private(set) var blocks: [CampusBlock] = []
    private(set) var hasLoaded = false
    private(set) var isSaving = false
    private(set) var fieldErrors: [String: [String]] = [:]
    private(set) var errorMessage: String?

    private let api: any APIClient
    private let currentLabel: String

    init(api: any APIClient, currentLabel: String = "") {
        self.api = api
        self.currentLabel = currentLabel
    }

    var facultyOptions: [FacultyBlockOption] {
        blocks.first { $0.id == academicBlockID }?.facultyBlocks ?? []
    }

    func load() async {
        do {
            blocks = try await api.campusBlocks()
            hasLoaded = true
            errorMessage = nil
            preselectCurrentCabin()
        } catch where error.isCancellation {
            // The screen went away.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns the updated user when it saved, so the caller can move on.
    func save() async -> Me? {
        guard !isSaving else { return nil }
        isSaving = true
        defer { isSaving = false }
        fieldErrors = [:]
        errorMessage = nil
        do {
            return try await api.setCabin(CabinRequest(
                academicBlock: academicBlockID,
                facultyBlock: facultyBlockID,
                cabin: cabin.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        } catch APIError.validation(let errors) {
            let known = ["academic_block", "faculty_block", "cabin"]
            fieldErrors = errors.filter { known.contains($0.key) }
            let other = errors.filter { !known.contains($0.key) }.values.flatMap { $0 }
            errorMessage = other.isEmpty ? nil : other.joined(separator: " ")
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// The backend gives the label "AB2 FB3 : 106" but not its parts, so changing a cabin starts from these.
    static func parseLabel(_ label: String) -> (academic: Int, faculty: Int, cabin: String)? {
        guard let match = label.wholeMatch(of: /AB(\d+) FB(\d+) : (\S+)/),
              let academic = Int(match.1), let faculty = Int(match.2) else { return nil }
        return (academic, faculty, String(match.3))
    }

    private func preselectCurrentCabin() {
        guard academicBlockID == nil, let current = Self.parseLabel(currentLabel) else { return }
        cabin = current.cabin
        guard let block = blocks.first(where: { $0.number == current.academic }) else { return }
        academicBlockID = block.id
        facultyBlockID = block.facultyBlocks.first { $0.number == current.faculty }?.id
    }
}
