import SwiftUI
import SwiftData

@main
struct DoughCalculatorApp: App {

    let container: ModelContainer = {
        let schema = Schema([DoughRecipe.self])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
