// ViewModels/DebtorDetailViewModel.swift
import Foundation
import SwiftUI

@MainActor
class DebtorDetailViewModel: ObservableObject {

    @Published var debtor: Debtor? = nil // Wird geladen
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    // Original bleibt private für Reset
    private var originalDebtor: Debtor?
    private var apiService = APIService.shared
    private var debtorIdToLoad: String

    // Initialisierer bleibt gleich
    init(debtorId: String) { /* ... wie zuvor ... */ }

    // loadDebtor bleibt gleich (setzt debtor und originalDebtor)
    func loadDebtor() async { /* ... wie zuvor ... */ }

    // hasChanges wird jetzt nicht mehr direkt von der View benötigt
    // var hasChanges: Bool { ... }

    // canSave wird jetzt nicht mehr direkt von der View benötigt
    // var canSave: Bool { ... }

    // Speichert die Änderungen am Schuldner über den APIService.
    // Nimmt den *aktuellen* Stand des Schuldners entgegen (von der View gesetzt).
    func saveDebtor() async -> Bool {
        // Prüfung, ob überhaupt ein Debtor zum Speichern da ist
        guard let currentDebtor = debtor else {
             errorMessage = "Keine Schuldnerdaten zum Speichern vorhanden."; showingAlert = true; return false
        }
        // Grundlegende Validierung im VM
        guard !currentDebtor.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
             errorMessage = "Schuldnername darf nicht leer sein."; showingAlert = true; return false
        }
        // Prüfe auf echte Änderungen im Vergleich zum Original
         guard currentDebtor != originalDebtor else {
             print("Save skipped: No effective changes.")
             errorMessage = "Keine Änderungen zum Speichern."
             showingAlert = true
             return true // Keine Änderungen -> "Erfolg"
         }


        isLoading = true; errorMessage = nil
        var success = false

        // Erstelle Payload nur mit geänderten Feldern
        let updatePayload = UpdateDebtorPayloadDTO( /* ... Payload erstellen, Vergleich mit originalDebtor ... */
             name: currentDebtor.name == originalDebtor?.name ? nil : currentDebtor.name,
             // ... (alle anderen Felder analog) ...
             addressStreet: currentDebtor.addressStreet == originalDebtor?.addressStreet ? nil : currentDebtor.addressStreet,
             addressZip: currentDebtor.addressZip == originalDebtor?.addressZip ? nil : currentDebtor.addressZip,
             addressCity: currentDebtor.addressCity == originalDebtor?.addressCity ? nil : currentDebtor.addressCity,
             addressCountry: currentDebtor.addressCountry == originalDebtor?.addressCountry ? nil : currentDebtor.addressCountry,
             email: currentDebtor.email == originalDebtor?.email ? nil : currentDebtor.email,
             phone: currentDebtor.phone == originalDebtor?.phone ? nil : currentDebtor.phone,
             debtorType: currentDebtor.debtorType == originalDebtor?.debtorType ? nil : currentDebtor.debtorType,
             notes: currentDebtor.notes == originalDebtor?.notes ? nil : currentDebtor.notes
        )

        // Prüfen, ob Payload effektiv leer ist (sollte durch obigen Check abgedeckt sein)
        let payloadData = try? JSONEncoder().encode(updatePayload); let payloadDict = try? JSONSerialization.jsonObject(with: payloadData ?? Data()) as? [String: Any]; if payloadDict?.isEmpty ?? true { print("No effective changes detected to send for update."); isLoading = false; errorMessage = "Keine Änderungen zum Speichern."; showingAlert = true; return true }


        do {
            print("Updating Debtor \(currentDebtor.id)...")
            let savedDebtor = try await apiService.updateDebtor(id: currentDebtor.id, payload: updatePayload)
            self.originalDebtor = savedDebtor // Original aktualisieren
            self.debtor = savedDebtor // Lokalen State synchronisieren
            success = true; print("Debtor saved successfully."); errorMessage = "Schuldner erfolgreich gespeichert."; showingAlert = true
        } catch { /* ... Fehlerbehandlung wie zuvor ... */
            self.errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"; self.showingAlert = true; success = false; print("Error saving Debtor: \(error)")
        }
        isLoading = false; return success
    }

    // Setzt den @Published debtor auf das Original zurück.
    // Die View muss dann ihre @State-Variablen neu laden via .onChange.
    func resetChanges() {
        if let original = originalDebtor { self.debtor = original }; errorMessage = nil; isLoading = false; print("Debtor changes reset.")
    }
}
