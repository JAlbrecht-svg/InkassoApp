import Foundation
import SwiftUI // Für @MainActor

// Definiere den APIError Enum (Korrekte, vollständige Version)
enum APIError: Error, LocalizedError {
    case invalidURL                         // Für ungültige URLs
    case requestFailed(Error)               // Für Netzwerkfehler (URLSession Fehler)
    case invalidResponseStatus(statusCode: Int, responseBody: String?) // Für HTTP-Status != 2xx
    case decodingError(Error)               // Für JSON Decoding Fehler
    case encodingError(Error)               // Für JSON Encoding Fehler
    case unauthorized                       // Für HTTP 401 Fehler
    case serverError(message: String?)      // Für allgemeine Serverfehler (z.B. 500)
    case operationFailed(message: String)   // Für andere spezifische Fehler

    // Die errorDescription ist für die Anzeige in Alerts nützlich
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige API URL konfiguriert."
        case .requestFailed(let error): return "Netzwerkanfrage fehlgeschlagen: \(error.localizedDescription)"
        case .invalidResponseStatus(let statusCode, let body):
            let bodyText = (body?.isEmpty ?? true) ? "Keine weitere Info vom Server." : body!
            return "Ungültiger Server-Status: \(statusCode).\nAntwort: \(bodyText)"
        case .decodingError(let error):
            var details = ""
             if let decodingError = error as? DecodingError {
                 switch decodingError {
                 case .typeMismatch(let type, let context):
                     details = "Typkonflikt für \(type) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .valueNotFound(let type, let context):
                      details = "Wert nicht gefunden für Typ \(type) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .keyNotFound(let key, let context):
                      details = "Schlüssel nicht gefunden: \(key.stringValue) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .dataCorrupted(let context):
                      details = "Daten beschädigt bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 @unknown default:
                     details = "Unbekannter Decoding-Fehler."
                 }
             } else {
                details = error.localizedDescription
             }
             return "Fehler beim Verarbeiten der Serverantwort: \(details)"
        case .encodingError(let error): return "Fehler beim Vorbereiten der Anfrage: \(error.localizedDescription)"
        case .unauthorized: return "Nicht autorisiert. Bitte API Token in den Einstellungen prüfen."
        case .serverError(let message): return "Serverfehler: \(message ?? "Unbekannter Fehler")"
        case .operationFailed(let message): return message
        }
    }
}

// Leere Struktur für Antworten ohne Body (z.B. 204)
struct EmptyResponse: Decodable {}


@MainActor // Stellt sicher, dass Updates auf dem Main Thread passieren (für @Published in ViewModels)
class APIService: ObservableObject {
    static let shared = APIService() // Singleton

    // Basis-URL (privat für Setzen, öffentlich lesbar über Computed Property)
    private var baseURL: URL?

    // Öffentliche Computed Property zum sicheren Lesen der URL als String
    var currentBaseURLString: String? {
        baseURL?.absoluteString
    }

    // API Token wird sicher aus dem Keychain geladen
    private var apiToken: String? {
        KeychainService.shared.loadToken()
    }

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()

        // Lade gespeicherte URL beim Start oder verwende deine Standard-URL
        let defaultUrlString = "https://wild-thunder-d361.siewertservices.workers.dev/api" // Deine URL + /api
        let savedUrlString = UserDefaults.standard.string(forKey: "apiBaseURL")

