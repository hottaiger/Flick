import XCTest
@testable import Flick

final class DisplayPlacementResolverTests: XCTestCase {
    func testPreferredScreenUsesNotchedDisplayWhenConnected() {
        let screens = NSScreen.screens
        let preferred = DisplayPlacementResolver.preferredScreen(from: screens)
        guard let notchedScreen = screens.max(by: { $0.safeAreaInsets.top < $1.safeAreaInsets.top }) else {
            return XCTFail("Expected at least one screen")
        }
        XCTAssertEqual(preferred, notchedScreen)
    }

    func testCollapsedFrameUsesRequestedWidthAndHeight() {
        let screen = NSScreen.main!
        let frame = DisplayPlacementResolver.collapsedFrame(on: screen, width: 104, height: 34)
        if DisplayPlacementResolver.notchRightFrame(on: screen, width: 104) == nil {
            XCTAssertEqual(frame.size, CGSize(width: 104, height: 34))
        } else {
            XCTAssertEqual(frame, DisplayPlacementResolver.notchRightFrame(on: screen, width: 104)!)
        }
    }

    func testCollapsedSurfaceOverlapsNotchBeforeTheFishBackground() {
        let screen = NSScreen.main!
        let surface = DisplayPlacementResolver.collapsedSurfaceFrame(on: screen)

        if let right = screen.auxiliaryTopRightArea {
            XCTAssertEqual(surface.minX, right.minX - 18, accuracy: 0.5)
            XCTAssertEqual(surface.minX + 48, right.minX + 30, accuracy: 0.5)
            XCTAssertEqual(surface.width, 152, accuracy: 0.5)
            XCTAssertEqual(surface.height, right.height, accuracy: 0.5)
        } else {
            XCTAssertEqual(surface.width, 136, accuracy: 0.5)
        }
    }

    func testNotchFrameUsesRightSafeAuxiliaryArea() {
        let screen = NSScreen.main!
        let frame = DisplayPlacementResolver.collapsedFrame(on: screen)
        guard let right = screen.auxiliaryTopRightArea else {
            XCTAssertEqual(frame.maxY, screen.visibleFrame.maxY, accuracy: 0.5)
            return
        }
        XCTAssertEqual(frame.minY, right.minY, accuracy: 0.5)
        XCTAssertEqual(frame.minX, right.minX - 18, accuracy: 0.5)
        XCTAssertLessThanOrEqual(frame.maxX, right.maxX)
        XCTAssertEqual(frame.height, right.height, accuracy: 0.5)
    }

    func testNotchPanelCanBecomeKeyForQuickEntry() {
        XCTAssertTrue(NotchPanelWindow(contentRect: .zero).canBecomeKey)
    }

    func testNotchPanelFloatsAboveMenuBarToReceiveClicks() {
        XCTAssertGreaterThan(NotchPanelWindow(contentRect: .zero).level.rawValue, NSWindow.Level.mainMenu.rawValue)
    }

    func testNotchPanelDoesNotConstrainNotchFrameAfterDisplayChange() {
        let screen = NSScreen.main!
        let desiredFrame = DisplayPlacementResolver.collapsedFrame(on: screen)
        let panel = NotchPanelWindow(contentRect: desiredFrame)
        XCTAssertEqual(panel.constrainFrameRect(desiredFrame, to: screen), desiredFrame)
    }
}
