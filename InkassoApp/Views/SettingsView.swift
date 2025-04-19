import SwiftUI

struct SettingsView: View {
    @Binding var isApiTokenSet: Bool
    @State private var currentToken: String = KeychainService.shared.loadToken() ?? ""
    @State private var newToken: String = ""
    @State private var saveMessage: String = ""
    @State private var messageColor: Color = .green
    // Lade über die Computed Property
    @State private var apiBaseURL: String = APIService.shared.currentBaseURLString ?? ""

    var forceShow: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Einstellungen")
                .font(.title)

            GroupBox("API Verbindung") {
                 VStack(alignment: .leading) {
                    Text("Basis-URL des Workers (inkl. /api Pfad):")
                    // Korrekt verkettete Modifier:
                    TextField("https://wild-thunder-d361.siewertservices.workers.dev/api", text: $apiBaseURL)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)
                        .disableAutocorrection(true)
                       

                    Text("Bearer Token:")
                        .padding(.top, 5)
                    SecureField("API Token hier einfügen", text: $newToken)
                         .textFieldStyle(.roundedBorder)

                    HStack {
                         Button("Verbindung testen & Speichern") {
                              saveSettings()
                         }
                         .disabled(newToken.isEmpty || apiBaseURL.isEmpty || !(apiBaseURL.lowercased().starts(with: "http")))

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
            // Verwende die Computed Property zum Lesen
            currentToken = KeychainService.shared.loadToken() ?? ""
            apiBaseURL = APIService.shared.currentBaseURLString ?? ""
            isApiTokenSet = !currentToken.isEmpty && !apiBaseURL.isEmpty
        }
    }

    // Korrigierte Speicherfunktion
    func saveSettings() {
        let cleanedUrlString = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)

        // --- KORRIGIERTE URL-PRÜFUNG ---
        guard !cleanedUrlString.isEmpty,
              cleanedUrlString.lowercased().starts(with: "http"),
              URL(string: cleanedUrlString) != nil // Prüft nur, ob URL syntaktisch gültig ist
        else {
            saveMessage = "Bitte eine gültige Basis-URL eingeben (muss mit http:// oder https:// beginnen)."
            messageColor = .red
            return
        }
        // --- ENDE KORREKTUR ---

        guard !newToken.isEmpty else {
             saveMessage = "Bitte einen API Token eingeben."
             messageColor = .red
             return
        }

        // Setze die URL im Service (die Methode ist public)
        APIService.shared.setBaseURL(urlString: cleanedUrlString)

        // Speichere den Token
        let success = KeychainService.shared.saveToken(newToken)
        if success {
            currentToken = newToken
            isApiTokenSet = true
            saveMessage = "Token & URL gespeichert!"
            messageColor = .green
            newToken = ""
            if forceShow == false {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
            }
        } else {
            saveMessage = "Fehler beim Speichern des Tokens im Schlüsselbund."
            messageColor = .red
        }
    }

    // deleteToken Funktion bleibt wie zuvor
    func deleteToken() {
        let success = KeychainService.shared.deleteToken()
         if success {
             currentToken = ""
             newToken = ""
             isApiTokenSet = false
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
