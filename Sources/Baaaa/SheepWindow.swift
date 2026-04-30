import AppKit

/// A small, transparent, click-through window that hosts a sheep.
final class SheepWindow: NSWindow {
    init(size: CGSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        // We *do* want mouse events so the user can grab the sheep,
        // but we never want to become key/main — that's enforced via
        // canBecomeKey / canBecomeMain below.
        ignoresMouseEvents = false
        isMovableByWindowBackground = false
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        // Don't deactivate other apps when shown.
        hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
