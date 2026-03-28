import Foundation

// MARK: - Enums

enum YeastType: String, Codable, CaseIterable, Identifiable {
    case fresh   = "Frischhefe"
    case dry     = "Trockenhefe"
    case instant = "Instanthefe"
    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .fresh:   return String(localized: "yeast.fresh")
        case .dry:     return String(localized: "yeast.dry")
        case .instant: return String(localized: "yeast.instant")
        }
    }
}

enum PrefermentType: String, Codable, CaseIterable, Identifiable {
    case poolish       = "Poolish"
    case biga          = "Biga"
    case pateFermentee = "Pâte fermentée"
    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .poolish:       return String(localized: "preferment.poolish")
        case .biga:          return String(localized: "preferment.biga")
        case .pateFermentee: return String(localized: "preferment.pateFermentee")
        }
    }

    var defaultHydration: Double {
        switch self {
        case .poolish:       return 100
        case .biga:          return 55
        case .pateFermentee: return 65
        }
    }
}

// MARK: - Dough Types & Presets

struct DoughPreset {
    let hydration: Double
    let saltPercentage: Double
    let yeastPercentage: Double
    let yeastType: YeastType
    let sugarPercentage: Double
    let fatPercentage: Double
    let fermentationTemperature: Double
    let defaultPortionWeight: Double   // empfohlenes Stückgewicht
    let tip: String                    // Backtipp
}

enum DoughType: String, Codable, CaseIterable, Identifiable {
    case custom          = "Benutzerdefiniert"
    case pizzaNeapolitan = "Pizza Napoletana"
    case pizzaRomana     = "Pizza al Taglio"
    case brot            = "Rustikales Brot"
    case broetchen       = "Brötchen"
    case baguette        = "Baguette"
    case focaccia        = "Focaccia"
    case brioche         = "Brioche"
    case vollkorn        = "Vollkornbrot"

    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .custom:          return String(localized: "dough.custom")
        case .pizzaNeapolitan: return String(localized: "dough.pizzaNeapolitan")
        case .pizzaRomana:     return String(localized: "dough.pizzaRomana")
        case .brot:            return String(localized: "dough.brot")
        case .broetchen:       return String(localized: "dough.broetchen")
        case .baguette:        return String(localized: "dough.baguette")
        case .focaccia:        return String(localized: "dough.focaccia")
        case .brioche:         return String(localized: "dough.brioche")
        case .vollkorn:        return String(localized: "dough.vollkorn")
        }
    }

    var preset: DoughPreset? {
        switch self {
        case .custom:
            return nil
        case .pizzaNeapolitan:
            return DoughPreset(
                hydration: 62, saltPercentage: 2.8, yeastPercentage: 0.1, yeastType: .fresh,
                sugarPercentage: 0, fatPercentage: 0, fermentationTemperature: 8,
                defaultPortionWeight: 270,
                tip: String(localized: "tip.pizzaNeapolitan")
            )
        case .pizzaRomana:
            return DoughPreset(
                hydration: 80, saltPercentage: 2.5, yeastPercentage: 0.2, yeastType: .fresh,
                sugarPercentage: 0, fatPercentage: 3, fermentationTemperature: 10,
                defaultPortionWeight: 350,
                tip: String(localized: "tip.pizzaRomana")
            )
        case .brot:
            return DoughPreset(
                hydration: 68, saltPercentage: 1.8, yeastPercentage: 1.5, yeastType: .fresh,
                sugarPercentage: 0, fatPercentage: 0, fermentationTemperature: 22,
                defaultPortionWeight: 750,
                tip: String(localized: "tip.brot")
            )
        case .broetchen:
            return DoughPreset(
                hydration: 58, saltPercentage: 1.8, yeastPercentage: 2.5, yeastType: .fresh,
                sugarPercentage: 2, fatPercentage: 3, fermentationTemperature: 22,
                defaultPortionWeight: 80,
                tip: String(localized: "tip.broetchen")
            )
        case .baguette:
            return DoughPreset(
                hydration: 72, saltPercentage: 1.8, yeastPercentage: 0.3, yeastType: .fresh,
                sugarPercentage: 0, fatPercentage: 0, fermentationTemperature: 10,
                defaultPortionWeight: 300,
                tip: String(localized: "tip.baguette")
            )
        case .focaccia:
            return DoughPreset(
                hydration: 80, saltPercentage: 2.0, yeastPercentage: 1.0, yeastType: .fresh,
                sugarPercentage: 0, fatPercentage: 5, fermentationTemperature: 22,
                defaultPortionWeight: 800,
                tip: String(localized: "tip.focaccia")
            )
        case .brioche:
            return DoughPreset(
                hydration: 55, saltPercentage: 1.5, yeastPercentage: 3.0, yeastType: .fresh,
                sugarPercentage: 10, fatPercentage: 30, fermentationTemperature: 20,
                defaultPortionWeight: 500,
                tip: String(localized: "tip.brioche")
            )
        case .vollkorn:
            return DoughPreset(
                hydration: 75, saltPercentage: 1.8, yeastPercentage: 2.0, yeastType: .fresh,
                sugarPercentage: 1, fatPercentage: 0, fermentationTemperature: 22,
                defaultPortionWeight: 750,
                tip: String(localized: "tip.vollkorn")
            )
        }
    }
}

