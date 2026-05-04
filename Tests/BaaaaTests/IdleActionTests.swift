import Testing
@testable import Baaaa

@Test func verificationSelectionIsHeadTurnForCurrentReview() {
    #expect(IdleActionSelection.enabledForVerification == .headTurn)
}

@Test func headTurnSequenceMatchesUpstreamFrames() {
    #expect(IdleActionStyles.headTurn.map(\.sprite) == [9, 10, 10, 9, 3])
    #expect(IdleActionStyles.totalTicks(IdleActionStyles.headTurn) == 42)
    #expect(IdleActionStyles.headTurn[1].ticks > IdleActionStyles.headTurn[0].ticks)
    #expect(IdleActionSelection.headTurnChance == 1...6)
}

@Test func lookDownSequenceMatchesUpstreamFrames() {
    #expect(IdleActionStyles.lookDown.map(\.sprite) == [78, 78, 78, 79, 80, 79, 78, 78, 78, 78, 78, 6])
}

@Test func scratchSequenceFitsLongPauseAndReturnsToStanding() {
    let frames = IdleActionStyles.scratch(fittingWithin: 180)
    #expect(IdleActionStyles.totalTicks(frames) <= 180)
    #expect(frames.last?.sprite == 3)
    #expect(frames.contains { $0.sprite == 105 })
    #expect(frames.contains { $0.sprite == 106 })
}

@Test func dozeSequenceFitsLongPauseAndReturnsToStanding() {
    let frames = IdleActionStyles.doze(fittingWithin: 180)
    #expect(IdleActionStyles.totalTicks(frames) <= 180)
    #expect(frames.last?.sprite == 3)
    #expect(frames.contains { $0.sprite == 8 })
}

@Test func idleActionStateAdvancesThroughFrames() {
    var state = IdleActionState(frames: [
        IdleActionFrame(sprite: 9, ticks: 2),
        IdleActionFrame(sprite: 10, ticks: 1),
    ])

    #expect(state.nextSpriteIndex() == 9)
    #expect(state.nextSpriteIndex() == 9)
    #expect(state.nextSpriteIndex() == 10)
    #expect(state.nextSpriteIndex() == nil)
}
