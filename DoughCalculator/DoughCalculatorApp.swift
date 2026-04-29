import SwiftUI
import SwiftData

@main
struct DoughCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: DoughRecipe.self,
            configurations: ModelConfiguration(cloudKitDatabase: .automatic)
        )
    }
}
