import AppKit
import Foundation

/// Tracks the user's currently-frontmost application so we can filter
/// the global window list down to windows the user can actually see.
///
/// We can't reliably ask macOS "which windows are visible right now"
/// — `CGWindowListCopyWindowInfo` with `.optionOnScreenOnly` returns
/// windows from other Spaces, other Stage Manager stages, and hidden
/// Electron-style background contexts. Filtering to the frontmost
/// app's PID is a simple and dependable proxy that stays correct as
/// the user switches between apps.
final class FrontmostApp {
    static let shared = FrontmostApp()

    /// PID of the most-recently-activated user app, or 0 if there
    /// hasn't been one yet. Our own app is never recorded here so the
    /// sheep keeps walking on the previous app's windows when the
    /// user clicks our status-bar icon.
    private(set) var pid: pid_t = 0

    private let myPID: pid_t = ProcessInfo.processInfo.processIdentifier

    private init() {
        // Seed from the current frontmost app at launch.
        if let app = NSWorkspace.shared.frontmostApplication,
           app.processIdentifier != myPID {
            pid = app.processIdentifier
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func activated(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if app.processIdentifier != myPID {
            pid = app.processIdentifier
        }
    }
}
