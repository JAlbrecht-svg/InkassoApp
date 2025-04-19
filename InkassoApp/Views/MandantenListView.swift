import SwiftUI

struct MandantenListView: View {
    @StateObject private var viewModel = MandantenViewModel()
    @State private var showingCreateSheet = false

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(viewModel.mandanten) { mandant in
                    NavigationLink(value: mandant) { // Wert für NavigationStack/SplitView
                        HStack {
                            Text(mandant.name)
                            Spacer()
                            Text("(\(mandant.mandantNumber))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteMandanten) // Löschen in Liste
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            // .searchable(text: $searchText) // TODO: Suche implementieren

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .navigationTitle("Mandanten")
        .navigationDestination(for: Mandant.self) { mandant in
             MandantDetailView(listViewModel: viewModel, mandantToEdit: mandant)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("Neu", systemImage: "plus")
                }
                 .help("Neuen Mandanten erstellen")
            }
            ToolbarItem {
                Button {
                    Task { await viewModel.loadMandanten() }
                } label: {
                    Label("Aktualisieren", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
                .help("Mandantenliste neu laden")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
             NavigationView { // NavigationView innerhalb des Sheets für Titel/Buttons
                  MandantDetailView(listViewModel: viewModel, mandantToEdit: nil)
             }
             .frame(minWidth: 400, minHeight: 400) // Gib dem Sheet eine Mindestgröße
        }
        .task {
            if viewModel.mandanten.isEmpty {
                await viewModel.loadMandanten()
            }
        }
        // Korrigierte Alert-Signatur
        .alert("Fehler", isPresented: $viewModel.showingAlert, presenting: viewModel.errorMessage) { _ in
             Button("OK"){ viewModel.errorMessage = nil } // Löscht die Fehlermeldung beim Schließen
        } message: { messageText in
             Text(messageText) // Zeigt die Fehlermeldung an
        }
    }

    private func deleteMandanten(at offsets: IndexSet) {
        let mandantenToDelete = offsets.map { viewModel.mandanten[$0] }
        Task {
            for mandant in mandantenToDelete {
                await viewModel.deleteMandant(mandant)
                // Fehler werden im ViewModel behandelt und per Alert angezeigt
            }
        }
    }
}

#Preview {
    NavigationView {
        MandantenListView()
    }
}
