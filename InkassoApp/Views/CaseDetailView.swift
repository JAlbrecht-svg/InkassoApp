import SwiftUI

struct CaseDetailView: View {
    @StateObject private var viewModel: CaseDetailViewModel
    private var caseListViewModel: CaseListViewModel?
    let caseToLoad: Case

    init(listViewModel: CaseListViewModel?, caseToLoad: Case) {
        self.caseListViewModel = listViewModel
        self.caseToLoad = caseToLoad
        _viewModel = StateObject(wrappedValue: CaseDetailViewModel(listViewModel: listViewModel))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.caseItem == nil {
                ProgressView("Lade Fall Details...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.showingAlert {
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable().scaledToFit().frame(width: 50, height: 50)
                        .foregroundColor(.red).padding(.bottom)
                    Text("Fehler beim Laden").font(.title2).padding(.bottom, 5)
                    Text(error).foregroundColor(.red).multilineTextAlignment(.center)
                    Button("Erneut versuchen") {
                        Task { await viewModel.loadCaseDetails(caseId: caseToLoad.id) }
                    }
                    .padding(.top)
                }
                .padding()
            } else if let caseItem = viewModel.caseItem {
                Form {
                    basicInfoSection(caseItem: caseItem)
                    auftragSection(caseItem: caseItem)
                    debtorSection(caseItem: caseItem)
                    amountsSection(caseItem: caseItem)
                    statusSection(caseItem: caseItem)
                    paymentsSection(caseItem: caseItem)
                    actionsSection(caseItem: caseItem)
                }
                .disabled(viewModel.isLoading)
                .overlay {
                    if viewModel.isLoading {
                         ProgressView()
                             .padding()
                             .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                             .shadow(radius: 3)
                     }
                }
            } else {
                 Text("Fallinformationen nicht verfügbar oder werden geladen...")
                     .foregroundColor(.secondary)
                     .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .navigationTitle("Fall: \(caseToLoad.caseReference)")
        .task {
            if viewModel.caseItem == nil || viewModel.caseItem?.id != caseToLoad.id {
                await viewModel.loadCaseDetails(caseId: caseToLoad.id)
            }
        }
        .sheet(isPresented: $viewModel.showingAddPaymentSheet) {
             NavigationView {
                 AddPaymentSheet(caseId: viewModel.caseItem?.id ?? "",
                                 currency: viewModel.caseItem?.currency ?? "EUR",
                                 caseViewModel: viewModel)
             }
             .frame(minWidth: 350, idealWidth: 400, minHeight: 400)
        }
        .sheet(isPresented: $viewModel.showingAddActionSheet) {
              NavigationView {
                  AddActionSheet(caseId: viewModel.caseItem?.id ?? "",
                                 actionTypeOptions: viewModel.actionTypeOptions,
                                 caseViewModel: viewModel)
              }
              .frame(minWidth: 350, idealWidth: 450, minHeight: 450)
        }
        .alert("Hinweis", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
         .toolbar {
              ToolbarItemGroup(placement: .primaryAction) {
                  Button { viewModel.showingAddPaymentSheet = true } label: {
                      Label("Zahlung", systemImage: "eurosign.circle")
                  }.help("Neue Zahlung erfassen")

                  Button { viewModel.showingAddActionSheet = true } label: {
                      Label("Aktion", systemImage: "plus.message")
                  }.help("Neue Aktion/Notiz erfassen")
              }
         }
    }

    // --- Aufgeteilte Sektionen ---
    @ViewBuilder private func basicInfoSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func auftragSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func debtorSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func amountsSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func statusSection(caseItem: Case) -> some View { /* ... wie zuvor, verwendet $viewModel.selectedStatusOptionId ... */ }
    @ViewBuilder private func paymentsSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func actionsSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }

    // --- Korrigierter Helfer für Statusfarbe ---
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
            case "open": return .blue
            case "reminder_1", "reminder_2", "payment_plan", "contested": return .orange
            case "paid": return .green
            case "legal_internal", "legal_external", "legal": return .purple
            case "closed_uncollectible": return .gray
            default: return .secondary // Fehlender Default-Fall hinzugefügt
        }
    }
    // --- Ende Korrektur ---
}

// Preview bleibt wie zuvor
#Preview {
     let mockCase = Case(id: "case-prev", debtorId: "d1", auftragId: "a1", caseReference: "AZ-PREV-001", originalAmount: 100.50, feesAmount: 10, interestAmount: 2.5, paidAmount: 20, currency: "EUR", status: "reminder_1", reasonForClaim: "Testrechnung", openedAt: Date().ISO8601Format(), dueDate: Date().ISO8601Format(), closedAt: nil, createdAt: Date().ISO8601Format(), updatedAt: Date().ISO8601Format(), debtorName: "Max Schuldner Preview", auftragName: "Test Auftrag Preview", mandantName: "Test Mandant Preview", mandantNumber: "1234", addressStreet: "Test Str. 1", addressZip: "12345", addressCity: "Teststadt")
     return NavigationView {
         CaseDetailView(listViewModel: nil, caseToLoad: mockCase)
     }
}
