import Foundation
import Observation

@MainActor
@Observable
final class ProfessorsViewModel {
    /// The backend refuses searches shorter than this.
    static let minimumSearchLength = 2

    var query = ""
    private(set) var professors: [Professor] = []
    private(set) var isLoading = false
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
        isLoading = true
        defer { isLoading = false }
        do {
            professors = isSearching
                ? try await api.searchProfessors(query.trimmingCharacters(in: .whitespaces))
                : try await api.myProfessors()
            errorMessage = nil
        } catch where error.isCancellation {
            // A newer keystroke or refresh replaced this request.
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
