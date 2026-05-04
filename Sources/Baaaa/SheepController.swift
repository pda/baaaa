import AppKit
import CoreGraphics

/// Drives a single sheep: physics, AI, animation and window placement.
///
/// Coordinates are in AppKit screen space (origin at the bottom-left of
/// the primary display, y growing upward). When we read other windows'
/// positions via `CGWindowListCopyWindowInfo` we convert from
/// CoreGraphics (top-left origin) into AppKit space.
final class SheepController: SheepDragDelegate {
    // MARK: Tunables

    /// Display size of the sheep. The sprite tiles are 40×40 — we
    /// render at 2× for a more visible pet on modern displays.
    static let displaySize: CGFloat = 80

    /// Simulation tick rate (frames per second).
    private static let tickHz: Double = 30

    /// Horizontal walking speed, in points per tick.
    private static let walkSpeed: CGFloat = 1.0

    /// Gravity acceleration, points per tick².
    private static let gravity: CGFloat = 0.35

    /// Terminal falling speed, points per tick.
    private static let maxFallSpeed: CGFloat = 8.0

    /// Maximum step-up height (points) the sheep can absorb while
    /// walking before it has to fall instead.
    private static let stepUpTolerance: CGFloat = 4.0

    // MARK: State

    /// Minimum landing speed (in points per tick) that triggers the
    /// post-landing dazed animation. Tiny step-downs while walking
    /// don't qualify — we only daze after a "real" fall.
    private static let dazeSpeedThreshold: CGFloat = 4.0

    private let window: SheepWindow
    private let view: SheepView
    private let screen: NSScreen
    private var timer: Timer?

    private enum Mode { case falling, walking, dragging, dazed }
    private var mode: Mode = .falling

    private var x: CGFloat
    private var y: CGFloat
    private var vy: CGFloat = 0
    /// +1 for right, −1 for left. The sprite faces left by default, so
    /// a rightward direction means we flip horizontally.
    private var direction: CGFloat = -1

    private var tick: Int = 0
    /// While >0 the sheep stands still and idles before walking again.
    private var idleTicks: Int = 0

    /// Position into `SpriteIndex.dazed` while in the dazed mode.
    private var dazedStep: Int = 0
    /// Ticks remaining on the current dazed frame.
    private var dazedFrameTicks: Int = 0

    /// Offset between the cursor and the sheep window's bottom-left
    /// while a drag is in progress.
    private var dragOffset: NSSize = .zero

    // MARK: Init

    init(screen: NSScreen) {
        self.screen = screen
        let size = CGSize(width: Self.displaySize, height: Self.displaySize)
        self.window = SheepWindow(size: size)
        self.view = SheepView(frame: NSRect(origin: .zero, size: size))
        self.window.contentView = self.view

        // Spawn somewhere along the top of the screen.
        let frame = screen.visibleFrame
        self.x = CGFloat.random(in: frame.minX...(frame.maxX - Self.displaySize))
        self.y = frame.maxY - Self.displaySize
        self.direction = Bool.random() ? -1 : 1

        self.view.dragDelegate = self
    }

    // MARK: Lifecycle

    func start() {
        positionWindow()
        view.setSprite(index: SpriteIndex.fall, flipped: direction > 0)
        window.orderFrontRegardless()

        let interval = 1.0 / Self.tickHz
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.step()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        window.orderOut(nil)
    }

    // MARK: Simulation

    private func step() {
        tick &+= 1
        switch mode {
        case .falling: stepFalling()
        case .walking: stepWalking()
        case .dragging: stepDragging()
        case .dazed: stepDazed()
        }
        positionWindow()
    }

    private func stepFalling() {
        vy -= Self.gravity
        if vy < -Self.maxFallSpeed { vy = -Self.maxFallSpeed }
        let nextY = y + vy

        // Find the highest surface lying in (nextY, y]. This way we
        // can never "overshoot" a window top in one tick: if our
        // proposed move would carry us through a window's top edge,
        // we land on it instead.
        let surface = surfaceY(forSheepX: x, atOrBelow: y)
        if nextY <= surface {
            y = surface
            let landingSpeed = abs(vy)
            vy = 0
            // Pick a new direction occasionally on landing.
            if Bool.random() { direction = -direction }

            if landingSpeed >= Self.dazeSpeedThreshold {
                // Hit the ground hard enough to be momentarily dazed —
                // play the impact / stars-spinning / sit-up sequence
                // before resuming the walk cycle.
                enterDazed()
            } else {
                mode = .walking
                idleTicks = Int.random(in: 6...30)
                view.setSprite(index: SpriteIndex.walk[0], flipped: direction > 0)
            }
        } else {
            y = nextY
            view.setSprite(index: SpriteIndex.fall, flipped: direction > 0)
        }
    }

