import Foundation
import SwiftUI

@MainActor
class DebtorDetailViewModel: ObservableObject {

    // Der Debtor, der bearbeitet wird (Optional, da er geladen werden muss)
    @Published var debtor: Debtor? = nil
    // Zustand für Lade-/Speicheranzeige
    @Published var isLoading: Bool = false
    // Fehlermeldung für die View
    @Published var errorMessage: String? = nil
    // Steuert die Anzeige des Alerts in der View
    @Published var showingAlert: Bool = false

    // Hält das Original zum Vergleichen und Zurücksetzen
    private var originalDebtor: Debtor?
    // Referenz zum API Service
    private var apiService = APIService.shared
    // Die ID des zu ladenden/bearbeitenden Schuldners
    private var debtorIdToLoad: String

    // Initialisierer, der die ID des Schuldners erhält
    init(debtorId: String) {
        // Konvertiere ggf. Preview-IDs oder leere Strings
        self.debtorIdToLoad = debtorId.isEmpty || debtorId == "debtor-preview" ? "" : debtorId
        print("Debtor Detail VM init for ID: \(self.debtorIdToLoad.isEmpty ? "New/Invalid" : self.debtorIdToLoad)")
        // Wenn die ID leer ist, könnte man hier einen leeren Debtor erstellen (für "Neu"-Funktion)
        // if self.debtorIdToLoad.isEmpty {
        //     self.debtor = Debtor(...) // Leere Instanz erstellen
        //     self.originalDebtor = self.debtor
        // }
        // Aktuell laden wir immer, auch wenn die ID bekannt ist, über .task in der View
    }

    /// Lädt die Details für den Schuldner mit der `debtorIdToLoad`.
    func loadDebtor() async {
        guard !isLoading else { return }
        // Nur laden, wenn eine gültige ID vorhanden ist
        guard !debtorIdToLoad.isEmpty else {
            print("Cannot load debtor: debtorIdToLoad is empty.")
            self.errorMessage = "Keine Schuldner-ID zum Laden vorhanden."
            self.showingAlert = true
            return
        }
        // Nur neu laden, wenn noch kein Debtor geladen wurde oder die ID nicht übereinstimmt
        if debtor != nil && debtor?.id == debtorIdToLoad {
            print("Debtor \(debtorIdToLoad) already loaded.")
            return
        }

        isLoading = true
        errorMessage = nil
        print("Lade Debtor Details für ID: \(debtorIdToLoad)")
        do {
            let fetchedDebtor = try await apiService.fetchDebtor(id: debtorIdToLoad)
            self.debtor = fetchedDebtor
            self.originalDebtor = fetchedDebtor // Original nach dem Laden speichern
            errorMessage = nil
        } catch {
            self.errorMessage = "Fehler beim Laden der Schuldnerdetails: \(error.localizedDescription)"
            self.showingAlert = true
            print("Error loading debtor details: \(error)")
            self.debtor = nil // Setze zurück bei Fehler
            self.originalDebtor = nil
        }
        isLoading = false
    }

    /// Computed Property, die prüft, ob der Debtor neu erstellt wird (also noch keine ID vom Server hat).
    var isNewDebtor: Bool {
        // Wahr, wenn originalDebtor nil ist (wurde noch nie vom Server geladen/gespeichert)
        originalDebtor == nil
    }

    /// Computed Property, die prüft, ob Änderungen vorgenommen wurden.
    var hasChanges: Bool {
        guard let current = debtor, let original = originalDebtor else {
            // Wenn kein Original existiert (neuer Debtor), gibt es Änderungen, sobald debtor nicht nil ist
            return debtor != nil
        }
        // Vergleiche alle relevanten Felder
        return current.name != original.name ||
               current.debtorType != original.debtorType ||
               current.addressStreet != original.addressStreet ||
               current.addressZip != original.addressZip ||
               current.addressCity != original.addressCity ||
               current.addressCountry != original.addressCountry ||
               current.email != original.email ||
               current.phone != original.phone ||
               current.notes != original.notes
    }

