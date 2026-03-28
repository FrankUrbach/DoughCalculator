import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system
    @AppStorage("unitSystem")  private var unitSystem:  UnitSystem  = .metric

    // Tracks which alert to show after a language change.
    @State private var languageAlert: LanguageAlert? = nil

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Language
                Section {
                    Picker("Language", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: appLanguage) { _, newLang in
                        newLang.apply()
                        languageAlert = makeAlert(for: newLang)
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("language.restartMessage")
                        .font(.caption)
                }

                // MARK: Units
                Section("Units") {
                    Picker("Units", selection: $unitSystem) {
                        Text("Metric (g, °C)").tag(UnitSystem.metric)
                        Text("Imperial (oz, °F)").tag(UnitSystem.imperial)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Alert: restart only
        .alert(
            String(localized: "Restart Required"),
            isPresented: Binding(
                get: { languageAlert == .restartOnly },
                set: { if !$0 { languageAlert = nil } }
            )
        ) {
            Button("OK", role: .cancel) { languageAlert = nil }
        } message: {
            Text("language.restartMessage")
        }
        // Alert: restart + unit suggestion (imperial)
        .alert(
            String(localized: "Restart Required"),
            isPresented: Binding(
                get: { languageAlert == .suggestImperial },
                set: { if !$0 { languageAlert = nil } }
            )
        ) {
            Button("Switch to Imperial") {
                unitSystem = .imperial
                languageAlert = nil
            }
            Button("Keep Current Units", role: .cancel) { languageAlert = nil }
        } message: {
            Text("language.suggestImperial")
        }
        // Alert: restart + unit suggestion (metric)
        .alert(
            String(localized: "Restart Required"),
            isPresented: Binding(
                get: { languageAlert == .suggestMetric },
                set: { if !$0 { languageAlert = nil } }
            )
        ) {
            Button("Switch to Metric") {
                unitSystem = .metric
                languageAlert = nil
            }
            Button("Keep Current Units", role: .cancel) { languageAlert = nil }
        } message: {
            Text("language.suggestMetric")
        }
    }

    // MARK: - Alert logic

    private func makeAlert(for language: AppLanguage) -> LanguageAlert {
        switch language.suggestedUnitSystem {
        case .imperial where unitSystem != .imperial:
            return .suggestImperial
        case .metric where unitSystem != .metric:
            return .suggestMetric
        default:
            return .restartOnly
        }
    }
}

// MARK: - Alert state

private enum LanguageAlert: Equatable {
    case restartOnly
    case suggestImperial
    case suggestMetric
}

#Preview {
    SettingsView()
}