        if let urlStr = savedUrlString, !urlStr.isEmpty {
             self.baseURL = URL(string: urlStr)
             print("APIService initialized. BaseURL loaded from UserDefaults: \(urlStr)")
        } else {
             self.baseURL = URL(string: defaultUrlString)
             print("APIService initialized. BaseURL set to default: \(defaultUrlString)")
             // Optional: Speichere die Default-URL direkt beim ersten Start
             // if self.baseURL != nil {
             //     UserDefaults.standard.set(defaultUrlString, forKey: "apiBaseURL")
             // }
        }
        if self.baseURL == nil {
             print("WARNING: APIService could not initialize baseURL.")
        }
    }

    // Öffentliche Methode zum Setzen/Aktualisieren der Basis-URL (aus SettingsView)
    func setBaseURL(urlString: String) {
        let cleanedUrlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        self.baseURL = URL(string: cleanedUrlString)
        // Speichere für nächsten Start
        if self.baseURL != nil {
            UserDefaults.standard.set(cleanedUrlString, forKey: "apiBaseURL")
            print("API Base URL set and saved to: \(cleanedUrlString)")
        } else {
             print("API Base URL could not be set (invalid URL?): \(cleanedUrlString)")
             UserDefaults.standard.removeObject(forKey: "apiBaseURL") // Ungültige URL löschen
        }
    }

    // Computed Property zum Prüfen, ob der Service für Anfragen bereit ist
    var isConfigured: Bool {
        return baseURL != nil && apiToken != nil && !(apiToken?.isEmpty ?? true)
    }

    // MARK: - Helper für Requests
    private func buildRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let currentBaseURL = baseURL else {
            throw APIError.operationFailed(message: "API Basis-URL ist nicht konfiguriert. Bitte in Einstellungen prüfen.")
        }
        // Stelle sicher, dass der Pfad relativ ist oder konstruiere die URL korrekt
        guard let url = URL(string: path, relativeTo: currentBaseURL) else {
            print("Error creating URL from path: \(path) relative to \(currentBaseURL.absoluteString)")
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // Timeout auf 30 Sekunden erhöht

        guard let token = apiToken, !token.isEmpty else {
            print("API Service: API Token fehlt im Keychain!")
            throw APIError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = body
            // Optional: Body loggen (Vorsicht bei sensiblen Daten!)
            // print("[DATA] Request Body: \(String(data: body, encoding: .utf8) ?? "Non-UTF8 Body")")
        }
        print("[\(method)] Requesting URL: \(request.url?.absoluteString ?? "INVALID URL")")
        return request
    }

    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTP Response received from \(request.url?.absoluteString ?? "?")")
                throw APIError.invalidResponseStatus(statusCode: 0, responseBody: "Keine HTTP Response erhalten")
            }

            let responseBodyString = String(data: data, encoding: .utf8) ?? "Body nicht als UTF-8 dekodierbar"
            // Logge immer Status und Body (gekürzt bei Erfolg?)
            if !(200...299).contains(httpResponse.statusCode) {
                 print("[\(httpResponse.statusCode)] Response ERROR from \(request.url?.path ?? ""):\n\(responseBodyString)")
            } else {
                 // Body bei Erfolg nur gekürzt loggen?
                 let preview = responseBodyString.prefix(500)
                 print("[\(httpResponse.statusCode)] Response OK from \(request.url?.path ?? ""):\n\(preview)\(responseBodyString.count > 500 ? "..." : "")")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 { throw APIError.unauthorized }
                var serverErrorMessage: String? = nil
                if let errorJson = try? decoder.decode([String: String].self, from: data), let msg = errorJson["error"] {
                    serverErrorMessage = msg
                } else {
                    serverErrorMessage = responseBodyString.isEmpty ? nil : responseBodyString
                }
                throw APIError.invalidResponseStatus(statusCode: httpResponse.statusCode, responseBody: serverErrorMessage)
            }

            // 204 No Content Handling
            if httpResponse.statusCode == 204 {
                if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T { return empty }
                if T.self != EmptyResponse.self {
                    throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received 204 No Content but expected Decodable type \(T.self)")))
                }
                if let empty = EmptyResponse() as? T { return empty } // Fallback für T == EmptyResponse
                throw APIError.operationFailed(message: "Inkonsistenter Zustand bei 204 Response Handling für \(T.self)")
            }

            // Leere Daten bei anderem Statuscode als 204
            if data.isEmpty {
                 if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T { return empty }
                 throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received empty data but expected non-empty Decodable type \(T.self)")))
            }

            // Dekodieren
            do {
                let decodedObject = try decoder.decode(T.self, from: data)
                return decodedObject
            } catch {
                print("--- Decoding Error ---") // Detailliertes Logging beibehalten
                print("Failed to decode type: \(T.self)")
                print("Error: \(error)")
                print("Localized Description: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError { /* ... detaillierte Ausgaben ... */ }
                print("Raw Response Body String: \(responseBodyString)")
                print("--- End Decoding Error ---")
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error // APIError weiterwerfen
        } catch {
            // Fange URLSession-spezifische Fehler ab
            let nsError = error as NSError
            print("URLSession Error / Other Error: Code \(nsError.code), Domain: \(nsError.domain), Description: \(error.localizedDescription)")
            throw APIError.requestFailed(error) // Andere Fehler (Netzwerk etc.)
        }
    }

    // MARK: - Mandanten Endpunkte (Nur Lesen)

    func fetchMandanten() async throws -> [Mandant] {
        let request = try buildRequest(path: "mandanten")
        return try await performRequest(request: request)
    }

    func fetchMandant(id: String) async throws -> Mandant {
        let request = try buildRequest(path: "mandanten/\(id)")
        return try await performRequest(request: request)
    }

    // MARK: - Auftraege Endpunkte (Nur Lesen)

    func fetchAuftraege(mandantId: String? = nil) async throws -> [Auftrag] {
        let path = mandantId == nil ? "auftraege" : "mandanten/\(mandantId!)/auftraege"
        // TODO: Query Parameter für weitere Filter hinzufügen
        let request = try buildRequest(path: path)
        return try await performRequest(request: request)
    }

    func fetchAuftrag(id: String) async throws -> Auftrag {
        let request = try buildRequest(path: "auftraege/\(id)")
        // Annahme: API liefert hier ggf. JOIN-Daten mit (Model muss optional sein)
        return try await performRequest(request: request)
    }

    // MARK: - Cases Endpunkte (Lesen + Status Update)

    func fetchCases(auftragId: String? = nil, debtorId: String? = nil, status: String? = nil, limit: Int = 50, offset: Int = 0, searchTerm: String? = nil) async throws -> [Case] {
        var queryItems: [URLQueryItem] = []
        if let auftragId = auftragId { queryItems.append(URLQueryItem(name: "auftragId", value: auftragId)) }
        if let debtorId = debtorId { queryItems.append(URLQueryItem(name: "debtorId", value: debtorId)) }
        if let status = status, !status.isEmpty { queryItems.append(URLQueryItem(name: "status", value: status)) }
        if let term = searchTerm, !term.isEmpty { queryItems.append(URLQueryItem(name: "search", value: term)) }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))

        var components = URLComponents()
        components.path = "cases" // Pfad ohne / am Anfang für relativeTo
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let path = components.string else { throw APIError.invalidURL }

        let request = try buildRequest(path: path)
        // Annahme: API liefert JOIN-Daten für Namen mit (Case-Model hat optionale Namen)
        return try await performRequest(request: request)
    }

    func fetchCase(id: String) async throws -> Case {
        // Annahme: API liefert hier JOIN-Daten für Debtor, Auftrag, Mandant mit
        let request = try buildRequest(path: "cases/\(id)")
        return try await performRequest(request: request) // Case Struct muss optionale Namen haben
    }

     func updateCase(id: String, payload: UpdateCasePayloadDTO) async throws -> Case {
         guard payload.status != nil || payload.reasonForClaim != nil /* || andere erlaubte Felder */ else {
             throw APIError.operationFailed(message: "Keine änderbaren Felder im Payload für updateCase gefunden.")
         }
        do {
             let body = try encoder.encode(payload)
             let request = try buildRequest(path: "cases/\(id)", method: "PUT", body: body)
             return try await performRequest(request: request)
        } catch let error where !(error is APIError) {
            throw APIError.encodingError(error)
        }
     }

    // MARK: - Payments Endpunkte (Lesen, Erstellen)
    func fetchPayments(caseId: String) async throws -> [Payment] {
        let request = try buildRequest(path: "cases/\(caseId)/payments")
        return try await performRequest(request: request)
    }
    func createPayment(payload: CreatePaymentPayloadDTO) async throws -> Payment {
        do {
            let body = try encoder.encode(payload)
            let request = try buildRequest(path: "payments", method: "POST", body: body)
            return try await performRequest(request: request)
        } catch let error where !(error is APIError) {
            throw APIError.encodingError(error)
        }
    }

    // MARK: - Actions Endpunkte (Lesen, Erstellen, Update Notes)
     func fetchActions(caseId: String) async throws -> [Action] {
         let request = try buildRequest(path: "cases/\(caseId)/actions")
          return try await performRequest(request: request)
     }
     func createAction(payload: CreateActionPayloadDTO) async throws -> Action {
         do {
             // TODO: createdByUser aus eingeloggtem User-Kontext füllen (wenn implementiert)
             let body = try encoder.encode(payload)
             let request = try buildRequest(path: "actions", method: "POST", body: body)
             return try await performRequest(request: request)
         } catch let error where !(error is APIError) {
             throw APIError.encodingError(error)
         }
     }
     func updateActionNotes(id: String, notes: String?) async throws -> Action {
         let payload = UpdateActionPayloadDTO(notes: notes)
          do {
             let body = try encoder.encode(payload)
             let request = try buildRequest(path: "actions/\(id)", method: "PUT", body: body)
             return try await performRequest(request: request)
         } catch let error where !(error is APIError) {
             throw APIError.encodingError(error)
         }
     }

    // MARK: - Debtors Endpunkte (Nur Lesen)
     func fetchDebtors(searchTerm: String? = nil, limit: Int = 50, offset: Int = 0) async throws -> [Debtor] {
          var queryItems: [URLQueryItem] = []
          if let term = searchTerm, !term.isEmpty { queryItems.append(URLQueryItem(name: "search", value: term)) }
          queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
          queryItems.append(URLQueryItem(name: "offset", value: String(offset)))

          var components = URLComponents()
          components.path = "debtors" // Annahme: Endpunkt existiert
          components.queryItems = queryItems.isEmpty ? nil : queryItems

          guard let path = components.string else { throw APIError.invalidURL }

          let request = try buildRequest(path: path)
          return try await performRequest(request: request)
     }

      func fetchDebtor(id: String) async throws -> Debtor {
          let request = try buildRequest(path: "debtors/\(id)") // Annahme Endpunkt existiert
            return try await performRequest(request: request)
       }

     // MARK: - Workflows & Steps Endpunkte (Nur Lesen, falls für Anzeige benötigt)
      func fetchWorkflows() async throws -> [Workflow] {
          let request = try buildRequest(path: "workflows")
          return try await performRequest(request: request)
      }
       func fetchWorkflowSteps(workflowId: String) async throws -> [WorkflowStep] {
          let request = try buildRequest(path: "workflows/\(workflowId)/steps")
          return try await performRequest(request: request)
      }

}
