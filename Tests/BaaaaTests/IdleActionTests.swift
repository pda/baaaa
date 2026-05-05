import Testing
@testable import Baaaa

@Test func branchSelectionIncludesNonEdgeIdleBehaviours() {
    #expect(IdleActionSelection.enabledForBranch == [.headTurn, .doze, .sleep, .eat])
}

@Test func headTurnSequenceMatchesUpstreamFrames() {
    #expect(IdleActionStyles.headTurn.map(\.sprite) == [9, 10, 10, 9, 3])
    #expect(IdleActionStyles.totalTicks(IdleActionStyles.headTurn) == 42)
    #expect(IdleActionStyles.headTurn[1].ticks > IdleActionStyles.headTurn[0].ticks)
}

@Test func headTurnSelectionPreservesRareChanceTuning() {
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

@Test func sleepStyleMatchesUpstreamFrames() {
    #expect(IdleActionStyles.sleep.entryFrames.map(\.sprite) == [107, 108, 107, 108, 107, 31, 32, 33, 0, 1])
    #expect(IdleActionStyles.sleep.sleepFrames.map(\.sprite) == [0, 1])
    #expect(IdleActionStyles.sleep.wakeFrames.map(\.sprite) == [0, 80, 79, 78, 77, 37, 38, 39, 38, 37, 6, 3])
}

@Test func sleepActionLoopsForRequestedDurationBeforeWaking() {
    let style = SleepActionStyle(
        pauseThresholdTicks: 1,
        entryFrames: [IdleActionFrame(sprite: 10, ticks: 1)],
        sleepFrames: [
            IdleActionFrame(sprite: 20, ticks: 1),
            IdleActionFrame(sprite: 21, ticks: 1),
        ],
        wakeFrames: [IdleActionFrame(sprite: 30, ticks: 1)],
        sleepTicksRange: 4...4,
        cooldownRange: 3...3
    )
    var state = IdleActionState(sleepStyle: style, sleepTicks: 4)

    let sprites: [Int?] = (0..<7).map { _ in state.nextSpriteIndex() }
    #expect(sprites == [10, 20, 21, 20, 21, 30, nil])
}

@Test func sleepCooldownBlocksImmediateRepeatSleep() {
    let style = SleepActionStyle(
        pauseThresholdTicks: 5,
        entryFrames: [IdleActionFrame(sprite: 10, ticks: 1)],
        sleepFrames: [IdleActionFrame(sprite: 20, ticks: 1)],
        wakeFrames: [IdleActionFrame(sprite: 30, ticks: 1)],
        sleepTicksRange: 4...4,
        cooldownRange: 3...3
    )
    var sleep = SleepBehaviourState(style: style)

    #expect(!sleep.canStartSleep(forPauseTicks: 4))
    #expect(sleep.canStartSleep(forPauseTicks: 5))

    sleep.startCooldown(nextCooldownTicks: 3)
    #expect(!sleep.canStartSleep(forPauseTicks: 5))

    sleep.advanceCooldown()
    #expect(!sleep.canStartSleep(forPauseTicks: 5))

    sleep.advanceCooldown()
    #expect(!sleep.canStartSleep(forPauseTicks: 5))

    sleep.advanceCooldown()
    #expect(sleep.canStartSleep(forPauseTicks: 5))
}

@Test func eatSequenceFitsPauseAndReturnsToStanding() {
    let frames = IdleActionStyles.eat(fittingWithin: 120)
    #expect(IdleActionStyles.totalTicks(frames) <= 120)
    #expect(frames.last?.sprite == 3)
    #expect(frames.contains { $0.sprite == 58 })
    #expect(frames.contains { $0.sprite == 61 })
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
