import Foundation

/// Runs `action` on a timer until the surrounding task is cancelled, which SwiftUI does when the screen goes away.
@MainActor
func repeatEvery(_ interval: Duration, _ action: () async -> Void) async {
    while !Task.isCancelled {
        try? await Task.sleep(for: interval)
        if Task.isCancelled { return }
        await action()
    }
}

extension Duration {
    /// The web app's dashboards refresh at the same rate.
    static let dashboardRefresh = Duration.seconds(10)
}
