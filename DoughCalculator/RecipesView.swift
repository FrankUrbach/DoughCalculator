import SwiftUI

struct RecipesView: View {
    @Binding var recipe:  DoughRecipe
    @Binding var mainTab: Int
    @Binding var calcTab: CalcTab
    @EnvironmentObject var store: RecipeStore

    @AppStorage("unitSystem") private var unitSystem: UnitSystem = .metric
    @State private var searchText = ""

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    // Gefilterte Rezepte: Suche über Name, Teigart (lokalisiert) und Notizen
    private var filteredRecipes: [DoughRecipe] {
        guard !searchText.isEmpty else { return store.recipes }
        let q = searchText.lowercased()
        return store.recipes.filter {
            $0.name.lowercased().contains(q)
            || $0.doughType.localizedName.lowercased().contains(q)
            || $0.notes.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes",
                        systemImage: "list.clipboard",
                        description: Text("Save recipes via the calculator.")
                    )
                } else if filteredRecipes.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredRecipes) { saved in
                            Button {
                                // Ansehen → Ergebnis-Tab
                                recipe  = saved
                                calcTab = .ergebnis
                                mainTab = 0
                            } label: {
                                recipeRow(saved)
                            }
                            // Bearbeiten (links) / Löschen (rechts)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    recipe  = saved
                                    calcTab = .einstellungen
                                    mainTab = 0
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.accentColor)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(saved)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Name, dough type or note")
        }
    }

    // MARK: - Aktionen

    private func delete(_ saved: DoughRecipe) {
        if let idx = store.recipes.firstIndex(where: { $0.id == saved.id }) {
            store.delete(at: IndexSet(integer: idx))
        }
    }

    // MARK: - Listenzeile

    private func recipeRow(_ saved: DoughRecipe) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // Name + Teigart-Badge
            HStack(spacing: 6) {
                Text(saved.name)
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
                if saved.doughType != .custom {
                    Text(saved.doughType.localizedName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }

            // Kennzahlen-Zeile
            HStack(spacing: 14) {
                if saved.usePortions {
                    Label("\(saved.portionCount) × \(UnitFormatter.formatWeightCompact(saved.portionWeight, system: unitSystem))",
                          systemImage: "square.grid.2x2")
                } else {
                    Label(UnitFormatter.formatWeightCompact(saved.effectiveDoughWeight, system: unitSystem), systemImage: "scalemass")
                }
                Label("\(Int(saved.hydration)) %", systemImage: "drop")
                Label(saved.yeastType.localizedName,    systemImage: "leaf")
                if saved.usePreferment {
                    Label(saved.prefermentType.localizedName, systemImage: "clock.badge.checkmark")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            // Notizen
            if !saved.notes.isEmpty {
                Text(saved.notes)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            // Datum
            Text(Self.dateFormatter.string(from: saved.savedDate))
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 2)
    }

}

#Preview {
    RecipesView(
        recipe:  .constant(DoughRecipe()),
        mainTab: .constant(1),
        calcTab: .constant(.ergebnis)
    )
    .environmentObject(RecipeStore())
}