// MARK: - Recipe Model

struct DoughRecipe: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = String(localized: "New Recipe")

    // Teigart
    var doughType: DoughType = .custom

    // Portionsrechner
    var usePortions: Bool = false
    var portionCount: Int = 4
    var portionWeight: Double = 250

    // Teig
    var doughWeight: Double = 600
    var hydration: Double = 65
    var saltPercentage: Double = 2
    var yeastType: YeastType = .fresh
    var yeastPercentage: Double = 2
    var sugarPercentage: Double = 0
    var fatPercentage: Double = 0
    var fermentationTemperature: Double = 20

    // Kühlschrankgare
    var useColdFermentation: Bool   = false
    var coldFermentationHours: Double = 24    // Stunden im Kühlschrank (≈ 4 °C)
    var warmPhaseHours: Double        = 1     // Akklimatisierung bei Raumtemperatur

    // Vorteig
    var usePreferment = false
    var prefermentType: PrefermentType = .poolish
    var prefermentFlourPercentage: Double = 30
    var prefermentHydration: Double = 100
    var prefermentYeastPercentage: Double = 0.1

    var notes = ""
    var savedDate = Date()

    // Effektives Teiggewicht: entweder direkt oder aus Portionen berechnet
    var effectiveDoughWeight: Double {
        usePortions ? Double(portionCount) * portionWeight : doughWeight
    }

    // Preset auf das aktuelle Rezept anwenden
    mutating func apply(_ preset: DoughPreset) {
        hydration               = preset.hydration
        saltPercentage          = preset.saltPercentage
        yeastPercentage         = preset.yeastPercentage
        yeastType               = preset.yeastType
        sugarPercentage         = preset.sugarPercentage
        fatPercentage           = preset.fatPercentage
        fermentationTemperature = preset.fermentationTemperature
        // Im Portionsmodus Stückgewicht auf Vorgabe setzen
        if usePortions { portionWeight = preset.defaultPortionWeight }
    }

    // MARK: Custom Decoder (Rückwärtskompatibilität)

    enum CodingKeys: String, CodingKey {
        case id, name, doughType, usePortions, portionCount, portionWeight
        case doughWeight, hydration, saltPercentage, yeastType, yeastPercentage
        case sugarPercentage, fatPercentage, fermentationTemperature
        case useColdFermentation, coldFermentationHours, warmPhaseHours
        case usePreferment, prefermentType, prefermentFlourPercentage
        case prefermentHydration, prefermentYeastPercentage
        case notes, savedDate
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = (try? c.decodeIfPresent(UUID.self,   forKey: .id))   ?? UUID()
        name        = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? String(localized: "New Recipe")
        doughType   = (try? c.decodeIfPresent(DoughType.self, forKey: .doughType)) ?? .custom
        usePortions = (try? c.decodeIfPresent(Bool.self,   forKey: .usePortions))  ?? false
        portionCount  = (try? c.decodeIfPresent(Int.self,    forKey: .portionCount))  ?? 4
        portionWeight = (try? c.decodeIfPresent(Double.self, forKey: .portionWeight)) ?? 250
        doughWeight   = (try? c.decodeIfPresent(Double.self, forKey: .doughWeight))   ?? 600
        hydration     = (try? c.decodeIfPresent(Double.self, forKey: .hydration))     ?? 65
        saltPercentage  = (try? c.decodeIfPresent(Double.self, forKey: .saltPercentage))  ?? 2
        yeastType       = (try? c.decodeIfPresent(YeastType.self, forKey: .yeastType))    ?? .fresh
        yeastPercentage = (try? c.decodeIfPresent(Double.self, forKey: .yeastPercentage)) ?? 2
        sugarPercentage = (try? c.decodeIfPresent(Double.self, forKey: .sugarPercentage)) ?? 0
        fatPercentage   = (try? c.decodeIfPresent(Double.self, forKey: .fatPercentage))   ?? 0
        fermentationTemperature = (try? c.decodeIfPresent(Double.self, forKey: .fermentationTemperature)) ?? 20
        useColdFermentation   = (try? c.decodeIfPresent(Bool.self,   forKey: .useColdFermentation))   ?? false
        coldFermentationHours = (try? c.decodeIfPresent(Double.self, forKey: .coldFermentationHours)) ?? 24
        warmPhaseHours        = (try? c.decodeIfPresent(Double.self, forKey: .warmPhaseHours))        ?? 1
        usePreferment            = (try? c.decodeIfPresent(Bool.self,           forKey: .usePreferment))            ?? false
        prefermentType           = (try? c.decodeIfPresent(PrefermentType.self, forKey: .prefermentType))           ?? .poolish
        prefermentFlourPercentage = (try? c.decodeIfPresent(Double.self, forKey: .prefermentFlourPercentage)) ?? 30
        prefermentHydration       = (try? c.decodeIfPresent(Double.self, forKey: .prefermentHydration))       ?? 100
        prefermentYeastPercentage = (try? c.decodeIfPresent(Double.self, forKey: .prefermentYeastPercentage)) ?? 0.1
        notes     = (try? c.decodeIfPresent(String.self, forKey: .notes))     ?? ""
        savedDate = (try? c.decodeIfPresent(Date.self,   forKey: .savedDate)) ?? Date()
    }
}

