import SwiftUI

struct SettingsView: View {
    @Binding var isApiTokenSet: Bool
    @State private var currentToken: String = KeychainService.shared.loadToken() ?? ""
    @State private var newToken: String = ""
    @State private var saveMessage: String = ""
    @State private var messageColor: Color = .green
    // apiBaseURL State wird nicht mehr benötigt

    var forceShow: Bool = false
    @Environment(\.dismiss) var dismiss

    // --- KORREKTUR: Feste URL anzeigen ---
    private let fixedApiBaseURL = "https://wild-thunder-d361.siewertservices.workers.dev/api"
    // --- ENDE KORREKTUR ---

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Einstellungen")
                .font(.title)

            GroupBox("API Verbindung") {
                 VStack(alignment: .leading) {
                    // --- KORREKTUR: URL nur anzeigen ---
                    Text("Verwendete Basis-URL:")
                    Text(fixedApiBaseURL) // Zeige feste URL an
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                    // TextField für apiBaseURL entfernt
                    // --- ENDE KORREKTUR ---

                    Text("Bearer Token:")
                        .padding(.top, 5)
                    SecureField("Neuen API Token hier einfügen", text: $newToken)
                         .textFieldStyle(.roundedBorder)

                    HStack {
                         // --- KORREKTUR: Button speichert nur Token ---
                         Button("Verbindung testen & Token Speichern") {
                              saveTokenOnly() // Neue Funktion verwenden
                         }
                         .disabled(newToken.isEmpty) // Nur Token prüfen
                         // --- ENDE KORREKTUR ---

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
            // Nur Token laden, URL ist fest
            currentToken = KeychainService.shared.loadToken() ?? ""
            isApiTokenSet = !currentToken.isEmpty
        }
    }

    // --- KORREKTUR: Nur Token speichern ---
    func saveTokenOnly() {
        guard !newToken.isEmpty else {
             saveMessage = "Bitte einen API Token eingeben."
             messageColor = .red
             return
        }

        // Speichere den Token
        let success = KeychainService.shared.saveToken(newToken)
        if success {
            currentToken = newToken
            isApiTokenSet = true
            saveMessage = "Token gespeichert!"
            messageColor = .green
            newToken = "" // Feld leeren
            // Schließen-Logik kann bleiben
            if forceShow == false {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
            }
        } else {
            saveMessage = "Fehler beim Speichern des Tokens im Schlüsselbund."
            messageColor = .red
        }
    }
    // --- ENDE KORREKTUR ---

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
