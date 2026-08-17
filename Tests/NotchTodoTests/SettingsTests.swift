import XCTest
@testable import NotchTodo

final class SettingsTests: XCTestCase {
    func testDefaultShortcutIsOptionEnter() {
        XCTAssertEqual(ShortcutChoice.defaultChoice, .optionReturn)
        XCTAssertEqual(ShortcutChoice.optionReturn.title, "Option + Enter")
    }

    @MainActor func testDefaultAutoCollapseIsOff() {
        XCTAssertEqual(AppSettings.defaultAutoCollapseSeconds, 0, accuracy: 0.001)
    }

    func testStatusBarUsesFishIcon() {
        XCTAssertEqual(StatusBarIcon.symbolName, "fish.fill")
    }
}
