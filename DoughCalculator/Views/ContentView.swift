import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var recipe  = DoughRecipe()
    @State private var editingRecipe: DoughRecipe? = nil
    @State private var mainTab = 0
    @State private var calcTab = CalcTab.einstellungen
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $mainTab) {
            CalculatorView(recipe: $recipe, editingRecipe: $editingRecipe, activeTab: $calcTab)
                .tabItem { Label("Calculator", systemImage: "scalemass.fill") }
                .tag(0)

            RecipesView(recipe: $recipe, editingRecipe: $editingRecipe, mainTab: $mainTab, calcTab: $calcTab)
                .tabItem { Label("Recipes", systemImage: "list.clipboard.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .task { migrateIfNeeded() }
    }

    private func migrateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "migration_swiftdata_done") else { return }
        defer { UserDefaults.standard.set(true, forKey: "migration_swiftdata_done") }
        guard
            let data   = UserDefaults.standard.data(forKey: "dough_recipes_v1"),
            let legacy = try? JSONDecoder().decode([LegacyRecipe].self, from: data)
        else { return }
        for l in legacy {
            let r = DoughRecipe()
            r.id                        = l.id
            r.name                      = l.name
            r.doughType                 = l.doughType
            r.usePortions               = l.usePortions
            r.portionCount              = l.portionCount
            r.portionWeight             = l.portionWeight
            r.doughWeight               = l.doughWeight
            r.hydration                 = l.hydration
            r.saltPercentage            = l.saltPercentage
            r.yeastType                 = l.yeastType
            r.yeastPercentage           = l.yeastPercentage
            r.sugarPercentage           = l.sugarPercentage
            r.fatPercentage             = l.fatPercentage
            r.doughLossPercentage       = l.doughLossPercentage
            r.fermentationTemperature   = l.fermentationTemperature
            r.useColdFermentation       = l.useColdFermentation
            r.coldFermentationHours     = l.coldFermentationHours
            r.warmPhaseHours            = l.warmPhaseHours
            r.usePreferment             = l.usePreferment
            r.prefermentType            = l.prefermentType
            r.prefermentFlourPercentage = l.prefermentFlourPercentage
            r.prefermentHydration       = l.prefermentHydration
            r.prefermentYeastPercentage = l.prefermentYeastPercentage
            r.notes                     = l.notes
            r.savedDate                 = l.savedDate
            modelContext.insert(r)
        }
        try? modelContext.save()
        UserDefaults.standard.removeObject(forKey: "dough_recipes_v1")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DoughRecipe.self, inMemory: true)
}
