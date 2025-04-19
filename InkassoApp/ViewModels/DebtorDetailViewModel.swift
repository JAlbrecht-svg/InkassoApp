// ViewModels/DebtorDetailViewModel.swift
import Foundation
import SwiftUI

@MainActor
class DebtorDetailViewModel: ObservableObject {

    @Published var debtor: Debtor? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    private var originalDebtor: Debtor? // Für Vergleich/Reset
    private var apiService = APIService.shared
    private var debtorIdToLoad: String

    init(debtorId: String) {
        // Konvertiere Platzhalter-ID zur Sicherheit
        self.debtorIdToLoad = debtorId == "debtor-preview" ? "debtor-001" : debtorId
        print("Debtor Detail VM init for ID: \(self.debtorIdToLoad)")
    }

    func loadDebtor() async {
        guard !isLoading else { return }
        // Nur neu laden, wenn noch kein Debtor geladen wurde oder die ID sich geändert hat (sollte nicht passieren)
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
            self.originalDebtor = fetchedDebtor
            errorMessage = nil
        } catch {
            self.errorMessage = "Fehler beim Laden der Schuldnerdetails: \(error.localizedDescription)"
            self.showingAlert = true
            print("Error loading debtor details: \(error)")
            self.debtor = nil
            self.originalDebtor = nil
        }
        isLoading = false
    }

    var hasChanges: Bool {
        guard let current = debtor, let original = originalDebtor else { return false }
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

    var canSave: Bool {
        guard let current = debtor else { return false }
        // Prüfe, ob Name nicht leer ist UND Änderungen vorhanden sind
        return !current.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasChanges
    }

    func saveDebtor() async -> Bool {
        guard let currentDebtor = debtor, canSave else {
            print("Save skipped: No changes or invalid data.")
            if debtor?.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                 errorMessage = "Schuldnername darf nicht leer sein."
                 showingAlert = true
            } else if !hasChanges {
                 errorMessage = "Keine Änderungen zum Speichern."
                 showingAlert = true // Zeige Info
            }
            return false
        }

        isLoading = true
        errorMessage = nil
        var success = false

        // Erstelle Payload nur mit geänderten Feldern
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

        // Prüfen, ob Payload effektiv leer ist (keine Änderungen gesendet)
        let payloadData = try? JSONEncoder().encode(updatePayload)
        let payloadDict = try? JSONSerialization.jsonObject(with: payloadData ?? Data()) as? [String: Any]
        if payloadDict?.isEmpty ?? true {
             print("No effective changes to send for update.")
             isLoading = false
             errorMessage = "Keine Änderungen zum Speichern." // Zeige Info
             showingAlert = true
             return true // Betrachte es als "Erfolg" ohne API-Call
        }


        do {
            print("Updating Debtor \(currentDebtor.id)...")
            let savedDebtor = try await apiService.updateDebtor(id: currentDebtor.id, payload: updatePayload)
            self.originalDebtor = savedDebtor // Original aktualisieren
            self.debtor = savedDebtor // Lokalen State aktualisieren
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

    func resetChanges() {
        self.debtor = originalDebtor // Auf letzten gespeicherten Stand zurücksetzen
        errorMessage = nil
        isLoading = false
        print("Debtor changes reset.")
    }
}
