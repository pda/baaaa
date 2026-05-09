import AppKit
import CoreGraphics
import Foundation

struct ThoughtBubbleContent: Equatable {
    let text: String

    init(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = trimmed.isEmpty ? "..." : trimmed
    }
}

enum ThoughtKind: CaseIterable, Equatable {
    case question
    case ellipsis
    case zzz
    case exclamation
    case grass
    case ledge
    case window

    var text: String {
        switch self {
        case .question: "?"
        case .ellipsis: "..."
        case .zzz: "zzz"
        case .exclamation: "!"
        case .grass: "grass?"
        case .ledge: "nice ledge"
        case .window: "new window?"
        }
    }

    var content: ThoughtBubbleContent {
        ThoughtBubbleContent(text: text)
    }

    static func random() -> ThoughtKind {
        allCases.randomElement() ?? .ellipsis
    }
}

enum ThoughtFallCause {
    case normal
    case edge
    case dragged
}

enum ThoughtStimulus {
    case shortIdle
    case longIdle
    case headTurn
    case doze
    case sleep
    case eat
    case nearEdge
    case landing(surface: SurfaceKind, cause: ThoughtFallCause)
    case hardLanding(surface: SurfaceKind, cause: ThoughtFallCause)
    case sheepEncounter
    case turnAway
    case passingSheep
    case screenEdge

    var chancePercent: Int {
        switch self {
        case .shortIdle:
            24
        case .longIdle:
            65
        case .headTurn, .doze, .nearEdge:
            75
        case .sleep, .eat:
            100
        case .landing:
            45
        case .hardLanding, .turnAway, .screenEdge:
            100
        case .sheepEncounter:
            35
        case .passingSheep:
            2
        }
    }

    func durationTicks(for content: ThoughtBubbleContent) -> Int {
        let base = switch self {
        case .shortIdle, .passingSheep:
            42
        case .longIdle, .headTurn, .doze, .eat, .nearEdge, .landing, .sheepEncounter, .turnAway, .screenEdge:
            72
        case .sleep:
            120
        case .hardLanding:
            90
        }
        return min(max(base, content.text.count * 4), 180)
    }

    var contents: [ThoughtBubbleContent] {
        switch self {
        case .shortIdle:
            Self.contents("baaa", "...", "grass?")
        case .longIdle:
            Self.contents("grass?", "cloud?", "nap?", "baaa")
        case .headTurn:
            Self.contents("huh?", "wind?", "baaa?")
        case .doze:
            Self.contents("sleepy", "zzz?", "soft wool")
        case .sleep:
            Self.contents("zzz", "dream grass")
        case .eat:
            Self.contents("grass?", "munch", "good grass")
        case .nearEdge:
            Self.contents("careful", "long drop", "nice ledge")
        case let .landing(surface, cause):
            landingContents(surface: surface, cause: cause)
        case let .hardLanding(surface, cause):
            hardLandingContents(surface: surface, cause: cause)
        case .sheepEncounter:
            Self.contents("baaa?", "hello?", "you grass?")
        case .turnAway:
            Self.contents("nope", "later", "baaa")
        case .passingSheep:
            Self.contents("pardon", "baa", "wool squeeze")
        case .screenEdge:
            Self.contents("wall?", "turn", "baaa")
        }
    }

    private func landingContents(surface: SurfaceKind, cause: ThoughtFallCause) -> [ThoughtBubbleContent] {
        switch cause {
        case .dragged:
            Self.contents("again?", "whee?", "put down")
        case .edge:
            Self.contents("still here", "long drop", "baaa")
        case .normal:
            switch surface {
            case .desktop:
                Self.contents("grass?", "ground", "soft grass")
            case .dock:
                Self.contents("dock?", "shiny ledge", "careful")
            case .window:
                Self.contents("nice ledge", "new window?", "perch")
            }
        }
    }

    private func hardLandingContents(surface: SurfaceKind, cause: ThoughtFallCause) -> [ThoughtBubbleContent] {
        switch cause {
        case .dragged:
            Self.contents("oof", "again?", "stars")
        case .edge:
            Self.contents("oof", "long drop", "stars")
        case .normal:
            switch surface {
            case .desktop:
                Self.contents("oof", "grass hard", "stars")
            case .dock:
                Self.contents("oof", "dock hard", "stars")
            case .window:
                Self.contents("oof", "hard window", "stars")
            }
        }
    }

    private static func contents(_ strings: String...) -> [ThoughtBubbleContent] {
        strings.map { ThoughtBubbleContent(text: $0) }
    }
}

enum ThoughtBubbleTailSide {
    case left
    case right
}

struct ThoughtBubbleTailCircle: Equatable {
    let center: CGPoint
    let radius: CGFloat
}

private struct ActiveThoughtBubble: Equatable {
    let content: ThoughtBubbleContent
    let durationTicks: Int
    var ageTicks: Int = 0

    var remainingTicks: Int {
        max(0, durationTicks - ageTicks)
    }
}

