import SwiftUI

struct WorkflowStepListView: View {
    @StateObject private var viewModel = WorkflowStepListViewModel()
    let workflowId: String
    let workflowName: String

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Lade Schritte...")
            } else if let error = viewModel.errorMessage {
                 VStack {
                     Text("Fehler: \(error)").foregroundColor(.red).padding()
                     Button("Erneut versuchen") { Task { await viewModel.loadSteps(workflowId: workflowId) } }
                 }
            } else {
                List {
                     if viewModel.steps.isEmpty {
                        Text("Keine Schritte für diesen Workflow definiert.")
                            .foregroundColor(.secondary)
                    }
                    // Steps sollten bereits sortiert vom ViewModel kommen
                    ForEach(viewModel.steps) { step in
                        NavigationLink(value: step) {
                            HStack {
                                Text("\(step.stepOrder).").bold().frame(width: 30, alignment: .trailing) // Feste Breite für Nummer
                                VStack(alignment: .leading) {
                                    Text(step.name)
                                    Text("Aktion: \(step.actionToPerform), Trigger: \(step.triggerType) (\(step.triggerValue))")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                if step.feeToCharge > 0 {
                                     Text(String(format: "+%.2f", step.feeToCharge)) // Währung?
                                         .font(.caption)
                                         .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    // TODO: Löschen hinzufügen? (.onDelete)
                    // TODO: Drag and Drop zum Neusortieren? (Komplexer)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Schritte: \(workflowName)")
        .navigationDestination(for: WorkflowStep.self) { step in
            WorkflowStepDetailView(step: step)
        }
        .toolbar {
             ToolbarItem {
                  Button {
                      // TODO: Sheet/Navigation zum Erstellen eines neuen Schritts
                  } label: { Label("Neuer Schritt", systemImage: "plus") }
                  .help("Neuen Schritt hinzufügen")
             }
            ToolbarItem {
                Button { Task { await viewModel.loadSteps(workflowId: workflowId) } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadSteps(workflowId: workflowId)
        }
         // Korrigierte Alert-Signatur
         .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
    }
}

struct WorkflowStepDetailView: View {
    @State var step: WorkflowStep // State für Bearbeitung
     // TODO: DetailViewModel für Bearbeitung

    var body: some View {
        Form {
            TextField("Name:", text: $step.name)
            Stepper("Reihenfolge: \(step.stepOrder)", value: $step.stepOrder, in: 1...100) // Beispiel Range

            // TODO: Bessere Picker für trigger_type und action_to_perform (aus KV laden?)
            TextField("Trigger Typ:", text: $step.triggerType)
            Stepper("Trigger Wert (Tage): \(step.triggerValue)", value: $step.triggerValue, in: 0...365)

            TextField("Aktion:", text: $step.actionToPerform)
            TextField("Vorlagen-ID:", text: Binding(
                get: { step.templateIdentifier ?? ""},
                set: { step.templateIdentifier = $0.isEmpty ? nil : $0 }
            ))
            TextField("Gebühr:", value: $step.feeToCharge, format: .number) // TODO: Währung?
                .keyboardType(.decimalPad)
             TextField("Zielstatus Case:", text: Binding(
                 get: { step.targetCaseStatus ?? ""},
                 set: { step.targetCaseStatus = $0.isEmpty ? nil : $0 }
             ))

             Group { // System-Infos
                 Text("ID: \(step.id)").font(.caption)
                 Text("Workflow ID: \(step.workflowId)").font(.caption)
                 Text("Erstellt: \(formattedDate(step.createdAt))") // Globale Funktion
                 Text("Geändert: \(formattedDate(step.updatedAt))") // Globale Funktion
             }.foregroundColor(.secondary)

        }
        .padding()
        .navigationTitle("Schritt Bearbeiten") // Titel anpassen
         .toolbar { // TODO: Speichern Button
             ToolbarItem { Button("Speichern") { /* TODO: Save step */ } }
         }
    }
}

#Preview {
    NavigationView {
        WorkflowStepListView(workflowId: "wf-preview", workflowName: "Test Workflow")
    }
}
