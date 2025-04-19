//
//  PaymentListViewModel.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import Foundation
import SwiftUI

@MainActor
class PaymentListViewModel: ObservableObject {
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showingAlert = false

    private var apiService = APIService.shared

    func loadPayments(caseId: String) async {
        guard !isLoading else { return }
        isLoading = true
        // errorMessage = nil
         print("Lade Payments für Case: \(caseId)")
        do {
            payments = try await apiService.fetchPayments(caseId: caseId)
            errorMessage = nil
        } catch {
             self.errorMessage = "Fehler beim Laden der Payments: \(error.localizedDescription)"
             self.showingAlert = true
        }
        isLoading = false
    }
    // Create wird oft in einem anderen Kontext ausgelöst (z.B. CaseDetailView)
}