//
//  MandantenViewModel.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import Foundation
import SwiftUI

@MainActor
class MandantenViewModel: ObservableObject {

    @Published var mandanten: [Mandant] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert: Bool = false // Für Fehler-Alerts

    private var apiService = APIService.shared

    func loadMandanten() async {
        isLoading = true
        // errorMessage = nil // Fehler nicht sofort löschen, damit Alert sichtbar bleibt
        print("Lade Mandanten...")

        do {
            let fetchedMandanten = try await apiService.fetchMandanten()
            self.mandanten = fetchedMandanten
            self.errorMessage = nil // Fehler löschen bei Erfolg
            print("Mandanten geladen: \(mandanten.count)")
        } catch let error as APIError {
             print("API Error loading Mandanten: \(error.localizedDescription)")
             self.errorMessage = error.localizedDescription
             self.showingAlert = true
        } catch {
            print("Unexpected Error loading Mandanten: \(error)")
            self.errorMessage = "Unerwarteter Fehler: \(error.localizedDescription)"
            self.showingAlert = true
        }

        isLoading = false
    }

     func deleteMandant(_ mandant: Mandant) async -> Bool {
         // Optional: Zeige Bestätigungsdialog vor dem Löschen
         isLoading = true
         errorMessage = nil
         var success = false
         do {
             try await apiService.deleteMandant(id: mandant.id)
             // Erfolgreich -> aus lokaler Liste entfernen
             mandanten.removeAll { $0.id == mandant.id }
             success = true
             print("Mandant \(mandant.id) gelöscht.")
         } catch let error as APIError {
              print("API Error deleting Mandant: \(error.localizedDescription)")
              self.errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
              self.showingAlert = true
              success = false
         } catch {
             print("Unexpected Error deleting Mandant: \(error)")
             self.errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
             self.showingAlert = true
             success = false
         }
         isLoading = false
         return success
     }

    // Wird vom DetailViewModel aufgerufen
    func refreshMandantInList(_ updatedMandant: Mandant) {
        if let index = mandanten.firstIndex(where: { $0.id == updatedMandant.id }) {
            mandanten[index] = updatedMandant
        } else {
            // Wenn neu erstellt, vorne hinzufügen
            mandanten.insert(updatedMandant, at: 0)
        }
    }
}