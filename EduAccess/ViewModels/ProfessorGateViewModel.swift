import Foundation
import Observation

/// Like the website, a professor with no cabin sets one before anything else.
@MainActor
@Observable
final class ProfessorGateViewModel {
    enum State: Equatable {
        case checking
        case needsCabin
        case ready
    }

    private(set) var state = State.checking
    private let api: any APIClient

    init(api: any APIClient) {
        self.api = api
    }

    func check() async {
        do {
            state = try await api.me().hasCabin ? .ready : .needsCabin
        } catch where error.isCancellation {
            // The screen went away.
        } catch {
            // The tabs show their own errors and can recover when the network does.
            state = .ready
        }
    }

    func cabinSaved() {
        state = .ready
    }
}
