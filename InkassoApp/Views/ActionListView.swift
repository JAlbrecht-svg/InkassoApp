import SwiftUI

struct ActionListView: View {
    @StateObject private var viewModel = ActionListViewModel()
    let caseId: String

    var body: some View {
        Group { // Group statt VStack
            if viewModel.isLoading && viewModel.actions.isEmpty {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                 Text("Fehler: \(error)").foregroundColor(.red)
            } else if viewModel.actions.isEmpty {
                 Text("Keine Aktionen vorhanden.").foregroundColor(.secondary)
            } else {
                // Zeige Liste ohne eigenen ListStyle
                ForEach(viewModel.actions) { action in
                    // NavigationLink optional, wenn Detailansicht gewünscht
                     // NavigationLink(value: action) {
                         HStack {
                             VStack(alignment: .leading) {
                                  Text(action.actionType) // TODO: Besser lesbaren Namen
                                      .font((action.notes != nil && !action.notes!.isEmpty) ? .headline : .body)
                                  Text(formattedDate(action.actionDate)).font(.caption).foregroundColor(.secondary)
                                   if let notes = action.notes, !notes.isEmpty {
                                       Text(notes)
                                           .font(.caption)
                                           .lineLimit(2) // Erlaube 2 Zeilen für Notizen in der Übersicht
                                           .foregroundColor(.gray)
                                   }
                             }
                             Spacer()
                             if action.cost > 0 {
                                  Text(action.cost, format: .currency(code: "EUR")) // TODO: Währung?
                                      .font(.caption)
                                      .foregroundColor(.orange)
                             }
                         }
                         .padding(.vertical, 2)
                     // } // Ende NavigationLink
                }
                // TODO: Löschen nicht empfohlen oder nur mit viel Vorsicht
            }
        }
        // Kein .navigationTitle oder .toolbar hier
        .task {
            await viewModel.loadActions(caseId: caseId)
        }
        // Alert wird im übergeordneten View behandelt
        // .navigationDestination(for: Action.self) { action in ... } // Nur wenn Link aktiv ist
    }
}

// DetailView bleibt wie zuvor (ActionDetailView.swift)

#Preview {
     Form {
         Section("Testaktionen") {
             ActionListView(caseId: "case-preview")
         }
     }
     .padding()
     .frame(width: 400, height: 300)
}
