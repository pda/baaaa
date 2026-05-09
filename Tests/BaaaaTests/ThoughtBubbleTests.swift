import AppKit
import CoreGraphics
import Testing
@testable import Baaaa

@Test func thoughtBubbleStartsAndExpiresAfterDuration() {
    var state = ThoughtBubbleState(cooldownRange: 3...3)

    state.begin(kind: .question, durationTicks: 2, nextCooldownTicks: 3)
    #expect(state.active == ThoughtKind.question.content)

    state.advance()
    #expect(state.active == ThoughtKind.question.content)

    state.advance()
    #expect(state.active == nil)
}

@Test func thoughtBubbleCooldownBlocksImmediateRestart() {
    var state = ThoughtBubbleState(cooldownRange: 3...3)

    state.begin(kind: .question, durationTicks: 1, nextCooldownTicks: 3)
    state.advance()
    #expect(state.active == nil)

    state.maybeBegin(
        forPauseTicks: 120,
        nextPercent: { _ in 0 },
        nextContent: { ThoughtKind.ellipsis.content }
    )
    #expect(state.active == nil)

    state.advance()
    state.advance()
    state.advance()
    state.maybeBegin(
        forPauseTicks: 120,
        nextPercent: { _ in 0 },
        nextContent: { ThoughtKind.ellipsis.content }
    )
    #expect(state.active == ThoughtKind.ellipsis.content)
}

@Test func sleepStimulusUsesSleepyThoughts() {
    var state = ThoughtBubbleState(cooldownRange: 3...3)

    state.maybeBegin(
        stimulus: .sleep,
        force: true,
        nextContentIndex: { _ in 0 }
    )

    #expect(state.active == ThoughtBubbleContent(text: "zzz"))
}

@Test func eatingStimulusUsesGrassThoughts() {
    var state = ThoughtBubbleState(cooldownRange: 3...3)

    state.maybeBegin(
        stimulus: .eat,
        force: true,
        nextContentIndex: { _ in 0 }
    )

    #expect(state.active == ThoughtBubbleContent(text: "grass?"))
}

@Test func windowLandingStimulusUsesPerchThoughts() {
    var state = ThoughtBubbleState(cooldownRange: 3...3)

    state.maybeBegin(
        stimulus: .landing(surface: .window, cause: .normal),
        force: true,
        nextContentIndex: { _ in 0 }
    )

    #expect(state.active == ThoughtBubbleContent(text: "nice ledge"))
}

@Test func hardEdgeLandingStimulusUsesImpactThoughts() {
    var state = ThoughtBubbleState(cooldownRange: 3...3)

    state.maybeBegin(
        stimulus: .hardLanding(surface: .desktop, cause: .edge),
        force: true,
        nextContentIndex: { _ in 0 }
    )

    #expect(state.active == ThoughtBubbleContent(text: "oof"))
}

@Test func thoughtBubbleSizeExpandsForLongerThoughts() {
    let shortSize = ThoughtBubbleLayout.size(for: ThoughtKind.question.content)
    let longerSize = ThoughtBubbleLayout.size(for: ThoughtBubbleContent(text: "this ledge is nice"))

    #expect(shortSize == ThoughtBubbleLayout.minSize)
    #expect(longerSize.width > shortSize.width)
    #expect(longerSize.height >= shortSize.height)
}

@Test func niceLedgeFitsWithoutWrapping() {
    let content = ThoughtKind.ledge.content
    let size = ThoughtBubbleLayout.size(for: content)
    let textRect = ThoughtBubbleLayout.textRect(for: content, in: CGRect(origin: .zero, size: size))
    let bounds = NSAttributedString(
        string: content.text,
        attributes: ThoughtBubbleLayout.textAttributes(for: content)
    ).boundingRect(
        with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )

    #expect(ceil(bounds.width) <= textRect.width)
    #expect(ceil(bounds.height) <= textRect.height)
}

@Test func textIsVerticallyCenteredInBubbleBody() {
    let content = ThoughtKind.grass.content
    let size = ThoughtBubbleLayout.size(for: content)
    let bounds = CGRect(origin: .zero, size: size)
    let bodyRect = ThoughtBubbleLayout.bodyRect(in: bounds)
    let textRect = ThoughtBubbleLayout.textRect(for: content, in: bounds)

    #expect(abs(textRect.midY - bodyRect.midY) < 0.5)
}

@Test func tailCirclesMirrorForRightFacingSheep() {
    let bounds = CGRect(origin: .zero, size: ThoughtBubbleLayout.minSize)
    let left = ThoughtBubbleLayout.tailCircles(in: bounds, side: .left)
    let right = ThoughtBubbleLayout.tailCircles(in: bounds, side: .right)

    #expect(left.count == right.count)
    for index in left.indices {
        #expect(left[index].center.x < bounds.midX)
        #expect(right[index].center.x > bounds.midX)
        #expect(left[index].center.y == right[index].center.y)
        #expect(left[index].radius == right[index].radius)
        #expect(abs((bounds.midX - left[index].center.x) - (right[index].center.x - bounds.midX)) < 0.5)
    }
}

@Test func thoughtBubbleSizeWrapsVeryLongThoughtsInsideMaximumWidth() {
    let size = ThoughtBubbleLayout.size(
        for: ThoughtBubbleContent(text: "I wonder whether that window is going anywhere")
    )

    #expect(size.width <= ThoughtBubbleLayout.maxSize.width)
    #expect(size.height > ThoughtBubbleLayout.minSize.height)
}

@Test func thoughtBubbleLayoutCentersAboveSheepWhenThereIsRoom() {
    let frame = ThoughtBubbleLayout.frame(
        content: ThoughtKind.question.content,
        sheepOrigin: CGPoint(x: 100, y: 80),
        sheepSize: CGSize(width: 80, height: 80),
        screenFrame: CGRect(x: 0, y: 0, width: 500, height: 500),
        floatOffset: 0
    )

    #expect(frame.origin.x == 102)
    #expect(frame.origin.y == 164)
}

@Test func thoughtBubbleLayoutFallsBackBelowNearTopOfScreen() {
    let frame = ThoughtBubbleLayout.frame(
        content: ThoughtKind.question.content,
        sheepOrigin: CGPoint(x: 100, y: 430),
        sheepSize: CGSize(width: 80, height: 80),
        screenFrame: CGRect(x: 0, y: 0, width: 500, height: 500),
        floatOffset: 0
    )

    #expect(frame.origin.x == 102)
    #expect(frame.origin.y == 366)
}

@Test func thoughtBubbleLayoutClampsToScreenEdges() {
    let leftFrame = ThoughtBubbleLayout.frame(
        content: ThoughtKind.question.content,
        sheepOrigin: CGPoint(x: -20, y: 80),
        sheepSize: CGSize(width: 80, height: 80),
        screenFrame: CGRect(x: 0, y: 0, width: 500, height: 500),
        floatOffset: 0
    )
    let rightFrame = ThoughtBubbleLayout.frame(
        content: ThoughtKind.question.content,
        sheepOrigin: CGPoint(x: 470, y: 80),
        sheepSize: CGSize(width: 80, height: 80),
        screenFrame: CGRect(x: 0, y: 0, width: 500, height: 500),
        floatOffset: 0
    )

    #expect(leftFrame.origin.x == 0)
    #expect(rightFrame.origin.x == 424)
}
