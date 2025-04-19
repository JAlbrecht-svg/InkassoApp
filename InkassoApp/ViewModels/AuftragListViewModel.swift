import Foundation
import SwiftUI

@MainActor
class AuftragListViewModel: ObservableObject {
    @Published var auftraege: [Auftrag] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    private var apiService = APIService.shared
    var mandantIdFilter: String? // Wird von View gesetzt

    func loadAuftraege() async {
        guard !isLoading else { return }
        isLoading = true
        // errorMessage = nil
        print("Lade Aufträge für Mandant: \(mandantIdFilter ?? "Alle")")
        do {
            auftraege = try await apiService.fetchAuftraege(mandantId: mandantIdFilter)
            errorMessage = nil
        } catch {
             self.errorMessage = "Fehler beim Laden der Aufträge: \(error.localizedDescription)"
             self.showingAlert = true
        }
        isLoading = false
    }
    // TODO: Delete, Refresh etc.
}
