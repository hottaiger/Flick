import XCTest
@testable import Flick

final class TaskBoardDisplayTests: XCTestCase {
    func testCapsuleShowsFirstTitleAndTruncatesAfterFiveCharacters() {
        XCTAssertEqual(CapsuleSummaryText.title(from: ["SFE-42281", "稍后处理"]), "SFE-42281")
        XCTAssertEqual(CapsuleSummaryText.title(from: ["买牛奶"]), "买牛奶")
        XCTAssertEqual(CapsuleSummaryText.title(from: ["一二三四五六"]), "一二三四五...")
        XCTAssertEqual(CapsuleSummaryText.title(from: ["SFE-42281ABC"]), "SFE-42281A...")
        XCTAssertEqual(CapsuleSummaryText.title(from: []), L10n.t("capsule.empty"))
    }
}
