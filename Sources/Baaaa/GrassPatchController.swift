import AppKit
import CoreGraphics

struct GrassObservation: Equatable {
    let id: Int
    let frame: CGRect
    let isClaimed: Bool

    var centerX: CGFloat { frame.midX }
}

enum GrassTargeting {
    private static let leftMouthOffsetRatio: CGFloat = 0.28
    private static let rightMouthOffsetRatio: CGFloat = 0.72

    static func nearestAvailable(to mouthX: CGFloat, in grass: [GrassObservation]) -> GrassObservation? {
        grass.filter { !$0.isClaimed }.min { lhs, rhs in
            abs(lhs.centerX - mouthX) < abs(rhs.centerX - mouthX)
        }
    }

    static func mouthX(sheepX: CGFloat, sheepWidth: CGFloat, direction: CGFloat) -> CGFloat {
        sheepX + sheepWidth * (direction > 0 ? rightMouthOffsetRatio : leftMouthOffsetRatio)
    }

    static func canEat(
        grassCenterX: CGFloat,
        sheepX: CGFloat,
        sheepWidth: CGFloat,
        reachDistance: CGFloat
    ) -> Bool {
        let leftMouthX = sheepX + sheepWidth * leftMouthOffsetRatio
        let rightMouthX = sheepX + sheepWidth * rightMouthOffsetRatio
        return min(abs(grassCenterX - leftMouthX), abs(grassCenterX - rightMouthX)) <= reachDistance
    }

    static func seekingDirection(
        grassCenterX: CGFloat,
        sheepX: CGFloat,
        sheepWidth: CGFloat,
        currentDirection: CGFloat,
        centerTolerance: CGFloat
    ) -> CGFloat {
        let delta = grassCenterX - (sheepX + sheepWidth / 2)
        if abs(delta) <= centerTolerance {
            return currentDirection
        }
        return delta > 0 ? 1 : -1
    }
}

enum GrassPatchPlacement {
    static func frame(
        screenFrame: CGRect,
        dockRect: CGRect,
        displaySize: CGFloat,
        centerX: CGFloat
    ) -> CGRect {
        let clampedCenterX = min(max(centerX, dockRect.minX), dockRect.maxX)
        let originX = min(
            max(clampedCenterX - (displaySize / 2), screenFrame.minX),
            screenFrame.maxX - displaySize
        )
        let surfaceY = GroundSurface.floorY(
            screenFrame: screenFrame,
            sheepX: originX,
            sheepWidth: displaySize,
            dockRect: dockRect
        )
        return CGRect(x: originX, y: surfaceY, width: displaySize, height: displaySize)
    }
}

final class GrassPatchController {
    private static let spriteIndices = [151, 152]
    private static let displaySize: CGFloat = 56
    private static var nextID = 0

    private let window: SheepWindow
    private let view: SheepView

    let id: Int
    private(set) var frame: CGRect
    private(set) var isClaimed = false

    init?(screen: NSScreen) {
        guard let dockRect = DockGeometry.current(on: screen)?.rect else { return nil }

        Self.nextID += 1
        id = Self.nextID

        let centerX = CGFloat.random(in: dockRect.minX...dockRect.maxX)
        frame = GrassPatchPlacement.frame(
            screenFrame: screen.frame,
            dockRect: dockRect,
            displaySize: Self.displaySize,
            centerX: centerX
        )

        let size = CGSize(width: Self.displaySize, height: Self.displaySize)
        window = SheepWindow(size: size)
        window.ignoresMouseEvents = true
        // Keep grass above ordinary app windows but below the sheep,
        // even when a patch is spawned after the sheep window.
        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
        view = SheepView(frame: NSRect(origin: .zero, size: size))
        window.contentView = view
    }

    var observation: GrassObservation {
        GrassObservation(id: id, frame: frame, isClaimed: isClaimed)
    }

    func claim() -> Bool {
        guard !isClaimed else { return false }
        isClaimed = true
        return true
    }

    func releaseClaim() {
        isClaimed = false
    }

    func start() {
        window.setFrameOrigin(frame.origin)
        view.setSprite(index: Self.spriteIndices.randomElement() ?? Self.spriteIndices[0], flipped: false)
        window.orderFrontRegardless()
    }

    func stop() {
        window.orderOut(nil)
    }
}
