import CoreGraphics
import Testing
@testable import Baaaa

@Test func grassPatchPlacementSitsOnDockSurface() {
    let frame = GrassPatchPlacement.frame(
        screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        dockRect: CGRect(x: 360, y: 0, width: 720, height: 95),
        displaySize: 56,
        centerX: 640
    )

    #expect(frame == CGRect(x: 612, y: 95, width: 56, height: 56))
}

@Test func grassPatchPlacementFollowsRoundedDockEnds() {
    let frame = GrassPatchPlacement.frame(
        screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        dockRect: CGRect(x: 360, y: 0, width: 720, height: 95),
        displaySize: 56,
        centerX: 365
    )

    #expect(abs(frame.minY - 68.7132) <= 0.02)
}

@Test func grassTargetingIgnoresClaimedGrass() {
    let claimed = GrassObservation(
        id: 1,
        frame: CGRect(x: 80, y: 95, width: 56, height: 56),
        isClaimed: true
    )
    let available = GrassObservation(
        id: 2,
        frame: CGRect(x: 200, y: 95, width: 56, height: 56),
        isClaimed: false
    )

    #expect(GrassTargeting.nearestAvailable(to: claimed.centerX, in: [claimed, available]) == available)
    #expect(GrassTargeting.nearestAvailable(to: claimed.centerX, in: [claimed]) == nil)
}

@Test func grassSeekingCanCrossMouthDeadZoneWithoutAlternating() {
    let grassCenterX: CGFloat = 100
    let sheepWidth: CGFloat = 80
    let reachDistance: CGFloat = 12
    var sheepX: CGFloat = 60
    var direction: CGFloat = -1
    var directionChanges = 0

    for _ in 0..<20 {
        if GrassTargeting.canEat(
            grassCenterX: grassCenterX,
            sheepX: sheepX,
            sheepWidth: sheepWidth,
            reachDistance: reachDistance
        ) {
            break
        }

        let nextDirection = GrassTargeting.seekingDirection(
            grassCenterX: grassCenterX,
            sheepX: sheepX,
            sheepWidth: sheepWidth,
            currentDirection: direction,
            centerTolerance: reachDistance
        )
        if nextDirection != direction {
            directionChanges += 1
        }
        direction = nextDirection
        sheepX += direction
    }

    #expect(GrassTargeting.canEat(
        grassCenterX: grassCenterX,
        sheepX: sheepX,
        sheepWidth: sheepWidth,
        reachDistance: reachDistance
    ))
    #expect(directionChanges == 0)
}
