import SwiftUI

@main
struct InkassoAppApp: App {
    // Zentraler State für API-Token Verfügbarkeit (optional)
    @State private var isApiTokenSet: Bool = KeychainService.shared.loadToken() != nil

    var body: some Scene {
        WindowGroup {
            // Zeige ContentView wenn Token gesetzt, sonst Settings
            if isApiTokenSet {
                ContentView()
                    .environment(\.apiTokenAvailable, $isApiTokenSet) // Umgebungsvariable setzen
            } else {
                SettingsView(isApiTokenSet: $isApiTokenSet) // Übergibt Binding
            }
        }
        // Optional: Füge hier das Einstellungsfenster hinzu (über Menü erreichbar)
        // Settings {
        //     SettingsView(isApiTokenSet: $isApiTokenSet)
        // }
    }
}

// Eigener EnvironmentKey um Token-Status durchzureichen (optional)
struct ApiTokenAvailableKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var apiTokenAvailable: Binding<Bool> {
        get { self[ApiTokenAvailableKey.self] }
        set { self[ApiTokenAvailableKey.self] = newValue }
    }
}
