// Views/DebtorDetailView.swift
import SwiftUI

struct DebtorDetailView: View {
    @StateObject private var viewModel: DebtorDetailViewModel
    let debtorIdToLoad: String
    @Environment(\.dismiss) var dismiss

    init(debtorId: String) {
        self.debtorIdToLoad = debtorId
        // Verwende die übergebene ID für das ViewModel
        _viewModel = StateObject(wrappedValue: DebtorDetailViewModel(debtorId: debtorId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.debtor == nil {
                 ProgressView("Lade Schuldner...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let _ = viewModel.debtor { // Sicherstellen, dass Debtor nicht nil ist für Formular
                Form {
                    basicDataSection() // Verwende Binding an ViewModel
                    contactSection()
                    addressSection()
                    notesSection()
                    systemSection() // Zeigt Infos nur, wenn originalDebtor existiert
                }
                .disabled(viewModel.isLoading)
                .overlay { // Zeige Overlay nur während *Speichern* (hasChanges prüft, ob Laden fertig)
                     if viewModel.isLoading && viewModel.hasChanges {
                        ProgressView("Speichern...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 3)
                    }
                }
            } else if let error = viewModel.errorMessage {
                 VStack { Text("Fehler").font(.headline); Text(error).foregroundColor(.red); Button("Erneut laden") { Task { await viewModel.loadDebtor() } }.padding(.top) }
                 .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                 // Sollte nicht erreicht werden, wenn .task funktioniert
                 Text("Schuldnerdaten nicht verfügbar.")
                 .foregroundColor(.secondary)
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle(viewModel.debtor == nil ? "Lade..." : (viewModel.originalDebtor == nil ? "Neuer Schuldner?" : (viewModel.hasChanges ? "Bearbeiten: " : "") + (viewModel.debtor!.name.isEmpty ? "Unbenannt" : viewModel.debtor!.name)))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                 Button(viewModel.hasChanges ? "Änderungen verwerfen" : "Schließen") {
                     if viewModel.hasChanges { viewModel.resetChanges() }
                     dismiss()
                 }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") {
                    Task {
                        let success = await viewModel.saveDebtor()
                        // Schließe nicht automatisch, zeige Erfolgsmeldung oder Fehler via Alert
                        // if success { dismiss() }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isLoading) // Verwende canSave
            }
        }
        .task { // Lade Daten beim Erscheinen, wenn noch nicht geladen
            if viewModel.debtor == nil {
                 await viewModel.loadDebtor()
            }
        }
        // Zeige Fehler oder Erfolgsmeldung vom Speichern/Laden
        .alert(viewModel.errorMessage == nil ? "Erfolg" : "Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage ?? "Aktion erfolgreich.") { _ in
             Button("OK"){ viewModel.errorMessage = nil } // Schließe Alert
        } message: { messageText in
             Text(messageText) // Zeigt Fehler oder Erfolgsmeldung an
        }
    }

    // --- Aufgeteilte Sektionen mit Binding an ViewModel ---
    @ViewBuilder
    private func basicDataSection() -> some View {
        // Binding funktioniert nur, wenn debtor nicht nil ist
        if viewModel.debtor != nil {
            Section("Stammdaten") {
                TextField("Name:", text: $viewModel.debtor.bound.name)
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
                      .keyboardType(.emailAddress).autocapitalization(.none)
                 TextField("Telefon:", text: $viewModel.debtor.bound.phone.withDefault(""))
                     .keyboardType(.phonePad)
            }
         }
     }

    @ViewBuilder
     private func addressSection() -> some View {
         if viewModel.debtor != nil {
            Section("Adresse") {
                 TextField("Straße:", text: $viewModel.debtor.bound.addressStreet.withDefault(""))
                 TextField("PLZ:", text: $viewModel.debtor.bound.addressZip.withDefault(""))
                      .keyboardType(.numberPad)
                 TextField("Stadt:", text: $viewModel.debtor.bound.addressCity.withDefault(""))
                 TextField("Land:", text: $viewModel.debtor.bound.addressCountry.withDefault("DE"))
                     .autocapitalization(.allCharacters) // Länderkürzel oft groß
            }
         }
    }

     @ViewBuilder
     private func notesSection() -> some View {
         if viewModel.debtor != nil {
            Section("Notizen") {
                 TextEditor(text: $viewModel.debtor.bound.notes.withDefault(""))
                 .frame(minHeight: 80, maxHeight: 200)
                 .border(Color.secondary.opacity(0.5))
                 .cornerRadius(5)
            }
         }
     }

     @ViewBuilder
     private func systemSection() -> some View {
         // Zeige nur, wenn Debtor *geladen* wurde (originalDebtor gesetzt)
         if let original = viewModel.originalDebtor {
             Section("System") {
                 Text("ID: \(original.id)").font(.caption).foregroundColor(.secondary)
                 Text("Erstellt: \(formattedDate(original.createdAt))")
                 Text("Geändert: \(formattedDate(original.updatedAt))")
            }
         }
     }
}

// --- Binding Helper (unverändert) ---
extension Binding where Value == String? { func withDefault(_ defaultValue: String) -> Binding<String> { Binding<String>( get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0.isEmpty ? nil : $0 } ) } }
extension Binding where Value == Debtor? { var bound: SafeDebtorBinding { SafeDebtorBinding(source: self) } }
@dynamicMemberLookup struct SafeDebtorBinding { let source: Binding<Debtor?>; subscript<T>(dynamicMember keyPath: WritableKeyPath<Debtor, T>) -> Binding<T> where T: Equatable { Binding<T>( get: { source.wrappedValue?[keyPath: keyPath] ?? defaultValue(for: keyPath) }, set: { newValue in if source.wrappedValue != nil, source.wrappedValue?[keyPath: keyPath] != newValue { source.wrappedValue?[keyPath: keyPath] = newValue } } ) }; private func defaultValue<T>(for keyPath: WritableKeyPath<Debtor, T>) -> T { switch keyPath { case \Debtor.name: return "" as! T; case \Debtor.debtorType: return "private" as! T; default: if T.self == String.self { return "" as! T } else if T.self == Int.self { return 0 as! T } else if T.self == Double.self { return 0.0 as! T } else { fatalError("No default value for non-optional keypath \(keyPath)") } } } }

// Preview bleibt wie zuvor
#Preview { /* ... */ }
