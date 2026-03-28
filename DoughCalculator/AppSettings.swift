import Foundation

// MARK: - Unit System

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric   = "metric"
    case imperial = "imperial"
    var id: String { rawValue }
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case system  = "system"
    case german  = "de"
    case english = "en"
    var id: String { rawValue }

    /// Always shown in the language's own name — never translated.
    var displayName: String {
        switch self {
        case .system:  return String(localized: "System Language")
        case .german:  return "Deutsch"
        case .english: return "English"
        }
    }

    /// Unit system that naturally pairs with this language (nil = no suggestion).
    var suggestedUnitSystem: UnitSystem? {
        switch self {
        case .english: return .imperial
        case .german:  return .metric
        case .system:  return nil
        }
    }

    /// Writes the language preference into UserDefaults so iOS picks it up after restart.
    func apply() {
        switch self {
        case .system:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .german:
            UserDefaults.standard.set(["de"], forKey: "AppleLanguages")
        case .english:
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Unit Formatter

enum UnitFormatter {

    // MARK: Weight – precise (calculator results)

    static func formatWeight(_ grams: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            if grams >= 1000 { return String(format: "%.2f kg", grams / 1000) }
            if grams < 0.1   { return String(format: "%.3f g",  grams) }
            if grams < 10    { return String(format: "%.2f g",  grams) }
            return String(format: "%.1f g", grams)
        case .imperial:
            let oz = grams / 28.3495
            if oz >= 32 { return String(format: "%.2f lb", oz / 16) }
            if oz >= 1  { return String(format: "%.1f oz", oz) }
            return String(format: "%.2f oz", oz)
        }
    }

    // MARK: Weight – compact (recipe list)

    static func formatWeightCompact(_ grams: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            if grams >= 1000 { return String(format: "%.1f kg", grams / 1000) }
            return String(format: "%.0f g", grams)
        case .imperial:
            let oz = grams / 28.3495
            if oz >= 16 { return String(format: "%.1f lb", oz / 16) }
            return String(format: "%.0f oz", oz)
        }
    }

    // MARK: Temperature

    static func formatTemperature(_ celsius: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "\(Int(celsius)) °C"
        case .imperial:
            return "\(Int(celsius * 9 / 5 + 32)) °F"
        }
    }

    // MARK: Weight unit label (for input fields)

    static func weightUnit(system: UnitSystem) -> String {
        system == .metric ? "g" : "oz"
    }

    // MARK: Input conversion helpers (internal storage always in grams)

    static func gramsToDisplay(_ grams: Double, system: UnitSystem) -> Double {
        system == .metric ? grams : grams / 28.3495
    }

    static func displayToGrams(_ value: Double, system: UnitSystem) -> Double {
        system == .metric ? value : value * 28.3495
    }
}
