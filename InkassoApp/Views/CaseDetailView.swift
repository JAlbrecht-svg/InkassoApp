import SwiftUI

struct CaseDetailView: View {
    // ... (@StateObject, init etc. wie zuvor) ...

    var body: some View {
        ScrollView {
            Form {
                // ... (Andere Sektionen: basicInfo, auftrag, amounts etc. wie zuvor) ...

                // --- DEBTOR SECTION mit korrektem NavigationLink ---
                 @ViewBuilder
                 private func debtorSection(caseItem: Case) -> some View {
                    Section("Schuldner") {
                         Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 15, verticalSpacing: 8) {
                             GridRow {
                                 Text("Name:")
                                 // --- KORREKTER NAVIGATION LINK ---
                                 // Übergibt die debtorId (String) als Wert
                                 NavigationLink(value: caseItem.debtorId) {
                                     Text(caseItem.debtorName ?? caseItem.debtorId)
                                         .fontWeight(.medium)
                                         .foregroundColor(.accentColor) // Macht es wie einen Link aussehen
                                         // .underline() // Optional
                                 }
                                 .buttonStyle(.plain) // Wichtig für korrekten Look
                                 // --- ENDE KORREKTUR ---
                             }
                             if caseItem.addressStreet != nil || caseItem.addressCity != nil {
                                 GridRow(alignment: .top) { Text("Adresse:"); Text("\(caseItem.addressStreet ?? "")\n\(caseItem.addressZip ?? "") \(caseItem.addressCity ?? "")").textSelection(.enabled) }
                             } else {
                                 GridRow { Text("Adresse:"); Text("(Nicht verfügbar)").foregroundColor(.secondary) }
                             }
                         }
                    }
                }
                // --- ENDE DEBTOR SECTION ---

                // ... (Andere Sektionen: status, paymentPlan, payments, actions etc. wie zuvor) ...

            } // Ende Form
            .padding()
        }
        // ... (Rest der View: task, sheets, alert, toolbar, statusColor etc. wie zuvor) ...
    }
    // ... (Alle anderen @ViewBuilder Section-Funktionen wie zuvor) ...
}

// Preview bleibt wie zuvor
#Preview { /* ... wie zuvor ... */ }

// String Extension bleibt in Utils
