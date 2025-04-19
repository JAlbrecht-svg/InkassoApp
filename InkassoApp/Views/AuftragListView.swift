import SwiftUI

struct AuftragListView: View {
    @StateObject private var viewModel = AuftragListViewModel()
    var mandantIdFilter: String?

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Lade Aufträge...")
            } else if let error = viewModel.errorMessage {
                 VStack {
                     Text("Fehler: \(error)").foregroundColor(.red).padding()
                     Button("Erneut versuchen") { Task { await viewModel.loadAuftraege() } }
                 }
            } else {
                List {
                     if viewModel.auftraege.isEmpty {
                         Text(mandantIdFilter == nil ? "Keine Aufträge vorhanden." : "Keine Aufträge für diesen Mandanten vorhanden.")
                             .foregroundColor(.secondary)
                     }
                    ForEach(viewModel.auftraege) { auftrag in
                        NavigationLink(value: auftrag) {
                             VStack(alignment: .leading) {
                                 Text(auftrag.name).font(.headline)
                                 Text("Sub-ID: \(auftrag.auftragSubId)")
                                 // TODO: Mandantennamen anzeigen
                                 Text("Mandant ID: \(auftrag.mandantId)").font(.caption).foregroundColor(.secondary)
                             }
                        }
                    }
                    // TODO: onDelete
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle(mandantIdFilter == nil ? "Alle Aufträge" : "Aufträge") // Titel anpassen
        .navigationDestination(for: Auftrag.self) { auftrag in
            AuftragDetailView(auftrag: auftrag)
        }
        .toolbar {
             ToolbarItem {
                  Button {
                      // TODO: Sheet zum Erstellen
                  } label: { Label("Neu", systemImage: "plus") }
                  .help("Neuen Auftrag erstellen")
             }
            ToolbarItem {
                Button { Task { await viewModel.loadAuftraege() } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
             viewModel.mandantIdFilter = mandantIdFilter
             // Immer laden, da Filter sich ändern kann
             await viewModel.loadAuftraege()
        }
         // Korrigierte Alert-Signatur
        .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
    }
}

struct AuftragDetailView: View {
    let auftrag: Auftrag
    // TODO: DetailViewModel

    var body: some View {
        Form {
            Text("ID: \(auftrag.id)").font(.caption).foregroundColor(.secondary)
            Text("Mandant ID: \(auftrag.mandantId)") // TODO: Name anzeigen
            Text("Sub-ID: \(auftrag.auftragSubId)")
            Text("Name: \(auftrag.name)")
            Text("Workflow ID: \(auftrag.workflowId ?? "Keiner")") // TODO: Name anzeigen
            Text("Start: \(formattedDateOptional(auftrag.startDate))") // Globale Funktion verwenden
            Text("Ende: \(formattedDateOptional(auftrag.endDate))")   // Globale Funktion verwenden
            Text("Notizen: \(auftrag.notes ?? "-")")
            Text("Erstellt: \(formattedDate(auftrag.createdAt))")     // Globale Funktion verwenden
            Text("Geändert: \(formattedDate(auftrag.updatedAt))")   // Globale Funktion verwenden

            // TODO: Verknüpfte Fälle anzeigen/laden (NavigationLink zu CaseListView mit Filter?)
            Section("Zugehörige Fälle") {
                 NavigationLink("Fälle anzeigen") {
                      CaseListView(auftragIdFilter: auftrag.id)
                 }
            }
        }
        .padding()
        .navigationTitle("Auftrag: \(auftrag.name)")
         .toolbar {
             ToolbarItem { Button("Bearbeiten") { /* TODO */ } }
         }
    }
}

#Preview {
    NavigationView {
        AuftragListView()
    }
}
