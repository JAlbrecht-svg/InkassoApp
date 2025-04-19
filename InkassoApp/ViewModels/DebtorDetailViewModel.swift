// ViewModels/DebtorDetailViewModel.swift
import Foundation
import SwiftUI

@MainActor
class DebtorDetailViewModel: ObservableObject {

    @Published var debtor: Debtor? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    // Original zum Vergleichen und für isNewDebtor Check (bleibt private)
    private var originalDebtor: Debtor?
    private var apiService = APIService.shared
    private var debtorIdToLoad: String

    // Initialisierer nimmt nur die ID entgegen
    init(debtorId: String) {
        self.debtorIdToLoad = debtorId.isEmpty || debtorId == "debtor-preview" ? "" : debtorId
        print("Debtor Detail VM init for ID: \(self.debtorIdToLoad.isEmpty ? "New/Invalid" : self.debtorIdToLoad)")
    }

    /// Computed Property, die prüft, ob der Debtor neu ist (wird von der View verwendet)
    var isNewDebtor: Bool {
        originalDebtor == nil
    }

    /// Lädt die Details für den Schuldner
    func loadDebtor() async {
        guard !isLoading else { return }
        guard !debtorIdToLoad.isEmpty else {
            self.errorMessage = "Keine Schuldner-ID zum Laden vorhanden."; self.showingAlert = true; return
        }
        if debtor != nil && debtor?.id == debtorIdToLoad { print("Debtor \(debtorIdToLoad) already loaded."); return }

        isLoading = true; errorMessage = nil
        print("Lade Debtor Details für ID: \(debtorIdToLoad)")
        do {
            let fetchedDebtor = try await apiService.fetchDebtor(id: debtorIdToLoad)
            self.debtor = fetchedDebtor; self.originalDebtor = fetchedDebtor; errorMessage = nil
        } catch {
            self.errorMessage = "Fehler: \(error.localizedDescription)"; self.showingAlert = true; print("Error loading debtor details: \(error)"); self.debtor = nil; self.originalDebtor = nil
        }
        isLoading = false
    }

    /// Prüft, ob Änderungen vorliegen
    var hasChanges: Bool {
        guard let current = debtor, let original = originalDebtor else { return debtor != nil } // Änderung, wenn neu und debtor existiert
        return current != original // Verwendet Hashable Konformität für einfachen Vergleich
    }

    /// Prüft, ob gespeichert werden kann
    var canSave: Bool {
        guard let current = debtor else { return false }
        return !current.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasChanges && !isLoading
    }

    /// Speichert die Änderungen
    func saveDebtor() async -> Bool {
        guard let currentDebtor = debtor, canSave else {
            print("Save skipped: No effective changes or invalid data.")
            if debtor?.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true { errorMessage = "Schuldnername darf nicht leer sein."; showingAlert = true }
            else if !hasChanges { errorMessage = "Keine Änderungen zum Speichern."; showingAlert = true }
            return false
        }

        isLoading = true; errorMessage = nil
        var success = false
        let updatePayload = UpdateDebtorPayloadDTO( /* ... Payload wie zuvor erstellen ... */
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
        // Prüfen ob Payload effektiv leer ist (optional)
        let payloadData = try? JSONEncoder().encode(updatePayload); let payloadDict = try? JSONSerialization.jsonObject(with: payloadData ?? Data()) as? [String: Any]; if payloadDict?.isEmpty ?? true { print("No effective changes to send."); isLoading = false; errorMessage = "Keine Änderungen zum Speichern."; showingAlert = true; return true }

        do {
            print("Updating Debtor \(currentDebtor.id)...")
            let savedDebtor = try await apiService.updateDebtor(id: currentDebtor.id, payload: updatePayload)
            self.originalDebtor = savedDebtor; self.debtor = savedDebtor; success = true; print("Debtor saved successfully."); errorMessage = "Schuldner erfolgreich gespeichert."; showingAlert = true
        } catch { /* ... Fehlerbehandlung wie zuvor ... */
            self.errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"; self.showingAlert = true; success = false; print("Error saving Debtor: \(error)")
        }
        isLoading = false; return success
    }

    /// Setzt Änderungen zurück
    func resetChanges() { if let original = originalDebtor { self.debtor = original }; errorMessage = nil; isLoading = false; print("Debtor changes reset.") }
}
