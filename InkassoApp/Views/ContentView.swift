import SwiftUI

struct ContentView: View {
    @Environment(\.apiTokenAvailable) var apiTokenAvailable

    var body: some View {
        NavigationSplitView {
            // Sidebar (wie zuvor)
            List { /* ... Links für Fälle, Einstellungen ... */ }
            .listStyle(.sidebar)
            .navigationTitle("InkassoApp")
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 400)

        } detail: {
            // --- NavigationStack bleibt ---
            NavigationStack {
                 VStack { /* ... Platzhalter-Text ... */ }
                 .padding()
                 // --- KORRIGIERTE/ERGÄNZTE NAVIGATION DESTINATIONS ---
                 // Ziel für Navigation zum Case Detail (von CaseListView)
                 .navigationDestination(for: Case.self) { caseItem in
                     // Passendes ViewModel für CaseDetail übergeben
                     CaseDetailView(listViewModel: nil, caseToLoad: caseItem) // listViewModel hier optional
                 }
                 // Ziel für Navigation zum Debtor Detail (von CaseDetailView) anhand der ID
                 .navigationDestination(for: String.self) { entityId in
                     // Unterscheide, welcher Typ von ID übergeben wurde
                     if entityId.starts(with: "debtor-") {
                          DebtorDetailView(debtorId: entityId)
                     } else {
                          // Fallback oder Ziel für andere ID-Typen
                          Text("Unbekanntes Navigationsziel für ID: \(entityId)")
                     }
                 }
                 // --- ENDE KORREKTUR/ERGÄNZUNG ---
            }
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}

#Preview { /* ... wie zuvor ... */ }
