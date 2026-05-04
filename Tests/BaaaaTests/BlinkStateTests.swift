import Testing
@testable import Baaaa

@Test func blinkStyleUsesChosenTopRowFrames() {
    #expect(BlinkStyles.sheep.frames.map(\.sprite) == [7, 8, 7])
    #expect(BlinkStyles.sheep.doubleFrames?.map(\.sprite) == [7, 8, 7, 3, 7, 8, 7])
}

@Test func cooldownSurvivesShortWalkingBurst() {
    var blink = BlinkState(
        standingSprite: BlinkStyles.sheep.standingSprite,
        cooldownRange: BlinkStyles.sheep.cooldownRange,
        blinkFrames: BlinkStyles.sheep.frames,
        doubleBlinkFrames: BlinkStyles.sheep.doubleFrames,
        forceDoubleBlink: false,
        initialCooldownTicks: 1
    )

    #expect(blink.standingSpriteIndex() == 3)

    blink.endedStandingPose()
    #expect(blink.standingSpriteIndex() == 7)

    blink.endedStandingPose()
    #expect(blink.standingSpriteIndex() == 7)
}

@Test func interruptionsResetBlink() {
    var blink = BlinkState(
        standingSprite: BlinkStyles.sheep.standingSprite,
        cooldownRange: BlinkStyles.sheep.cooldownRange,
        blinkFrames: BlinkStyles.sheep.frames,
        doubleBlinkFrames: BlinkStyles.sheep.doubleFrames,
        forceDoubleBlink: false,
        initialCooldownTicks: 1
    )

    #expect(blink.standingSpriteIndex() == 3)
    blink.endedStandingPose()
    #expect(blink.standingSpriteIndex() == 7)

    blink.interrupted(nextCooldownTicks: 4)
    #expect(blink.standingSpriteIndex() == 3)
}

@Test func forcedDoubleBlinkPlaysTwoFullBlinks() {
    var blink = BlinkState(
        standingSprite: BlinkStyles.sheep.standingSprite,
        cooldownRange: BlinkStyles.sheep.cooldownRange,
        blinkFrames: BlinkStyles.sheep.frames,
        doubleBlinkFrames: BlinkStyles.sheep.doubleFrames,
        forceDoubleBlink: true,
        initialCooldownTicks: 0
    )

    let sprites = (0..<27).map { _ in blink.standingSpriteIndex() }
    #expect(sprites == [7, 7, 7, 7, 8, 8, 8, 8, 7, 7, 7, 7, 3, 3, 3, 7, 7, 7, 7, 8, 8, 8, 8, 7, 7, 7, 7])
}
