import SwiftUI

struct CaseDetailView: View {
    // --- EIGENSCHAFTEN (DIREKT INNERHALB STRUCT, AUSSERHALB BODY) ---
    @StateObject private var viewModel: CaseDetailViewModel
    // 'private' ist hier korrekt. 'weak' ist bei ObservableObject nicht üblich,
    // wenn keine Zyklen drohen, aber schadet hier nicht.
    private weak var caseListViewModel: CaseListViewModel?
    let caseToLoad: Case
    // --- ENDE EIGENSCHAFTEN ---
    
    // Initialisierer (Direkt innerhalb Struct)
    init(listViewModel: CaseListViewModel?, caseToLoad: Case) {
        self.caseListViewModel = listViewModel
        self.caseToLoad = caseToLoad
        // Erstelle das StateObject *hier*
        _viewModel = StateObject(wrappedValue: CaseDetailViewModel(listViewModel: listViewModel))
    }
    
    // Body (Computed Property)
    var body: some View {
        // --- KORREKTE STRUKTUR BEGINNT HIER ---
        ScrollView { // Äußerste View
            Form { // Form innerhalb ScrollView
                // Bedingte Anzeige basierend auf ViewModel-Status
                if viewModel.isLoading && viewModel.caseItem == nil {
                    HStack { Spacer(); ProgressView("Lade Fall Details..."); Spacer() }
                        .padding(.vertical, 50)
                } else if let error = viewModel.errorMessage, viewModel.showingAlert, viewModel.caseItem == nil {
                    // Fehleranzeige
                    VStack(spacing: 15) {
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
                    .frame(maxWidth: .infinity)
                    
                } else if let caseItem = viewModel.caseItem {
                    // Hauptinhalt mit Sektionen
                    basicInfoSection(caseItem: caseItem)
                    auftragSection(caseItem: caseItem)
                    debtorSection(caseItem: caseItem)
                    amountsSection(caseItem: caseItem)
                    statusSection(caseItem: caseItem)
                    paymentPlanSection(caseItem: caseItem)
                    paymentsSection(caseItem: caseItem)
                    actionsSection(caseItem: caseItem)
                    
                } else {
                    Text("Fallinformationen nicht verfügbar oder werden geladen...")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
            } // Ende Form
            .padding() // Außenpadding für Form
        } // Ende ScrollView
        // Modifier für den Haupt-Container (ScrollView)
        .navigationTitle("Fall: \(caseToLoad.caseReference)")
        .task { if viewModel.caseItem == nil || viewModel.caseItem?.id != caseToLoad.id { await viewModel.loadCaseDetails(caseId: caseToLoad.id) } }
        .sheet(isPresented: $viewModel.showingAddPaymentSheet) { /* ... Sheet Payment ... */ }
        .sheet(isPresented: $viewModel.showingAddActionSheet) { /* ... Sheet Action ... */ }
        .alert("Hinweis", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in Button("OK"){ viewModel.errorMessage = nil } } message: { messageText in Text(messageText) }
        .toolbar { /* ... Toolbar ... */ }
        .overlay { /* ... Overlay für Ladeanzeige beim Speichern ... */ }
        // --- ENDE KORREKTE STRUKTUR BODY ---
    } // Ende Body
    
    // --- Computed Properties für Sektionen (DIREKT INNERHALB STRUCT, AUSSERHALB BODY) ---
    @ViewBuilder private func basicInfoSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func auftragSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func debtorSection(caseItem: Case) -> some View { /* ... Code von oben mit NavigationLink(value: caseItem.debtorId) ... */ }
    @ViewBuilder private func amountsSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func statusSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func paymentPlanSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func paymentsSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    @ViewBuilder private func actionsSection(caseItem: Case) -> some View { /* ... wie zuvor ... */ }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() { // Prüfe den Kleingeschriebenen Status
        case "open": return .blue
        case "reminder_1", "reminder_2", "payment_plan", "contested": return .orange
        case "paid": return .green
        case "legal_internal", "legal_external", "legal": return .purple
        case "closed_uncollectible": return .gray
            // --- Default-Fall für alle anderen/unbekannten Status ---
        default: return .secondary
            
        } // Ende Struct CaseDetailView
        
        // Preview bleibt wie zuvor
        #Preview { /* ... wie zuvor ... */ }
        
        // KEINE String Extension hier! (gehört nach Utils)
    }
}
