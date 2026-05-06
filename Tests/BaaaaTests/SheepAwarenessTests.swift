import CoreGraphics
import Testing
@testable import Baaaa

@Test func headOnEncounterStopsAtThreePointGap() {
    let selfID = 1
    let otherID = 2

    var awareness = SheepAwareness(considerationRange: 2...2)
    let sheep = SheepObservation(id: selfID, x: 100, y: 95, width: 80, direction: 1)
    let other = SheepObservation(id: otherID, x: 184, y: 95, width: 80, direction: -1)

    #expect(
        awareness.step(
            sheep: sheep,
            others: [other],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 2 },
            nextPercent: { _ in 99 }
        ) == .stop(atX: 101)
    )
}

@Test func encounterCanTurnAwayAfterConsidering() {
    let selfID = 1
    let otherID = 2

    var awareness = SheepAwareness(considerationRange: 2...2)
    let sheep = SheepObservation(id: selfID, x: 100, y: 95, width: 80, direction: 1)
    let other = SheepObservation(id: otherID, x: 184, y: 95, width: 80, direction: -1)

    _ = awareness.step(
        sheep: sheep,
        others: [other],
        walkSpeed: 1,
        nextConsiderationTicks: { _ in 2 },
        nextPercent: { _ in 99 }
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [other],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 2 },
            nextPercent: { _ in 99 }
        ) == .stop(atX: 101)
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [other],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 2 },
            nextPercent: { _ in 0 }
        ) == .reverseDirection
    )
}

@Test func consideringCancelsWhenOtherTurnsAway() {
    let selfID = 1
    let otherID = 2

    var awareness = SheepAwareness(considerationRange: 2...2)
    let sheep = SheepObservation(id: selfID, x: 100, y: 95, width: 80, direction: 1)
    let other = SheepObservation(id: otherID, x: 184, y: 95, width: 80, direction: -1)
    let turnedAway = SheepObservation(id: otherID, x: 184, y: 95, width: 80, direction: 1)

    _ = awareness.step(
        sheep: sheep,
        others: [other],
        walkSpeed: 1,
        nextConsiderationTicks: { _ in 2 },
        nextPercent: { _ in 99 }
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [turnedAway],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 2 },
            nextPercent: { _ in 99 }
        ) == .walkNormally
    )
}

@Test func idleSheepDoesNotTriggerEncounter() {
    let selfID = 1
    let otherID = 2

    var awareness = SheepAwareness(considerationRange: 2...2)
    let sheep = SheepObservation(id: selfID, x: 100, y: 95, width: 80, direction: 1)
    let pausedOther = SheepObservation(id: otherID, x: 184, y: 95, width: 80, direction: -1, isMoving: false)

    #expect(
        awareness.step(
            sheep: sheep,
            others: [pausedOther],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 2 },
            nextPercent: { _ in 99 }
        ) == .walkNormally
    )
}

@Test func clipPastStateIgnoresSameSheepUntilCooldownExpires() {
    let selfID = 1
    let otherID = 2

    var awareness = SheepAwareness(considerationRange: 1...1, clipPastTicks: 2)
    let sheep = SheepObservation(id: selfID, x: 100, y: 95, width: 80, direction: 1)
    let other = SheepObservation(id: otherID, x: 184, y: 95, width: 80, direction: -1)

    _ = awareness.step(
        sheep: sheep,
        others: [other],
        walkSpeed: 1,
        nextConsiderationTicks: { _ in 1 },
        nextPercent: { _ in 99 }
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [other],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 1 },
            nextPercent: { _ in 99 }
        ) == .passThroughEncounter
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [other],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 1 },
            nextPercent: { _ in 99 }
        ) == .passThroughEncounter
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [other],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 1 },
            nextPercent: { _ in 99 }
        ) == .passThroughEncounter
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [other],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 1 },
            nextPercent: { _ in 99 }
        ) == .stop(atX: 101)
    )
}

@Test func clipPastCanStillNoticeDifferentSheep() {
    let selfID = 1
    let firstOtherID = 2
    let secondOtherID = 3

    var awareness = SheepAwareness(considerationRange: 1...1, clipPastTicks: 4)
    let sheep = SheepObservation(id: selfID, x: 100, y: 95, width: 80, direction: 1)
    let firstOther = SheepObservation(id: firstOtherID, x: 184, y: 95, width: 80, direction: -1)
    let movedSheep = SheepObservation(id: selfID, x: 190, y: 95, width: 80, direction: 1)
    let firstOtherBehind = SheepObservation(id: firstOtherID, x: 100, y: 95, width: 80, direction: -1)
    let secondOtherAhead = SheepObservation(id: secondOtherID, x: 274, y: 95, width: 80, direction: -1)

    _ = awareness.step(
        sheep: sheep,
        others: [firstOther],
        walkSpeed: 1,
        nextConsiderationTicks: { _ in 1 },
        nextPercent: { _ in 99 }
    )

    #expect(
        awareness.step(
            sheep: sheep,
            others: [firstOther],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 1 },
            nextPercent: { _ in 99 }
        ) == .passThroughEncounter
    )

    #expect(
        awareness.step(
            sheep: movedSheep,
            others: [firstOtherBehind, secondOtherAhead],
            walkSpeed: 1,
            nextConsiderationTicks: { _ in 2 },
            nextPercent: { _ in 99 }
        ) == .stop(atX: 191)
    )
}
