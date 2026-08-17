import AppKit

struct DisplayPlacementResolver {
    static func preferredScreen(from screens: [NSScreen] = NSScreen.screens, fallback: NSScreen? = NSScreen.main) -> NSScreen? {
        screens.max { lhs, rhs in
            if lhs.safeAreaInsets.top != rhs.safeAreaInsets.top {
                return lhs.safeAreaInsets.top < rhs.safeAreaInsets.top
            }
            return lhs.frame.width < rhs.frame.width
        } ?? fallback
    }

    static func collapsedFrame(on screen: NSScreen, width: CGFloat = 104, height: CGFloat = 34, placement: ExternalDisplayPlacement = .center) -> NSRect {
        if let notchFrame = notchRightFrame(on: screen, width: width) { return notchFrame }
        let visible = screen.visibleFrame
        let x: CGFloat
        if screen.safeAreaInsets.top > 0 || placement == .center { x = visible.midX - width / 2 }
        else if placement == .leading { x = visible.minX + 16 }
        else { x = visible.maxX - width - 16 }
        return NSRect(x: x, y: visible.maxY - height, width: width, height: height)
    }

    static func collapsedSurfaceFrame(
        on screen: NSScreen,
        capsuleWidth: CGFloat = 104,
        fishWidth: CGFloat = 28,
        fishSpacing: CGFloat = 2,
        placement: ExternalDisplayPlacement = .center
    ) -> NSRect {
        let capsule = collapsedFrame(on: screen, width: capsuleWidth, placement: placement)
        let fishFootprint = fishWidth + fishSpacing
        if screen.safeAreaInsets.top > 0, let right = screen.auxiliaryTopRightArea {
            return NSRect(
                x: right.minX - 18,
                y: right.minY,
                width: capsuleWidth + fishFootprint + 18,
                height: right.height
            )
        }
        return NSRect(
            x: capsule.minX - fishFootprint,
            y: capsule.minY,
            width: capsuleWidth + fishFootprint,
            height: capsule.height
        )
    }

    static func notchRightFrame(on screen: NSScreen, width: CGFloat) -> NSRect? {
        guard screen.safeAreaInsets.top > 0,
              let right = screen.auxiliaryTopRightArea else { return nil }
        let x = min(right.minX - 18, right.maxX - width)
        return NSRect(x: x, y: right.minY, width: width, height: right.height)
    }

    static func expandedFrame(on screen: NSScreen, width: CGFloat = 420, height: CGFloat = 430, placement: ExternalDisplayPlacement = .center) -> NSRect {
        let collapsed = collapsedFrame(on: screen, width: width, height: 34, placement: placement)
        return NSRect(x: collapsed.minX, y: screen.visibleFrame.maxY - height, width: width, height: height)
    }
}
