import SwiftUI

struct CaseListView: View {
    @StateObject private var viewModel = CaseListViewModel()
    @State private var localSearchTerm: String = ""
    @State private var selectedStatus: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            // --- Filter- und Suchleiste ---
            HStack {
                 TextField("Suche (Aktenz., Schuldner...)", text: $localSearchTerm)
                     .textFieldStyle(.roundedBorder)
                     .onChange(of: localSearchTerm) { _, newValue in
                         viewModel.searchTextChanged(newValue)
                     }

                 Picker("Status", selection: $selectedStatus) {
                     ForEach(viewModel.statusOptions) { option in
                         Text(option.name).tag(option.id)
                     }
                 }
                 .frame(maxWidth: 200)
                 .onChange(of: selectedStatus) { _, newValue in
                     viewModel.statusFilter = newValue
                     viewModel.statusFilterChanged()
                 }
                 Spacer()
                 Button { Task { await viewModel.loadCases() } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                 .disabled(viewModel.isLoading)
            }
            .padding([.horizontal, .top])
            Divider()

            // --- Liste ---
            List {
                if viewModel.isLoading && viewModel.cases.isEmpty {
                     ProgressView("Lade Fälle...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !viewModel.isLoading && viewModel.cases.isEmpty {
                     Text("Keine Fälle für aktuelle Filter gefunden.")
                         .foregroundColor(.secondary)
                         .frame(maxWidth: .infinity, alignment: .center)
                         .padding()
                } else {
                     ForEach(viewModel.cases) { caseItem in
                        // Der Link, der den Wert setzt und Navigation auslöst
                         NavigationLink(value: caseItem) {
                             CaseListRow(caseItem: caseItem) // Eigene Row-View
                         }
                     }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            // --- KORREKTUR/BESTÄTIGUNG: Ziel hier definieren ---
            // Dieses Ziel wird innerhalb des NavigationStacks (aus ContentView) angezeigt
            .navigationDestination(for: Case.self) { caseItem in
                // Übergabe des listViewModel für Refresh-Möglichkeit
                CaseDetailView(listViewModel: viewModel, caseToLoad: caseItem)
            }
            // --- ENDE KORREKTUR/BESTÄTIGUNG ---
            .overlay { // Fehler-Overlay
                 if let error = viewModel.errorMessage, viewModel.showingAlert {
                    VStack { Text("Fehler").font(.headline); Text(error); Button("OK") { viewModel.showingAlert = false; viewModel.errorMessage = nil }.padding(.top) }
                    .padding().background(.regularMaterial).cornerRadius(10).shadow(radius: 5)
                 }
            }
        }
        .navigationTitle("Fallübersicht") // Titel für diese Ansicht
        .toolbar { // Toolbar für diese Ansicht
            ToolbarItem {
                 Button { /* TODO: Sheet für neuen Fall */ } label: { Label("Neu", systemImage: "plus.circle") }
                 .help("Neuen Fall erstellen")
            }
            // Der Refresh-Button ist jetzt oben in der Filterleiste
        }
        .task { // Beim ersten Erscheinen laden
            // Wende initiale Filter an, falls welche übergeben wurden (hier nicht der Fall)
            viewModel.statusFilter = selectedStatus // Initialen Wert setzen
            if viewModel.cases.isEmpty {
                await viewModel.loadCases()
            }
        }
    }
    // Löschfunktion bleibt wie zuvor (auskommentiert oder entfernt)
}

// CaseListRow bleibt wie zuvor
struct CaseListRow: View {
     let caseItem: Case
     var body: some View {
         HStack {
             VStack(alignment: .leading, spacing: 4) { /* ... wie zuvor ... */
                 Text(caseItem.caseReference).font(.headline)
                 Text("Schuldner: \(caseItem.debtorName ?? caseItem.debtorId)").font(.subheadline)
                 Text("Mandant: \(caseItem.mandantName ?? "...") (\(caseItem.mandantNumber ?? "?"))").font(.caption).foregroundColor(.secondary)
                 Text("Auftrag: \(caseItem.auftragName ?? caseItem.auftragId)").font(.caption).foregroundColor(.secondary)
             }
             Spacer()
             VStack(alignment: .trailing) { /* ... wie zuvor ... */
                  Text(caseItem.outstandingAmount, format: .currency(code: caseItem.currency)).font(.body.weight(.medium))
                  Text(caseItem.status.uppercased()).font(.system(size: 10, weight: .medium)).padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5)).background(statusColor(caseItem.status)).foregroundColor(.white).clipShape(Capsule())
                  Text("Fällig: \(formattedDateOptional(caseItem.dueDate))").font(.caption).foregroundColor(.secondary)
             }
         }
         .padding(.vertical, 4)
     }
      private func statusColor(_ status: String) -> Color { /* ... wie zuvor ... */
          switch status.lowercased() { case "open": return .blue; case "reminder_1", "reminder_2", "payment_plan", "contested": return .orange; case "paid": return .green; case "legal_internal", "legal_external", "legal": return .purple; case "closed_uncollectible": return .gray; default: return .secondary }
      }
 }

// Preview bleibt wie zuvor
#Preview {
    NavigationView {
        CaseListView()
    }
}
