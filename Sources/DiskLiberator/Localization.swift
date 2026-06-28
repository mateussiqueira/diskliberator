import SwiftUI

// MARK: - Localization Helper
extension String {
    var localized: LocalizedStringKey { LocalizedStringKey(self) }
    
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}

// MARK: - Localizable Text
extension Text {
    init(localized key: String) {
        self.init(LocalizedStringKey(key))
    }
}

// MARK: - Locale
enum AppLocale {
    static let supported: [Locale] = [.init(identifier: "en"), .init(identifier: "pt-BR")]
    static let current: Locale = {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("pt") { return .init(identifier: "pt-BR") }
        return .init(identifier: "en")
    }()
    
    static var isPortuguese: Bool { current.identifier == "pt-BR" }
}
