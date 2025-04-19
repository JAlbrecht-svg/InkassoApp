//
//  CaseDetailViewModel.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


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

    // Auswahlmöglichkeiten für Status (könnte aus API/KV kommen)
     let statusOptions: [CaseStatusOption] = [
        CaseStatusOption(id: "open"), CaseStatusOption(id: "reminder_1"), CaseStatusOption(id: "reminder_2"),
        CaseStatusOption(id: "payment_plan"), CaseStatusOption(id: "legal"), CaseStatusOption(id: "paid"),
        CaseStatusOption(id: "closed_uncollectible"), CaseStatusOption(id: "contested")
        // ... weitere ...
     ]
     // Auswahlmöglichkeiten für Action Types (könnte aus API/KV kommen)
      let actionTypeOptions: [String] = [
         "phone_call_attempt", "phone_call_success", "email_sent", "letter_sent",
         "payment_reminder", "address_updated", "note_added", "payment_plan_agreed",
         "legal_step_initiated", "cost_added"
         // ... weitere ...
      ]


    private var apiService = APIService.shared
    private weak var listViewModel: CaseListViewModel? // Um Hauptliste zu aktualisieren

    func loadCaseDetails(caseId: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        print("Lade Falldetails für ID: \(caseId)")
        do {
            let fetchedCase = try await apiService.fetchCase(id: caseId)
            self.caseItem = fetchedCase
            // Lade auch zugehörige Daten
            await loadAssociatedData()
            errorMessage = nil
        } catch {
            self.errorMessage = "Fehler beim Laden der Falldetails: \(error.localizedDescription)"
            self.showingAlert = true
            print("Error loading case details: \(error)")
        }
        isLoading = false
    }

    // Lädt Zahlungen und Aktionen für den aktuellen Fall
    func loadAssociatedData() async {
        guard let currentCaseId = caseItem?.id else { return }
        print("Lade assoziierte Daten für Fall: \(currentCaseId)")
        // Parallel laden
        async let paymentsLoad: () = paymentsViewModel.loadPayments(caseId: currentCaseId)
        async let actionsLoad: () = actionsViewModel.loadActions(caseId: currentCaseId)
        _ = await [paymentsLoad, actionsLoad] // Warte auf beide
    }

    // Ändert den Status des aktuellen Falls
    func updateStatus(newStatus: String) async {
         guard let currentCase = caseItem, !isLoading else { return }
         guard currentCase.status != newStatus else {
             print("Status ist bereits \(newStatus). Kein Update nötig.")
             return
         }

         isLoading = true
         errorMessage = nil
         print("Ändere Status von Fall \(currentCase.id) zu \(newStatus)")

         // Erstelle Payload nur mit Status
         let payload = UpdateCasePayloadDTO(status: newStatus)

         do {
             let updatedCase = try await apiService.updateCase(id: currentCase.id, payload: payload)
             // Aktualisiere lokalen Fall und informiere die Liste
             self.caseItem = updatedCase
             listViewModel?.refreshCaseInList(updatedCase)
             errorMessage = nil
             print("Status erfolgreich geändert.")
         } catch {
             self.errorMessage = "Fehler beim Ändern des Status: \(error.localizedDescription)"
             self.showingAlert = true
             print("Error updating case status: \(error)")
         }
         isLoading = false
    }

    // --- Logik für AddPaymentSheet / AddActionSheet ---
    // Diese wird von den Sheet-Views aufgerufen

    func saveNewPayment(payload: CreatePaymentPayloadDTO) async -> Bool {
         guard let currentCaseId = caseItem?.id, !isLoading else { return false }
         var mutablePayload = payload
         mutablePayload.caseId = currentCaseId // Stelle sicher, dass die CaseID korrekt ist

         isLoading = true
         errorMessage = nil
         var success = false
         print("Speichere neue Zahlung für Fall \(currentCaseId)...")

         do {
             _ = try await apiService.createPayment(payload: mutablePayload)
             // Erfolgreich: Lade Zahlungen neu und aktualisiere den Hauptfall (Beträge ändern sich!)
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
              // Erfolgreich: Lade Aktionen neu (und ggf. den Fall, falls Kosten anfielen)
              await actionsViewModel.loadActions(caseId: currentCaseId)
               // Optional: Fall neu laden, falls Aktion Kosten verursacht hat
               // await loadCaseDetails(caseId: currentCaseId)
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

    // Init um ListViewModel zu übergeben (optional, für Refresh)
    init(listViewModel: CaseListViewModel? = nil) {
        self.listViewModel = listViewModel
    }
}