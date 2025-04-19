import SwiftUI

struct ContentView: View {
    @Environment(\.apiTokenAvailable) var apiTokenAvailable

    var body: some View {
        NavigationSplitView {
            // Seitenleiste (Sidebar)
            List {
                NavigationLink {
                    CaseListView()
                } label: {
                    Label("Fälle", systemImage: "doc.text.fill")
                }

                // Optional: Füge hier wieder Links hinzu, wenn Sachbearbeiter
                // auch andere Listen sehen sollen (aber ohne Admin-Funktionen)
                /*
                 NavigationLink {
                     DebtorListView()
                 } label: {
                     Label("Schuldner", systemImage: "person.fill")
                 }

                 NavigationLink {
                      AuftragListView() // Zeigt alle Aufträge
                 } label: {
                     Label("Aufträge", systemImage: "briefcase.fill")
                 }

                 NavigationLink {
                      MandantenListView() // Zeigt alle Mandanten
                 } label: {
                     Label("Mandanten", systemImage: "person.2.fill")
                 }

                 NavigationLink {
                      WorkflowListView()
                 } label: {
                     Label("Workflows", systemImage: "arrow.triangle.branch")
                 }
                 */

                Divider()

                NavigationLink {
                     SettingsView(isApiTokenSet: apiTokenAvailable)
                } label: {
                    Label("Einstellungen", systemImage: "gear")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("InkassoApp")
            // --- KORREKTUR HIER ---
            // Füge diesen Modifier hinzu, um die Breite anzupassen
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 400)
            // --- ENDE KORREKTUR ---

        } detail: {
            // Detailbereich (Startansicht)
            VStack {
                 Image(systemName: "folder.badge.person.crop") // Passenderes Icon
                     .resizable()
                     .scaledToFit()
                     .frame(width: 80, height: 80)
                     .foregroundColor(.secondary)
                     .padding(.bottom)
                 Text("Bitte einen Bereich auswählen.")
                     .font(.title2)
                     .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}

#Preview {
    ContentView()
        .environment(\.apiTokenAvailable, .constant(true))
}
