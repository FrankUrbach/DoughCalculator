# DoughCalculator – Projektkontext

## Pfad & Repository
- **Lokal:** `/Users/frank/Documents/Xcode Projects/DoughCalculator/`
- **GitHub:** https://github.com/FrankUrbach/DoughCalculator (Branch: `main`)
- **Stack:** Swift / SwiftUI, iOS, kein CoreData aktiv, Persistenz via `UserDefaults` (Key: `dough_recipes_v1`)

---

## Dateistruktur
```
DoughCalculator/
├── DoughCalculatorApp.swift   – @main
├── ContentView.swift          – Root-TabView
├── DoughModels.swift          – Datenmodelle & Berechnungslogik
├── CalculatorView.swift       – Kalkulator-UI (zwei Sub-Tabs)
└── RecipesView.swift          – Rezeptliste (Suche, Edit, Delete)
```
`Persistence.swift` existiert noch als CoreData-Boilerplate – wird nicht genutzt.

---

## Architektur

### ContentView
Hält `@State`: `recipe: DoughRecipe`, `mainTab: Int` (0=Kalkulator, 1=Rezepte), `calcTab: CalcTab`.
Gibt alle drei als `@Binding` weiter. `RecipeStore` als `@EnvironmentObject`.

### CalcTab (enum, nicht private, in CalculatorView.swift)
`.einstellungen` / `.ergebnis`
Segmented Picker sitzt als erstes Form-Element **unter** der Toolbar.

### Navigation beim Rezept-Laden (RecipesView)
| Geste | calcTab | mainTab |
|---|---|---|
| Antippen (ansehen) | `.ergebnis` | 0 |
| Swipe links „Bearbeiten" | `.einstellungen` | 0 |
| Swipe rechts „Löschen" | – | – |

### Toolbar CalculatorView
- **Leading:** „Neu"
- **Trailing (bestehendes Rezept):** „Speichern" (direkt) + Diskette-Icon (Sheet: Kopie/Umbenennen)
- **Trailing (neues Rezept):** nur Diskette-Icon → öffnet `SaveRecipeSheet`

---

## DoughModels.swift

### Enums
- `YeastType`: `.fresh` / `.dry` / `.instant`
- `PrefermentType`: `.poolish` / `.biga` / `.pateFermentee`
- `DoughType`: `.custom`, `.pizzaNeapolitan`, `.pizzaRomana`, `.brot`, `.broetchen`, `.baguette`, `.focaccia`, `.brioche`, `.vollkorn` – je mit `DoughPreset`

### DoughRecipe (Codable, Identifiable, Equatable)
```swift
// Teigart
var doughType: DoughType

// Portionsrechner
var usePortions: Bool; var portionCount: Int; var portionWeight: Double
var effectiveDoughWeight: Double   // computed

// Teig
var doughWeight, hydration, saltPercentage, yeastType, yeastPercentage
var sugarPercentage, fatPercentage, fermentationTemperature

// Kühlschrankgare
var useColdFermentation: Bool
var coldFermentationHours: Double  // Stepper: 3–168h, Step 3
var warmPhaseHours: Double         // Stepper: 0–12h, Step 0.5

// Vorteig
var usePreferment, prefermentType, prefermentFlourPercentage
var prefermentHydration, prefermentYeastPercentage
```
Custom `init(from:)` mit `decodeIfPresent` sichert Rückwärtskompatibilität.

### DoughCalculation (struct)
- Baker's Percentages: `flourWeight`, `waterWeight`, `saltWeight`, `yeastWeight`, `sugarWeight`, `fatWeight`
- `yeastAmount(as:)` – Frisch:Trocken:Instant ≈ 3:1:0.9
- `estimatedFermentationHours` – Q10-Modell (1% Frischhefe @ 20°C ≈ 2h)
- `recommendedFreshYeastPercent` – Kühlschrankgare:
  `y = 2 / Σ(h_i × 2^((T_i−20)/10))`
  Phasen: Kühlschrank (4°C) + Akklimatisierung (Raumtemperatur)
- Vorteig: `prefermentFlour/Water/YeastWeight`, `mainDoughFlour/Water/YeastFresh/Dry/Instant`

---

## CalculatorView – Einstellungen-Tab (Sektionen)
1. **Teigart** – Picker + Auto-Preset + Backtipp (orange)
2. **Teig** – Portionsrechner-Toggle; Teigmenge od. Stücke × Gewicht; Hydration
3. **Zutaten** – Salz, Hefetyp (onChange → updateYeastForCold), Hefemenge (🔒 auto bei Kühlschrankgare)
4. **Optionale Zutaten** – Zucker, Fett/Öl (Toggle „Weitere Zutaten")
5. **Gärung** – Toggle Kühlschrankgare; wenn an: Kühlschrank-Dauer + Akklimatisierung + Raumtemperatur; sonst: Temperatur; + Toggle Vorteig
6. **Vorteig** – Typ, Mehlanteil, Hydration, Hefe (Frisch)

## CalculatorView – Ergebnis-Tab
- Teig-Sektion OHNE Hydration
- Nur die gewählte Hefe wird angezeigt (`switch recipe.yeastType`)
- Bei Vorteig: 3 Sections (Vorteig / Hauptteig / Gesamt)
- `fermentationRow`: Kühlschrankgare → ❄️ cyan + 🌡️ orange; normal → Timer orange

---

## Bekannte Eigenheiten
- `#Preview` erzeugt harmlose SourceKit-Warnung „use of unknown directive" – baut problemlos
- Entitlements: nur `app-sandbox` (CloudKit/Push wurde zu Beginn entfernt)

---

## Mögliche nächste Schritte
- App-Icon gestalten
- Unit-Tests für `DoughCalculation`
- Mehltypen (405/550/1050/Vollkorn/Manitoba) mit Wasserabsorptions-Korrekturfaktor
- Backtemperatur & -zeit als Hinweis je Teigart
- Lokalisierung (EN)
- Widget für Gärzeitenrechner