struct ThoughtBubbleState {
    private(set) var active: ThoughtBubbleContent?
    private let cooldownRange: ClosedRange<Int>
    private var cooldownTicks: Int
    private var current: ActiveThoughtBubble? {
        didSet {
            active = current?.content
        }
    }

    init(
        cooldownRange: ClosedRange<Int> = 120...240,
        initialCooldownTicks: Int = 0
    ) {
        self.active = nil
        self.cooldownRange = cooldownRange
        self.cooldownTicks = initialCooldownTicks
    }

    var floatOffset: CGFloat {
        guard let current else { return 0 }
        return sin(CGFloat(current.ageTicks) / 5.0) * 3
    }

    mutating func advance() {
        if cooldownTicks > 0 {
            cooldownTicks -= 1
        }

        guard var current else { return }
        current.ageTicks += 1
        if current.remainingTicks <= 0 {
            self.current = nil
        } else {
            self.current = current
        }
    }

    mutating func cancel() {
        current = nil
    }

    mutating func begin(
        content: ThoughtBubbleContent,
        durationTicks: Int,
        nextCooldownTicks: Int? = nil,
        force: Bool = false
    ) {
        guard force || (current == nil && cooldownTicks == 0) else { return }
        current = ActiveThoughtBubble(content: content, durationTicks: max(1, durationTicks))
        cooldownTicks = nextCooldownTicks ?? Int.random(in: cooldownRange)
    }

    mutating func begin(
        kind: ThoughtKind,
        durationTicks: Int,
        nextCooldownTicks: Int? = nil,
        force: Bool = false
    ) {
        begin(
            content: kind.content,
            durationTicks: durationTicks,
            nextCooldownTicks: nextCooldownTicks,
            force: force
        )
    }

    mutating func maybeBegin(
        forPauseTicks pauseTicks: Int,
        preferredContent: ThoughtBubbleContent? = nil,
        nextPercent: (Range<Int>) -> Int = { Int.random(in: $0) },
        nextContent: () -> ThoughtBubbleContent = { ThoughtKind.random().content }
    ) {
        guard current == nil, cooldownTicks == 0, pauseTicks >= 6 else { return }

        let chancePercent = pauseTicks >= 120 ? 100 : 70
        guard nextPercent(0..<100) < chancePercent else { return }

        let content = preferredContent ?? nextContent()
        let durationTicks = min(max(36, max(pauseTicks, content.text.count * 3)), 180)
        begin(content: content, durationTicks: durationTicks)
    }

    mutating func maybeBegin(
        stimulus: ThoughtStimulus,
        force: Bool = false,
        nextPercent: (Range<Int>) -> Int = { Int.random(in: $0) },
        nextContentIndex: (Range<Int>) -> Int = { Int.random(in: $0) }
    ) {
        guard force || (current == nil && cooldownTicks == 0) else { return }
        guard force || nextPercent(0..<100) < stimulus.chancePercent else { return }

        let contents = stimulus.contents
        guard !contents.isEmpty else { return }
        let content = contents[nextContentIndex(0..<contents.count)]
        begin(
            content: content,
            durationTicks: stimulus.durationTicks(for: content),
            force: force
        )
    }
}

enum ThoughtBubbleLayout {
    static let minSize = CGSize(width: 76, height: 60)
    static let maxSize = CGSize(width: 190, height: 118)
    static let tailHeight: CGFloat = 14
    private static let bodyInset: CGFloat = 4
    private static let textInsetX: CGFloat = 10
    private static let textInsetY: CGFloat = 8
    private static let textSlack: CGFloat = 4
    private static var horizontalPadding: CGFloat {
        (bodyInset + textInsetX) * 2
    }
    private static var verticalPadding: CGFloat {
        tailHeight + bodyInset + (textInsetY * 2)
    }

    static func size(for content: ThoughtBubbleContent) -> CGSize {
        let textWidth = max(1, maxSize.width - horizontalPadding)
        let text = NSAttributedString(
            string: content.text,
            attributes: textAttributes(for: content)
        )
        let bounds = measuredBounds(for: text, maxWidth: textWidth)

        return CGSize(
            width: clamp(ceil(bounds.width) + horizontalPadding + textSlack, min: minSize.width, max: maxSize.width),
            height: clamp(ceil(bounds.height) + verticalPadding, min: minSize.height, max: maxSize.height)
        )
    }

    static func frame(
        content: ThoughtBubbleContent,
        sheepOrigin: CGPoint,
        sheepSize: CGSize,
        screenFrame: CGRect,
        floatOffset: CGFloat
    ) -> CGRect {
        let size = size(for: content)
        let aboveY = sheepOrigin.y + sheepSize.height + 4 + floatOffset
        let belowY = sheepOrigin.y - size.height - 4 + floatOffset
        let hasRoomAbove = aboveY + size.height <= screenFrame.maxY
        let desiredY = hasRoomAbove ? aboveY : belowY
        let desiredX = sheepOrigin.x + (sheepSize.width - size.width) / 2

        return CGRect(
            x: clamp(desiredX, min: screenFrame.minX, max: screenFrame.maxX - size.width),
            y: clamp(desiredY, min: screenFrame.minY, max: screenFrame.maxY - size.height),
            width: size.width,
            height: size.height
        )
    }

