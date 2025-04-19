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
    @Published var actions: [Action] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert = false

     private var apiService = APIService.shared

    func loadActions(caseId: String) async {
         guard !isLoading else { return }
         isLoading = true
         // errorMessage = nil
         print("Lade Actions für Case: \(caseId)")
         do {
             actions = try await apiService.fetchActions(caseId: caseId)
             errorMessage = nil
         } catch {
              self.errorMessage = "Fehler beim Laden der Actions: \(error.localizedDescription)"
              self.showingAlert = true
         }
         isLoading = false
    }
     // Create wird oft in einem anderen Kontext ausgelöst
}