import Foundation
import SwiftUI // Für @MainActor und ObservableObject
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

    // Auswahlmöglichkeiten für Status-Filter bereitstellen (aus KV laden?)
    // Definition von CaseStatusOption muss in ModelTypes.swift sein
    let statusOptions: [CaseStatusOption] = [
        CaseStatusOption(id: ""), // Alle
        CaseStatusOption(id: "open"),
        CaseStatusOption(id: "reminder_1"),
        CaseStatusOption(id: "reminder_2"),
        CaseStatusOption(id: "payment_plan"),
        CaseStatusOption(id: "legal"), // Evtl. spezifischer
        CaseStatusOption(id: "paid"),
        CaseStatusOption(id: "closed_uncollectible"),
        CaseStatusOption(id: "contested")
        // ... weitere Status ...
    ]

    private var apiService = APIService.shared

    init() {
        // Debounce für Suchbegriff einrichten
        searchCancellable = searchTermDebounce
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // 0.5 Sek warten nach letzter Eingabe
            .removeDuplicates() // Nicht neu suchen, wenn Begriff gleich bleibt
            .sink { [weak self] term in // Verwende weak self um Retain Cycles zu vermeiden
                print("Debounced search term: \(term)")
                // --- KORREKTUR HIER ---
                // Starte einen neuen Task für den async-Aufruf
                Task {
                    // Stelle sicher, dass self noch existiert
                    await self?.loadCases(isSearchTriggered: true)
                }
                // --- ENDE KORREKTUR ---
            }
    }

    // Wird aufgerufen, wenn sich der Suchtext in der View ändert
    func searchTextChanged(_ newTerm: String) {
        // self.searchTerm wird durch @State/$localSearchTerm in der View aktualisiert
        // Sende nur den neuen Begriff an den Debouncer
        searchTermDebounce.send(newTerm)
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
                // TODO: Paginierung (limit/offset) hinzufügen und übergeben
            )
            self.cases = fetchedCases
            self.errorMessage = nil // Fehler löschen bei Erfolg
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

    // Aktualisiert einen Fall in der Liste (z.B. nach Update in DetailView)
    func refreshCaseInList(_ updatedCase: Case) {
         if let index = cases.firstIndex(where: { $0.id == updatedCase.id }) {
             // TODO: Prüfen ob der aktualisierte Fall noch den Filtern entspricht!
             cases[index] = updatedCase
             print("Fall \(updatedCase.id) in Liste aktualisiert.")
         }
     }

    // Löschfunktion bleibt auskommentiert, da für Fälle nicht empfohlen
    /*
    func deleteCase(_ caseItem: Case) async -> Bool { ... }
    */
}
