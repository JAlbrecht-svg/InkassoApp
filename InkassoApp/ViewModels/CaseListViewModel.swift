import Foundation
import SwiftUI
import Combine // Für Debounce bei Suche

@MainActor
class CaseListViewModel: ObservableObject {

    @Published var cases: [Case] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    // Filter & Such-Eigenschaften
    @Published var statusFilter: String = "" // Leerer String = Alle Status
    @Published var searchTerm: String = ""

    // Combine Subject und Cancellable für Debounce
    private var searchTermDebounce = PassthroughSubject<String, Never>()
    private var searchCancellable: AnyCancellable?


    // TODO: Auswahlmöglichkeiten für Status-Filter bereitstellen (aus KV laden?)
    let statusOptions: [CaseStatusOption] = [
        CaseStatusOption(id: ""), // Alle
        CaseStatusOption(id: "open"),
        CaseStatusOption(id: "reminder_1"),
        CaseStatusOption(id: "reminder_2"),
        CaseStatusOption(id: "payment_plan"),
        CaseStatusOption(id: "legal"), // Evtl. spezifischer
        CaseStatusOption(id: "paid"),
        CaseStatusOption(id: "closed_uncollectible")
        // ... weitere Status ...
    ]


    private var apiService = APIService.shared

    init() {
        // Debounce für Suchbegriff einrichten
        searchCancellable = searchTermDebounce
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // 0.5 Sek warten nach letzter Eingabe
            .removeDuplicates() // Nicht neu suchen, wenn Begriff gleich bleibt
            .sink { [weak self] term in
                print("Debounced search term: \(term)")
                self?.loadCases(isSearchTriggered: true) // Lade mit neuem Suchbegriff
            }
    }

    // Wird aufgerufen, wenn sich der Suchtext in der View ändert
    func searchTextChanged(_ newTerm: String) {
        self.searchTerm = newTerm // Aktualisiere den @Published Wert sofort für die UI
        searchTermDebounce.send(newTerm) // Sende an den Debouncer
    }

    // Wird aufgerufen, wenn sich der Status-Filter ändert
    func statusFilterChanged() {
        // Lade sofort neu, wenn Filter geändert wird
        Task {
            await loadCases(isSearchTriggered: false)
        }
    }

    func loadCases(isSearchTriggered: Bool = false) async {
        // Nur laden, wenn nicht bereits geladen wird
        guard !isLoading else { return }

        isLoading = true
        print("Lade Fälle... Filter: [Status: \(statusFilter.isEmpty ? "Alle" : statusFilter), Search: \(searchTerm)]")

        do {
            let fetchedCases = try await apiService.fetchCases(
                status: statusFilter.isEmpty ? nil : statusFilter, // Sende nil wenn leer
                searchTerm: searchTerm.isEmpty ? nil : searchTerm // Sende nil wenn leer
                // TODO: Paginierung (limit/offset) hinzufügen
            )
            self.cases = fetchedCases
            self.errorMessage = nil
            print("Fälle geladen: \(cases.count)")
        } catch let error as APIError {
             print("API Error loading cases: \(error.localizedDescription)")
             self.errorMessage = "Fehler: \(error.localizedDescription)"
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
             // TODO: Prüfen ob der aktualisierte Fall noch den Filtern entspricht!
             cases[index] = updatedCase
         }
     }
}
