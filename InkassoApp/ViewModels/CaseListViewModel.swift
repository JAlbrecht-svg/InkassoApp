import Foundation
import SwiftUI

@MainActor
class CaseListViewModel: ObservableObject {

    @Published var cases: [Case] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    var auftragIdFilter: String?
    var debtorIdFilter: String?
    var statusFilter: String?
    // TODO: Add other filters like date ranges, search term?

    private var apiService = APIService.shared

    func loadCases() async {
        guard !isLoading else { return }
        isLoading = true
        // errorMessage = nil

        print("Lade Fälle... Filter: [Auftrag: \(auftragIdFilter ?? "Alle"), Debtor: \(debtorIdFilter ?? "Alle"), Status: \(statusFilter ?? "Alle")]")

        do {
            let fetchedCases = try await apiService.fetchCases(
                auftragId: auftragIdFilter,
                debtorId: debtorIdFilter,
                status: statusFilter
                // TODO: Weitere Filter hier übergeben
            )
            self.cases = fetchedCases
            self.errorMessage = nil
            print("Fälle geladen: \(cases.count)")
        } catch let error as APIError {
             print("API Error loading cases: \(error.localizedDescription)")
             self.errorMessage = "Fehler beim Laden der Fälle: \(error.localizedDescription)"
             self.showingAlert = true
        } catch {
            print("Unexpected Error loading cases: \(error)")
            self.errorMessage = "Unerwarteter Fehler: \(error.localizedDescription)"
            self.showingAlert = true
        }

        isLoading = false
    }

    func refreshCaseInList(_ updatedCase: Case) {
         if let index = cases.firstIndex(where: { $0.id == updatedCase.id }) {
             cases[index] = updatedCase
             print("Fall \(updatedCase.id) in Liste aktualisiert.")
         }
     }
}
