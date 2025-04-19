import SwiftUI

struct CaseListView: View {
    @StateObject private var viewModel = CaseListViewModel()
    var auftragIdFilter: String?
    var debtorIdFilter: String?
    // TODO: Status Filter UI hinzufügen

    var body: some View {
        VStack {
            // TODO: Filter UI Elemente hier hinzufügen
            if viewModel.isLoading {
                ProgressView("Lade Fälle...")
            } else if let error = viewModel.errorMessage {
                 VStack {
                     Text("Fehler: \(error)").foregroundColor(.red).padding()
                     Button("Erneut versuchen") { Task { await viewModel.loadCases() } }
                 }
            } else {
                List {
                    if viewModel.cases.isEmpty {
                        Text("Keine Fälle für aktuelle Filter gefunden.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(viewModel.cases) { caseItem in
                        NavigationLink(value: caseItem) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(caseItem.caseReference).font(.headline)
                                    Text("Schuldner: \(caseItem.debtorName ?? caseItem.debtorId)") // Namen aus API nutzen
                                    Text("Mandant: \(caseItem.mandantName ?? "...")").font(.caption).foregroundColor(.secondary) // Namen aus API nutzen
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(String(format: "%.2f \(caseItem.currency)", caseItem.outstandingAmount))
                                    Text(caseItem.status.uppercased())
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                                        .background(statusColor(caseItem.status))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    // TODO: Löschen wird nicht empfohlen
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Fälle")
        .navigationDestination(for: Case.self) { caseItem in
            CaseDetailView(caseItem: caseItem)
        }
        .toolbar {
             ToolbarItem {
                  Button {
                      // TODO: Sheet/Navigation zum Erstellen eines neuen Falls
                  } label: { Label("Neu", systemImage: "plus.circle") } // Anderes Icon?
                  .help("Neuen Fall erstellen")
             }
            ToolbarItem {
                Button { Task { await viewModel.loadCases() } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            viewModel.auftragIdFilter = auftragIdFilter
            viewModel.debtorIdFilter = debtorIdFilter
            // viewModel.statusFilter = ... // Von UI setzen
            // TODO: Nur laden wenn Filter geändert oder Liste leer?
            await viewModel.loadCases()
        }
         // Korrigierte Alert-Signatur
         .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
    }

    // Helfer für Statusfarbe (wie zuvor)
    private func statusColor(_ status: String) -> Color {
        // ... (Implementierung von oben) ...
        switch status.lowercased() {
        case "open": return .blue
        case "reminder_1", "reminder_2": return .orange
        case "paid": return .green
        case "legal": return .purple
        case "closed_uncollectible": return .gray
        default: return .secondary
        }
    }
}

struct CaseDetailView: View {
    let caseItem: Case
    // TODO: DetailViewModel für Bearbeitung

    var body: some View {
        Form {
            Section("Basisdaten") {
                Text("ID: \(caseItem.id)").font(.caption)
                Text("Aktenzeichen: \(caseItem.caseReference)")
                Text("Status: \(caseItem.status.uppercased())")
                 // TODO: Verknüpfte Objekte verlinken
                 NavigationLink(value: caseItem.debtorId) { // Beispiel: Navigiere zu Debtor Detail?
                      Text("Schuldner: \(caseItem.debtorName ?? caseItem.debtorId)")
                 }
                 NavigationLink(value: caseItem.auftragId) { // Beispiel: Navigiere zu Auftrag Detail?
                    Text("Auftrag: \(caseItem.auftragName ?? caseItem.auftragId)")
                 }
                 Text("Mandant: \(caseItem.mandantName ?? "...")") // Kein direkter Link hier
            }
            Section("Beträge (\(caseItem.currency))") {
                 Text("Original: \(String(format: "%.2f", caseItem.originalAmount))")
                 Text("Gebühren: \(String(format: "%.2f", caseItem.feesAmount))")
                 Text("Zinsen: \(String(format: "%.2f", caseItem.interestAmount))")
                 Text("Gezahlt: \(String(format: "%.2f", caseItem.paidAmount))")
                 Text("Offen: \(String(format: "%.2f", caseItem.outstandingAmount))").bold()
            }
             Section("Daten") {
                 Text("Eröffnet am: \(formattedDate(caseItem.openedAt))") // Globale Funktion
                 Text("Fällig am: \(formattedDateOptional(caseItem.dueDate))") // Globale Funktion
                 Text("Geschlossen am: \(formattedDateOptional(caseItem.closedAt))") // Globale Funktion
             }
             Section("Grund") {
                  Text(caseItem.reasonForClaim ?? "-")
             }

             // Sektionen für Zahlungen und Aktionen
             Section("Zahlungen") {
                  NavigationLink("Zahlungen anzeigen (\(/* TODO: Anzahl laden? */ 0 ))") {
                       PaymentListView(caseId: caseItem.id)
                  }
             }
             Section("Aktionen") {
                  NavigationLink("Aktionen anzeigen (\(/* TODO: Anzahl laden? */ 0 ))") {
                       ActionListView(caseId: caseItem.id)
                  }
             }
        }
        .padding()
        .navigationTitle("Fall: \(caseItem.caseReference)")
        // TODO: Implementiere Navigation für Debtor/Auftrag
        // .navigationDestination(for: String.self) { id in ... }
         .toolbar {
             ToolbarItemGroup { // Gruppe für mehrere Buttons
                 Button { /* TODO: Neue Zahlung */ } label: { Label("Zahlung", systemImage: "eurosign.circle") }
                 Button { /* TODO: Neue Aktion */ } label: { Label("Aktion", systemImage: "plus.message") }
                 Button("Bearbeiten") { /* TODO */ }
             }
         }
    }
}

#Preview {
    NavigationView {
        // Mock Data für Preview
        let mockCase = Case(id: "case-prev", debtorId: "d1", auftragId: "a1", caseReference: "AZ-PREV-001", originalAmount: 100.50, feesAmount: 10, interestAmount: 2.5, paidAmount: 20, currency: "EUR", status: "reminder_1", reasonForClaim: "Testrechnung", openedAt: Date().ISO8601Format(), dueDate: Date().ISO8601Format(), closedAt: nil, createdAt: Date().ISO8601Format(), updatedAt: Date().ISO8601Format(), debtorName: "Max Schuldner", auftragName: "Test Auftrag", mandantName: "Test Mandant")
        CaseDetailView(caseItem: mockCase)
    }
}
