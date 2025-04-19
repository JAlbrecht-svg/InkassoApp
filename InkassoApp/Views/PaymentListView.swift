import SwiftUI

struct PaymentListView: View {
    @StateObject private var viewModel = PaymentListViewModel()
    let caseId: String

    var body: some View {
        // Entferne das äußere VStack, wenn es in einer Form Section ist
        Group { // Group statt VStack, damit List direkt in Form passt
            if viewModel.isLoading && viewModel.payments.isEmpty { // Nur initial laden anzeigen
                ProgressView()
            } else if let error = viewModel.errorMessage {
                 Text("Fehler: \(error)").foregroundColor(.red)
                 // Kein Button hier, Refresh im DetailView
            } else if viewModel.payments.isEmpty {
                 Text("Keine Zahlungen vorhanden.").foregroundColor(.secondary)
            } else {
                 // Zeige nur die Liste selbst
                 // Entferne .listStyle, um den Stil der Form zu übernehmen
                 ForEach(viewModel.payments) { payment in
                     HStack {
                         VStack(alignment: .leading) {
                             Text(formattedDate(payment.paymentDate))
                             Text(payment.paymentMethod ?? "Unbekannt")
                                 .font(.caption)
                                 .foregroundColor(.secondary)
                             if let ref = payment.reference, !ref.isEmpty {
                                 Text("Ref: \(ref)").font(.caption).italic()
                             }
                             if let notes = payment.notes, !notes.isEmpty {
                                 Text("Notiz: \(notes)").font(.caption).lineLimit(1)
                             }
                         }
                         Spacer()
                         Text(payment.amount, format: .currency(code: "EUR")) // TODO: Währung vom Fall nehmen
                             .fontWeight(.medium)
                             .foregroundColor(.green)
                     }
                     .padding(.vertical, 2) // Weniger Abstand in Form
                 }
                 // Kein .onDelete hier
            }
        }
        // Kein .navigationTitle oder .toolbar hier, wird von CaseDetailView gesteuert
        .task {
            await viewModel.loadPayments(caseId: caseId)
        }
        // Alert wird im übergeordneten View (CaseDetailView) behandelt
    }
}

// Preview angepasst
#Preview {
    // Zeige es in einer Liste oder Form für Kontext
    Form {
        Section("Testzahlungen") {
            PaymentListView(caseId: "case-preview")
        }
    }
    .padding()
    .frame(width: 400, height: 200)
}
