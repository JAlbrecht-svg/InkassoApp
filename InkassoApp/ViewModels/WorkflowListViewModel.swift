//
//  WorkflowListViewModel.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import Foundation
import SwiftUI

@MainActor
class WorkflowListViewModel: ObservableObject {
    @Published var workflows: [Workflow] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert = false

    private var apiService = APIService.shared

    func loadWorkflows() async {
         guard !isLoading else { return }
         isLoading = true
         // errorMessage = nil
         print("Lade Workflows...")
         do {
             workflows = try await apiService.fetchWorkflows()
             errorMessage = nil
         } catch {
              self.errorMessage = "Fehler beim Laden der Workflows: \(error.localizedDescription)"
              self.showingAlert = true
         }
         isLoading = false
    }
    // TODO: Delete, Refresh etc.
}