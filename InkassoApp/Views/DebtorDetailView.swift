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
        // Haupt-Group für Loading/Error/Content-Zustand
        Group {
            if viewModel.isLoading && viewModel.debtor == nil {
                 ProgressView("Lade Schuldner...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.showingAlert { // Zeige Fehler immer, wenn Alert aktiv ist
                 VStack { Text("Fehler").font(.headline); Text(error).foregroundColor(.red); Button("Erneut laden") { Task { await viewModel.loadDebtor() } }.padding(.top) }
                 .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.debtor != nil {
                // --- STRUKTURÄNDERUNG: Sections direkt im Form ---
                Form {
                    // --- Section "Stammdaten" ---
                    Section("Stammdaten") {
                        // Binding an Properties des optionalen ViewModels mit map/withDefault
                        TextField("Name:", text: $viewModel.debtor.map(keyPath: \.name, defaultValue: ""))
                            .textFieldStyle(.roundedBorder)
                        Picker("Typ:", selection: $viewModel.debtor.map(keyPath: \.debtorType, defaultValue: "private")) {
                            Text("Privat").tag("private")
                            Text("Firma").tag("business")
                        }
                        .pickerStyle(.segmented).frame(maxWidth: 150)
                    }

                    // --- Section "Kontakt" ---
                    Section("Kontakt") {
                         TextField("E-Mail:", text: $viewModel.debtor.map(keyPath: \.email, defaultValue: nil).withDefault(""))
                              .textFieldStyle(.roundedBorder)
                              .keyboardType(.emailAddress) // Korrekt hier
                              .autocapitalization(.none)   // Korrekt hier
                         TextField("Telefon:", text: $viewModel.debtor.map(keyPath: \.phone, defaultValue: nil).withDefault(""))
                              .textFieldStyle(.roundedBorder)
                             .keyboardType(.phonePad) // Korrekt hier
                    }

                    // --- Section "Adresse" ---
                     Section("Adresse") {
                         TextField("Straße:", text: $viewModel.debtor.map(keyPath: \.addressStreet, defaultValue: nil).withDefault(""))
                            .textFieldStyle(.roundedBorder)
                         TextField("PLZ:", text: $viewModel.debtor.map(keyPath: \.addressZip, defaultValue: nil).withDefault(""))
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad) // Korrekt hier
                         TextField("Stadt:", text: $viewModel.debtor.map(keyPath: \.addressCity, defaultValue: nil).withDefault(""))
                            .textFieldStyle(.roundedBorder)
                         TextField("Land:", text: $viewModel.debtor.map(keyPath: \.addressCountry, defaultValue: nil).withDefault("DE"))
                             .textFieldStyle(.roundedBorder)
                             .autocapitalization(.allCharacters) // Korrekt hier
                    }

                    // --- Section "Notizen" ---
                     Section("Notizen") {
                         TextEditor(text: $viewModel.debtor.map(keyPath: \.notes, defaultValue: nil).withDefault(""))
                         .frame(minHeight: 80, maxHeight: 200)
                         .border(Color.secondary.opacity(0.5))
                         .cornerRadius(5) // Vorsicht mit CornerRadius bei Border
                    }

                    // --- Section "System" ---
                    // Verwende viewModel.isNewDebtor statt originalDebtor direkt zu prüfen
                    if !viewModel.isNewDebtor, let debtor = viewModel.debtor {
                         Section("System") {
                             Text("ID: \(debtor.id)").font(.caption).foregroundColor(.secondary)
                             Text("Erstellt: \(formattedDate(debtor.createdAt))")
                             Text("Geändert: \(formattedDate(debtor.updatedAt))")
                        }
                     }

                } // Ende Form
                // Disable Form während Speichern
                .disabled(viewModel.isLoading && viewModel.hasChanges)
                .overlay { if viewModel.isLoading && viewModel.hasChanges { ProgressView("Speichern...") } }

            } else {
                 // Fallback, wenn Debtor nil ist, aber kein Fehler/Laden angezeigt wird
                 Text("Schuldnerdaten nicht verfügbar.")
                 .foregroundColor(.secondary)
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } // Ende Group
        .padding()
        // --- KORRIGIERTER NAVIGATIONSTITLE ---
        .navigationTitle(viewModel.debtor == nil ? "Lade..." : (viewModel.isNewDebtor ? "Neuer Schuldner?" : (viewModel.hasChanges ? "Bearbeiten: " : "") + (viewModel.debtor?.name.isEmpty ?? true ? "Unbenannt" : viewModel.debtor!.name)))
        // --- ENDE KORREKTUR ---
        .toolbar { /* ... Toolbar wie zuvor ... */
             ToolbarItem(placement: .cancellationAction) { Button(viewModel.hasChanges ? "Änderungen verwerfen" : "Schließen") { if viewModel.hasChanges { viewModel.resetChanges() }; dismiss() }.disabled(viewModel.isLoading && viewModel.hasChanges) }
             ToolbarItem(placement: .confirmationAction) { Button("Speichern") { Task { let success = await viewModel.saveDebtor() } }.disabled(!viewModel.canSave || viewModel.isLoading) }
        }
        .task { if viewModel.debtor == nil { await viewModel.loadDebtor() } }
        .alert(viewModel.errorMessage == nil ? "Info" : "Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage ?? "Aktion erfolgreich.") { _ in Button("OK"){ viewModel.errorMessage = nil } } message: { messageText in Text(messageText) }
    }

    // Die @ViewBuilder private func ...Section() Methoden werden nicht mehr benötigt und können gelöscht werden.
}

// --- Binding Helper (müssen in Utils/Binding+Helpers.swift oder fileprivate hier stehen) ---
// Stelle sicher, dass diese Helfer definiert sind!
fileprivate extension Binding where Value == String? { func withDefault(_ defaultValue: String = "") -> Binding<String> { Binding<String>( get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0.isEmpty ? nil : $0 } ) } }
fileprivate extension Binding where Value == Debtor? { func map<T>(keyPath: WritableKeyPath<Debtor, T>, defaultValue: T) -> Binding<T> { Binding<T>( get: { self.wrappedValue?[keyPath: keyPath] ?? defaultValue }, set: { newValue in if self.wrappedValue != nil { self.wrappedValue?[keyPath: keyPath] = newValue } else { print("Warning: Tried to set property on nil optional object \(Value.self)") } } ) } }

// Preview bleibt wie zuvor
#Preview {
    NavigationView {
        DebtorDetailView(debtorId: "debtor-preview")
    }
}
