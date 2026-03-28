import SwiftUI

// MARK: - Sub-Tab (nicht private – wird auch von ContentView/RecipesView genutzt)

enum CalcTab {
    case einstellungen, ergebnis
}

struct CalculatorView: View {
    @Binding var recipe:    DoughRecipe
    @Binding var activeTab: CalcTab
    @EnvironmentObject var store: RecipeStore

    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric

    @State private var showSaveSheet = false
    @State private var showOptional  = false

    private var calc: DoughCalculation { DoughCalculation(recipe: recipe) }

    private var isExistingRecipe: Bool {
        store.recipes.contains { $0.id == recipe.id }
    }

    // MARK: - Weight input bindings (display ↔ internal grams)

    private var portionWeightBinding: Binding<Double> {
        Binding(
            get: { UnitFormatter.gramsToDisplay(recipe.portionWeight, system: unitSystem) },
            set: { recipe.portionWeight = UnitFormatter.displayToGrams($0, system: unitSystem) }
        )
    }

    private var doughWeightBinding: Binding<Double> {
        Binding(
            get: { UnitFormatter.gramsToDisplay(recipe.doughWeight, system: unitSystem) },
            set: { recipe.doughWeight = UnitFormatter.displayToGrams($0, system: unitSystem) }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Picker("", selection: $activeTab) {
                    Text("Settings").tag(CalcTab.einstellungen)
                    Text("Result").tag(CalcTab.ergebnis)
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
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New") {
                        recipe       = DoughRecipe()
                        showOptional = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if isExistingRecipe {
                            Button("Save") { store.save(recipe) }
                                .fontWeight(.semibold)
                        }
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
            .onChange(of: recipe.id) { _, _ in
                showOptional = recipe.sugarPercentage > 0 || recipe.fatPercentage > 0
            }
        }
    }

    // MARK: - Settings sections

    @ViewBuilder private var teigartSection: some View {
        Section {
            Picker("Dough Type", selection: $recipe.doughType) {
                ForEach(DoughType.allCases) { Text($0.localizedName).tag($0) }
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
            Text("Dough Type")
        }
    }

    @ViewBuilder private func teigSection(showHydration: Bool) -> some View {
        Section("Dough") {
            Toggle("Portion Calculator", isOn: $recipe.usePortions)

            if recipe.usePortions {
                Stepper(value: $recipe.portionCount, in: 1...99) {
                    HStack {
                        Text("Number of Pieces")
                        Spacer()
                        Text("\(recipe.portionCount)")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                HStack {
                    Text("Weight per Piece")
                    Spacer()
                    TextField("250", value: portionWeightBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(UnitFormatter.weightUnit(system: unitSystem))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Dough")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(UnitFormatter.formatWeight(recipe.effectiveDoughWeight, system: unitSystem))
                        .foregroundStyle(.secondary).monospacedDigit()
                }
                .listRowBackground(Color.accentColor.opacity(0.06))
            } else {
                HStack {
                    Text("Dough Amount")
                    Spacer()
                    TextField("600", value: doughWeightBinding, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(UnitFormatter.weightUnit(system: unitSystem))
                        .foregroundStyle(.secondary)
                }
            }

            if showHydration {
                pctStepper("Hydration", value: $recipe.hydration, in: 40...100)
            }
        }
    }

    @ViewBuilder private var zutatenSection: some View {
        Section("Ingredients") {
            pctStepper("Salt", value: $recipe.saltPercentage, in: 0...5, step: 0.1)
            Picker("Yeast Type", selection: $recipe.yeastType) {
                ForEach(YeastType.allCases) { Text($0.localizedName).tag($0) }
            }
            .onChange(of: recipe.yeastType) { _, _ in
                if recipe.useColdFermentation { updateYeastForCold() }
            }
            if recipe.useColdFermentation {
                HStack {
                    Label("Yeast Amount (auto)", systemImage: "lock")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatPct(recipe.yeastPercentage))
                        .foregroundStyle(.secondary).monospacedDigit()
                }
            } else {
                pctStepper("Yeast Amount", value: $recipe.yeastPercentage, in: 0.01...5, step: 0.1)
            }
            Toggle("More Ingredients", isOn: $showOptional)
        }
    }

    @ViewBuilder private var optionalSection: some View {
        Section("Optional Ingredients") {
            pctStepper("Sugar",     value: $recipe.sugarPercentage, in: 0...20)
            pctStepper("Fat / Oil", value: $recipe.fatPercentage,   in: 0...50)
        }
    }

    @ViewBuilder private var gaerungSection: some View {
        Section("Fermentation") {
            Toggle("Refrigerator Fermentation", isOn: $recipe.useColdFermentation)
                .onChange(of: recipe.useColdFermentation) { _, enabled in
                    if enabled { updateYeastForCold() }
                }

            if recipe.useColdFermentation {
                Stepper(value: $recipe.coldFermentationHours, in: 3...168, step: 3) {
                    HStack {
                        Label("In Refrigerator", systemImage: "snowflake")
                        Spacer()
                        Text(formatHours(recipe.coldFermentationHours))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                .onChange(of: recipe.coldFermentationHours) { _, _ in updateYeastForCold() }

                Stepper(value: $recipe.warmPhaseHours, in: 0...12, step: 0.5) {
                    HStack {
                        Label("Acclimatization", systemImage: "thermometer.medium")
                        Spacer()
                        if recipe.warmPhaseHours == 0 {
                            Text("none").foregroundStyle(.secondary)
                        } else {
                            Text(formatHours(recipe.warmPhaseHours))
                                .foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }
                .onChange(of: recipe.warmPhaseHours) { _, _ in updateYeastForCold() }

                Stepper(value: $recipe.fermentationTemperature, in: 15...30, step: 1) {
                    HStack {
                        Text("Room Temperature")
                        Spacer()
                        Text(UnitFormatter.formatTemperature(recipe.fermentationTemperature, system: unitSystem))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                .onChange(of: recipe.fermentationTemperature) { _, _ in updateYeastForCold() }

            } else {
                Stepper(value: $recipe.fermentationTemperature, in: 1...40, step: 1) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(UnitFormatter.formatTemperature(recipe.fermentationTemperature, system: unitSystem))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                }
            }

            Toggle("Use Pre-ferment", isOn: $recipe.usePreferment)
        }
    }

    @ViewBuilder private var vorteigSection: some View {
        Section("Pre-ferment") {
            Picker("Type", selection: $recipe.prefermentType) {
                ForEach(PrefermentType.allCases) { Text($0.localizedName).tag($0) }
            }
            .onChange(of: recipe.prefermentType) { _, new in
                recipe.prefermentHydration = new.defaultHydration
            }
            pctStepper("Flour Share",    value: $recipe.prefermentFlourPercentage, in: 10...80,  step: 5)
            pctStepper("Hydration",      value: $recipe.prefermentHydration,       in: 40...150)
            pctStepper("Yeast (Fresh)",  value: $recipe.prefermentYeastPercentage, in: 0.01...1, step: 0.05)
        }
    }

    // MARK: - Result section

    @ViewBuilder private var ergebnisSection: some View {
        if recipe.usePreferment {
            let header = "\(String(localized: "Pre-ferment")): \(recipe.prefermentType.localizedName)"
            Section(header) {
                resultRow("Flour",       calc.prefermentFlourWeight)
                resultRow("Water",       calc.prefermentWaterWeight)
                resultRow("Fresh Yeast", calc.prefermentYeastWeight)
            }
            Section("Main Dough (Baking Day)") {
                resultRow("Flour",   calc.mainDoughFlour)
                resultRow("Water",   calc.mainDoughWater)
                switch recipe.yeastType {
                case .fresh:   resultRow("Fresh Yeast",  calc.mainDoughYeastFresh)
                case .dry:     resultRow("Dry Yeast",    calc.mainDoughYeastDry)
                case .instant: resultRow("Instant Yeast", calc.mainDoughYeastInstant)
                }
                resultRow("Salt", calc.saltWeight)
                if recipe.sugarPercentage > 0 { resultRow("Sugar",     calc.sugarWeight) }
                if recipe.fatPercentage   > 0 { resultRow("Fat / Oil", calc.fatWeight) }
            }
            Section {
                totalRow
                fermentationRow
            }
        } else {
            Section("Result") {
                resultRow("Flour",   calc.flourWeight)
                resultRow("Water",   calc.waterWeight)
                switch recipe.yeastType {
                case .fresh:   resultRow("Fresh Yeast",  calc.yeastAmount(as: .fresh))
                case .dry:     resultRow("Dry Yeast",    calc.yeastAmount(as: .dry))
                case .instant: resultRow("Instant Yeast", calc.yeastAmount(as: .instant))
                }
                resultRow("Salt", calc.saltWeight)
                if recipe.sugarPercentage > 0 { resultRow("Sugar",     calc.sugarWeight) }
                if recipe.fatPercentage   > 0 { resultRow("Fat / Oil", calc.fatWeight) }
                totalRow
                fermentationRow
            }
        }
    }

    @ViewBuilder private var totalRow: some View {
        HStack {
            Text("Total Dough").fontWeight(.semibold)
            Spacer()
            if recipe.usePortions {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(UnitFormatter.formatWeight(recipe.effectiveDoughWeight, system: unitSystem))
                        .fontWeight(.semibold).monospacedDigit()
                    Text("\(recipe.portionCount) × \(UnitFormatter.formatWeight(recipe.portionWeight, system: unitSystem))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text(UnitFormatter.formatWeight(recipe.effectiveDoughWeight, system: unitSystem))
                    .fontWeight(.semibold).monospacedDigit()
            }
        }
    }

    @ViewBuilder private var fermentationRow: some View {
        if recipe.useColdFermentation {
            HStack {
                Label("Refrigerator", systemImage: "snowflake")
                Spacer()
                Text(formatHours(recipe.coldFermentationHours))
                    .foregroundStyle(.cyan).monospacedDigit()
            }
            if recipe.warmPhaseHours > 0 {
                HStack {
                    Label("Acclimatization", systemImage: "thermometer.medium")
                    Spacer()
                    Text(formatHours(recipe.warmPhaseHours))
                        .foregroundStyle(.orange).monospacedDigit()
                }
            }
        } else {
            HStack {
                Label("Fermentation approx.", systemImage: "timer")
                Spacer()
                Text(calc.estimatedFermentationFormatted)
                    .foregroundStyle(.orange).monospacedDigit()
            }
        }
    }

    // MARK: - Helper views

    private func resultRow(_ label: LocalizedStringKey, _ value: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(UnitFormatter.formatWeight(value, system: unitSystem))
                .foregroundStyle(.secondary).monospacedDigit()
        }
    }

    private func pctStepper(
        _ label: LocalizedStringKey,
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

    // MARK: - Cold fermentation

    private func updateYeastForCold() {
        let freshPct = DoughCalculation(recipe: recipe).recommendedFreshYeastPercent
        switch recipe.yeastType {
        case .fresh:   recipe.yeastPercentage = freshPct
        case .dry:     recipe.yeastPercentage = freshPct / 3
        case .instant: recipe.yeastPercentage = freshPct / 3.333
        }
    }

    // MARK: - Formatting

    private func formatHours(_ h: Double) -> String {
        if h < 24 {
            let hInt = Int(h)
            let mInt = Int((h - Double(hInt)) * 60)
            return mInt > 0 ? "\(hInt)h \(mInt)min" : "\(hInt)h"
        }
        let days = h / 24
        return days == floor(days)
            ? "\(Int(days)) \(String(localized: "days"))"
            : String(format: "%.1f \(String(localized: "days"))", days)
    }

    private func formatPct(_ v: Double) -> String {
        v < 1 ? String(format: "%.2f %%", v) : String(format: "%.1f %%", v)
    }
}

// MARK: - Save / rename sheet

struct SaveRecipeSheet: View {
    @Binding var recipe: DoughRecipe
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Pizza Dough", text: $name)
                }
                Section("Notes") {
                    TextField("Optional", text: $recipe.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Save Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        recipe.name = name.isEmpty ? String(localized: "New Recipe") : name
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
