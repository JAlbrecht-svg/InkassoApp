//
//  ActionListViewModel.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import Foundation
import SwiftUI

@MainActor
class ActionListViewModel: ObservableObject {
    @Published var actions: [Action] = [] // Hält die Aktionen für eine bestimmte CaseId
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert = false

     private var apiService = APIService.shared
     private var currentCaseId: String? // Merken, für welchen Fall geladen wird

    func loadActions(caseId: String) async {
        // Verhindere Neuladen, wenn schon für diesen Fall geladen wird
         guard !isLoading || currentCaseId != caseId else { return }
         self.currentCaseId = caseId // CaseId merken
         isLoading = true
         // errorMessage = nil
         print("Lade Actions für Case: \(caseId)")
         do {
             actions = try await apiService.fetchActions(caseId: caseId)
             errorMessage = nil
         } catch {
              self.errorMessage = "Fehler beim Laden der Actions: \(error.localizedDescription)"
              self.showingAlert = true
              print("Error loading actions: \(error)")
              self.actions = [] // Liste leeren bei Fehler?
         }
         isLoading = false
    }

    // Funktion zum Hinzufügen einer neuen Aktion zur lokalen Liste (nach erfolgreichem Speichern)
    func addActionToList(_ newAction: Action) {
         // Füge hinzu und sortiere ggf. neu nach Datum
         actions.insert(newAction, at: 0) // Füge oben ein
         actions.sort { $0.actionDate > $1.actionDate } // Neueste zuerst
    }

     // TODO: Funktion zum Aktualisieren einer Aktion (z.B. Notizen) in der Liste
     func updateActionInList(_ updatedAction: Action) {
          if let index = actions.firstIndex(where: { $0.id == updatedAction.id }) {
              actions[index] = updatedAction
          }
     }
}