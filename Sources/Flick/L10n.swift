import Foundation

/// Localization helper. Strings are looked up in the module resource bundle so the
/// SwiftPM executable target can ship `.lproj` resources alongside the binary.
enum L10n {
    /// 应用界面始终使用简体中文（不跟随系统语言）。
    private static let bundle: Bundle = {
        // SwiftPM 生成的 lproj 目录名大小写可能不同（如 zh-hans），遍历本地化列表匹配中文。
        for localization in Bundle.module.localizations where localization.lowercased().hasPrefix("zh") {
            if let path = Bundle.module.path(forResource: localization, ofType: "lproj"),
               let zhBundle = Bundle(path: path) { return zhBundle }
        }
        return Bundle.module
    }()

    static func t(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, bundle: bundle, comment: comment)
    }

    /// Localized string with positional arguments (e.g. `"已完成 %lld 项"`).
    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: NSLocalizedString(key, bundle: bundle, comment: ""), arguments: args)
    }
}
