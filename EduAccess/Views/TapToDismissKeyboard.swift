import SwiftUI

/// Closes the keyboard when a tap lands outside a text field, on every screen and sheet. It watches taps on the
/// window, because rows in a Form never pass them to a SwiftUI gesture, and leaves each tap to reach its control.
struct TapToDismissKeyboard: UIViewRepresentable {
    func makeUIView(context: Context) -> InstallerView {
        InstallerView()
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {}

    final class InstallerView: UIView, UIGestureRecognizerDelegate {
        private let tap = UITapGestureRecognizer()

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, tap.view == nil else { return }
            tap.addTarget(self, action: #selector(closeKeyboard))
            // Controls must get their touches untouched, or a tap on a segmented picker can be lost.
            tap.cancelsTouchesInView = false
            tap.delaysTouchesEnded = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
        }

        @objc private func closeKeyboard() {
            window?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let view = touch.view else { return true }
            return !sequence(first: view, next: \.superview).contains { $0 is UITextInput }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
