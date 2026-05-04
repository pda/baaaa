import CoreGraphics
import Foundation

struct Failure: Error {
    let message: String
}

func expectEqual(_ actual: CGFloat, _ expected: CGFloat, _ label: String) throws {
    guard actual == expected else {
        throw Failure(message: "\(label): expected \(expected), got \(actual)")
    }
}

func expectApprox(_ actual: CGFloat, _ expected: CGFloat, _ tolerance: CGFloat, _ label: String) throws {
    guard abs(actual - expected) <= tolerance else {
        throw Failure(message: "\(label): expected \(expected) ± \(tolerance), got \(actual)")
    }
}

do {
    let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let dock = CGRect(x: 360, y: 0, width: 720, height: 95)

    try expectEqual(
        GroundSurface.floorY(
            screenFrame: screen,
            sheepX: 40,
            sheepWidth: 80,
            dockRect: dock
        ),
        0,
        "outside dock width should fall to desktop bottom"
    )

    try expectEqual(
        GroundSurface.floorY(
            screenFrame: screen,
            sheepX: 600,
            sheepWidth: 80,
            dockRect: dock
        ),
        95,
        "over dock width should stand on dock top"
    )

    try expectApprox(
        GroundSurface.floorY(
            screenFrame: screen,
            sheepX: 330,
            sheepWidth: 80,
            dockRect: dock
        ),
        76.6548,
        0.02,
        "rounded dock corners should lower the sheep onto the curved crown instead of a flat edge"
    )

    try expectApprox(
        GroundSurface.floorY(
            screenFrame: screen,
            sheepX: 350,
            sheepWidth: 80,
            dockRect: dock
        ),
        91.6588,
        0.01,
        "sheep should ride down the rounded dock end instead of dropping behind it"
    )

    try expectApprox(
        GroundSurface.floorY(
            screenFrame: screen,
            sheepX: 4,
            sheepWidth: 80,
            dockRect: CGRect(x: 0, y: 0, width: 87, height: 600)
        ),
        600,
        0.01,
        "side dock should expose its top edge as a finite platform"
    )

    let previousDock = CGRect(x: 360, y: 0, width: 720, height: 95)
    guard DockGeometry.nextCachedRect(previous: previousDock, resolved: nil, autohides: true) == nil else {
        throw Failure(message: "auto-hidden Dock should clear the cached floor when AX resolution fails")
    }
    guard DockGeometry.nextCachedRect(previous: previousDock, resolved: nil, autohides: false) == previousDock else {
        throw Failure(message: "non-hidden Dock should keep the last good rect across transient AX failures")
    }

    guard SurfaceState.shouldFall(currentY: 95, surfaceY: 0) else {
        throw Failure(message: "standing sheep should start falling as soon as their surface disappears")
    }
    guard !SurfaceState.shouldFall(currentY: 95, surfaceY: 94.6) else {
        throw Failure(message: "tiny surface jitter should not force a fall")
    }

    let rect = GroundSurface.appKitRect(
        topLeft: CGPoint(x: 619, y: 1523),
        size: CGSize(width: 1642, height: 87),
        primaryHeight: 1620
    )
    guard rect == CGRect(x: 619, y: 10, width: 1642, height: 87) else {
        throw Failure(message: "accessibility coordinates should convert into AppKit space")
    }

    print("DockGeometryRegression: all checks passed")
} catch let failure as Failure {
    fputs("DockGeometryRegression failed: \(failure.message)\n", stderr)
    exit(1)
} catch {
    fputs("DockGeometryRegression failed: \(error)\n", stderr)
    exit(1)
}
