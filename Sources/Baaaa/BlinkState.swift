import Foundation

struct BlinkState {
    struct Frame {
        let sprite: Int
        let ticks: Int
    }

    let standingSprite: Int
    let cooldownRange: ClosedRange<Int>
    let blinkFrames: [Frame]
    let doubleBlinkFrames: [Frame]?
    let doubleBlinkChance: Int
    let forceDoubleBlink: Bool?

    private(set) var cooldownTicks: Int
    private var isBlinking: Bool = false
    private var activeBlinkFrames: [Frame] = []
    private var blinkStep: Int = 0
    private var blinkFrameTicks: Int = 0

    init(
        standingSprite: Int,
        cooldownRange: ClosedRange<Int>,
        blinkFrames: [Frame],
        doubleBlinkFrames: [Frame]? = nil,
        doubleBlinkChance: Int = 0,
        forceDoubleBlink: Bool? = nil,
        initialCooldownTicks: Int? = nil
    ) {
        self.standingSprite = standingSprite
        self.cooldownRange = cooldownRange
        self.blinkFrames = blinkFrames
        self.doubleBlinkFrames = doubleBlinkFrames
        self.doubleBlinkChance = doubleBlinkChance
        self.forceDoubleBlink = forceDoubleBlink
        self.cooldownTicks = initialCooldownTicks ?? Int.random(in: cooldownRange)
    }

    /// Leaving a standing pose should stop any in-flight blink, but keep
    /// the accumulated cooldown so the next short pause can still blink.
    mutating func endedStandingPose() {
        isBlinking = false
        activeBlinkFrames = []
        blinkStep = 0
        blinkFrameTicks = 0
    }

    mutating func interrupted(nextCooldownTicks: Int? = nil) {
        reset(nextCooldownTicks: nextCooldownTicks)
    }

    mutating func standingSpriteIndex() -> Int {
        if isBlinking {
            blinkFrameTicks -= 1
            if blinkFrameTicks <= 0 {
                blinkStep += 1
                if blinkStep >= activeBlinkFrames.count {
                    reset()
                    return standingSprite
                }
                blinkFrameTicks = activeBlinkFrames[blinkStep].ticks
            }
            return activeBlinkFrames[blinkStep].sprite
        }

        if cooldownTicks > 0 {
            cooldownTicks -= 1
            return standingSprite
        }

        activeBlinkFrames = selectedBlinkFrames()
        isBlinking = true
        blinkStep = 0
        blinkFrameTicks = activeBlinkFrames[blinkStep].ticks
        return activeBlinkFrames[blinkStep].sprite
    }

    private mutating func reset(nextCooldownTicks: Int? = nil) {
        cooldownTicks = nextCooldownTicks ?? Int.random(in: cooldownRange)
        isBlinking = false
        activeBlinkFrames = []
        blinkStep = 0
        blinkFrameTicks = 0
    }

    private func selectedBlinkFrames() -> [Frame] {
        if let forceDoubleBlink {
            if forceDoubleBlink, let doubleBlinkFrames {
                return doubleBlinkFrames
            }
            return blinkFrames
        }

        if let doubleBlinkFrames, Int.random(in: 0..<100) < doubleBlinkChance {
            return doubleBlinkFrames
        }

        return blinkFrames
    }
}

struct BlinkStyle {
    let standingSprite: Int
    let cooldownRange: ClosedRange<Int>
    let frames: [BlinkState.Frame]
    let doubleFrames: [BlinkState.Frame]?
    let doubleBlinkChance: Int
}

enum BlinkStyles {
    /// Top-row eyelid frames chosen from the sprite sheet by hand:
    /// open-ish -> half-closed -> open-ish, with an occasional double blink.
    static let sheep = BlinkStyle(
        standingSprite: 3,
        cooldownRange: 20...60,
        frames: [
            BlinkState.Frame(sprite: 7, ticks: 4),
            BlinkState.Frame(sprite: 8, ticks: 4),
            BlinkState.Frame(sprite: 7, ticks: 4),
        ],
        doubleFrames: [
            BlinkState.Frame(sprite: 7, ticks: 4),
            BlinkState.Frame(sprite: 8, ticks: 4),
            BlinkState.Frame(sprite: 7, ticks: 4),
            BlinkState.Frame(sprite: 3, ticks: 3),
            BlinkState.Frame(sprite: 7, ticks: 4),
            BlinkState.Frame(sprite: 8, ticks: 4),
            BlinkState.Frame(sprite: 7, ticks: 4),
        ],
        doubleBlinkChance: 25
    )
}
