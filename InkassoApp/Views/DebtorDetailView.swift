// Views/DebtorDetailView.swift
import SwiftUI

struct DebtorDetailView: View {
    @StateObject private var viewModel: DebtorDetailViewModel
    let debtorIdToLoad: String
    @Environment(\.dismiss) var dismiss

    init(debtorId: String) {
        self.debtorIdToLoad = debtorId
        _viewModel = StateObject(wrappedValue: DebtorDetailViewModel(debtorId: debtorId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.debtor == nil {
                 ProgressView("Lade Schuldner...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let _ = viewModel.debtor { // Nur Form anzeigen, wenn Debtor geladen ist
                Form {
                    // Verwende die aufgeteilten Sektionen
                    basicDataSection()
                    contactSection()
                    addressSection()
                    notesSection()
                    systemSection() // Verwendet jetzt viewModel.isNewDebtor
                }
                .disabled(viewModel.isLoading && viewModel.hasChanges) // Deaktiviere nur beim Speichern
                .overlay { if viewModel.isLoading && viewModel.hasChanges { ProgressView("Speichern...") } }
            } else if let error = viewModel.errorMessage {
                 VStack { Text("Fehler").font(.headline); Text(error).foregroundColor(.red); Button("Erneut laden") { Task { await viewModel.loadDebtor() } }.padding(.top) }
                 .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else { Text("Schuldnerdaten nicht verfügbar.") }
        }
        .padding()
        .navigationTitle(viewModel.debtor == nil ? "Lade..." : (viewModel.isNewDebtor ? "Neuer Schuldner?" : (viewModel.hasChanges ? "Bearbeiten: " : "") + (viewModel.debtor!.name.isEmpty ? "Unbenannt" : viewModel.debtor!.name)))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                 Button(viewModel.hasChanges ? "Änderungen verwerfen" : "Schließen") { if viewModel.hasChanges { viewModel.resetChanges() }; dismiss() }
                 .disabled(viewModel.isLoading && viewModel.hasChanges) // Deaktiviere während Speichern
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { Task { let success = await viewModel.saveDebtor() } }
                .disabled(!viewModel.canSave || viewModel.isLoading)
            }
        }
        .task { if viewModel.debtor == nil { await viewModel.loadDebtor() } }
        .alert(viewModel.errorMessage == nil ? "Info" : "Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage ?? "Aktion erfolgreich.") { _ in Button("OK"){ viewModel.errorMessage = nil } } message: { messageText in Text(messageText) }
    }

    // --- Aufgeteilte Sektionen mit korrekten Modifiern ---
    @ViewBuilder
    private func basicDataSection() -> some View {
        if viewModel.debtor != nil {
            Section("Stammdaten") {
                TextField("Name:", text: $viewModel.debtor.bound.name)
                    .textFieldStyle(.roundedBorder) // Optional: Stil explizit setzen
                Picker("Typ:", selection: $viewModel.debtor.bound.debtorType) {
                    Text("Privat").tag("private")
                    Text("Firma").tag("business")
                }
                .pickerStyle(.segmented).frame(maxWidth: 150)
            }
        }
    }

     @ViewBuilder
     private func contactSection() -> some View {
         if viewModel.debtor != nil {
            Section("Kontakt") {
                 TextField("E-Mail:", text: $viewModel.debtor.bound.email.withDefault(""))
                      .textFieldStyle(.roundedBorder) // Korrekt hier
                      .keyboardType(.emailAddress)    // Korrekt hier
                      .autocapitalization(.none)    // Korrekt hier
                 TextField("Telefon:", text: $viewModel.debtor.bound.phone.withDefault(""))
                      .textFieldStyle(.roundedBorder) // Korrekt hier
                     .keyboardType(.phonePad)      // Korrekt hier
            }
         }
     }

    @ViewBuilder
     private func addressSection() -> some View {
         if viewModel.debtor != nil {
            Section("Adresse") {
                 TextField("Straße:", text: $viewModel.debtor.bound.addressStreet.withDefault(""))
                    .textFieldStyle(.roundedBorder)
                 TextField("PLZ:", text: $viewModel.debtor.bound.addressZip.withDefault(""))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad) // Korrekt hier
                 TextField("Stadt:", text: $viewModel.debtor.bound.addressCity.withDefault(""))
                    .textFieldStyle(.roundedBorder)
                 TextField("Land:", text: $viewModel.debtor.bound.addressCountry.withDefault("DE"))
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters) // Korrekt hier
            }
         }
    }

     @ViewBuilder
     private func notesSection() -> some View {
         if viewModel.debtor != nil {
            Section("Notizen") {
                 TextEditor(text: $viewModel.debtor.bound.notes.withDefault(""))
                 .frame(minHeight: 80, maxHeight: 200)
                 .border(Color.secondary.opacity(0.5)) // Besser als cornerRadius für TextEditor manchmal
            }
         }
     }

     @ViewBuilder
     private func systemSection() -> some View {
         // Zeige nur, wenn Debtor *geladen* wurde (also nicht neu ist)
         // Verwende die neue Computed Property vom ViewModel
         if !viewModel.isNewDebtor, let debtor = viewModel.debtor {
             Section("System") {
                 Text("ID: \(debtor.id)").font(.caption).foregroundColor(.secondary)
                 Text("Erstellt: \(formattedDate(debtor.createdAt))")
                 Text("Geändert: \(formattedDate(debtor.updatedAt))")
            }
         }
     }
}

// --- Binding Helper (bleiben unverändert) ---
extension Binding where Value == String? { func withDefault(_ defaultValue: String) -> Binding<String> { /* ... */ } }
extension Binding where Value == Debtor? { var bound: SafeDebtorBinding { /* ... */ } }
@dynamicMemberLookup struct SafeDebtorBinding { /* ... */ }

// Preview bleibt wie zuvor
#Preview { /* ... */ }
