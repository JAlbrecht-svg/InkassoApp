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
            } else if let _ = viewModel.debtor { // Nur anzeigen, wenn Debtor-Objekt existiert
                Form { // Verwende Form für macOS Standard-Layout
                    basicDataSection()
                    contactSection()
                    addressSection()
                    notesSection()
                    systemSection() // Verwendet jetzt viewModel.isNewDebtor
                }
                // Wende Disabled auf Form an, nicht auf Section
                .disabled(viewModel.isLoading && viewModel.hasChanges)
                .overlay { if viewModel.isLoading && viewModel.hasChanges { ProgressView("Speichern...") } }
            } else if let error = viewModel.errorMessage {
                 VStack { /* ... Fehleranzeige wie zuvor ... */ }
                 .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else { Text("Schuldnerdaten nicht verfügbar.").foregroundColor(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .padding()
        .navigationTitle(viewModel.debtor == nil ? "Lade..." : (viewModel.originalDebtor == nil ? "Schuldner Bearbeiten" : (viewModel.hasChanges ? "Bearbeiten: " : "") + (viewModel.debtor!.name.isEmpty ? "Unbenannt" : viewModel.debtor!.name)))
        .toolbar { /* ... Toolbar wie zuvor ... */ }
        .task { if viewModel.debtor == nil { await viewModel.loadDebtor() } }
        .alert(viewModel.errorMessage == nil ? "Info" : "Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage ?? "Aktion erfolgreich.") { _ in Button("OK"){ viewModel.errorMessage = nil } } message: { messageText in Text(messageText) }
    }

    // --- Aufgeteilte Sektionen mit korrekten Modifiern ---
    @ViewBuilder
    private func basicDataSection() -> some View {
        if viewModel.debtor != nil {
            Section("Stammdaten") {
                TextField("Name:", text: $viewModel.debtor.map(keyPath: \.name, defaultValue: ""))
                    .textFieldStyle(.roundedBorder)
                Picker("Typ:", selection: $viewModel.debtor.map(keyPath: \.debtorType, defaultValue: "private")) {
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
                 // --- KORREKTE MODIFIER ---
                 TextField("E-Mail:", text: $viewModel.debtor.map(keyPath: \.email, defaultValue: nil).withDefault(""))
                      .textFieldStyle(.roundedBorder)
                      
                     
                 TextField("Telefon:", text: $viewModel.debtor.map(keyPath: \.phone, defaultValue: nil).withDefault(""))
                      .textFieldStyle(.roundedBorder)
                     .keyboardType(.phonePad)      // Korrekt verkettet
                 // --- ENDE KORREKTUR ---
            }
         }
     }

    @ViewBuilder
     private func addressSection() -> some View {
         // Der Fehler L111 (Generic parameter 'V') war wahrscheinlich ein Folgefehler.
         // Mit korrekten Bindings und Modifiern sollte er weg sein.
         if viewModel.debtor != nil {
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
         }
    }

     @ViewBuilder
     private func notesSection() -> some View {
         if viewModel.debtor != nil {
            Section("Notizen") {
                 TextEditor(text: $viewModel.debtor.map(keyPath: \.notes, defaultValue: nil).withDefault(""))
                 .frame(minHeight: 80, maxHeight: 200)
                 .border(Color.secondary.opacity(0.5))
                 // .disabled(viewModel.isLoading) // Disabled hier auf TextEditor, nicht auf Section!
            }
            // .disabled(viewModel.isLoading) // Nicht hier auf Section anwenden
         }
     }

     @ViewBuilder
     private func systemSection() -> some View {
         // --- KORREKTUR: Verwende isNewDebtor ---
         if !viewModel.isNewDebtor, let debtor = viewModel.debtor {
             Section("System") {
                 Text("ID: \(debtor.id)").font(.caption).foregroundColor(.secondary)
                 Text("Erstellt: \(formattedDate(debtor.createdAt))")
                 Text("Geändert: \(formattedDate(debtor.updatedAt))")
            }
         }
         // --- ENDE KORREKTUR ---
     }
}

// --- Binding Helper (müssen in Utils/Binding+Helpers.swift oder fileprivate hier stehen) ---
fileprivate extension Binding where Value == String? { func withDefault(_ defaultValue: String = "") -> Binding<String> { Binding<String>( get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0.isEmpty ? nil : $0 } ) } }
fileprivate extension Binding where Value == Debtor? { func map<T>(keyPath: WritableKeyPath<Debtor, T>, defaultValue: T) -> Binding<T> { Binding<T>( get: { self.wrappedValue?[keyPath: keyPath] ?? defaultValue }, set: { newValue in if self.wrappedValue != nil { self.wrappedValue?[keyPath: keyPath] = newValue } else { print("Warning: Tried to set property on nil optional object \(Value.self)") } } ) } }
// @dynamicMemberLookup struct SafeDebtorBinding { ... } // Dieser Helper wird NICHT mehr benötigt/verwendet

// Preview bleibt wie zuvor
#Preview { /* ... */ }
