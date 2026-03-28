import SwiftUI

struct ContentView: View {
    @StateObject private var store   = RecipeStore()
    @State private var recipe        = DoughRecipe()
    @State private var mainTab       = 0                    // 0 = Kalkulator, 1 = Rezepte
    @State private var calcTab       = CalcTab.einstellungen

    var body: some View {
        TabView(selection: $mainTab) {
            CalculatorView(recipe: $recipe, activeTab: $calcTab)
                .tabItem { Label("Calculator", systemImage: "scalemass.fill") }
                .tag(0)

            RecipesView(recipe: $recipe, mainTab: $mainTab, calcTab: $calcTab)
                .tabItem { Label("Recipes", systemImage: "list.clipboard.fill") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .environmentObject(store)
    }
}

#Preview {
    ContentView()
}
