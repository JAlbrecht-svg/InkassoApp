import Foundation
import SwiftUI

@MainActor
class DebtorDetailViewModel: ObservableObject {

    @Published var debtor: Debtor? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    private(set) var originalDebtor: Debtor? // Setter ist private, Getter internal (default)
    private var apiService = APIService.shared
    private var debtorIdToLoad: String

    init(debtorId: String) {
        self.debtorIdToLoad = debtorId.isEmpty || debtorId == "debtor-preview" ? "" : debtorId
    }

    var isNewDebtor: Bool {
        originalDebtor == nil
    }

    func loadDebtor() async {
        guard !isLoading else { return }
        guard !debtorIdToLoad.isEmpty else {
            self.errorMessage = "Keine Schuldner-ID zum Laden vorhanden."
            self.showingAlert = true
            return
        }
        if debtor != nil && debtor?.id == debtorIdToLoad {
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let fetchedDebtor = try await apiService.fetchDebtor(id: debtorIdToLoad)
            self.debtor = fetchedDebtor
            self.originalDebtor = fetchedDebtor
            errorMessage = nil
        } catch {
            self.errorMessage = "Fehler beim Laden der Schuldnerdetails: \(error.localizedDescription)"
            self.showingAlert = true
            self.debtor = nil
            self.originalDebtor = nil
        }
        isLoading = false
    }

    func saveDebtor() async -> Bool {
        guard let currentDebtor = debtor else {
             errorMessage = "Keine Schuldnerdaten zum Speichern vorhanden."; showingAlert = true; return false
        }
        guard !currentDebtor.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
             errorMessage = "Schuldnername darf nicht leer sein."; showingAlert = true; return false
        }
        guard currentDebtor != originalDebtor else {
             errorMessage = "Keine Änderungen zum Speichern."
             showingAlert = true
             return true
         }

        isLoading = true
        errorMessage = nil
        var success = false

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

        let payloadData = try? JSONEncoder().encode(updatePayload)
        let payloadDict = try? JSONSerialization.jsonObject(with: payloadData ?? Data()) as? [String: Any]
        if payloadDict?.isEmpty ?? true {
             isLoading = false
             errorMessage = "Keine Änderungen zum Speichern."
             showingAlert = true
             return true
        }

        do {
            let savedDebtor = try await apiService.updateDebtor(id: currentDebtor.id, payload: updatePayload)
            self.originalDebtor = savedDebtor
            self.debtor = savedDebtor
            success = true
            errorMessage = "Schuldner erfolgreich gespeichert."
            showingAlert = true
        } catch {
             self.errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
             self.showingAlert = true
             success = false
        }
        isLoading = false
        return success
    }

    func resetChanges() {
        if let original = originalDebtor {
            self.debtor = original
        }
        errorMessage = nil
        isLoading = false
    }
}
