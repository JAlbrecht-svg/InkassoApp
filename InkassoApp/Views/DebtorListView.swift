import SwiftUI

struct DebtorListView: View {
    @StateObject private var viewModel = DebtorListViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Lade Schuldner...")
            } else if let error = viewModel.errorMessage {
                 VStack {
                     Text("Fehler: \(error)").foregroundColor(.red).padding()
                     Button("Erneut versuchen") { Task { await viewModel.loadDebtors() } }
                 }
            } else {
                List {
                     if viewModel.debtors.isEmpty {
                         Text("Keine Schuldner vorhanden.")
                             .foregroundColor(.secondary)
                     }
                    ForEach(viewModel.debtors) { debtor in
                        NavigationLink(value: debtor) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(debtor.name).font(.headline)
                                    Text("\(debtor.addressZip ?? "") \(debtor.addressCity ?? "")")
                                         .font(.subheadline)
                                         .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(debtor.debtorType == "business" ? "Firma" : "Privat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                     // TODO: Löschen nur wenn keine Fälle verknüpft sind!
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Schuldner")
        .navigationDestination(for: Debtor.self) { debtor in
            DebtorDetailView(debtor: debtor)
        }
        .toolbar {
             ToolbarItem {
                  Button {
                      // TODO: Sheet/Navigation zum Erstellen eines neuen Schuldners
                  } label: { Label("Neu", systemImage: "plus") }
                  .help("Neuen Schuldner erstellen")
             }
            ToolbarItem {
                Button { Task { await viewModel.loadDebtors() } } label: { Label("Aktualisieren", systemImage: "arrow.clockwise") }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            if viewModel.debtors.isEmpty {
                await viewModel.loadDebtors()
            }
        }
         // Korrigierte Alert-Signatur
         .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil }
        } message: { messageText in
             Text(messageText)
        }
    }
}


struct DebtorDetailView: View {
    let debtor: Debtor
    // TODO: DetailViewModel für Bearbeitung

    var body: some View {
         Form {
             Section("Kontaktdaten") {
                Text("Name: \(debtor.name)")
                Text("Typ: \(debtor.debtorType == "business" ? "Firma" : "Privat")")
                Text("E-Mail: \(debtor.email ?? "-")")
                Text("Telefon: \(debtor.phone ?? "-")")
             }
             Section("Adresse") {
                  Text("Straße: \(debtor.addressStreet ?? "-")")
                  Text("PLZ: \(debtor.addressZip ?? "-")")
                  Text("Stadt: \(debtor.addressCity ?? "-")")
                  Text("Land: \(debtor.addressCountry ?? "DE")") // Default DE?
             }
              Section("Notizen") {
                   Text(debtor.notes ?? "-")
              }
             Section("System") {
                  Text("ID: \(debtor.id)").font(.caption)
                  Text("Erstellt: \(formattedDate(debtor.createdAt))")   // Globale Funktion
                  Text("Geändert: \(formattedDate(debtor.updatedAt))") // Globale Funktion
             }
             Section("Zugehörige Fälle") {
                  NavigationLink("Fälle anzeigen (\(/* TODO: Anzahl laden? */ 0 ))") {
                       CaseListView(debtorIdFilter: debtor.id)
                  }
             }
         }
         .padding()
         .navigationTitle("Schuldner: \(debtor.name)")
          .toolbar { // TODO: Bearbeiten/Speichern Buttons
              ToolbarItem { Button("Bearbeiten") { /* TODO */ } }
          }
    }
}

#Preview {
    NavigationView {
        DebtorListView()
    }
}