    private func enterDazed() {
        mode = .dazed
        dazedStep = 0
        let frame = SpriteIndex.dazed[0]
        dazedFrameTicks = frame.ticks
        view.setSprite(index: frame.sprite, flipped: direction > 0)
    }

    private func stepDazed() {
        dazedFrameTicks -= 1
        if dazedFrameTicks > 0 { return }
        dazedStep += 1
        if dazedStep >= SpriteIndex.dazed.count {
            // Recovery complete — resume normal walking.
            mode = .walking
            idleTicks = Int.random(in: 6...30)
            view.setSprite(index: SpriteIndex.walk[0], flipped: direction > 0)
            return
        }
        let frame = SpriteIndex.dazed[dazedStep]
        dazedFrameTicks = frame.ticks
        view.setSprite(index: frame.sprite, flipped: direction > 0)
    }

    private func stepWalking() {
        if !refreshStandingSurface() { return }

        // Idle pause between bursts of walking.
        if idleTicks > 0 {
            idleTicks -= 1
            view.setSprite(index: SpriteIndex.walk[0], flipped: direction > 0)
            return
        }

        x += direction * Self.walkSpeed

        // Bounce off horizontal screen edges.
        let frame = screen.visibleFrame
        if x < frame.minX {
            x = frame.minX
            direction = 1
        } else if x > frame.maxX - Self.displaySize {
            x = frame.maxX - Self.displaySize
            direction = -1
        }

        if !refreshStandingSurface() { return }

        // Animate the walk cycle.
        let frameIndex = SpriteIndex.walk[(tick / 6) % SpriteIndex.walk.count]
        view.setSprite(index: frameIndex, flipped: direction > 0)

        // Occasionally turn around or pause for a moment.
        if Int.random(in: 0..<400) == 0 {
            direction = -direction
        }
        if Int.random(in: 0..<300) == 0 {
            idleTicks = Int.random(in: 15...60)
        }
    }

    private func refreshStandingSurface() -> Bool {
        let surface = surfaceY(
            forSheepX: x,
            atOrBelow: y + Self.stepUpTolerance
        )
        if SurfaceState.shouldFall(currentY: y, surfaceY: surface) {
            mode = .falling
            vy = 0
            view.setSprite(index: SpriteIndex.fall, flipped: direction > 0)
            return false
        }

        y = surface
        return true
    }

    private func stepDragging() {
        // While the user is dragging, the position is set directly by
        // the drag callbacks — but we still want a little animation
        // life, so cycle through the drag frames.
        let frameIndex = SpriteIndex.drag[(tick / 4) % SpriteIndex.drag.count]
        view.setSprite(index: frameIndex, flipped: direction > 0)
    }

    // MARK: SheepDragDelegate

    func sheepBeganDrag(at globalPoint: NSPoint) {
        mode = .dragging
        vy = 0
        idleTicks = 0
        dragOffset = NSSize(width: globalPoint.x - x, height: globalPoint.y - y)
        view.setSprite(index: SpriteIndex.drag[0], flipped: direction > 0)
    }

    func sheepDragged(to globalPoint: NSPoint) {
        guard mode == .dragging else { return }
        x = globalPoint.x - dragOffset.width
        y = globalPoint.y - dragOffset.height
        positionWindow()
    }

    func sheepEndedDrag() {
        guard mode == .dragging else { return }
        // Drop from wherever we were released. Snap onto a surface
        // immediately if we were already touching one, otherwise fall.
        mode = .falling
        vy = 0
    }

    // MARK: Window placement / surface detection

