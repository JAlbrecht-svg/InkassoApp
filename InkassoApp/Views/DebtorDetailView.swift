import SwiftUI

struct DebtorDetailView: View {
    @StateObject private var viewModel: DebtorDetailViewModel
    let debtorIdToLoad: String
    @Environment(\.dismiss) var dismiss

    // Lokaler State für die Formularfelder
    @State private var name: String = ""
    @State private var debtorType: String = "private"
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var addressStreet: String = ""
    @State private var addressZip: String = ""
    @State private var addressCity: String = ""
    @State private var addressCountry: String = "DE"
    @State private var notes: String = ""
    @State private var hasLoadedInitialData = false
    @State private var internalErrorMessage: String? = nil

    // Prüft auf lokale Änderungen
    private var hasLocalChanges: Bool { /* ... Implementierung wie zuvor ... */
        guard let original = viewModel.originalDebtor else { return !name.isEmpty }
        return name != original.name || debtorType != original.debtorType || addressStreet != (original.addressStreet ?? "") || addressZip != (original.addressZip ?? "") || addressCity != (original.addressCity ?? "") || addressCountry != (original.addressCountry ?? "DE") || email != (original.email ?? "") || phone != (original.phone ?? "") || notes != (original.notes ?? "")
    }
    // Prüft, ob lokal gespeichert werden kann
    private var canSaveLocally: Bool { /* ... Implementierung wie zuvor ... */
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasLocalChanges && !viewModel.isLoading
    }

    // Initialisierer
    init(debtorId: String) {
        self.debtorIdToLoad = debtorId
        _viewModel = StateObject(wrappedValue: DebtorDetailViewModel(debtorId: debtorId))
    }

