import Foundation

struct IdleActionFrame {
    let sprite: Int
    let ticks: Int
}

private struct FrameSequenceState {
    private let frames: [IdleActionFrame]
    private var frameIndex: Int = 0
    private var frameTicksRemaining: Int

    init(frames: [IdleActionFrame]) {
        self.frames = frames
        self.frameTicksRemaining = frames.first?.ticks ?? 0
    }

    mutating func nextSpriteIndex() -> Int? {
        guard frameIndex < frames.count else { return nil }

        let sprite = frames[frameIndex].sprite
        frameTicksRemaining -= 1
        if frameTicksRemaining <= 0 {
            frameIndex += 1
            if frameIndex < frames.count {
                frameTicksRemaining = frames[frameIndex].ticks
            }
        }
        return sprite
    }
}

struct SleepActionStyle {
    let pauseThresholdTicks: Int
    let entryFrames: [IdleActionFrame]
    let sleepFrames: [IdleActionFrame]
    let wakeFrames: [IdleActionFrame]
    let sleepTicksRange: ClosedRange<Int>
    let cooldownRange: ClosedRange<Int>
}

struct SleepBehaviourState {
    let style: SleepActionStyle
    private(set) var cooldownTicks: Int = 0

    func canStartSleep(forPauseTicks pauseTicks: Int) -> Bool {
        cooldownTicks == 0 && pauseTicks >= style.pauseThresholdTicks
    }

    mutating func advanceCooldown() {
        if cooldownTicks > 0 {
            cooldownTicks -= 1
        }
    }

    mutating func startCooldown(nextCooldownTicks: Int? = nil) {
        cooldownTicks = nextCooldownTicks ?? Int.random(in: style.cooldownRange)
    }
}

private struct SleepActionState {
    private enum Phase {
        case entry(FrameSequenceState, remainingSleepTicks: Int)
        case sleeping(frameIndex: Int, frameTicksRemaining: Int, remainingSleepTicks: Int)
        case waking(FrameSequenceState)
        case done
    }

    private let style: SleepActionStyle
    private var phase: Phase

    init(style: SleepActionStyle, sleepTicks: Int? = nil) {
        self.style = style

        let remainingSleepTicks = max(1, sleepTicks ?? Int.random(in: style.sleepTicksRange))
        if style.entryFrames.isEmpty {
            if style.sleepFrames.isEmpty {
                self.phase = .waking(FrameSequenceState(frames: style.wakeFrames))
            } else {
                let firstFrame = style.sleepFrames[0]
                self.phase = .sleeping(
                    frameIndex: 0,
                    frameTicksRemaining: firstFrame.ticks,
                    remainingSleepTicks: remainingSleepTicks
                )
            }
        } else {
            self.phase = .entry(
                FrameSequenceState(frames: style.entryFrames),
                remainingSleepTicks: remainingSleepTicks
            )
        }
    }

    mutating func nextSpriteIndex() -> Int? {
        switch phase {
        case let .entry(sequence, remainingSleepTicks):
            var sequence = sequence
            if let sprite = sequence.nextSpriteIndex() {
                phase = .entry(sequence, remainingSleepTicks: remainingSleepTicks)
                return sprite
            }
            return beginSleeping(remainingSleepTicks: remainingSleepTicks)

        case let .sleeping(frameIndex, frameTicksRemaining, remainingSleepTicks):
            return advanceSleepingPhase(
                frameIndex: frameIndex,
                frameTicksRemaining: frameTicksRemaining,
                remainingSleepTicks: remainingSleepTicks
            )

        case let .waking(sequence):
            var sequence = sequence
            if let sprite = sequence.nextSpriteIndex() {
                phase = .waking(sequence)
                return sprite
            }
            phase = .done
            return nil

        case .done:
            return nil
        }
    }

    private mutating func beginSleeping(remainingSleepTicks: Int) -> Int? {
        guard !style.sleepFrames.isEmpty else {
            return beginWaking()
        }

        let firstFrame = style.sleepFrames[0]
        phase = .sleeping(
            frameIndex: 0,
            frameTicksRemaining: firstFrame.ticks,
            remainingSleepTicks: remainingSleepTicks
        )
        return nextSpriteIndex()
    }

    private mutating func beginWaking() -> Int? {
        guard !style.wakeFrames.isEmpty else {
            phase = .done
            return nil
        }

        phase = .waking(FrameSequenceState(frames: style.wakeFrames))
        return nextSpriteIndex()
    }

