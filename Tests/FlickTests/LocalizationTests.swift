import XCTest
@testable import Flick

final class LocalizationTests: XCTestCase {
    func testModuleBundleLoadsTranslation() {
        // L10n.t looks up via Bundle.module. A loaded translation is non-empty and
        // differs from the raw key (NSLocalizedString returns the key when missing).
        let translated = L10n.t("board.now")
        XCTAssertFalse(translated.isEmpty)
        XCTAssertNotEqual(translated, "board.now", "Localizable resource bundle is not wired up")
    }

    func testKnownKeysResolveInPreferredLanguage() {
        // Either locale resolves to a real value, never the raw key.
        let keys = ["board.now", "board.later", "quickadd.placeholder", "quickadd.empty"]
        for key in keys {
            let value = L10n.t(key)
            XCTAssertNotEqual(value, key, "Key '\(key)' did not resolve to a translation")
        }
    }
}