    // Haupt-Body
    var body: some View {
        Group {
            if viewModel.isLoading && !hasLoadedInitialData {
                 ProgressView("Lade Schuldner...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.showingAlert {
                 VStack { Text("Fehler").font(.headline); Text(error).foregroundColor(.red); Button("Erneut laden") { Task { await viewModel.loadDebtor() } }.padding(.top) }
                 .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.debtor != nil || debtorIdToLoad.isEmpty { // Zeige Formular wenn geladen ODER Neuanlage
                // --- Refactoring: Rufe nur die debtorForm Property auf ---
                debtorForm
                // --- Ende Refactoring ---
            } else {
                Text("Schuldnerdaten nicht verfügbar.")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
           }
        }
        .padding() // Außenpadding für Group
        .navigationTitle(determineTitle())
        .toolbar { /* ... Toolbar wie zuvor ... */ }
        .task { // Initiales Laden
            if viewModel.debtor == nil && !debtorIdToLoad.isEmpty {
                 await viewModel.loadDebtor()
                 if !hasLoadedInitialData { // Vermeide Überschreiben bei erneutem Laden
                      updateLocalState(from: viewModel.debtor)
                      hasLoadedInitialData = true
                 }
            } else if debtorIdToLoad.isEmpty && !hasLoadedInitialData {
                 resetLocalChanges(); hasLoadedInitialData = true
            }
        }
        .onChange(of: viewModel.debtor) { _, newDebtorData in // Synchronisiere lokalen State
             if !viewModel.isLoading { updateLocalState(from: newDebtorData) }
        }
        .alert(viewModel.errorMessage == nil ? "Info" : "Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage ?? "Aktion erfolgreich.") { _ in Button("OK"){ viewModel.errorMessage = nil } } message: { messageText in Text(messageText) }
    }


    // --- NEU: Das gesamte Formular in einer Computed Property ---
    private var debtorForm: some View {
        Form {
            Section("Stammdaten") {
                TextField("Name:", text: $name)
                    .textFieldStyle(.roundedBorder)
                Picker("Typ:", selection: $debtorType) {
                    Text("Privat").tag("private")
                    Text("Firma").tag("business")
                }
                .pickerStyle(.segmented).frame(maxWidth: 150)
            }

            Section("Kontakt") {
                 TextField("E-Mail:", text: $email)
                      .textFieldStyle(.roundedBorder)
                 TextField("Telefon:", text: $phone)
                      .textFieldStyle(.roundedBorder)
                     .keyboardType(.phonePad)
            }

             Section("Adresse") {
                 TextField("Straße:", text: $addressStreet)
                    .textFieldStyle(.roundedBorder)
                 TextField("PLZ:", text: $addressZip)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                 TextField("Stadt:", text: $addressCity)
                    .textFieldStyle(.roundedBorder)
                 TextField("Land:", text: $addressCountry)
                     .textFieldStyle(.roundedBorder)
                     .autocapitalization(.allCharacters)
            }

             Section("Notizen") {
                 TextEditor(text: $notes)
                 .frame(minHeight: 80, maxHeight: 200)
                 .border(Color.secondary.opacity(0.5))
                 // .disabled(viewModel.isLoading && hasLocalChanges) // Disable hier statt auf Section
            }

             // Zeige System-Infos nur, wenn Debtor *geladen* wurde
            if !viewModel.isNewDebtor, let debtor = viewModel.debtor {
                 Section("System") {
                     Text("ID: \(debtor.id)").font(.caption).foregroundColor(.secondary)
                     Text("Erstellt: \(formattedDate(debtor.createdAt))")
                     Text("Geändert: \(formattedDate(debtor.updatedAt))")
                }
             }

            // Lokale Fehlermeldung (z.B. Name fehlt)
            if let localError = internalErrorMessage {
                 Text(localError).foregroundColor(.red)
            }
        } // Ende Form
        .disabled(viewModel.isLoading && hasLocalChanges) // Disable Form während Speichern
        .overlay { if viewModel.isLoading && hasLocalChanges { ProgressView("Speichern...") } }
    }
    // --- ENDE debtorForm ---


    // --- Lokale Hilfsfunktionen ---
    private func updateLocalState(from debtor: Debtor?) { /* ... wie zuvor ... */
        name = debtor?.name ?? ""; debtorType = debtor?.debtorType ?? "private"; email = debtor?.email ?? ""; phone = debtor?.phone ?? ""; addressStreet = debtor?.addressStreet ?? ""; addressZip = debtor?.addressZip ?? ""; addressCity = debtor?.addressCity ?? ""; addressCountry = debtor?.addressCountry ?? "DE"; notes = debtor?.notes ?? ""
    }
    private func resetLocalChanges() { /* ... wie zuvor ... */
        updateLocalState(from: viewModel.originalDebtor); internalErrorMessage = nil
    }
    private func saveChanges() async { /* ... Implementierung wie zuvor ... */
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { internalErrorMessage = "Name darf nicht leer sein."; return }; internalErrorMessage = nil
        guard viewModel.debtor != nil else { internalErrorMessage = "Kein Schuldner zum Speichern geladen."; return }
        viewModel.debtor?.name = name; viewModel.debtor?.debtorType = debtorType; viewModel.debtor?.email = email.isEmpty ? nil : email; viewModel.debtor?.phone = phone.isEmpty ? nil : phone; viewModel.debtor?.addressStreet = addressStreet.isEmpty ? nil : addressStreet; viewModel.debtor?.addressZip = addressZip.isEmpty ? nil : addressZip; viewModel.debtor?.addressCity = addressCity.isEmpty ? nil : addressCity; viewModel.debtor?.addressCountry = addressCountry.isEmpty ? "DE" : addressCountry; viewModel.debtor?.notes = notes.isEmpty ? nil : notes
        let success = await viewModel.saveDebtor()
    }
    private func determineTitle() -> String { /* ... Implementierung wie zuvor ... */
        if viewModel.debtor == nil && !viewModel.isLoading { return "Fehler" }; if viewModel.debtor == nil && viewModel.isLoading { return "Lade Schuldner..." }; let baseName = viewModel.debtor?.name.isEmpty ?? true ? "Schuldner bearbeiten" : viewModel.debtor!.name; return hasLocalChanges ? "Bearbeiten: \(baseName)" : baseName
    }

} // Ende Struct DebtorDetailView

// --- Binding Helper (fileprivate oder in Utils) ---
// Stelle sicher, dass diese hier oder in Utils definiert sind!
fileprivate extension Binding where Value == String? { func withDefault(_ defaultValue: String = "") -> Binding<String> { Binding<String>( get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0.isEmpty ? nil : $0 } ) } }
// fileprivate extension Binding where Value == Debtor? { func map<T>(keyPath: WritableKeyPath<Debtor, T>, defaultValue: T) -> Binding<T> { ... } } // Wird nicht mehr benötigt

// Preview bleibt wie zuvor
#Preview { /* ... wie zuvor ... */ }
