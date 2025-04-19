// Views/DebtorDetailView.swift
import SwiftUI

struct DebtorDetailView: View {
    @StateObject private var viewModel: DebtorDetailViewModel
    let debtorIdToLoad: String
    @Environment(\.dismiss) var dismiss

    // --- Lokaler State für die Formularfelder ---
    @State private var name: String = ""
    @State private var debtorType: String = "private" // Default
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var addressStreet: String = ""
    @State private var addressZip: String = ""
    @State private var addressCity: String = ""
    @State private var addressCountry: String = "DE" // Default
    @State private var notes: String = ""

    // Zustand, um zu wissen, ob initial geladen wurde
    @State private var hasLoadedInitialData = false
    @State private var internalErrorMessage: String? = nil // Für lokale Validierung

    // Prüft auf lokale Änderungen
    private var hasLocalChanges: Bool {
        guard let original = viewModel.originalDebtor else { return !name.isEmpty } // Wenn neu -> Änderungen sobald Name da ist
        return name != original.name ||
               debtorType != original.debtorType ||
               addressStreet != (original.addressStreet ?? "") ||
               addressZip != (original.addressZip ?? "") ||
               addressCity != (original.addressCity ?? "") ||
               addressCountry != (original.addressCountry ?? "DE") ||
               email != (original.email ?? "") ||
               phone != (original.phone ?? "") ||
               notes != (original.notes ?? "")
    }

    // Prüft, ob lokal gespeichert werden kann
    private var canSaveLocally: Bool {
         !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasLocalChanges && !viewModel.isLoading
    }

    init(debtorId: String) {
        self.debtorIdToLoad = debtorId
        _viewModel = StateObject(wrappedValue: DebtorDetailViewModel(debtorId: debtorId))
    }

