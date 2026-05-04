import AppKit
import ApplicationServices
import CoreGraphics

struct DockGeometry {
    let rect: CGRect

    private static let refreshInterval: CFTimeInterval = 0.5
    private static let dockBundleID = "com.apple.dock"
    private static let dockEdgeTolerance: CGFloat = 24
    private static let trustPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String

    private static var cachedRect: CGRect?
    private static var lastRefresh: CFAbsoluteTime = 0
    private static var promptedForTrust = false

    static func current(on screen: NSScreen) -> DockGeometry? {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastRefresh >= refreshInterval {
            let primaryHeight = NSScreen.screens.first?.frame.height ?? screen.frame.height
            cachedRect = nextCachedRect(
                previous: cachedRect,
                resolved: resolveRect(primaryHeight: primaryHeight),
                autohides: autohides()
            )
            lastRefresh = now
        }

        guard let cachedRect else { return nil }
        let rect = cachedRect.intersection(screen.frame)
        if rect.isNull || rect.isEmpty { return nil }
        return DockGeometry(rect: rect)
    }

    private static func resolveRect(primaryHeight: CGFloat) -> CGRect? {
        guard isAccessibilityTrusted() else { return nil }
        guard let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: dockBundleID).first else {
            return nil
        }

        let app = AXUIElementCreateApplication(dockApp.processIdentifier)
        AXUIElementSetMessagingTimeout(app, 0.2)

        let screenFrames = NSScreen.screens.map(\.frame)
        let candidates = listElements(withRole: kAXListRole as String, in: app, maxDepth: 4)
            .compactMap { rect(for: $0, primaryHeight: primaryHeight) }
            .filter { rect in
                screenFrames.contains { screenFrame in
                    looksLikeDock(rect, on: screenFrame)
                }
            }

        return candidates.max { lhs, rhs in
            lhs.width * lhs.height < rhs.width * rhs.height
        }
    }

    static func nextCachedRect(previous: CGRect?, resolved: CGRect?, autohides: Bool) -> CGRect? {
        if let resolved { return resolved }
        return autohides ? nil : previous
    }

    private static func isAccessibilityTrusted() -> Bool {
        if AXIsProcessTrusted() { return true }
        if !promptedForTrust {
            promptedForTrust = true
            _ = AXIsProcessTrustedWithOptions([trustPromptKey: true] as CFDictionary)
        }
        return false
    }

    private static func autohides() -> Bool {
        UserDefaults(suiteName: dockBundleID)?.bool(forKey: "autohide") ?? false
    }

    private static func listElements(withRole role: String, in element: AXUIElement, maxDepth: Int) -> [AXUIElement] {
        var matches: [AXUIElement] = []
        if stringAttribute(kAXRoleAttribute as CFString, of: element) == role {
            matches.append(element)
        }
        if maxDepth == 0 { return matches }
        guard let children = elementArrayAttribute(kAXChildrenAttribute as CFString, of: element) else {
            return matches
        }
        for child in children {
            matches.append(contentsOf: listElements(withRole: role, in: child, maxDepth: maxDepth - 1))
        }
        return matches
    }

    private static func rect(for element: AXUIElement, primaryHeight: CGFloat) -> CGRect? {
        guard let topLeft = pointAttribute(kAXPositionAttribute as CFString, of: element),
              let size = sizeAttribute(kAXSizeAttribute as CFString, of: element)
        else {
            return nil
        }
        let rect = GroundSurface.appKitRect(
            topLeft: topLeft,
            size: size,
            primaryHeight: primaryHeight
        )
        guard rect.width > 0, rect.height > 0 else { return nil }
        return rect
    }

    private static func looksLikeDock(_ rect: CGRect, on screenFrame: CGRect) -> Bool {
        guard rect.intersects(screenFrame) else { return false }
        let nearBottom = abs(rect.minY - screenFrame.minY) <= dockEdgeTolerance
        let nearLeft = abs(rect.minX - screenFrame.minX) <= dockEdgeTolerance
        let nearRight = abs(rect.maxX - screenFrame.maxX) <= dockEdgeTolerance
        return nearBottom || nearLeft || nearRight
    }

    private static func stringAttribute(_ attribute: CFString, of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private static func elementArrayAttribute(_ attribute: CFString, of element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? [AXUIElement]
    }

    private static func pointAttribute(_ attribute: CFString, of element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID()
        else {
            return nil
        }

        let axValue = rawValue as! AXValue
        var point = CGPoint.zero
        guard AXValueGetType(axValue) == .cgPoint,
              AXValueGetValue(axValue, .cgPoint, &point)
        else {
            return nil
        }
        return point
    }

    private static func sizeAttribute(_ attribute: CFString, of element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID()
        else {
            return nil
        }

        let axValue = rawValue as! AXValue
        var size = CGSize.zero
        guard AXValueGetType(axValue) == .cgSize,
              AXValueGetValue(axValue, .cgSize, &size)
        else {
            return nil
        }
        return size
    }
}

enum GroundSurface {
    static func floorY(
        screenFrame: CGRect,
        sheepX: CGFloat,
        sheepWidth: CGFloat,
        dockRect: CGRect?
    ) -> CGFloat {
        let desktopY = screenFrame.minY
        guard let dockRect else { return desktopY }

        let sheepCenterX = sheepX + (sheepWidth / 2)
        guard sheepCenterX >= dockRect.minX, sheepCenterX <= dockRect.maxX else {
            return desktopY
        }

        return max(desktopY, roundedTopY(for: dockRect, at: sheepCenterX))
    }

    static func appKitRect(
        topLeft: CGPoint,
        size: CGSize,
        primaryHeight: CGFloat
    ) -> CGRect {
        CGRect(
            x: topLeft.x,
            y: primaryHeight - topLeft.y - size.height,
            width: size.width,
            height: size.height
        )
    }

    private static func roundedTopY(for dockRect: CGRect, at x: CGFloat) -> CGFloat {
        let radius = min(dockRect.height / 2, dockRect.width / 2)
        let flatLeft = dockRect.minX + radius
        let flatRight = dockRect.maxX - radius
        if x >= flatLeft, x <= flatRight {
            return dockRect.maxY
        }

        let cornerCenterX = x < flatLeft ? flatLeft : flatRight
        let cornerCenterY = dockRect.maxY - radius
        let dx = x - cornerCenterX
        let dy = sqrt(max(0, (radius * radius) - (dx * dx)))
        return cornerCenterY + dy
    }
}