    private mutating func prepareWaking() {
        if style.wakeFrames.isEmpty {
            phase = .done
            return
        }

        phase = .waking(FrameSequenceState(frames: style.wakeFrames))
    }

    private mutating func advanceSleepingPhase(
        frameIndex: Int,
        frameTicksRemaining: Int,
        remainingSleepTicks: Int
    ) -> Int {
        let sprite = style.sleepFrames[frameIndex].sprite
        let nextRemainingSleepTicks = remainingSleepTicks - 1

        if nextRemainingSleepTicks <= 0 {
            prepareWaking()
            return sprite
        }

        let nextFrameTicksRemaining = frameTicksRemaining - 1
        if nextFrameTicksRemaining > 0 {
            phase = .sleeping(
                frameIndex: frameIndex,
                frameTicksRemaining: nextFrameTicksRemaining,
                remainingSleepTicks: nextRemainingSleepTicks
            )
            return sprite
        }

        let nextFrameIndex = (frameIndex + 1) % style.sleepFrames.count
        phase = .sleeping(
            frameIndex: nextFrameIndex,
            frameTicksRemaining: style.sleepFrames[nextFrameIndex].ticks,
            remainingSleepTicks: nextRemainingSleepTicks
        )
        return sprite
    }
}

struct IdleActionState {
    private enum Storage {
        case frames(FrameSequenceState)
        case sleep(SleepActionState)
    }

    private var storage: Storage

    init(frames: [IdleActionFrame]) {
        self.storage = .frames(FrameSequenceState(frames: frames))
    }

    init(sleepStyle: SleepActionStyle = IdleActionStyles.sleep, sleepTicks: Int? = nil) {
        self.storage = .sleep(SleepActionState(style: sleepStyle, sleepTicks: sleepTicks))
    }

    var isSleep: Bool {
        if case .sleep = storage {
            return true
        }
        return false
    }

    mutating func nextSpriteIndex() -> Int? {
        switch storage {
        case let .frames(state):
            var state = state
            let sprite = state.nextSpriteIndex()
            storage = .frames(state)
            return sprite

        case let .sleep(state):
            var state = state
            let sprite = state.nextSpriteIndex()
            storage = .sleep(state)
            return sprite
        }
    }
}

enum IdleActionKind {
    case headTurn
    case lookDown
    case doze
    case sleep
    case eat
}

enum IdleActionStyles {
    private static let slowTicks = 6
    private static let mediumTicks = 4
    private static let headTurnSetupTicks = 5
    private static let headTurnStareTicks = 14
    private static let sleepFrameTicks = 5

    static let headTurn: [IdleActionFrame] = [
        IdleActionFrame(sprite: 9, ticks: headTurnSetupTicks),
        IdleActionFrame(sprite: 10, ticks: headTurnStareTicks),
        IdleActionFrame(sprite: 10, ticks: headTurnStareTicks),
        IdleActionFrame(sprite: 9, ticks: headTurnSetupTicks),
        IdleActionFrame(sprite: 3, ticks: 4),
    ]

