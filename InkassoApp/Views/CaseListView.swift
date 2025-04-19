import SwiftUI

struct CaseListView: View {
    @StateObject private var viewModel = CaseListViewModel()
    // Lokaler State für UI-gebundene Filterwerte
    @State private var localSearchTerm: String = ""
    @State private var selectedStatus: String = "" // Leerer String = Alle

    var body: some View {
        VStack(alignment: .leading) {
            // --- Filter- und Suchleiste ---
            HStack {
                 // Suchfeld
                 TextField("Suche (Aktenz., Schuldner...)", text: $localSearchTerm)
                     .textFieldStyle(.roundedBorder)
                     .onChange(of: localSearchTerm) { _, newValue in
                         viewModel.searchTextChanged(newValue) // Informiert ViewModel über Änderung
                     }

                 // Status Filter Picker
                 Picker("Status", selection: $selectedStatus) {
                     ForEach(viewModel.statusOptions) { option in
                         Text(option.name).tag(option.id) // id ist der Wert (z.B. "open", "")
                     }
                 }
                 .frame(maxWidth: 200) // Breite begrenzen
                 .onChange(of: selectedStatus) { _, newValue in
                     viewModel.statusFilter = newValue // ViewModel direkt setzen
                     viewModel.statusFilterChanged() // Löst Neuladen aus
                 }

                 Spacer() // Schiebt Elemente nach links

                 Button {
                     // Manuelles Neuladen (zusätzlich zu Filtern/Suche)
                     Task { await viewModel.loadCases() }
                 } label: {
                     Label("Aktualisieren", systemImage: "arrow.clockwise")
                 }
                 .disabled(viewModel.isLoading)

            }
            .padding([.horizontal, .top])

            Divider()

            // --- Liste ---
            List {
                if viewModel.isLoading && viewModel.cases.isEmpty {
                    // Zeige Ladeindikator nur, wenn Liste komplett leer ist
                     ProgressView("Lade Fälle...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !viewModel.isLoading && viewModel.cases.isEmpty {
                     Text("Keine Fälle für aktuelle Filter gefunden.")
                         .foregroundColor(.secondary)
                         .frame(maxWidth: .infinity, alignment: .center)
                         .padding()
                } else {
                     ForEach(viewModel.cases) { caseItem in
                         NavigationLink(value: caseItem) {
                             CaseListRow(caseItem: caseItem) // Eigene Row-View für Übersicht
                         }
                     }
                      // TODO: Löschen wird nicht empfohlen
                }

                 // Ladeanzeige am Ende, wenn mehr Daten geladen werden (Paginierung)
                 // if viewModel.isLoading && !viewModel.cases.isEmpty {
                 //     ProgressView().frame(maxWidth: .infinity, alignment: .center).padding()
                 // }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .overlay { // Zeige Fehler als Overlay
                 if let error = viewModel.errorMessage, viewModel.showingAlert {
                     VStack {
                         Text("Fehler")
                             .font(.headline)
                         Text(error)
                         Button("OK") { viewModel.showingAlert = false; viewModel.errorMessage = nil }
                             .padding(.top)
                     }
                     .padding()
                     .background(.ultraThinMaterial)
                     .cornerRadius(10)
                     .shadow(radius: 5)
                 }
            }


        }
        .navigationTitle("Fallübersicht")
        .navigationDestination(for: Case.self) { caseItem in
            // Detailansicht mit Übergabe des ListViewModels für Refresh
            CaseDetailView(listViewModel: viewModel, caseToLoad: caseItem)
        }
        .task { // Beim ersten Erscheinen laden
            if viewModel.cases.isEmpty {
                await viewModel.loadCases()
            }
        }
        // Alert wird nicht mehr benötigt, da als Overlay angezeigt
        // .alert("Fehler", ...)
    }
}

// Eigene View für eine Zeile in der Liste -> Bessere Struktur
struct CaseListRow: View {
    let caseItem: Case

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(caseItem.caseReference).font(.headline)
                Text("Schuldner: \(caseItem.debtorName ?? caseItem.debtorId)")
                    .font(.subheadline)
                Text("Mandant: \(caseItem.mandantName ?? "...") (\(caseItem.mandantNumber ?? "?"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                 Text("Auftrag: \(caseItem.auftragName ?? caseItem.auftragId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                 // Formatierung für Währung über NumberFormatter (lokalisiert)
                 Text(caseItem.outstandingAmount, format: .currency(code: caseItem.currency))
                    .font(.body.weight(.medium))

                 Text(caseItem.status.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
                    .background(statusColor(caseItem.status))
                    .foregroundColor(.white)
                    .clipShape(Capsule()) // Abgerundete Ecken

                 Text("Fällig: \(formattedDateOptional(caseItem.dueDate))") // Globale Funktion
                     .font(.caption)
                     .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4) // Etwas vertikaler Abstand
    }

     // Helfer für Statusfarbe
     private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
            case "open": return .blue
            case "reminder_1", "reminder_2", "payment_plan", "contested": return .orange
            case "paid": return .green
            case "legal_internal", "legal_external", "legal": return .purple
            case "closed_uncollectible": return .gray
            default: return .secondary
        }
    }
}


#Preview {
    NavigationView {
        CaseListView()
    }
}
