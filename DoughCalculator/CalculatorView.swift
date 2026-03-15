import SwiftUI

// MARK: - Sub-Tab (nicht private – wird auch von ContentView/RecipesView genutzt)

enum CalcTab {
    case einstellungen, ergebnis
}

struct CalculatorView: View {
    @Binding var recipe:    DoughRecipe
    @Binding var activeTab: CalcTab       // von ContentView verwaltet
    @EnvironmentObject var store: RecipeStore

    @State private var showSaveSheet = false
    @State private var showOptional  = false

    private var calc: DoughCalculation { DoughCalculation(recipe: recipe) }

    /// Rezept ist bereits gespeichert → "Speichern"-Button statt Sheet-Icon zeigen
    private var isExistingRecipe: Bool {
        store.recipes.contains { $0.id == recipe.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Segmented Picker direkt unterhalb der Toolbar-Buttons
                Picker("", selection: $activeTab) {
                    Text("Einstellungen").tag(CalcTab.einstellungen)
                    Text("Ergebnis").tag(CalcTab.ergebnis)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

                switch activeTab {
                case .einstellungen:
                    teigartSection
                    teigSection(showHydration: true)
                    zutatenSection
                    if showOptional { optionalSection }
                    gaerungSection
                    if recipe.usePreferment { vorteigSection }

                case .ergebnis:
                    teigSection(showHydration: false)
                    ergebnisSection
                }
            }
            .navigationTitle("Kalkulator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Neu") {
                        recipe       = DoughRecipe()
                        showOptional = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Vorhandenes Rezept: direkt speichern ohne Sheet
                        if isExistingRecipe {
                            Button("Speichern") {
                                store.save(recipe)
                            }
                            .fontWeight(.semibold)
                        }
                        // Neues Rezept oder „Speichern unter": Sheet öffnen
                        Button { showSaveSheet = true } label: {
                            Image(systemName: isExistingRecipe
                                  ? "square.and.arrow.down.on.square"
                                  : "square.and.arrow.down")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                SaveRecipeSheet(recipe: $recipe).environmentObject(store)
            }
            // Wenn ein Rezept geladen wird, optionale Zutaten ggf. einblenden.
            // Die Tab-Auswahl steuert ContentView über das Binding.
            .onChange(of: recipe.id) { _, _ in
                showOptional = recipe.sugarPercentage > 0 || recipe.fatPercentage > 0
            }
        }
    }

    // MARK: - Einstellungs-Sektionen

    @ViewBuilder private var teigartSection: some View {
        Section {
            Picker("Teigart", selection: $recipe.doughType) {
                ForEach(DoughType.allCases) { Text($0.rawValue).tag($0) }
            }
            .onChange(of: recipe.doughType) { _, newType in
                if let preset = newType.preset {
                    recipe.apply(preset)
                    showOptional = preset.sugarPercentage > 0 || preset.fatPercentage > 0
                }
            }
            if let tip = recipe.doughType.preset?.tip {
                Label(tip, systemImage: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .listRowBackground(Color.orange.opacity(0.07))
            }
        } header: {
            Text("Teigart")
        }
    }

    @ViewBuilder private func teigSection(showHydration: Bool) -> some View {
        Section("Teig") {
            Toggle("Portionsrechner", isOn: $recipe.usePortions)

            if recipe.usePortions {
                Stepper(value: $recipe.portionCount, in: 1...99) {
                    HStack {
                        Text("Anzahl Stücke")
                        Spacer()
                        Text("\(recipe.portionCount)")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                HStack {
                    Text("Gewicht / Stück")
                    Spacer()
                    TextField("250", value: $recipe.portionWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g").foregroundStyle(.secondary)
                }
                HStack {
                    Text("Teig gesamt")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatG(recipe.effectiveDoughWeight))
                        .foregroundStyle(.secondary).monospacedDigit()
                }
                .listRowBackground(Color.accentColor.opacity(0.06))
            } else {
                HStack {
                    Text("Teigmenge")
                    Spacer()
                    TextField("600", value: $recipe.doughWeight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("g").foregroundStyle(.secondary)
                }
            }

            if showHydration {
                pctStepper("Hydration", value: $recipe.hydration, in: 40...100)
            }
        }
    }

    @ViewBuilder private var zutatenSection: some View {
        Section("Zutaten") {
            pctStepper("Salz", value: $recipe.saltPercentage, in: 0...5, step: 0.1)
            Picker("Hefetyp", selection: $recipe.yeastType) {
                ForEach(YeastType.allCases) { Text($0.rawValue).tag($0) }
            }
            .onChange(of: recipe.yeastType) { _, _ in
                if recipe.useColdFermentation { updateYeastForCold() }
            }
            // Bei Kühlschrankgare: auto-berechneter Wert, nur lesend anzeigen
            if recipe.useColdFermentation {
                HStack {
                    Label("Hefemenge (auto)", systemImage: "lock")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatPct(recipe.yeastPercentage))
                        .foregroundStyle(.secondary).monospacedDigit()
                }
            } else {
                pctStepper("Hefemenge", value: $recipe.yeastPercentage, in: 0.01...5, step: 0.1)
            }
            Toggle("Weitere Zutaten", isOn: $showOptional)
        }
    }

    @ViewBuilder private var optionalSection: some View {
        Section("Optionale Zutaten") {
            pctStepper("Zucker",    value: $recipe.sugarPercentage, in: 0...20)
            pctStepper("Fett / Öl", value: $recipe.fatPercentage,   in: 0...50)
        }
    }

    @ViewBuilder private var gaerungSection: some View {
        Section("Gärung") {
            Toggle("Kühlschrankgare", isOn: $recipe.useColdFermentation)
                .onChange(of: recipe.useColdFermentation) { _, enabled in
                    if enabled { updateYeastForCold() }
                }

            if recipe.useColdFermentation {
                // Dauer im Kühlschrank (≈ 4 °C)
                Stepper(value: $recipe.coldFermentationHours, in: 3...168, step: 3) {
                    HStack {
                        Label("Im Kühlschrank", systemImage: "snowflake")
                        Spacer()
                        Text(formatHours(recipe.coldFermentationHours))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                .onChange(of: recipe.coldFermentationHours) { _, _ in updateYeastForCold() }

                // Akklimatisierung bei Raumtemperatur
                Stepper(value: $recipe.warmPhaseHours, in: 0...12, step: 0.5) {
                    HStack {
                        Label("Akklimatisierung", systemImage: "thermometer.medium")
                        Spacer()
                        if recipe.warmPhaseHours == 0 {
                            Text("keine").foregroundStyle(.secondary)
                        } else {
                            Text(formatHours(recipe.warmPhaseHours))
                                .foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }
                .onChange(of: recipe.warmPhaseHours) { _, _ in updateYeastForCold() }

                // Raumtemperatur (für Akklimatisierung & Hefemengen-Berechnung)
                Stepper(value: $recipe.fermentationTemperature, in: 15...30, step: 1) {
                    HStack {
                        Text("Raumtemperatur")
                        Spacer()
                        Text("\(Int(recipe.fermentationTemperature)) °C")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                .onChange(of: recipe.fermentationTemperature) { _, _ in updateYeastForCold() }

            } else {
                Stepper(value: $recipe.fermentationTemperature, in: 1...40, step: 1) {
                    HStack {
                        Text("Temperatur")
                        Spacer()
                        Text("\(Int(recipe.fermentationTemperature)) °C")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }

            Toggle("Vorteig verwenden", isOn: $recipe.usePreferment)
        }
    }

    @ViewBuilder private var vorteigSection: some View {
        Section("Vorteig") {
            Picker("Typ", selection: $recipe.prefermentType) {
                ForEach(PrefermentType.allCases) { Text($0.rawValue).tag($0) }
            }
            .onChange(of: recipe.prefermentType) { _, new in
                recipe.prefermentHydration = new.defaultHydration
            }
            pctStepper("Mehlanteil",    value: $recipe.prefermentFlourPercentage, in: 10...80,  step: 5)
            pctStepper("Hydration",     value: $recipe.prefermentHydration,       in: 40...150)
            pctStepper("Hefe (Frisch)", value: $recipe.prefermentYeastPercentage, in: 0.01...1, step: 0.05)
        }
    }

    // MARK: - Ergebnis-Sektion

    @ViewBuilder private var ergebnisSection: some View {
        if recipe.usePreferment {
            Section("Vorteig: \(recipe.prefermentType.rawValue)") {
                resultRow("Mehl",       calc.prefermentFlourWeight)
                resultRow("Wasser",     calc.prefermentWaterWeight)
                resultRow("Frischhefe", calc.prefermentYeastWeight)
            }
            Section("Hauptteig (Backtag)") {
                resultRow("Mehl",   calc.mainDoughFlour)
                resultRow("Wasser", calc.mainDoughWater)
                switch recipe.yeastType {
                case .fresh:   resultRow("Frischhefe",  calc.mainDoughYeastFresh)
                case .dry:     resultRow("Trockenhefe", calc.mainDoughYeastDry)
                case .instant: resultRow("Instanthefe", calc.mainDoughYeastInstant)
                }
                resultRow("Salz", calc.saltWeight)
                if recipe.sugarPercentage > 0 { resultRow("Zucker",    calc.sugarWeight) }
                if recipe.fatPercentage   > 0 { resultRow("Fett / Öl", calc.fatWeight)   }
            }
            Section {
                totalRow
                fermentationRow
            }
        } else {
            Section("Ergebnis") {
                resultRow("Mehl",   calc.flourWeight)
                resultRow("Wasser", calc.waterWeight)
                switch recipe.yeastType {
                case .fresh:   resultRow("Frischhefe",  calc.yeastAmount(as: .fresh))
                case .dry:     resultRow("Trockenhefe", calc.yeastAmount(as: .dry))
                case .instant: resultRow("Instanthefe", calc.yeastAmount(as: .instant))
                }
                resultRow("Salz", calc.saltWeight)
                if recipe.sugarPercentage > 0 { resultRow("Zucker",    calc.sugarWeight) }
                if recipe.fatPercentage   > 0 { resultRow("Fett / Öl", calc.fatWeight)   }
                totalRow
                fermentationRow
            }
        }
    }

    @ViewBuilder private var totalRow: some View {
        HStack {
            Text("Teig gesamt").fontWeight(.semibold)
            Spacer()
            if recipe.usePortions {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatG(recipe.effectiveDoughWeight))
                        .fontWeight(.semibold).monospacedDigit()
                    Text("\(recipe.portionCount) × \(formatG(recipe.portionWeight))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text(formatG(recipe.effectiveDoughWeight))
                    .fontWeight(.semibold).monospacedDigit()
            }
        }
    }

    @ViewBuilder private var fermentationRow: some View {
        if recipe.useColdFermentation {
            HStack {
                Label("Kühlschrank", systemImage: "snowflake")
                Spacer()
                Text(formatHours(recipe.coldFermentationHours))
                    .foregroundStyle(.cyan).monospacedDigit()
            }
            if recipe.warmPhaseHours > 0 {
                HStack {
                    Label("Akklimatisierung", systemImage: "thermometer.medium")
                    Spacer()
                    Text(formatHours(recipe.warmPhaseHours))
                        .foregroundStyle(.orange).monospacedDigit()
                }
            }
        } else {
            HStack {
                Label("Gärzeit ca.", systemImage: "timer")
                Spacer()
                Text(calc.estimatedFermentationFormatted)
                    .foregroundStyle(.orange).monospacedDigit()
            }
        }
    }

    // MARK: - Hilfs-Views

    private func resultRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(formatG(value)).foregroundStyle(.secondary).monospacedDigit()
        }
    }

    private func pctStepper(
        _ label: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text(formatPct(value.wrappedValue))
                    .foregroundStyle(.secondary).monospacedDigit()
            }
        }
    }

    // MARK: - Kühlschrankgare

    /// Hefemenge aus cold-fermentation-Parametern neu berechnen und im Rezept setzen.
    private func updateYeastForCold() {
        let freshPct = DoughCalculation(recipe: recipe).recommendedFreshYeastPercent
        switch recipe.yeastType {
        case .fresh:   recipe.yeastPercentage = freshPct
        case .dry:     recipe.yeastPercentage = freshPct / 3
        case .instant: recipe.yeastPercentage = freshPct / 3.333
        }
    }

    private func formatHours(_ h: Double) -> String {
        if h < 24 {
            let hInt = Int(h)
            let mInt = Int((h - Double(hInt)) * 60)
            return mInt > 0 ? "\(hInt)h \(mInt)min" : "\(hInt)h"
        }
        let days = h / 24
        return days == floor(days) ? "\(Int(days)) Tage" : String(format: "%.1f Tage", days)
    }

    // MARK: - Formatierung

    private func formatG(_ v: Double) -> String {
        if v >= 1000 { return String(format: "%.2f kg", v / 1000) }
        if v < 0.1   { return String(format: "%.3f g", v) }
        if v < 10    { return String(format: "%.2f g", v) }
        return String(format: "%.1f g", v)
    }

    private func formatPct(_ v: Double) -> String {
        v < 1 ? String(format: "%.2f %%", v) : String(format: "%.1f %%", v)
    }
}

// MARK: - Rezept speichern / umbenennen

struct SaveRecipeSheet: View {
    @Binding var recipe: DoughRecipe
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z.B. Pizzateig", text: $name)
                }
                Section("Notizen") {
                    TextField("Optional", text: $recipe.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Rezept speichern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        recipe.name = name.isEmpty ? "Neues Rezept" : name
                        store.save(recipe)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { name = recipe.name }
        }
    }
}

#Preview {
    CalculatorView(recipe: .constant(DoughRecipe()), activeTab: .constant(.einstellungen))
        .environmentObject(RecipeStore())
}
