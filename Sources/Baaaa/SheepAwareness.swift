import CoreGraphics

struct SheepObservation: Equatable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let direction: CGFloat

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
            guard encounterStillApplies(for: sheep, others: others, otherID: otherID) else {
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
            if ticksRemaining <= 0 || !others.contains(where: { $0.id == otherID }) {
                state = .idle
                return .walkNormally
            }

            state = .clippingPast(otherID: otherID, ticksRemaining: ticksRemaining - 1)
            return .passThroughEncounter
        }
    }

    private func encounterStillApplies(
        for sheep: SheepObservation,
        others: [SheepObservation],
        otherID: Int
    ) -> Bool {
        guard let other = others.first(where: { $0.id == otherID }) else { return false }
        return abs(other.y - sheep.y) <= Self.laneTolerance
    }

    private func nextEncounter(
        for sheep: SheepObservation,
        others: [SheepObservation],
        walkSpeed: CGFloat
    ) -> (otherID: Int, stopX: CGFloat)? {
        guard walkSpeed > 0 else { return nil }

        let candidates = others.compactMap { other -> (Int, CGFloat, CGFloat)? in
            guard abs(other.y - sheep.y) <= Self.laneTolerance else { return nil }
            guard other.direction == -sheep.direction else { return nil }

            if sheep.direction > 0 {
                let gap = other.leftX - sheep.rightX
                guard gap >= 0, gap <= walkSpeed + Self.stopGap else { return nil }
                let stopX = min(sheep.x + walkSpeed, other.leftX - sheep.width - Self.stopGap)
                return (other.id, gap, stopX)
            }

            let gap = sheep.leftX - other.rightX
            guard gap >= 0, gap <= walkSpeed + Self.stopGap else { return nil }
            let stopX = max(sheep.x - walkSpeed, other.rightX + Self.stopGap)
            return (other.id, gap, stopX)
        }

        return candidates.min { lhs, rhs in lhs.1 < rhs.1 }.map { ($0.0, $0.2) }
    }
}
