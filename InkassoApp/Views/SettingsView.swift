import SwiftUI

struct SettingsView: View {
    @Binding var isApiTokenSet: Bool // Wird übergeben
    @State private var currentToken: String = KeychainService.shared.loadToken() ?? ""
    @State private var newToken: String = ""
    @State private var saveMessage: String = ""
    @State private var messageColor: Color = .green
    // Optional: API Base URL hier konfigurierbar machen
    @State private var apiBaseURL: String = APIService.shared.baseURL?.absoluteString ?? ""

    // forceShow wird verwendet, um den "Abbrechen"-Button auszublenden,
    // wenn die View beim App-Start wegen fehlendem Token angezeigt wird.
    var forceShow: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Einstellungen")
                .font(.title)

            GroupBox("API Verbindung") {
                 VStack(alignment: .leading) {
                    Text("Basis-URL des Workers:")
                    TextField("https://worker.subdomain.workers.dev", text: $apiBaseURL)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Text("Bearer Token:")
                        .padding(.top, 5)
                    SecureField("API Token hier einfügen", text: $newToken)
                         .textFieldStyle(.roundedBorder)

                    HStack {
                         Button("Verbindung testen & Speichern") {
                              // TODO: API Test-Endpunkt implementieren?
                              saveSettings()
                         }
                         .disabled(newToken.isEmpty || apiBaseURL.isEmpty)

                         Spacer()
                    }

                     Text("Aktuell gespeicherter Token: \(currentToken.isEmpty ? "Keiner" : "\(String(currentToken.prefix(4)))...\(String(currentToken.suffix(4)))")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 1)

                     if !saveMessage.isEmpty {
                         Text(saveMessage)
                             .foregroundColor(messageColor)
                             .padding(.top, 5)
                     }
                 }.padding(.vertical, 5)

            }


             GroupBox("Gespeicherten Token löschen") {
                 Button("Gespeicherten API Token löschen") {
                      deleteToken()
                 }
                 .disabled(currentToken.isEmpty)
                 .buttonStyle(.bordered)
                 .tint(.red)
             }

            Spacer()

            HStack{
                 Spacer()
                 // Nur anzeigen wenn nicht beim Start erzwungen
                 if !forceShow {
                     Button("Schließen") {
                         dismiss() // Schließt das Einstellungsfenster
                     }
                     .keyboardShortcut(.cancelAction) // Erlaubt CMD+. oder ESC
                 }
             }

        }
        .padding()
        .frame(minWidth: 450, idealWidth: 500, minHeight: 300) // Größe für Einstellungsfenster
        .onAppear {
            // Stelle sicher, dass die angezeigten Werte aktuell sind
            currentToken = KeychainService.shared.loadToken() ?? ""
            apiBaseURL = APIService.shared.baseURL?.absoluteString ?? "" // Lade aktuelle URL
        }
    }

    func saveSettings() {
        guard let url = URL(string: apiBaseURL), !newToken.isEmpty else {
            saveMessage = "Bitte gültige URL und Token eingeben."
            messageColor = .red
            return
        }
        APIService.shared.setBaseURL(urlString: apiBaseURL) // Speichere URL im Service

        let success = KeychainService.shared.saveToken(newToken)
        if success {
            currentToken = newToken // Aktualisiere Anzeige (maskiert)
            isApiTokenSet = true // Informiere die App, dass Token jetzt da ist
            saveMessage = "Token & URL gespeichert!"
            messageColor = .green
            newToken = "" // Feld leeren
            if forceShow == false { // Nur automatisch schließen, wenn es das normale Einstellungsfenster ist
                dismiss()
            }
        } else {
            saveMessage = "Fehler beim Speichern des Tokens im Schlüsselbund."
            messageColor = .red
        }
    }

    func deleteToken() {
        let success = KeychainService.shared.deleteToken()
         if success {
             currentToken = ""
             newToken = ""
             isApiTokenSet = false // Informiere die App
             saveMessage = "Token erfolgreich gelöscht."
             messageColor = .green
         } else {
             saveMessage = "Fehler beim Löschen des Tokens."
             messageColor = .red
         }
    }
}

struct SettingsView_Previews: PreviewProvider {
    // Statisches Binding für die Vorschau
    @State static var tokenSet = false
    static var previews: some View {
        SettingsView(isApiTokenSet: $tokenSet)
    }
}
