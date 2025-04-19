import Foundation
import SwiftUI

@MainActor
class DebtorListViewModel: ObservableObject {

    @Published var debtors: [Debtor] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    // TODO: Filter hinzufügen? (z.B. Suchbegriff für Name)

    private var apiService = APIService.shared

    func loadDebtors() async {
         guard !isLoading else { return }
        isLoading = true
       // errorMessage = nil
        print("Lade Schuldner...")

        do {
            // TODO: APIService.fetchDebtors implementieren!
            self.debtors = try await apiService.fetchDebtors(/*filter: ...*/)
            self.errorMessage = nil
            print("Schuldner geladen: \(debtors.count)")
        } catch let error as APIError {
             print("API Error loading debtors: \(error.localizedDescription)")
             self.errorMessage = "Fehler beim Laden der Schuldner: \(error.localizedDescription)"
             self.showingAlert = true
        } catch {
            print("Unexpected Error loading debtors: \(error)")
            self.errorMessage = "Unerwarteter Fehler: \(error.localizedDescription)"
            self.showingAlert = true
        }

        isLoading = false
    }

    // TODO: Delete/Refresh Funktionen
    func refreshDebtorInList(_ updatedDebtor: Debtor) {
         if let index = debtors.firstIndex(where: { $0.id == updatedDebtor.id }) {
             debtors[index] = updatedDebtor
         }
     }
}
