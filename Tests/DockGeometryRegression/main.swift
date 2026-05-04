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

    try expectEqual(
        GroundSurface.floorY(
            screenFrame: screen,
            sheepX: 4,
            sheepWidth: 80,
            dockRect: CGRect(x: 0, y: 0, width: 87, height: 600)
        ),
        600,
        "side dock should expose its top edge as a finite platform"
    )

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