// MARK: - Calculation Logic

struct DoughCalculation {
    let recipe: DoughRecipe

    private var totalFactor: Double {
        1
        + recipe.hydration / 100
        + recipe.saltPercentage / 100
        + recipe.yeastPercentage / 100
        + recipe.sugarPercentage / 100
        + recipe.fatPercentage / 100
    }

    var flourWeight: Double { recipe.effectiveDoughWeight / max(totalFactor, 0.01) }
    var waterWeight: Double { flourWeight * recipe.hydration / 100 }
    var saltWeight:  Double { flourWeight * recipe.saltPercentage / 100 }
    var yeastWeight: Double { flourWeight * recipe.yeastPercentage / 100 }
    var sugarWeight: Double { flourWeight * recipe.sugarPercentage / 100 }
    var fatWeight:   Double { flourWeight * recipe.fatPercentage / 100 }

    // Umrechnung zwischen Hefetypen. Verhältnis Frisch : Trocken : Instant ≈ 3 : 1 : 0.9
    func yeastAmount(as targetType: YeastType) -> Double {
        let fresh: Double
        switch recipe.yeastType {
        case .fresh:   fresh = yeastWeight
        case .dry:     fresh = yeastWeight * 3
        case .instant: fresh = yeastWeight * 3.333
        }
        switch targetType {
        case .fresh:   return fresh
        case .dry:     return fresh / 3
        case .instant: return fresh / 3.333
        }
    }

    // Empfohlene Frischhefe-% für Kühlschrankgare (Q10-Modell, mehrphasig).
    // Formel: y = 2 / Σ(h_i * 2^((T_i − 20) / 10))
    // Phasen: Kühlschrank (4 °C) + optionale Akklimatisierung (Raumtemperatur).
    var recommendedFreshYeastPercent: Double {
        let coldContrib = recipe.coldFermentationHours * pow(2.0, (4.0  - 20.0) / 10.0)
        let warmContrib = recipe.warmPhaseHours        * pow(2.0, (recipe.fermentationTemperature - 20.0) / 10.0)
        let denom = coldContrib + warmContrib
        guard denom > 0 else { return 0.1 }
        return max(0.01, min(2.0 / denom, 5.0))
    }

    // Geschätzte Gehzeit. Referenz: 1 % Frischhefe @ 20 °C ≈ 2 h. Q10 ≈ 2,0.
    var estimatedFermentationHours: Double {
        let freshPercent = flourWeight > 0 ? yeastAmount(as: .fresh) / flourWeight * 100 : 0
        guard freshPercent > 0 else { return 0 }
        let t = 2.0 * (1.0 / freshPercent) * pow(2.0, (20.0 - recipe.fermentationTemperature) / 10.0)
        return max(0.25, min(t, 999))
    }

    var estimatedFermentationFormatted: String {
        let h = estimatedFermentationHours
        if h < 1 { return "\(Int(h * 60)) min" }
        let hours = Int(h)
        let mins  = Int((h - Double(hours)) * 60)
        if h < 48 { return mins > 0 ? "\(hours)h \(mins)min" : "\(hours)h" }
        return String(format: "%.1f \(String(localized: "days"))", h / 24)
    }

    // MARK: Vorteig

    var prefermentFlourWeight: Double {
        recipe.usePreferment ? flourWeight * recipe.prefermentFlourPercentage / 100 : 0
    }
    var prefermentWaterWeight: Double {
        recipe.usePreferment ? prefermentFlourWeight * recipe.prefermentHydration / 100 : 0
    }
    // Vorteig-Hefe als % des Vorteig-Mehls; Ergebnis immer in Frischhefe-Gramm
    var prefermentYeastWeight: Double {
        recipe.usePreferment ? prefermentFlourWeight * recipe.prefermentYeastPercentage / 100 : 0
    }

    // Hauptteig (Backtag)
    var mainDoughFlour: Double { flourWeight - prefermentFlourWeight }
    var mainDoughWater: Double { waterWeight - prefermentWaterWeight }

    var mainDoughYeastFresh:   Double { max(0, yeastAmount(as: .fresh) - prefermentYeastWeight) }
    var mainDoughYeastDry:     Double { mainDoughYeastFresh / 3 }
    var mainDoughYeastInstant: Double { mainDoughYeastFresh / 3.333 }
}

// MARK: - Persistence

class RecipeStore: ObservableObject {
    @Published var recipes: [DoughRecipe] = []
    private let key = "dough_recipes_v1"

    init() { load() }

    func save(_ recipe: DoughRecipe) {
        var r = recipe
        r.savedDate = Date()
        if let i = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[i] = r
        } else {
            recipes.insert(r, at: 0)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([DoughRecipe].self, from: data)
        else { return }
        recipes = decoded
    }
}
