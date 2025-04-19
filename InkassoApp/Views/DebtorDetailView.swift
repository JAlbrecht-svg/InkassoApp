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
            } else if let error = viewModel.errorMessage, viewModel.showingAlert {
                 VStack { Text("Fehler").font(.headline); Text(error).foregroundColor(.red); Button("Erneut laden") { Task { await viewModel.loadDebtor() } }.padding(.top) }
                 .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.debtor != nil { // Formular nur anzeigen wenn Debtor geladen ist
                Form {
                    // Verwende die aufgeteilten Sektionen
                    basicDataSection()
                    contactSection()
                    addressSection()
                    notesSection()
                    systemSection() // Verwendet jetzt viewModel.isNewDebtor
                }
                .disabled(viewModel.isLoading && viewModel.hasChanges)
                .overlay { if viewModel.isLoading && viewModel.hasChanges { ProgressView("Speichern...") } }
            } else {
                 Text("Schuldnerdaten nicht verfügbar.")
                 .foregroundColor(.secondary)
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle(viewModel.debtor == nil ? "Lade..." : (viewModel.debtor!.name.isEmpty && viewModel.originalDebtor == nil ? "Schuldner Bearbeiten" : (viewModel.hasChanges ? "Bearbeiten: " : "") + (viewModel.debtor!.name.isEmpty ? "Unbenannt" : viewModel.debtor!.name)))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                 Button(viewModel.hasChanges ? "Änderungen verwerfen" : "Schließen") { if viewModel.hasChanges { viewModel.resetChanges() }; dismiss() }
                 .disabled(viewModel.isLoading && viewModel.hasChanges)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { Task { let success = await viewModel.saveDebtor() } }
                .disabled(!viewModel.canSave || viewModel.isLoading)
            }
        }
        .task { if viewModel.debtor == nil { await viewModel.loadDebtor() } }
        .alert(viewModel.errorMessage == nil ? "Info" : "Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage ?? "Aktion erfolgreich.") { _ in Button("OK"){ viewModel.errorMessage = nil } } message: { messageText in Text(messageText) }
    }

    // --- Aufgeteilte Sektionen mit korrekten Bindings ---
    @ViewBuilder
    private func basicDataSection() -> some View {
        // Verwende map-Helper für Binding an Properties des optionalen debtor
        Section("Stammdaten") {
            TextField("Name:", text: $viewModel.debtor.map(keyPath: \.name, defaultValue: ""))
                .textFieldStyle(.roundedBorder)
            Picker("Typ:", selection: $viewModel.debtor.map(keyPath: \.debtorType, defaultValue: "private")) {
                Text("Privat").tag("private")
                Text("Firma").tag("business")
            }
            .pickerStyle(.segmented).frame(maxWidth: 150)
        }
        // Deaktiviere Section, wenn debtor noch nil ist (sollte nicht passieren wegen äußerem if)
        .disabled(viewModel.debtor == nil)
    }

     @ViewBuilder
     private func contactSection() -> some View {
         Section("Kontakt") {
             // Verwende withDefault-Helper für optionale Strings
             TextField("E-Mail:", text: $viewModel.debtor.map(keyPath: \.email, defaultValue: nil).withDefault(""))
                  .textFieldStyle(.roundedBorder)
                  .keyboardType(.emailAddress) // Korrekt hier
                  .autocapitalization(.none)   // Korrekt hier
             TextField("Telefon:", text: $viewModel.debtor.map(keyPath: \.phone, defaultValue: nil).withDefault(""))
                  .textFieldStyle(.roundedBorder)
                  .keyboardType(.phonePad) // Korrekt hier
        }
        .disabled(viewModel.debtor == nil)
     }

    @ViewBuilder
     private func addressSection() -> some View {
         Section("Adresse") {
             TextField("Straße:", text: $viewModel.debtor.map(keyPath: \.addressStreet, defaultValue: nil).withDefault(""))
                .textFieldStyle(.roundedBorder)
             TextField("PLZ:", text: $viewModel.debtor.map(keyPath: \.addressZip, defaultValue: nil).withDefault(""))
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
             TextField("Stadt:", text: $viewModel.debtor.map(keyPath: \.addressCity, defaultValue: nil).withDefault(""))
                .textFieldStyle(.roundedBorder)
             TextField("Land:", text: $viewModel.debtor.map(keyPath: \.addressCountry, defaultValue: nil).withDefault("DE"))
                 .textFieldStyle(.roundedBorder)
                 .autocapitalization(.allCharacters)
        }
        .disabled(viewModel.debtor == nil)
    }

     @ViewBuilder
     private func notesSection() -> some View {
         Section("Notizen") {
             TextEditor(text: $viewModel.debtor.map(keyPath: \.notes, defaultValue: nil).withDefault(""))
             .frame(minHeight: 80, maxHeight: 200)
             .border(Color.secondary.opacity(0.5))
             .cornerRadius(5) // CornerRadius nach Border kann komisch aussehen, evtl. weglassen
        }
        .disabled(viewModel.debtor == nil)
     }

     @ViewBuilder
     private func systemSection() -> some View {
         // Verwende viewModel.isNewDebtor wie zuvor
         if !viewModel.isNewDebtor, let debtor = viewModel.debtor {
             Section("System") {
                 Text("ID: \(debtor.id)").font(.caption).foregroundColor(.secondary)
                 Text("Erstellt: \(formattedDate(debtor.createdAt))")
                 Text("Geändert: \(formattedDate(debtor.updatedAt))")
            }
         }
     }
}

// --- Binding Helper müssen hier oder in Utils definiert sein ---
// (Aus Utils/Binding+Helpers.swift hierher verschoben oder global machen)
fileprivate extension Binding where Value == String? {
     func withDefault(_ defaultValue: String = "") -> Binding<String> { /* ... Implementierung wie oben ... */ }
}
fileprivate extension Binding where Value == Debtor? {
     func map<T>(keyPath: WritableKeyPath<Debtor, T>, defaultValue: T) -> Binding<T> { /* ... Implementierung wie oben ... */ }
}

#Preview { /* ... wie zuvor ... */ }
