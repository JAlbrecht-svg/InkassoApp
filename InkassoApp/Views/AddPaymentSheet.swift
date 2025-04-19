import SwiftUI

struct AddPaymentSheet: View {
    // Übergebene Daten
    let caseId: String
    let currency: String
    // Verwende @ObservedObject, wenn das ViewModel von außen kommt
    @ObservedObject var caseViewModel: CaseDetailViewModel

    // Lokaler State für Formulareingaben
    @State private var amountString: String = ""
    @State private var paymentDate: Date = Date() // Default = heute
    @State private var paymentMethod: String = ""
    @State private var reference: String = ""
    @State private var notes: String = ""

    // Zustand für UI
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    @Environment(\.dismiss) var dismiss

    // Computed Property für Betrag
    private var amountValue: Double? {
        let cleanedString = amountString.replacingOccurrences(of: ",", with: ".")
        return Double(cleanedString)
    }

    // Prüft, ob gespeichert werden kann
    private var canSave: Bool {
        amountValue != nil && amountValue! > 0 && !isSaving
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Neue Zahlung erfassen")
                .font(.title2)
                .padding(.bottom)

            Form {
                TextField("Betrag (\(currency)):", text: $amountString)
                    // Korrekt angehängte Modifier:
                    .textFieldStyle(.roundedBorder) // <-- Wendet den RoundedBorderTextFieldStyle an
                    .textContentType(.URL)
                    .disableAutocorrection(true)

                DatePicker("Zahlungsdatum:", selection: $paymentDate, displayedComponents: .date)

                TextField("Zahlungsmethode (Optional):", text: $paymentMethod)
                    .textFieldStyle(.roundedBorder)

                TextField("Referenz/Verwendungszweck (Optional):", text: $reference)
                    .textFieldStyle(.roundedBorder)

                Section("Notizen (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .border(Color.secondary.opacity(0.5))
                        .cornerRadius(5)
                }

                if let errorMessage = errorMessage {
                    Text("Fehler: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding(.top, 5)
                }
            }

            Spacer() // Drückt Buttons nach unten

            HStack {
                Spacer()
                Button("Abbrechen") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Speichern") {
                    Task { await savePayment() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
                .overlay { // Zeige Ladeanzeige über Button
                    if isSaving { ProgressView().controlSize(.small) }
                }
            }

        }
        .padding()
        .frame(minWidth: 350, idealWidth: 400, minHeight: 400) // Mindestgröße für Sheet
    }

    func savePayment() async {
        guard let amount = amountValue else {
            errorMessage = "Bitte einen gültigen Betrag eingeben (z.B. 123.45)."
            return
        }
        guard amount > 0 else {
             errorMessage = "Betrag muss größer als 0 sein."
             return
        }

        isSaving = true
        errorMessage = nil

        // ISO Format für Datum (nur YYYY-MM-DD)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let paymentDateString = dateFormatter.string(from: paymentDate)

        let payload = CreatePaymentPayloadDTO(
            caseId: caseId,
            amount: amount,
            paymentDate: paymentDateString,
            paymentMethod: paymentMethod.isEmpty ? nil : paymentMethod,
            reference: reference.isEmpty ? nil : reference,
            notes: notes.isEmpty ? nil : notes
        )

        // Rufe Speicherfunktion im CaseDetailViewModel auf
        let success = await caseViewModel.saveNewPayment(payload: payload)

        if success {
            dismiss() // Schließe Sheet bei Erfolg
        } else {
             isSaving = false // Erlaube erneuten Versuch
             // Fehlermeldung wird im CaseDetailViewModel gesetzt und im Alert angezeigt,
             // aber wir können sie hier auch nochmal anzeigen
             errorMessage = caseViewModel.errorMessage ?? "Unbekannter Fehler beim Speichern."
        }
    }
}

// Preview bleibt wie zuvor
#Preview {
    let previewCase = Case(id: "case-prev", debtorId: "d1", auftragId: "a1", caseReference: "AZ-PREV-001", originalAmount: 100.50, feesAmount: 10, interestAmount: 2.5, paidAmount: 20, currency: "EUR", status: "reminder_1", reasonForClaim: "Testrechnung", openedAt: Date().ISO8601Format(), dueDate: Date().ISO8601Format(), closedAt: nil, createdAt: Date().ISO8601Format(), updatedAt: Date().ISO8601Format())
    let detailVM = CaseDetailViewModel(listViewModel: nil)
    detailVM.caseItem = previewCase

    return Text("Vorschau-Button")
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                 AddPaymentSheet(caseId: "case-prev", currency: "EUR", caseViewModel: detailVM)
            }
        }
}
