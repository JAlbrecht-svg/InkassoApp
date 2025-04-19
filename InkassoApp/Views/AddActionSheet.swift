//
//  AddActionSheet.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import SwiftUI

struct AddActionSheet: View {
    // Übergebene Daten
    let caseId: String
    let actionTypeOptions: [String]
    @ObservedObject var caseViewModel: CaseDetailViewModel // Für Callback

    // Lokaler State für Formulareingaben
    @State private var selectedActionType: String = ""
    @State private var actionDate: Date = Date()
    @State private var notes: String = ""
    @State private var costString: String = ""

    // Zustand für UI
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    @Environment(\.dismiss) var dismiss

     // Computed Property für Kosten
    private var costValue: Double? {
        let cleanedString = costString.replacingOccurrences(of: ",", with: ".")
        guard !cleanedString.isEmpty else { return 0.0 } // Erlaube leeres Feld (-> Kosten 0.0)
        return Double(cleanedString)
    }

     // Prüft, ob gespeichert werden kann
     private var canSave: Bool {
         !selectedActionType.isEmpty && !isSaving && costValue != nil // costValue ist nie nil wenn Logik oben stimmt
     }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Neue Aktion / Notiz erfassen")
                .font(.title2)
                .padding(.bottom)

            Form {
                Picker("Aktionstyp:", selection: $selectedActionType) {
                     Text("Bitte wählen...").tag("")
                     ForEach(actionTypeOptions, id: \.self) { type in
                         // Zeige Typ lesbarer an
                         Text(type.replacingOccurrences(of: "_", with: " ").capitalized).tag(type)
                     }
                 }

                DatePicker("Aktionsdatum:", selection: $actionDate, displayedComponents: .date)

                 TextField("Kosten (Optional):", text: $costString)
                     .textFieldStyle(.roundedBorder)

                 Section("Notizen (Optional)") {
                     TextEditor(text: $notes)
                         .frame(height: 150)
                         .border(Color.secondary.opacity(0.5))
                         .cornerRadius(5)
                 }

                  if let errorMessage = errorMessage {
                     Text("Fehler: \(errorMessage)")
                         .foregroundColor(.red)
                         .padding(.top, 5)
                 }
            }

            Spacer()

             HStack {
                 Spacer()
                 Button("Abbrechen") {
                     dismiss()
                 }
                 .keyboardShortcut(.cancelAction)

                 Button("Speichern") {
                     Task { await saveAction() }
                 }
                 .keyboardShortcut(.defaultAction)
                 .disabled(!canSave)
                 .overlay { if isSaving { ProgressView().controlSize(.small) } }
             }

        }
        .padding()
        .frame(minWidth: 350, idealWidth: 450, minHeight: 450)
         .onAppear {
             // Setze initialen Wert für Picker
             if selectedActionType.isEmpty && !actionTypeOptions.isEmpty {
                  selectedActionType = actionTypeOptions.contains("note_added") ? "note_added" : actionTypeOptions.first ?? ""
             }
         }
    }

    func saveAction() async {
         guard !selectedActionType.isEmpty else {
             errorMessage = "Bitte einen Aktionstyp auswählen."
             return
         }
         guard let cost = costValue else {
             errorMessage = "Ungültiger Wert für Kosten."
             return
         }
         if cost < 0 {
              errorMessage = "Kosten dürfen nicht negativ sein."
              return
         }


         isSaving = true
         errorMessage = nil

         // ISO Format für Datum (nur YYYY-MM-DD)
         let dateFormatter = ISO8601DateFormatter()
         dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
         let actionDateString = dateFormatter.string(from: actionDate)

         // TODO: createdByUser vom eingeloggten Benutzer holen
         let createdByUser: String? = nil // Platzhalter

         let payload = CreateActionPayloadDTO(
             caseId: caseId,
             actionType: selectedActionType,
             actionDate: actionDateString,
             notes: notes.isEmpty ? nil : notes,
             cost: cost, // Sende Wert oder 0.0
             createdByUser: createdByUser
         )

         // Rufe Speicherfunktion im CaseDetailViewModel auf
         let success = await caseViewModel.saveNewAction(payload: payload)

         if success {
             dismiss() // Schließe bei Erfolg
         } else {
             isSaving = false
             // Fehlermeldung wird im CaseDetailViewModel gesetzt und dort per Alert angezeigt,
             // wir können sie hier aber auch direkt anzeigen.
             errorMessage = caseViewModel.errorMessage ?? "Unbekannter Fehler beim Speichern."
         }
    }
}

// Preview braucht Dummy ViewModel
#Preview {
     let previewCase = Case(id: "case-prev", debtorId: "d1", auftragId: "a1", caseReference: "AZ-PREV-001", originalAmount: 100.50, feesAmount: 10, interestAmount: 2.5, paidAmount: 20, currency: "EUR", status: "reminder_1", reasonForClaim: "Testrechnung", openedAt: Date().ISO8601Format(), dueDate: Date().ISO8601Format(), closedAt: nil, createdAt: Date().ISO8601Format(), updatedAt: Date().ISO8601Format())
     let detailVM = CaseDetailViewModel(listViewModel: nil)
     detailVM.caseItem = previewCase

     return Text("Vorschau-Button")
        .sheet(isPresented: .constant(true)) {
             NavigationView {
                 AddActionSheet(caseId: "case-prev", actionTypeOptions: ["note_added", "phone_call_success", "letter_sent"], caseViewModel: detailVM)
             }
        }
}