    static let lookDown: [IdleActionFrame] = [
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 79, ticks: mediumTicks),
        IdleActionFrame(sprite: 80, ticks: mediumTicks),
        IdleActionFrame(sprite: 79, ticks: mediumTicks),
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 78, ticks: mediumTicks),
        IdleActionFrame(sprite: 6, ticks: mediumTicks),
    ]

    static func scratch(fittingWithin pauseTicks: Int) -> [IdleActionFrame] {
        let setup: [IdleActionFrame] = [
            IdleActionFrame(sprite: 12, ticks: slowTicks),
            IdleActionFrame(sprite: 13, ticks: slowTicks),
            IdleActionFrame(sprite: 103, ticks: slowTicks),
            IdleActionFrame(sprite: 104, ticks: slowTicks),
        ]
        let loop: [IdleActionFrame] = [
            IdleActionFrame(sprite: 105, ticks: slowTicks),
            IdleActionFrame(sprite: 106, ticks: slowTicks),
        ]
        let tail: [IdleActionFrame] = [
            IdleActionFrame(sprite: 104, ticks: slowTicks),
            IdleActionFrame(sprite: 105, ticks: slowTicks),
            IdleActionFrame(sprite: 104, ticks: slowTicks),
            IdleActionFrame(sprite: 104, ticks: slowTicks),
            IdleActionFrame(sprite: 103, ticks: slowTicks),
            IdleActionFrame(sprite: 13, ticks: slowTicks),
            IdleActionFrame(sprite: 12, ticks: slowTicks),
            IdleActionFrame(sprite: 3, ticks: slowTicks),
        ]

        let loopTicks = totalTicks(loop)
        let baseTicks = totalTicks(setup) + totalTicks(tail)
        let loopBudget = max(0, pauseTicks - baseTicks)
        let loopCount = max(1, min(4, loopBudget / max(1, loopTicks)))
        return setup + Array(repeating: loop, count: loopCount).flatMap { $0 } + tail
    }

    static func doze(fittingWithin pauseTicks: Int) -> [IdleActionFrame] {
        let setup: [IdleActionFrame] = [
            IdleActionFrame(sprite: 6, ticks: slowTicks),
            IdleActionFrame(sprite: 7, ticks: slowTicks),
            IdleActionFrame(sprite: 8, ticks: slowTicks),
            IdleActionFrame(sprite: 8, ticks: slowTicks),
        ]
        let loop: [IdleActionFrame] = [
            IdleActionFrame(sprite: 7, ticks: slowTicks),
            IdleActionFrame(sprite: 8, ticks: slowTicks),
            IdleActionFrame(sprite: 8, ticks: slowTicks),
        ]
        let tail: [IdleActionFrame] = [
            IdleActionFrame(sprite: 8, ticks: slowTicks),
            IdleActionFrame(sprite: 7, ticks: slowTicks),
            IdleActionFrame(sprite: 6, ticks: slowTicks),
            IdleActionFrame(sprite: 3, ticks: slowTicks),
        ]

        let loopTicks = totalTicks(loop)
        let baseTicks = totalTicks(setup) + totalTicks(tail)
        let loopBudget = max(0, pauseTicks - baseTicks)
        let loopCount = max(1, min(5, loopBudget / max(1, loopTicks)))
        return setup + Array(repeating: loop, count: loopCount).flatMap { $0 } + tail
    }

    static let sleep = SleepActionStyle(
        pauseThresholdTicks: 120,
        entryFrames: [
            IdleActionFrame(sprite: 107, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 108, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 107, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 108, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 107, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 31, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 32, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 33, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 0, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 1, ticks: sleepFrameTicks),
        ],
        sleepFrames: [
            IdleActionFrame(sprite: 0, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 1, ticks: sleepFrameTicks),
        ],
        wakeFrames: [
            IdleActionFrame(sprite: 0, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 80, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 79, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 78, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 77, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 37, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 38, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 39, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 38, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 37, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 6, ticks: sleepFrameTicks),
            IdleActionFrame(sprite: 3, ticks: sleepFrameTicks),
        ],
        sleepTicksRange: 180...300,
        cooldownRange: 900...1500
    )

    static func eat(fittingWithin pauseTicks: Int) -> [IdleActionFrame] {
        let setup: [IdleActionFrame] = [
            IdleActionFrame(sprite: 6, ticks: mediumTicks),
            IdleActionFrame(sprite: 6, ticks: mediumTicks),
            IdleActionFrame(sprite: 6, ticks: mediumTicks),
            IdleActionFrame(sprite: 6, ticks: mediumTicks),
            IdleActionFrame(sprite: 58, ticks: mediumTicks),
        ]
        let loop: [IdleActionFrame] = [
            IdleActionFrame(sprite: 59, ticks: mediumTicks),
            IdleActionFrame(sprite: 59, ticks: mediumTicks),
            IdleActionFrame(sprite: 60, ticks: mediumTicks),
            IdleActionFrame(sprite: 61, ticks: mediumTicks),
            IdleActionFrame(sprite: 60, ticks: mediumTicks),
            IdleActionFrame(sprite: 61, ticks: mediumTicks),
        ]
        let tail: [IdleActionFrame] = [
            IdleActionFrame(sprite: 6, ticks: mediumTicks),
            IdleActionFrame(sprite: 3, ticks: mediumTicks),
        ]

        let loopTicks = totalTicks(loop)
        let baseTicks = totalTicks(setup) + totalTicks(tail)
        let loopBudget = max(0, pauseTicks - baseTicks)
        let loopCount = max(1, min(5, loopBudget / max(1, loopTicks)))
        return setup + Array(repeating: loop, count: loopCount).flatMap { $0 } + tail
    }

    static func totalTicks(_ frames: [IdleActionFrame]) -> Int {
        frames.reduce(into: 0) { $0 += $1.ticks }
    }
}

enum IdleActionSelection {
    /// Active non-edge idle behaviours for this branch. `lookDown` stays
    /// out for now so it can be reviewed separately.
    static let enabledForBranch: [IdleActionKind] = [.headTurn, .doze, .sleep, .eat]
    static let headTurnChance = 1...6
}
