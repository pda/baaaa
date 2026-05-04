import CoreGraphics
import Testing
@testable import Baaaa

@Test func floorYFallsToDesktopOutsideDockWidth() {
    #expect(
        GroundSurface.floorY(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            sheepX: 40,
            sheepWidth: 80,
            dockRect: CGRect(x: 360, y: 0, width: 720, height: 95)
        ) == 0
    )
}

@Test func floorYStandsOnTopOfDock() {
    #expect(
        GroundSurface.floorY(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            sheepX: 600,
            sheepWidth: 80,
            dockRect: CGRect(x: 360, y: 0, width: 720, height: 95)
        ) == 95
    )
}

@Test func roundedDockCornersLowerSurface() {
    #expect(abs(
        GroundSurface.floorY(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            sheepX: 330,
            sheepWidth: 80,
            dockRect: CGRect(x: 360, y: 0, width: 720, height: 95)
        ) - 76.6548
    ) <= 0.02)
}

@Test func roundedDockEndKeepsSheepOnCrown() {
    #expect(abs(
        GroundSurface.floorY(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            sheepX: 350,
            sheepWidth: 80,
            dockRect: CGRect(x: 360, y: 0, width: 720, height: 95)
        ) - 91.6588
    ) <= 0.01)
}

@Test func sideDockExposesFiniteTopEdge() {
    #expect(abs(
        GroundSurface.floorY(
            screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            sheepX: 4,
            sheepWidth: 80,
            dockRect: CGRect(x: 0, y: 0, width: 87, height: 600)
        ) - 600
    ) <= 0.01)
}

@Test func autoHiddenDockClearsCachedFloor() {
    let previousDock = CGRect(x: 360, y: 0, width: 720, height: 95)
    #expect(DockGeometry.nextCachedRect(previous: previousDock, resolved: nil, autohides: true) == nil)
}

@Test func visibleDockKeepsPreviousRectAcrossTransientFailures() {
    let previousDock = CGRect(x: 360, y: 0, width: 720, height: 95)
    #expect(DockGeometry.nextCachedRect(previous: previousDock, resolved: nil, autohides: false) == previousDock)
}

@Test func surfaceStateFallsWhenSurfaceDisappears() {
    #expect(SurfaceState.shouldFall(currentY: 95, surfaceY: 0))
}

@Test func surfaceStateIgnoresTinyJitter() {
    #expect(!SurfaceState.shouldFall(currentY: 95, surfaceY: 94.6))
}

@Test func accessibilityCoordinatesConvertToAppKitSpace() {
    #expect(
        GroundSurface.appKitRect(
            topLeft: CGPoint(x: 619, y: 1523),
            size: CGSize(width: 1642, height: 87),
            primaryHeight: 1620
        ) == CGRect(x: 619, y: 10, width: 1642, height: 87)
    )
}