    private func positionWindow() {
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Find the y-coordinate (AppKit, bottom-left origin) of the
    /// highest "ground" surface at column `sheepX` whose top edge is
    /// at or below `maxY`. Candidates are the bottom of the screen,
    /// the top edge of the Dock when the sheep actually overlaps it,
    /// and the *visible* portion of the top edge of any normal
    /// application window beneath us.
    ///
    /// "Visible" means: the segment of a window's top edge that isn't
    /// occluded by any window that sits in front of it. We require
    /// enough of the sheep's footprint to overlap that visible
    /// segment before considering the window walkable.
    ///
    /// `CGWindowListCopyWindowInfo` returns windows from *all* Spaces
    /// (and from many hidden Electron-style background contexts), so
    /// rather than trying to interpret the global window list we
    /// restrict ourselves to the windows of the user's currently
    /// frontmost application — those are reliably visible. See
    /// `FrontmostApp` for how that's tracked.
    private func surfaceY(forSheepX sheepX: CGFloat, atOrBelow maxY: CGFloat) -> CGFloat {
        var best = GroundSurface.floorY(
            screenFrame: screen.frame,
            sheepX: sheepX,
            sheepWidth: Self.displaySize,
            dockRect: DockGeometry.current(on: screen)?.rect
        )

        let frontmostPID = FrontmostApp.shared.pid
        if frontmostPID == 0 { return best }

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return best
        }

        // Pre-parse and filter to layer-0 windows owned by the
        // frontmost app. Preserve the front-to-back ordering supplied
        // by the API for occlusion testing among those windows.
        let windows: [WindowEntry] = raw.compactMap { info in
            guard let b = info[kCGWindowBounds as String] as? [String: CGFloat] else { return nil }
            let pid = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value ?? -1
            if pid != frontmostPID { return nil }
            let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue ?? 0
            if layer != 0 { return nil }
            let alpha = CGFloat((info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1.0)
            if alpha < 0.1 { return nil }
            let bounds = CGRect(
                x: b["X"] ?? 0,
                y: b["Y"] ?? 0,
                width: b["Width"] ?? 0,
                height: b["Height"] ?? 0
            )
            if bounds.width < 60 || bounds.height < 30 { return nil }
            return WindowEntry(bounds: bounds)
        }

        // CG coordinates have the origin at the top-left of the
        // primary display, with y growing downward. Convert window
        // tops into AppKit space using the primary screen's height.
        let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height

        let sheepLeft = sheepX
        let sheepRight = sheepX + Self.displaySize
        let minVisibleLength = Self.displaySize * 0.4

        for (i, w) in windows.enumerated() {
            let topCG = w.bounds.minY
            let topNS = primaryHeight - topCG
            if topNS > maxY { continue }
            // Already found a strictly higher walkable surface.
            if topNS <= best { continue }

            // Start with the entire top edge, then subtract the
            // x-extent of every window that's in front of us *and*
            // crosses this top edge's y line.
            var spans: [Span] = [Span(low: w.bounds.minX, high: w.bounds.maxX)]
            for j in 0..<i {
                let fr = windows[j].bounds
                if topCG < fr.minY || topCG > fr.maxY { continue }
                spans = Span.subtract(spans, low: fr.minX, high: fr.maxX)
                if spans.isEmpty { break }
            }
            if spans.isEmpty { continue }

            // Sum visible length within the sheep's footprint.
            var visibleLength: CGFloat = 0
            for s in spans {
                let lo = max(s.low, sheepLeft)
                let hi = min(s.high, sheepRight)
                if hi > lo { visibleLength += hi - lo }
                if visibleLength >= minVisibleLength { break }
            }
            if visibleLength >= minVisibleLength {
                best = topNS
            }
        }

        return best
    }
}

// MARK: - Window-list helpers

private struct WindowEntry {
    let bounds: CGRect      // CG coordinates (top-left origin)
}

/// A 1-D x-axis interval [low, high]. Used to track the visible
/// portions of a window's top edge as we subtract front-most occluders.
private struct Span {
    let low: CGFloat
    let high: CGFloat

    static func subtract(_ spans: [Span], low cutLow: CGFloat, high cutHigh: CGFloat) -> [Span] {
        var out: [Span] = []
        out.reserveCapacity(spans.count + 1)
        for s in spans {
            if cutHigh <= s.low || cutLow >= s.high {
                // No overlap.
                out.append(s)
                continue
            }
            // Left remainder.
            if cutLow > s.low {
                out.append(Span(low: s.low, high: cutLow))
            }
            // Right remainder.
            if cutHigh < s.high {
                out.append(Span(low: cutHigh, high: s.high))
            }
        }
        return out
    }
}

// MARK: - Sprite indices

/// Frame indices into the eSheep sprite sheet (16 columns × 11 rows).
private enum SpriteIndex {
    /// Frames used for the standing/walking cycle. The original
    /// `animations.xml` alternates frames 2 and 3 every 200 ms.
    static let walk: [Int] = [2, 3]

    /// Single-frame falling pose used by the original "fall" animation.
    static let fall: Int = 133

    /// Frames cycled through by the original "drag" animation.
    static let drag: [Int] = [42, 43, 44]

    /// One step of the dazed-after-landing animation.
    struct DazedFrame { let sprite: Int; let ticks: Int }

    /// Post-landing "dazed" sequence, taken from the upstream eSheep
    /// `fall soft` animation: an impact bounce, a brief stars-spinning
    /// loop above the head, then a sit-up before resuming the walk.
    /// Tick counts are calibrated for the 30 Hz simulation tick — the
    /// whole sequence runs in roughly one second.
    static let dazed: [DazedFrame] = [
        DazedFrame(sprite: 49, ticks: 6),  // impact bounce
        DazedFrame(sprite: 13, ticks: 5),  // stars spin
        DazedFrame(sprite: 12, ticks: 5),  // stars spin
        DazedFrame(sprite: 13, ticks: 5),  // stars spin
        DazedFrame(sprite: 12, ticks: 5),  // stars spin
        DazedFrame(sprite: 6,  ticks: 7),  // sitting up / recovery
    ]
}
