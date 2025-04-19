//
//  CaseDetailView.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//


import SwiftUI

struct CaseDetailView: View {
    // ViewModel wird hier erstellt, da es den Zustand für *diesen* Detailbildschirm hält
    @StateObject private var viewModel: CaseDetailViewModel
    // Referenz zum Listen-ViewModel für Refresh nach Statusänderung etc.
    private var caseListViewModel: CaseListViewModel?

    // Wird für Navigation übergeben
    let caseToLoad: Case

    // Initialisierer
    init(listViewModel: CaseListViewModel?, caseToLoad: Case) {
        self.caseListViewModel = listViewModel
        self.caseToLoad = caseToLoad
        // Erstelle das StateObject *hier* mit den übergebenen Daten
        _viewModel = StateObject(wrappedValue: CaseDetailViewModel(listViewModel: listViewModel))
    }


    var body: some View {
        // Zeige Lade-/Fehlerstatus oder den Inhalt
        Group {
            if viewModel.isLoading && viewModel.caseItem == nil {
                ProgressView("Lade Fall Details...")
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Fehler beim Laden").font(.headline).padding(.bottom)
                    Text(error).foregroundColor(.red)
                    Button("Erneut versuchen") {
                        Task { await viewModel.loadCaseDetails(caseId: caseToLoad.id) }
                    }
                    .padding(.top)
                }
            } else if let caseItem = viewModel.caseItem {
                // Hauptansicht mit Formularen und eingebetteten Listen
                Form {
                    // --------- Falldaten (Read-Only) ---------
                    Section("Falldaten") {
                        Grid(alignment: .leading) {
                            GridRow { Text("Aktenzeichen:"); Text(caseItem.caseReference).bold() }
                            GridRow { Text("Status:"); Text(caseItem.status.uppercased()).foregroundColor(statusColor(caseItem.status)) }
                            GridRow { Text("Grund:"); Text(caseItem.reasonForClaim ?? "-") }
                            GridRow { Text("Eröffnet:"); Text(formattedDate(caseItem.openedAt)) }
                            GridRow { Text("Fällig:"); Text(formattedDateOptional(caseItem.dueDate)) }
                            GridRow { Text("Geschlossen:"); Text(formattedDateOptional(caseItem.closedAt)) }
                        }
                    }

                     // --------- Auftrags-/Mandantendaten (Read-Only) ---------
                    Section("Auftrag / Mandant") {
                         Grid(alignment: .leading) {
                            GridRow { Text("Auftrag:"); Text("\(caseItem.auftragName ?? "-") (\(caseItem.auftragId))") }
                            GridRow { Text("Mandant:"); Text("\(caseItem.mandantName ?? "-") (\(caseItem.mandantNumber ?? "?"))") }
                            // TODO: Link zu Auftrag/Mandant (wenn separate Views dafür existieren würden)
                         }
                    }

                    // --------- Schuldnerdaten (Read-Only) ---------
                    Section("Schuldner") {
                         Grid(alignment: .leading) {
                            GridRow { Text("Name:"); Text(caseItem.debtorName ?? caseItem.debtorId) }
                            GridRow { Text("Adresse:"); Text("\(caseItem.addressStreet ?? "")\n\(caseItem.addressZip ?? "") \(caseItem.addressCity ?? "")") }
                            // TODO: Link zu Schuldnerdetails (wenn separate View existiert)
                         }
                    }

                    // --------- Beträge (Read-Only) ---------
                    Section("Beträge (\(caseItem.currency))") {
                         Grid(alignment: .leading) {
                            GridRow { Text("Hauptforderung:"); Text(caseItem.originalAmount, format: .currency(code: caseItem.currency)) }
                            GridRow { Text("Gebühren:"); Text(caseItem.feesAmount, format: .currency(code: caseItem.currency)) }
                            GridRow { Text("Zinsen:"); Text(caseItem.interestAmount, format: .currency(code: caseItem.currency)) }
                            GridRow { Text("Gezahlt:"); Text(caseItem.paidAmount, format: .currency(code: caseItem.currency)).foregroundColor(.green) }
                            GridRow { Text("Gesamtforderung:"); Text(caseItem.totalDue, format: .currency(code: caseItem.currency)) }
                            GridRow { Text("Offen:"); Text(caseItem.outstandingAmount, format: .currency(code: caseItem.currency)).bold() }
                         }
                    }

                     // --------- Status ändern ---------
                     Section("Status ändern") {
                         HStack {
                             Picker("Neuer Status:", selection: $viewModel.selectedStatusOptionId) {
                                 ForEach(viewModel.statusOptions) { option in
                                     Text(option.name).tag(option.id)
                                 }
                             }
                              .disabled(viewModel.isLoading || viewModel.selectedStatusOptionId == caseItem.status) // Deaktivieren wenn Status schon gesetzt ist

                             Button("Übernehmen") {
                                 Task { await viewModel.updateStatus(newStatus: viewModel.selectedStatusOptionId) }
                             }
                             .disabled(viewModel.isLoading || viewModel.selectedStatusOptionId == caseItem.status)
                             .padding(.leading)
                         }
                     }

                    // --------- Zahlungen ---------
                    Section("Zahlungen") {
                        // Eingebettete PaymentListView
                        PaymentListView(caseId: caseItem.id)
                            .frame(minHeight: 100, maxHeight: 300) // Begrenzte Höhe
                         Button("Neue Zahlung erfassen...") {
                              viewModel.showingAddPaymentSheet = true
                         }
                         .padding(.top, 5)
                    }

                     // --------- Aktionen ---------
                    Section("Aktionen / Notizen") {
                        // Eingebettete ActionListView
                        ActionListView(caseId: caseItem.id)
                             .frame(minHeight: 150, maxHeight: 400) // Begrenzte Höhe
                         Button("Neue Aktion/Notiz erfassen...") {
                              viewModel.showingAddActionSheet = true
                         }
                         .padding(.top, 5)
                    }

                } // Ende Form
                .disabled(viewModel.isLoading) // Gesamtes Formular während Laden deaktivieren
                .overlay { // Ladeindikator als Overlay
                    if viewModel.isLoading {
                         ProgressView()
                             .padding()
                             .background(.ultraThinMaterial)
                             .cornerRadius(10)
                     }
                }

            } else {
                // Wird angezeigt, wenn caseItem noch nil ist, aber kein Fehler vorliegt
                 Text("Fallinformationen nicht verfügbar.")
                     .foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle("Fall: \(caseToLoad.caseReference)") // Titel aus übergebenem Item
        .task {
            // Lade Details, wenn die View erscheint
            await viewModel.loadCaseDetails(caseId: caseToLoad.id)
        }
        .sheet(isPresented: $viewModel.showingAddPaymentSheet) {
             // Sheet für neue Zahlung
             NavigationView { // NavigationView im Sheet für Titel/Buttons
                 AddPaymentSheet(caseId: viewModel.caseItem?.id ?? "", // ID übergeben
                                 currency: viewModel.caseItem?.currency ?? "EUR",
                                 viewModel: viewModel) // ViewModel für Callback
             }
        }
        .sheet(isPresented: $viewModel.showingAddActionSheet) {
             // Sheet für neue Aktion
              NavigationView {
                  AddActionSheet(caseId: viewModel.caseItem?.id ?? "",
                                 actionTypeOptions: viewModel.actionTypeOptions, // Optionsliste übergeben
                                 viewModel: viewModel)
              }
        }
        .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
            Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
            Text(messageText)
        }
    }

