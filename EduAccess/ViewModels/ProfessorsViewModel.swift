import Foundation
import Observation

@MainActor
@Observable
final class ProfessorsViewModel {
    /// The backend refuses searches shorter than this.
    static let minimumSearchLength = 2

    var query = ""
    private(set) var professors: [Professor] = []
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    var isSearching: Bool {
        query.trimmingCharacters(in: .whitespaces).count >= Self.minimumSearchLength
    }

    /// Shows search results for a long enough query, otherwise the student's saved professors.
    func load() async {
        let requested = query
        do {
            let result = isSearching
                ? try await api.searchProfessors(query.trimmingCharacters(in: .whitespaces))
                : try await api.myProfessors()
            // A timed refresh can finish after the student typed something new. Its result is out of date.
            guard requested == query else { return }
            professors = result
            hasLoaded = true
            errorMessage = nil
        } catch where error.isCancellation {
            // A newer keystroke or refresh replaced this request.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func autoRefresh(every interval: Duration = .dashboardRefresh) async {
        await repeatEvery(interval) { await load() }
    }

    /// In the saved list an unsaved professor leaves the list. In search results they stay, with the new state.
    func toggleSaved(_ professor: Professor) async {
        do {
            let updated = try await api.setSaved(!professor.isMine, professorID: professor.id)
            if !isSearching && !updated.isMine {
                professors.removeAll { $0.id == updated.id }
            } else if let index = professors.firstIndex(where: { $0.id == updated.id }) {
                professors[index] = updated
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension Error {
    var isCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}