    /// Computed Property, die prüft, ob gespeichert werden kann.
    var canSave: Bool {
        // Es muss ein Debtor-Objekt geben, der Name darf nicht leer sein,
        // es muss Änderungen geben und es darf nicht gerade geladen/gespeichert werden.
        guard let current = debtor else { return false }
        return !current.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasChanges && !isLoading
    }

    /// Speichert die Änderungen am Schuldner über den APIService.
    func saveDebtor() async -> Bool {
        guard let currentDebtor = debtor else {
             errorMessage = "Keine Schuldnerdaten zum Speichern vorhanden."; showingAlert = true; return false
        }
        guard canSave else {
            print("Save skipped: No effective changes or invalid data.")
            if currentDebtor.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                 errorMessage = "Schuldnername darf nicht leer sein."
                 showingAlert = true
            } else if !hasChanges {
                 errorMessage = "Keine Änderungen zum Speichern." // Info
                 showingAlert = true
            }
            return false
        }

        isLoading = true
        errorMessage = nil
        var success = false

        // Erstelle Payload nur mit den geänderten Feldern (wie im Original-Check)
        // Stelle sicher, dass UpdateDebtorPayloadDTO in PayloadDTOs.swift existiert
        let updatePayload = UpdateDebtorPayloadDTO(
            name: currentDebtor.name == originalDebtor?.name ? nil : currentDebtor.name,
            addressStreet: currentDebtor.addressStreet == originalDebtor?.addressStreet ? nil : currentDebtor.addressStreet,
            addressZip: currentDebtor.addressZip == originalDebtor?.addressZip ? nil : currentDebtor.addressZip,
            addressCity: currentDebtor.addressCity == originalDebtor?.addressCity ? nil : currentDebtor.addressCity,
            addressCountry: currentDebtor.addressCountry == originalDebtor?.addressCountry ? nil : currentDebtor.addressCountry,
            email: currentDebtor.email == originalDebtor?.email ? nil : currentDebtor.email,
            phone: currentDebtor.phone == originalDebtor?.phone ? nil : currentDebtor.phone,
            debtorType: currentDebtor.debtorType == originalDebtor?.debtorType ? nil : currentDebtor.debtorType,
            notes: currentDebtor.notes == originalDebtor?.notes ? nil : currentDebtor.notes
        )

        // Prüfen, ob Payload effektiv leer ist (sollte durch canSave abgedeckt sein, aber doppelt hält besser)
        let payloadData = try? JSONEncoder().encode(updatePayload)
        let payloadDict = try? JSONSerialization.jsonObject(with: payloadData ?? Data()) as? [String: Any]
        if payloadDict?.isEmpty ?? true {
             print("No effective changes detected to send for update.")
             isLoading = false
             errorMessage = "Keine Änderungen zum Speichern." // Info
             showingAlert = true
             return true // Betrachte es als "Erfolg", da keine Aktion nötig
        }


        do {
            print("Updating Debtor \(currentDebtor.id)...")
            // Rufe die updateDebtor Methode im APIService auf
            let savedDebtor = try await apiService.updateDebtor(id: currentDebtor.id, payload: updatePayload)

            // Nach erfolgreichem Speichern: Original aktualisieren und lokalen State synchronisieren
            self.originalDebtor = savedDebtor
            self.debtor = savedDebtor // Wichtig, damit hasChanges wieder false wird
            success = true
            print("Debtor saved successfully.")
            errorMessage = "Schuldner erfolgreich gespeichert." // Erfolgsmeldung
            showingAlert = true

        } catch let error as APIError {
             print("API Error saving Debtor: \(error.localizedDescription)")
             self.errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
             self.showingAlert = true
             success = false
        } catch {
            print("Unexpected Error saving Debtor: \(error)")
            self.errorMessage = "Unerwarteter Fehler: \(error.localizedDescription)"
            self.showingAlert = true
            success = false
        }
        isLoading = false
        return success
    }

    /// Setzt die Änderungen auf den letzten gespeicherten Stand zurück.
    func resetChanges() {
        // Nur zurücksetzen, wenn ein Original existiert
        if let original = originalDebtor {
            self.debtor = original
            errorMessage = nil // Auch Fehler zurücksetzen
            isLoading = false // Sicherstellen, dass Loading-State beendet ist
            print("Debtor changes reset.")
        }
    }
}
