import SwiftUI

struct PaymentListView: View {
    @StateObject private var viewModel = PaymentListViewModel()
    let caseId: String
    // Optional: Zusätzliche Infos für Titel o.ä.
    var caseReference: String?

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Lade Zahlungen...")
            } else if let error = viewModel.errorMessage {
                 VStack {
                     Text("Fehler: \(error)").foregroundColor(.red).padding()
                     Button("Erneut versuchen") { Task { await viewModel.loadPayments(caseId: caseId) } }
                 }
            } else {
                List {
                    if viewModel.payments.isEmpty {
                        Text("Keine Zahlungen vorhanden.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(viewModel.payments) { payment in
                        // Kein NavigationLink zum Detail, da wenig Infos
                        HStack {
                            VStack(alignment: .leading) {
                                Text(formattedDate(payment.paymentDate)) // Globale Funktion
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
                            Text(String(format: "%.2f", payment.amount)) // TODO: Währung?
                                .fontWeight(.medium)
                                .foregroundColor(.green) // Grün für Zahlung
                        }
                    }
                    // Delete/Edit nicht vorgesehen
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle(caseReference != nil ? "Zahlungen: \(caseReference!)" : "Zahlungen")
        .toolbar {
            ToolbarItem {
                Button {
                    // TODO: Sheet zum Erstellen einer neuen Zahlung
                } label: { Label("Neue Zahlung", systemImage: "plus.circle") }
                .help("Neue Zahlung erfassen")
            }
            ToolbarItem {
                Button { Task { await viewModel.loadPayments(caseId: caseId) } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadPayments(caseId: caseId)
        }
         // Korrigierte Alert-Signatur
         .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
    }
}

// DetailView für Payment (wenn benötigt)
struct PaymentDetailView: View {
    let payment: Payment

    var body: some View {
        Form {
             Text("Betrag: \(String(format: "%.2f", payment.amount))") // Währung?
             Text("Zahlungsdatum: \(formattedDate(payment.paymentDate))") // Globale Funktion
             Text("Methode: \(payment.paymentMethod ?? "-")")
             Text("Referenz: \(payment.reference ?? "-")")
             Text("Notizen: \(payment.notes ?? "-")")
             Text("Erfasst am: \(formattedDate(payment.recordedAt))") // Globale Funktion
             Text("ID: \(payment.id)").font(.caption)
             Text("Case ID: \(payment.caseId)").font(.caption)
        }
        .padding()
        .navigationTitle("Zahlungsdetail")
    }
}

#Preview {
    NavigationView {
        PaymentListView(caseId: "case-preview", caseReference: "AZ-PREVIEW-001")
    }
}
