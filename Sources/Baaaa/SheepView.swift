import AppKit
import QuartzCore

protocol SheepDragDelegate: AnyObject {
    /// Called on mouseDown. `globalPoint` is in AppKit screen
    /// coordinates (origin at the bottom-left of the primary display).
    func sheepBeganDrag(at globalPoint: NSPoint)
    func sheepDragged(to globalPoint: NSPoint)
    func sheepEndedDrag()
}

/// A small layer-backed view that renders a single sheep sprite and
/// forwards click+drag gestures to a delegate (the controller).
final class SheepView: NSView {
    weak var dragDelegate: SheepDragDelegate?

    private let imageLayer = CALayer()
    private var currentIndex: Int = -1
    private var currentFlipped: Bool = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        let host = CALayer()
        host.frame = bounds
        host.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        layer = host

        imageLayer.frame = bounds
        imageLayer.contentsGravity = .resizeAspect
        // Keep the pixel art crisp when scaled up.
        imageLayer.magnificationFilter = .nearest
        imageLayer.minificationFilter = .nearest
        imageLayer.contentsScale = host.contentsScale
        host.addSublayer(imageLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    func setSprite(index: Int, flipped: Bool) {
        guard index != currentIndex || flipped != currentFlipped else { return }
        currentIndex = index
        currentFlipped = flipped
        let cgImage = SpriteSheet.shared.tile(index: index, flipped: flipped)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageLayer.contents = cgImage
        CATransaction.commit()
    }

    // MARK: - Mouse handling

    /// Allow the sheep window to receive a mouseDown without first
    /// becoming key (since we deliberately don't accept key status).
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragDelegate?.sheepBeganDrag(at: NSEvent.mouseLocation)
    }

    override func mouseDragged(with event: NSEvent) {
        dragDelegate?.sheepDragged(to: NSEvent.mouseLocation)
    }

    override func mouseUp(with event: NSEvent) {
        dragDelegate?.sheepEndedDrag()
    }
}
