import SwiftUI

struct ContentView: View {
    @Environment(\.apiTokenAvailable) var apiTokenAvailable

    var body: some View {
        // Hauptansicht ist jetzt direkt die Fallliste
        NavigationView { // NavigationView statt NavigationSplitView für einfachere Struktur
             CaseListView() // Starte mit der Fallliste
                 .toolbar {
                     ToolbarItem(placement: .navigation) { // Button um Sidebar ggf. einzublenden (Standard bei NavigationView)
                         // Dieser Button ist bei NavigationView oft automatisch da
                         Button(action: toggleSidebar, label: {
                             Image(systemName: "sidebar.left")
                         })
                     }
                 }
        }
        // Optional: Wenn du doch eine Seitenleiste willst, nimm NavigationSplitView wie zuvor
        // und passe die List-Inhalte an (nur Fälle und Einstellungen?)
        /*
        NavigationSplitView {
            List {
                NavigationLink {
                    CaseListView()
                } label: {
                    Label("Fälle", systemImage: "doc.text.fill")
                }

                Divider()

                NavigationLink {
                     SettingsView(isApiTokenSet: apiTokenAvailable)
                } label: {
                    Label("Einstellungen", systemImage: "gear")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("InkassoApp")
        } detail: {
             Text("Bitte einen Fall auswählen.")
                 .font(.title2)
                 .foregroundColor(.secondary)
        }
        */
        .frame(minWidth: 700, minHeight: 450)
    }

    // Helper für Sidebar Toggle (nur bei NavigationView relevant)
     private func toggleSidebar() {
          // Standard macOS Sidebar Toggle
          NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
      }
}

#Preview {
    ContentView()
        .environment(\.apiTokenAvailable, .constant(true))
}
