import Foundation
import SwiftUI

@MainActor
class CaseDetailViewModel: ObservableObject {

    @Published var caseItem: Case? = nil // Der aktuell angezeigte Fall
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false

    // Zustand für eingebettete Listen
    @Published var paymentsViewModel = PaymentListViewModel()
    @Published var actionsViewModel = ActionListViewModel()

    // Zustand für Sheets/Modals
    @Published var showingAddPaymentSheet = false
    @Published var showingAddActionSheet = false

    // --- HINZUGEFÜGTE @Published Variable ---
    @Published var selectedStatusOptionId: String = "" // Hält die Auswahl des Status-Pickers

    // Auswahlmöglichkeiten für Status (wie zuvor)
     let statusOptions: [CaseStatusOption] = [
        CaseStatusOption(id: "open"), CaseStatusOption(id: "reminder_1"), CaseStatusOption(id: "reminder_2"),
        CaseStatusOption(id: "payment_plan"), CaseStatusOption(id: "legal"), CaseStatusOption(id: "paid"),
        CaseStatusOption(id: "closed_uncollectible"), CaseStatusOption(id: "contested")
        // TODO: Diese Liste ggf. aus KV oder API laden für Flexibilität
     ]
     // Auswahlmöglichkeiten für Action Types (wie zuvor)
      let actionTypeOptions: [String] = [
         "phone_call_attempt", "phone_call_success", "email_sent", "letter_sent",
         "payment_reminder", "address_updated", "note_added", "payment_plan_agreed",
         "legal_step_initiated", "cost_added"
         // TODO: Diese Liste ggf. aus KV oder API laden
      ]


    private var apiService = APIService.shared
    private weak var listViewModel: CaseListViewModel? // Um Hauptliste zu aktualisieren

    // Init (wie zuvor)
    init(listViewModel: CaseListViewModel? = nil) {
        self.listViewModel = listViewModel
    }

    func loadCaseDetails(caseId: String) async {
        guard !isLoading else { return }
        // Reset state before loading new case
        self.caseItem = nil // Clear previous case while loading
        self.selectedStatusOptionId = "" // Reset picker selection
        isLoading = true
        errorMessage = nil
        print("Lade Falldetails für ID: \(caseId)")
        do {
            let fetchedCase = try await apiService.fetchCase(id: caseId)
            self.caseItem = fetchedCase
            // --- Initialisiere Picker-Auswahl mit geladenem Status ---
            self.selectedStatusOptionId = fetchedCase.status
            // --- Ende Initialisierung ---
            await loadAssociatedData() // Lade auch zugehörige Daten
            errorMessage = nil
        } catch {
            self.errorMessage = "Fehler beim Laden der Falldetails: \(error.localizedDescription)"
            self.showingAlert = true
            print("Error loading case details: \(error)")
            self.caseItem = nil // Stelle sicher, dass caseItem bei Fehler nil ist
        }
        isLoading = false
    }

    // Lädt Zahlungen und Aktionen für den aktuellen Fall (wie zuvor)
    func loadAssociatedData() async {
        guard let currentCaseId = caseItem?.id else { return }
        print("Lade assoziierte Daten für Fall: \(currentCaseId)")
        // Parallel laden
        async let paymentsLoad: () = paymentsViewModel.loadPayments(caseId: currentCaseId)
        async let actionsLoad: () = actionsViewModel.loadActions(caseId: currentCaseId)
        _ = await [paymentsLoad, actionsLoad] // Warte auf beide
    }

    // Ändert den Status des aktuellen Falls (wie zuvor, setzt jetzt auch selectedStatusOptionId bei Erfolg)
    func updateStatus(newStatus: String) async {
         guard let currentCase = caseItem, !isLoading else { return }
         guard currentCase.status != newStatus else {
             print("Status ist bereits \(newStatus). Kein Update nötig.")
             return
         }

         isLoading = true
         errorMessage = nil
         print("Ändere Status von Fall \(currentCase.id) zu \(newStatus)")
         let payload = UpdateCasePayloadDTO(status: newStatus)

         do {
             let updatedCase = try await apiService.updateCase(id: currentCase.id, payload: payload)
             // Aktualisiere lokalen Fall UND die Picker-Auswahl
             self.caseItem = updatedCase
             self.selectedStatusOptionId = updatedCase.status // <- Wichtig bei Erfolg
             listViewModel?.refreshCaseInList(updatedCase) // Informiere Liste
             errorMessage = nil
             print("Status erfolgreich geändert.")
         } catch {
             self.errorMessage = "Fehler beim Ändern des Status: \(error.localizedDescription)"
             self.showingAlert = true
             print("Error updating case status: \(error)")
             // Setze Picker zurück auf alten Status bei Fehler?
             self.selectedStatusOptionId = currentCase.status // <- Setze zurück bei Fehler
         }
         isLoading = false
    }

    // Speichert neue Zahlung (wie zuvor)
    func saveNewPayment(payload: CreatePaymentPayloadDTO) async -> Bool {
         guard let currentCaseId = caseItem?.id, !isLoading else { return false }
         var mutablePayload = payload
         mutablePayload.caseId = currentCaseId

         isLoading = true
         errorMessage = nil
         var success = false
         print("Speichere neue Zahlung für Fall \(currentCaseId)...")

         do {
             _ = try await apiService.createPayment(payload: mutablePayload)
             await loadCaseDetails(caseId: currentCaseId) // Lädt Fall + Zahlungen/Aktionen neu
             success = true
             print("Zahlung erfolgreich gespeichert.")
         } catch {
              self.errorMessage = "Fehler beim Speichern der Zahlung: \(error.localizedDescription)"
              self.showingAlert = true
              print("Error saving payment: \(error)")
              success = false
         }
         isLoading = false
         return success
    }

     // Speichert neue Aktion (wie zuvor)
     func saveNewAction(payload: CreateActionPayloadDTO) async -> Bool {
          guard let currentCaseId = caseItem?.id, !isLoading else { return false }
          var mutablePayload = payload
          mutablePayload.caseId = currentCaseId

          isLoading = true
          errorMessage = nil
          var success = false
          print("Speichere neue Aktion für Fall \(currentCaseId)...")

          do {
              _ = try await apiService.createAction(payload: mutablePayload)
              await actionsViewModel.loadActions(caseId: currentCaseId) // Nur Aktionen neu laden
               // Optional: Fall neu laden, falls Aktion Kosten verursacht hat
               if payload.cost != nil && payload.cost! > 0 {
                    await loadCaseDetails(caseId: currentCaseId) // Lade Fall neu, um Beträge zu aktualisieren
               }
              success = true
              print("Aktion erfolgreich gespeichert.")
          } catch {
               self.errorMessage = "Fehler beim Speichern der Aktion: \(error.localizedDescription)"
               self.showingAlert = true
               print("Error saving action: \(error)")
               success = false
          }
          isLoading = false
          return success
     }
}
