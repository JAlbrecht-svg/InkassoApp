import SwiftUI

struct ActionListView: View {
    @StateObject private var viewModel = ActionListViewModel()
    let caseId: String
    var caseReference: String?

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Lade Aktionen...")
            } else if let error = viewModel.errorMessage {
                 VStack {
                     Text("Fehler: \(error)").foregroundColor(.red).padding()
                     Button("Erneut versuchen") { Task { await viewModel.loadActions(caseId: caseId) } }
                 }
            } else {
                List {
                     if viewModel.actions.isEmpty {
                        Text("Keine Aktionen vorhanden.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(viewModel.actions) { action in
                        NavigationLink(value: action) {
                            HStack {
                                VStack(alignment: .leading) {
                                     Text(action.actionType) // TODO: Besser lesbaren Namen anzeigen
                                         .font((action.notes != nil && !action.notes!.isEmpty) ? .headline : .body)
                                     Text(formattedDate(action.actionDate)).font(.caption).foregroundColor(.secondary) // Globale Funktion
                                      if let notes = action.notes, !notes.isEmpty {
                                          Text(notes)
                                              .font(.caption)
                                              .lineLimit(1)
                                              .foregroundColor(.gray)
                                      }
                                }
                                Spacer()
                                if action.cost > 0 {
                                     Text(String(format: "+%.2f", action.cost)) // TODO: Währung?
                                         .font(.caption)
                                         .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    // TODO: Löschen hinzufügen? (.onDelete)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle(caseReference != nil ? "Aktionen: \(caseReference!)" : "Aktionen")
        .navigationDestination(for: Action.self) { action in
            ActionDetailView(action: action)
        }
        .toolbar {
            ToolbarItem {
                 Button {
                     // TODO: Sheet/Navigation zum Erstellen einer neuen Aktion
                 } label: { Label("Neue Aktion", systemImage: "plus.message") }
                 .help("Neue Aktion erfassen")
            }
            ToolbarItem {
                Button { Task { await viewModel.loadActions(caseId: caseId) } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadActions(caseId: caseId)
        }
         // Korrigierte Alert-Signatur
         .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
    }
}

struct ActionDetailView: View {
    // Verwende @State, um Bearbeitung der Notizen zu ermöglichen
    @State var action: Action
    // TODO: DetailViewModel für Speichern der Notizen

    var body: some View {
        Form {
             Text("Typ: \(action.actionType)")
             Text("Datum: \(formattedDate(action.actionDate))") // Globale Funktion
             Text("Kosten: \(String(format: "%.2f", action.cost))") // Währung?
             Text("Benutzer: \(action.createdByUser ?? "-")")

             Section("Notizen") {
                 TextEditor(text: Binding( // Binding für optionale Notizen
                    get: { action.notes ?? "" },
                    set: { action.notes = $0.isEmpty ? nil : $0 }
                 ))
                 .frame(minHeight: 100, maxHeight: 300)
                 .border(Color.secondary.opacity(0.5)) // Rand zur besseren Sichtbarkeit
             }

             Text("ID: \(action.id)").font(.caption)
             Text("Erstellt am: \(formattedDate(action.createdAt))") // Globale Funktion
        }
        .padding()
        .navigationTitle("Aktion: \(action.actionType)")
         .toolbar {
             ToolbarItem { Button("Notiz Speichern") { /* TODO: Save action notes (call ViewModel) */ } }
         }
    }
}

#Preview {
    NavigationView {
        ActionListView(caseId: "case-preview", caseReference: "AZ-PREVIEW-001")
    }
}
