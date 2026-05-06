import CoreGraphics

struct SheepObservation: Equatable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let direction: CGFloat
    let isMoving: Bool

    init(
        id: Int,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        direction: CGFloat,
        isMoving: Bool = true
    ) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.direction = direction
        self.isMoving = isMoving
    }

    var leftX: CGFloat { x }
    var rightX: CGFloat { x + width }
}

struct SheepAwareness {
    static let stopGap: CGFloat = 3
    static let laneTolerance: CGFloat = 6

    enum Decision: Equatable {
        case walkNormally
        case passThroughEncounter
        case stop(atX: CGFloat)
        case reverseDirection
    }

    private enum State: Equatable {
        case idle
        case considering(otherID: Int, stopX: CGFloat, ticksRemaining: Int)
        case clippingPast(otherID: Int, ticksRemaining: Int)
    }

    private let considerationRange: ClosedRange<Int>
    private let clipPastTicks: Int
    private let turnAwayChance: Int
    private var state: State = .idle

    init(
        considerationRange: ClosedRange<Int> = 60...120,
        clipPastTicks: Int = 45,
        turnAwayChance: Int = 50
    ) {
        self.considerationRange = considerationRange
        self.clipPastTicks = clipPastTicks
        self.turnAwayChance = turnAwayChance
    }

    var isEngaged: Bool {
        switch state {
        case .idle:
            false
        case .considering, .clippingPast:
            true
        }
    }

    mutating func reset() {
        state = .idle
    }

    mutating func step(
        sheep: SheepObservation,
        others: [SheepObservation],
        walkSpeed: CGFloat,
        nextConsiderationTicks: (ClosedRange<Int>) -> Int = { Int.random(in: $0) },
        nextPercent: (Range<Int>) -> Int = { Int.random(in: $0) }
    ) -> Decision {
        switch state {
        case .idle:
            guard let encounter = nextEncounter(for: sheep, others: others, walkSpeed: walkSpeed) else {
                return .walkNormally
            }
            let holdTicks = max(0, nextConsiderationTicks(considerationRange) - 1)
            state = .considering(
                otherID: encounter.otherID,
                stopX: encounter.stopX,
                ticksRemaining: holdTicks
            )
            return .stop(atX: encounter.stopX)

        case let .considering(otherID, stopX, ticksRemaining):
            guard encounterStillApplies(
                for: sheep,
                others: others,
                otherID: otherID,
                walkSpeed: max(walkSpeed, 1)
            ) else {
                state = .idle
                return .walkNormally
            }

            if ticksRemaining > 0 {
                state = .considering(otherID: otherID, stopX: stopX, ticksRemaining: ticksRemaining - 1)
                return .stop(atX: stopX)
            }

            if nextPercent(0..<100) < turnAwayChance {
                state = .idle
                return .reverseDirection
            }

            state = .clippingPast(otherID: otherID, ticksRemaining: clipPastTicks)
            return .passThroughEncounter

        case let .clippingPast(otherID, ticksRemaining):
            let effectiveWalkSpeed = max(walkSpeed, 1)
            let remainingTicks = ticksRemaining - 1
            let ignoredOtherID = remainingTicks >= 0 ? otherID : nil

            if let encounter = nextEncounter(
                for: sheep,
                others: others,
                walkSpeed: effectiveWalkSpeed,
                ignoring: ignoredOtherID
            ) {
                let holdTicks = max(0, nextConsiderationTicks(considerationRange) - 1)
                state = .considering(
                    otherID: encounter.otherID,
                    stopX: encounter.stopX,
                    ticksRemaining: holdTicks
                )
                return .stop(atX: encounter.stopX)
            }

            if remainingTicks < 0 {
                state = .idle
                return .walkNormally
            }

            state = .clippingPast(otherID: otherID, ticksRemaining: remainingTicks)
            return .passThroughEncounter
        }
    }

    private func encounterStillApplies(
        for sheep: SheepObservation,
        others: [SheepObservation],
        otherID: Int,
        walkSpeed: CGFloat
    ) -> Bool {
        guard let other = others.first(where: { $0.id == otherID }) else { return false }
        guard let gap = encounterGap(for: sheep, other: other) else { return false }
        return gap <= walkSpeed + Self.stopGap
    }

    private func nextEncounter(
        for sheep: SheepObservation,
        others: [SheepObservation],
        walkSpeed: CGFloat,
        ignoring ignoredOtherID: Int? = nil
    ) -> (otherID: Int, stopX: CGFloat)? {
        guard walkSpeed > 0 else { return nil }

        let candidates = others.compactMap { other -> (Int, CGFloat, CGFloat)? in
            guard other.id != ignoredOtherID else { return nil }
            guard let gap = encounterGap(for: sheep, other: other) else { return nil }
            guard gap <= walkSpeed + Self.stopGap else { return nil }
            return (other.id, gap, stopX(for: sheep, other: other, walkSpeed: walkSpeed))
        }

        return candidates.min { lhs, rhs in lhs.1 < rhs.1 }.map { ($0.0, $0.2) }
    }

    private func encounterGap(for sheep: SheepObservation, other: SheepObservation) -> CGFloat? {
        guard other.isMoving else { return nil }
        guard abs(other.y - sheep.y) <= Self.laneTolerance else { return nil }
        guard other.direction == -sheep.direction else { return nil }

        if sheep.direction > 0 {
            let gap = other.leftX - sheep.rightX
            guard gap >= 0 else { return nil }
            return gap
        }

        let gap = sheep.leftX - other.rightX
        guard gap >= 0 else { return nil }
        return gap
    }

    private func stopX(
        for sheep: SheepObservation,
        other: SheepObservation,
        walkSpeed: CGFloat
    ) -> CGFloat {
        if sheep.direction > 0 {
            return min(sheep.x + walkSpeed, other.leftX - sheep.width - Self.stopGap)
        }

        return max(sheep.x - walkSpeed, other.rightX + Self.stopGap)
    }
}
