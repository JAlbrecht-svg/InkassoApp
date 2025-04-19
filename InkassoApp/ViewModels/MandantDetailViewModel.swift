import SwiftUI

struct MandantDetailView: View {
    @StateObject private var viewModel: MandantDetailViewModel
    @Environment(\.dismiss) var dismiss

    init(listViewModel: MandantenViewModel, mandantToEdit: Mandant?) {
        if let mandant = mandantToEdit {
            _viewModel = StateObject(wrappedValue: MandantDetailViewModel(mandant: mandant, listViewModel: listViewModel))
        } else {
            _viewModel = StateObject(wrappedValue: MandantDetailViewModel(listViewModel: listViewModel))
        }
    }

    var body: some View {
        Form {
            TextField("Mandantennr. (4-stellig):", text: $viewModel.mandant.mandantNumber)
                .disabled(viewModel.isLoading)

            TextField("Name:", text: $viewModel.mandant.name)
                .disabled(viewModel.isLoading)

            TextField("Ansprechpartner:", text: Binding(
                get: { viewModel.mandant.contactPerson ?? "" },
                set: { viewModel.mandant.contactPerson = $0.isEmpty ? nil : $0 }
            ))
            .disabled(viewModel.isLoading)

            // --- Korrigierte Modifier ---
            TextField("E-Mail:", text: Binding(
                get: { viewModel.mandant.email ?? "" },
                set: { viewModel.mandant.email = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder) // Gilt für TextField
            .keyboardType(.emailAddress)    // Gilt für TextField
            .textContentType(.emailAddress) // Gilt für TextField
            .autocapitalization(.none)    // Gilt für TextField
            .disabled(viewModel.isLoading)

            TextField("Telefon:", text: Binding(
                 get: { viewModel.mandant.phone ?? "" },
                 set: { viewModel.mandant.phone = $0.isEmpty ? nil : $0 }
             ))
             .textFieldStyle(.roundedBorder) // Gilt für TextField
             .keyboardType(.phonePad)      // Gilt für TextField
             .textContentType(.telephoneNumber) // Gilt für TextField
             .disabled(viewModel.isLoading)
            // --- Ende Korrekturen ---

            Picker("Aktiv:", selection: $viewModel.mandant.isActive) {
                Text("Ja").tag(1)
                Text("Nein").tag(0)
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isLoading)

            if !viewModel.isNew {
                 Group {
                    // Verwende die globale Funktion
                    Text("Erstellt am: \(formattedDate(viewModel.mandant.createdAt))")
                    Text("Geändert am: \(formattedDate(viewModel.mandant.updatedAt))")
                 }
                 .font(.caption)
                 .foregroundColor(.secondary)
            }

             if viewModel.isLoading {
                 ProgressView("Speichern...")
                     .padding(.top)
             }
             if let errorMessage = viewModel.errorMessage {
                 Text("Fehler: \(errorMessage)")
                     .foregroundColor(.red)
                     .padding(.top)
             }
        }
        .padding()
        .navigationTitle(viewModel.isNew ? "Neuer Mandant" : "Mandant Bearbeiten")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(viewModel.isNew ? "Verwerfen" : "Abbrechen") {
                    if viewModel.canSave && !viewModel.isNew {
                         viewModel.resetChanges()
                    }
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    Task {
                        let success = await viewModel.saveMandant()
                        if success {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isLoading)
            }
        }
        .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK") { viewModel.errorMessage = nil }
        } message: { message in
             Text(message)
        }
    }

    // Entferne die lokale formattedDate Funktion hier, nutze die globale.
}

// ... (Previews bleiben gleich) ...