    static func textAttributes(for content: ThoughtBubbleContent) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        return [
            .font: font(for: content),
            .foregroundColor: NSColor.black.withAlphaComponent(0.82),
            .paragraphStyle: paragraph,
        ]
    }

    static func bodyRect(in bounds: CGRect) -> CGRect {
        CGRect(
            x: bodyInset,
            y: tailHeight,
            width: bounds.width - (bodyInset * 2),
            height: bounds.height - tailHeight - bodyInset
        )
    }

    static func textRect(in bounds: CGRect) -> CGRect {
        bodyRect(in: bounds).insetBy(dx: textInsetX, dy: textInsetY)
    }

    static func textRect(for content: ThoughtBubbleContent, in bounds: CGRect) -> CGRect {
        let available = textRect(in: bounds)
        let text = NSAttributedString(
            string: content.text,
            attributes: textAttributes(for: content)
        )
        let measured = measuredBounds(for: text, maxWidth: available.width)
        let width = min(available.width, ceil(measured.width) + textSlack)
        let height = min(available.height, ceil(measured.height))

        return CGRect(
            x: available.midX - width / 2,
            y: available.midY - height / 2,
            width: width,
            height: height
        )
    }

    static func tailCircles(in bounds: CGRect, side: ThoughtBubbleTailSide) -> [ThoughtBubbleTailCircle] {
        let sign: CGFloat = side == .left ? -1 : 1
        return [
            ThoughtBubbleTailCircle(
                center: CGPoint(x: bounds.midX + sign * 8, y: 10),
                radius: 5
            ),
            ThoughtBubbleTailCircle(
                center: CGPoint(x: bounds.midX + sign * 17, y: 4),
                radius: 3
            ),
        ]
    }

    private static func font(for content: ThoughtBubbleContent) -> NSFont {
        switch content.text.count {
        case 0...3:
            NSFont.boldSystemFont(ofSize: 22)
        case 4...14:
            NSFont.boldSystemFont(ofSize: 15)
        default:
            NSFont.boldSystemFont(ofSize: 13)
        }
    }

    private static func measuredBounds(for text: NSAttributedString, maxWidth: CGFloat) -> CGRect {
        let naturalBounds = text.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        if naturalBounds.width <= maxWidth {
            return naturalBounds
        }

        return text.boundingRect(
            with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
    }

    private static func clamp(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
        Swift.max(lower, Swift.min(value, upper))
    }
}

final class ThoughtBubbleWindow: NSWindow {
    private let bubbleView: ThoughtBubbleView

    init() {
        self.bubbleView = ThoughtBubbleView(frame: NSRect(origin: .zero, size: ThoughtBubbleLayout.minSize))
        super.init(
            contentRect: NSRect(origin: .zero, size: ThoughtBubbleLayout.minSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        hidesOnDeactivate = false
        contentView = bubbleView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(
        content: ThoughtBubbleContent,
        frame: CGRect,
        tailSide: ThoughtBubbleTailSide,
        above parentWindow: NSWindow
    ) {
        bubbleView.content = content
        bubbleView.tailSide = tailSide
        setFrame(frame, display: true)

        if parentWindow.windowNumber != 0 {
            order(.above, relativeTo: parentWindow.windowNumber)
        } else {
            orderFrontRegardless()
        }
    }

    func hide() {
        orderOut(nil)
    }
}

private final class ThoughtBubbleView: NSView {
    var content = ThoughtBubbleContent(text: "...") {
        didSet {
            needsDisplay = true
        }
    }
    var tailSide: ThoughtBubbleTailSide = .left {
        didSet {
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.clear.setFill()
        dirtyRect.fill()

        drawBubbleBody()
        drawText()
    }

    private func drawBubbleBody() {
        let bodyRect = ThoughtBubbleLayout.bodyRect(in: bounds)
        let radius = min(18, bodyRect.height / 2)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: radius, yRadius: radius)

        NSColor.white.withAlphaComponent(0.94).setFill()
        NSColor.black.withAlphaComponent(0.58).setStroke()
        body.lineWidth = 2
        body.fill()
        body.stroke()

        for circle in ThoughtBubbleLayout.tailCircles(in: bounds, side: tailSide) {
            drawTailCircle(center: circle.center, radius: circle.radius)
        }
    }

    private func drawTailCircle(center: CGPoint, radius: CGFloat) {
        let rect = NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let circle = NSBezierPath(ovalIn: rect)
        NSColor.white.withAlphaComponent(0.94).setFill()
        NSColor.black.withAlphaComponent(0.58).setStroke()
        circle.lineWidth = 1.5
        circle.fill()
        circle.stroke()
    }

    private func drawText() {
        let text = NSAttributedString(
            string: content.text,
            attributes: ThoughtBubbleLayout.textAttributes(for: content)
        )
        text.draw(
            with: ThoughtBubbleLayout.textRect(for: content, in: bounds),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
    }
}
