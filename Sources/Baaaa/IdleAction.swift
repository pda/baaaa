import Foundation

struct IdleActionFrame {
    let sprite: Int
    let ticks: Int
}

struct IdleActionState {
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

enum IdleActionKind {
    case headTurn
    case lookDown
    case pee
    case doze
}

enum IdleActionStyles {
    private static let slowTicks = 6
    private static let mediumTicks = 4
    private static let headTurnSetupTicks = 5
    private static let headTurnStareTicks = 14

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

    static func totalTicks(_ frames: [IdleActionFrame]) -> Int {
        frames.reduce(into: 0) { $0 += $1.ticks }
    }
}

enum IdleActionSelection {
    /// Keep one upstream idle behaviour live at a time while validating
    /// how it reads in the app. Switch this to the next case after review.
    static let enabledForVerification: IdleActionKind = .headTurn
    static let headTurnChance = 1...6
}
