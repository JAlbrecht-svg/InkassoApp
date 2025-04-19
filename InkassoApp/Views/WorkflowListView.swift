import SwiftUI

struct WorkflowListView: View {
    @StateObject private var viewModel = WorkflowListViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Lade Workflows...")
            } else if let error = viewModel.errorMessage {
                 VStack {
                     Text("Fehler: \(error)").foregroundColor(.red).padding()
                     Button("Erneut versuchen") { Task { await viewModel.loadWorkflows() } }
                 }
            } else {
                List {
                     if viewModel.workflows.isEmpty {
                         Text("Keine Workflow-Vorlagen vorhanden.")
                             .foregroundColor(.secondary)
                     }
                    ForEach(viewModel.workflows) { workflow in
                        NavigationLink(value: workflow) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(workflow.name).font(.headline)
                                    Text(workflow.category.capitalized).font(.subheadline)
                                }
                                Spacer()
                                Text(workflow.mandantId == nil ? "Global" : "Mandantenspez.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    // TODO: Löschen hinzufügen? (.onDelete)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Workflow Vorlagen")
        .navigationDestination(for: Workflow.self) { workflow in
            WorkflowDetailView(workflow: workflow)
        }
        .toolbar {
             ToolbarItem {
                  Button {
                      // TODO: Sheet/Navigation zum Erstellen eines neuen Workflows
                  } label: { Label("Neu", systemImage: "plus") }
                  .help("Neue Workflow Vorlage erstellen")
             }
            ToolbarItem {
                Button { Task { await viewModel.loadWorkflows() } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            if viewModel.workflows.isEmpty {
                await viewModel.loadWorkflows()
            }
        }
        // Korrigierte Alert-Signatur
        .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
    }
}

struct WorkflowDetailView: View {
    let workflow: Workflow
    // TODO: DetailViewModel für Bearbeitung

    var body: some View {
        Form {
             Text("Name: \(workflow.name)")
             Text("Kategorie: \(workflow.category.capitalized)")
             Text("Beschreibung: \(workflow.description ?? "-")")
             Text("Mandant: \(workflow.mandantId ?? "Global")") // TODO: Mandantennamen laden?
             Text("ID: \(workflow.id)").font(.caption)
             Text("Erstellt: \(formattedDate(workflow.createdAt))") // Globale Funktion
             Text("Geändert: \(formattedDate(workflow.updatedAt))") // Globale Funktion

             Section("Workflow Schritte") {
                 NavigationLink {
                      WorkflowStepListView(workflowId: workflow.id, workflowName: workflow.name)
                 } label: {
                      Text("Schritte anzeigen und bearbeiten")
                 }
             }
             // TODO: Bearbeitungsfelder
        }
        .padding()
        .navigationTitle("Workflow: \(workflow.name)")
        .toolbar { // TODO: Bearbeiten/Speichern Buttons
             ToolbarItem { Button("Bearbeiten") { /* TODO */ } }
        }
    }
}

#Preview {
    NavigationView {
        WorkflowListView()
    }
}
