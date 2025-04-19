//
//  WorkflowStepListViewModel.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import Foundation
import SwiftUI

@MainActor
class WorkflowStepListViewModel: ObservableObject {
    @Published var steps: [WorkflowStep] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert = false

    private var apiService = APIService.shared

    func loadSteps(workflowId: String) async {
         guard !isLoading else { return }
         isLoading = true
         // errorMessage = nil
         print("Lade Steps für Workflow: \(workflowId)")
         do {
             steps = try await apiService.fetchWorkflowSteps(workflowId: workflowId)
             // Optional sortieren nach stepOrder falls API das nicht garantiert
             steps.sort { $0.stepOrder < $1.stepOrder }
             errorMessage = nil
         } catch {
              self.errorMessage = "Fehler beim Laden der Steps: \(error.localizedDescription)"
              self.showingAlert = true
         }
         isLoading = false
    }
    // TODO: Create, Update, Delete, Reorder etc.
}