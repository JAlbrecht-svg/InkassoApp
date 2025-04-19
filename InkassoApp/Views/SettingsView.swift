import SwiftUI

struct SettingsView: View {
    @Binding var isApiTokenSet: Bool
    // Lade initiale Werte beim Erstellen des @State
    @State private var currentToken: String = KeychainService.shared.loadToken() ?? ""
    @State private var newToken: String = ""
    @State private var saveMessage: String = ""
    @State private var messageColor: Color = .green
    @State private var apiBaseURL: String = APIService.shared.currentBaseURLString ?? "" // Korrekter Lesezugriff

    var forceShow: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Einstellungen")
                .font(.title)

            GroupBox("API Verbindung") {
                 VStack(alignment: .leading) {
                    Text("Basis-URL des Workers (inkl. /api Pfad):") // Hinweis hinzugefügt
                    // Modifier direkt am TextField anwenden:
                     TextField("https://wild-thunder-d361.siewertservices.workers.dev/api", text: $apiBaseURL)
                         .textFieldStyle(.roundedBorder)
                         .textContentType(.URL)         // Korrekt: Direkt am TextField
                         .disableAutocorrection(true) // Korrekt: Direkt am TextField
                         .(true)
                         

                    Text("Bearer Token:")
                        .padding(.top, 5)
                    SecureField("API Token hier einfügen", text: $newToken)
                         .textFieldStyle(.roundedBorder)

                    HStack {
                         Button("Verbindung testen & Speichern") {
                              // TODO: API Test-Endpunkt implementieren im Worker?
                              saveSettings()
                         }
                         // Prüfe auch, ob die URL gültig *aussieht* und Token nicht leer ist
                         .disabled(newToken.isEmpty || apiBaseURL.isEmpty || !(apiBaseURL.lowercased().starts(with: "http")))

                         Spacer()
                    }

                    Text("Aktuell gespeicherter Token: \(currentToken.isEmpty ? "Keiner" : "\(String(currentToken.prefix(4)))...\(String(currentToken.suffix(4)))")") // Korrekte Klammerung
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
                 if !forceShow {
                     Button("Schließen") {
                         dismiss()
                     }
                     .keyboardShortcut(.cancelAction)
                 }
             }

        }
        .padding()
        .frame(minWidth: 450, idealWidth: 500, minHeight: 300)
        .onAppear {
            // Werte beim Erscheinen/Aktualisieren der View neu laden
            currentToken = KeychainService.shared.loadToken() ?? ""
            apiBaseURL = APIService.shared.currentBaseURLString ?? "" // Korrekter Lesezugriff
            isApiTokenSet = !currentToken.isEmpty && !apiBaseURL.isEmpty // Update Status
        }
    }

    // Korrigierte Speicherfunktion
    func saveSettings() {
        let cleanedUrlString = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)

        // Prüfe die URL *bevor* sie gesetzt wird
        guard let url = URL(string: cleanedUrlString), !cleanedUrlString.isEmpty, cleanedUrlString.lowercased().starts(with: "http") else {
            saveMessage = "Bitte eine gültige Basis-URL eingeben (muss mit http:// oder https:// beginnen)."
            messageColor = .red
            return
        }
        // Prüfe den Token
        guard !newToken.isEmpty else {
             saveMessage = "Bitte einen API Token eingeben."
             messageColor = .red
             return
        }

        // Setze die URL im Service
        APIService.shared.setBaseURL(urlString: cleanedUrlString)

        // Speichere den Token
        let success = KeychainService.shared.saveToken(newToken)
        if success {
            currentToken = newToken
            isApiTokenSet = true // Wichtig: Status aktualisieren
            saveMessage = "Token & URL gespeichert! App ggf. neu starten oder Hauptfenster neu laden."
            messageColor = .green
            newToken = "" // Feld leeren
            if forceShow == false {
                // Kurze Pause geben, damit Nutzer die Nachricht sieht? Oder direkt schließen.
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                      dismiss()
                 }
            }
        } else {
            saveMessage = "Fehler beim Speichern des Tokens im Schlüsselbund."
            messageColor = .red
            // isApiTokenSet bleibt unverändert oder false? Eher unverändert lassen.
        }
    }

    // deleteToken Funktion bleibt wie zuvor
    func deleteToken() {
        let success = KeychainService.shared.deleteToken()
         if success {
             currentToken = ""
             newToken = ""
             isApiTokenSet = false // Wichtig: Status aktualisieren
             saveMessage = "Token erfolgreich gelöscht."
             messageColor = .green
         } else {
             saveMessage = "Fehler beim Löschen des Tokens."
             messageColor = .red
         }
    }
}

// Preview bleibt wie zuvor
struct SettingsView_Previews: PreviewProvider {
    @State static var tokenSet = false
    static var previews: some View {
        SettingsView(isApiTokenSet: $tokenSet)
    }
}