     // Helfer für Statusfarbe (Duplikat aus ListView - besser in Util auslagern)
     private func statusColor(_ status: String) -> Color {
         switch status.lowercased() {
             case "open": return .blue
             case "reminder_1", "reminder_2", "payment_plan", "contested": return .orange
             case "paid": return .green
             case "legal_internal", "legal_external", "legal": return .purple
             case "closed_uncollectible": return .gray
             default: return .secondary
         }
     }
}


#Preview {
    // Mock-Daten für Preview
    let mockCase = Case(id: "case-prev", debtorId: "d1", auftragId: "a1", caseReference: "AZ-PREV-001", originalAmount: 100.50, feesAmount: 10, interestAmount: 2.5, paidAmount: 20, currency: "EUR", status: "reminder_1", reasonForClaim: "Testrechnung", openedAt: Date().ISO8601Format(), dueDate: Date().ISO8601Format(), closedAt: nil, createdAt: Date().ISO8601Format(), updatedAt: Date().ISO8601Format(), debtorName: "Max Schuldner Preview", auftragName: "Test Auftrag Preview", mandantName: "Test Mandant Preview", mandantNumber: "1234", addressStreet: "Test Str. 1", addressZip: "12345", addressCity: "Teststadt") // Ergänzte Mock-Daten

    return NavigationView {
        // Pass dummy list view model (or nil)
        CaseDetailView(listViewModel: nil, caseToLoad: mockCase)
    }
}