    var body: some View {
        Group {
            // Zeige Laden nur initial
            if viewModel.isLoading && !hasLoadedInitialData {
                 ProgressView("Lade Schuldner...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Zeige Fehler nur initial oder wenn Speichern fehlschlägt
            } else if let error = viewModel.errorMessage, viewModel.showingAlert {
                 VStack { Text("Fehler").font(.headline); Text(error).foregroundColor(.red); Button("OK") { viewModel.showingAlert = false; viewModel.errorMessage = nil }.padding(.top) }
                 .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.debtor != nil || debtorIdToLoad.isEmpty { // Zeige Formular wenn geladen ODER wenn ID leer war (Neuanlage - TODO?)
                // Formular bindet jetzt an lokalen @State
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
                              .keyboardType(.emailAddress)
                              .autocapitalization(.none)
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
                    }

                    // Zeige System-Infos nur, wenn Debtor vom VM geladen wurde
                    if let loadedDebtor = viewModel.debtor {
                        Section("System") {
                             Text("ID: \(loadedDebtor.id)").font(.caption).foregroundColor(.secondary)
                             Text("Erstellt: \(formattedDate(loadedDebtor.createdAt))")
                             Text("Geändert: \(formattedDate(loadedDebtor.updatedAt))")
                        }
                    }
                    // Lokale Fehlermeldung (z.B. Name fehlt)
                    if let localError = internalErrorMessage {
                         Text(localError).foregroundColor(.red)
                    }
                } // Ende Form
                // Deaktiviere nur beim Speichern, nicht beim initialen Laden
                .disabled(viewModel.isLoading && hasLocalChanges)
                .overlay { if viewModel.isLoading && hasLocalChanges { ProgressView("Speichern...") } }

            } else { Text("Schuldnerdaten nicht verfügbar.") } // Fallback
        }
        .padding()
        .navigationTitle(determineTitle()) // Dynamischer Titel basierend auf State
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                 Button(hasLocalChanges ? "Änderungen verwerfen" : "Schließen") {
                     if hasLocalChanges { resetLocalChanges() } // Lokale Änderungen zurücksetzen
                     dismiss()
                 }
                 .disabled(viewModel.isLoading && hasLocalChanges) // Deaktivieren während Speichern
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Speichern") { Task { await saveChanges() } }
                .disabled(!canSaveLocally || viewModel.isLoading) // Verwende lokale Prüfung
            }
        }
        .task { // Initiales Laden
            if viewModel.debtor == nil && !debtorIdToLoad.isEmpty {
                 await viewModel.loadDebtor()
                 // Setze State nach Laden, aber nur wenn noch nicht initialisiert
                 if !hasLoadedInitialData {
                      updateLocalState(from: viewModel.debtor)
                      hasLoadedInitialData = true
                 }
            } else if debtorIdToLoad.isEmpty {
                 // Initialisiere für Neuanlage (TODO: Logik für 'Neu' Button fehlt noch)
                 resetLocalChanges() // Setzt auf Defaults
                 hasLoadedInitialData = true
            }
        }
        // Synchronisiere lokalen State, wenn sich der Debtor im ViewModel ändert (z.B. nach Reset oder externem Refresh)
        .onChange(of: viewModel.debtor) { _, newDebtorData in
             // Nur aktualisieren, wenn nicht gerade gespeichert wird,
             // um Konflikte zu vermeiden und lokale Edits zu erhalten
             if !viewModel.isLoading {
                print("ViewModel debtor changed, updating local state.")
                updateLocalState(from: newDebtorData)
             }
        }
        // Alert für Fehler vom ViewModel
        .alert("Hinweis", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in Button("OK"){ viewModel.errorMessage = nil } } message: { messageText in Text(messageText) }
    }

    // --- Lokale Hilfsfunktionen ---

    // Aktualisiert den lokalen State aus dem ViewModel
    private func updateLocalState(from debtor: Debtor?) {
        name = debtor?.name ?? ""
        debtorType = debtor?.debtorType ?? "private"
        email = debtor?.email ?? ""
        phone = debtor?.phone ?? ""
        addressStreet = debtor?.addressStreet ?? ""
        addressZip = debtor?.addressZip ?? ""
        addressCity = debtor?.addressCity ?? ""
        addressCountry = debtor?.addressCountry ?? "DE"
        notes = debtor?.notes ?? ""
    }

    // Setzt lokalen State zurück (auf Basis des Originals im VM oder auf leer)
    private func resetLocalChanges() {
        updateLocalState(from: viewModel.originalDebtor) // Setzt auf Original zurück
        internalErrorMessage = nil // Lokalen Fehler löschen
    }

    // Überträgt lokalen State ins VM und ruft Speichern auf
    private func saveChanges() async {
        // Lokale Validierung
         guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
             internalErrorMessage = "Name darf nicht leer sein."
             return
         }
        internalErrorMessage = nil // Fehler zurücksetzen

        // Erstelle/Aktualisiere das Debtor-Objekt im ViewModel mit den lokalen State-Werten
        // Wenn debtor nil ist (Neuanlage - noch nicht unterstützt), müsste hier ein neues erstellt werden.
        // Für Update:
        guard viewModel.debtor != nil else {
             internalErrorMessage = "Kein Schuldner zum Speichern geladen."
             return
        }

        viewModel.debtor?.name = name
        viewModel.debtor?.debtorType = debtorType
        viewModel.debtor?.email = email.isEmpty ? nil : email
        viewModel.debtor?.phone = phone.isEmpty ? nil : phone
        viewModel.debtor?.addressStreet = addressStreet.isEmpty ? nil : addressStreet
        viewModel.debtor?.addressZip = addressZip.isEmpty ? nil : addressZip
        viewModel.debtor?.addressCity = addressCity.isEmpty ? nil : addressCity
        viewModel.debtor?.addressCountry = addressCountry.isEmpty ? "DE" : addressCountry
        viewModel.debtor?.notes = notes.isEmpty ? nil : notes

        // Rufe die Speicherfunktion im ViewModel auf
        let success = await viewModel.saveDebtor()

        // Nach erfolgreichem Speichern ist der lokale State synchron mit viewModel.debtor
        // und hasLocalChanges sollte false sein.
        // View wird durch .onChange(of: viewModel.debtor) aktualisiert, falls saveDebtor das Objekt ändert.
    }

    // Hilfsfunktion für den Titel
    private func determineTitle() -> String {
         if viewModel.debtor == nil && !viewModel.isLoading { return "Fehler" }
         if viewModel.debtor == nil && viewModel.isLoading { return "Lade Schuldner..." }
         // Annahme: OriginalDebtor ist nur nil bei Neuanlage
         let baseName = viewModel.debtor?.name.isEmpty ?? true ? "Schuldner bearbeiten" : viewModel.debtor!.name
         return hasLocalChanges ? "Bearbeiten: \(baseName)" : baseName
     }

}

// Binding Helper werden nicht mehr benötigt in dieser View
// Preview bleibt wie zuvor
#Preview { /* ... */ }
