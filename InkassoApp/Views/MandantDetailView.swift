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
                // TODO: Input Formatter hinzufügen für 4 Ziffern

            TextField("Name:", text: $viewModel.mandant.name)
                .disabled(viewModel.isLoading)

            TextField("Ansprechpartner:", text: Binding(
                get: { viewModel.mandant.contactPerson ?? "" },
                set: { viewModel.mandant.contactPerson = $0.isEmpty ? nil : $0 }
            ))
            .disabled(viewModel.isLoading)

            TextField("E-Mail:", text: Binding(
                get: { viewModel.mandant.email ?? "" },
                set: { viewModel.mandant.email = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .disabled(viewModel.isLoading)

            TextField("Telefon:", text: Binding(
                 get: { viewModel.mandant.phone ?? "" },
                 set: { viewModel.mandant.phone = $0.isEmpty ? nil : $0 }
             ))
             .textFieldStyle(.roundedBorder)
             .keyboardType(.phonePad)
             .textContentType(.telephoneNumber)
             .disabled(viewModel.isLoading)

            Picker("Aktiv:", selection: $viewModel.mandant.isActive) {
                Text("Ja").tag(1)
                Text("Nein").tag(0)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 150) // Breite des Pickers begrenzen
            .disabled(viewModel.isLoading)


            if !viewModel.isNew {
                 Group {
                    Text("Erstellt am: \(formattedDate(viewModel.mandant.createdAt))")
                    Text("Geändert am: \(formattedDate(viewModel.mandant.updatedAt))")
                 }
                 .font(.caption)
                 .foregroundColor(.secondary)
                 .padding(.top)
            }

             // Ladeanzeige und Fehleranzeige
             if viewModel.isLoading {
                 ProgressView("Speichern...")
                     .padding(.top)
             }
             // Fehlermeldung wird jetzt über den Alert angezeigt
             // if let errorMessage = viewModel.errorMessage { ... }

        }
        .padding()
        .navigationTitle(viewModel.isNew ? "Neuer Mandant" : "Mandant Bearbeiten")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(viewModel.isNew ? "Verwerfen" : (viewModel.hasChanges ? "Abbrechen" : "Schließen")) {
                    if viewModel.hasChanges && !viewModel.isNew {
                         viewModel.resetChanges() // Änderungen zurücksetzen
                    }
                    dismiss()
                }
                 // Deaktiviere "Verwerfen" während des Ladens
                 .disabled(viewModel.isLoading && viewModel.isNew)
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
        // Alert für Fehler beim Speichern
        .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK") { viewModel.errorMessage = nil } // Fehler ausblenden bei OK
        } message: { messageText in
             Text(messageText)
        }
    }
}

// Previews wie zuvor
#Preview("Edit Existing") { ... }
#Preview("Create New") { ... }
