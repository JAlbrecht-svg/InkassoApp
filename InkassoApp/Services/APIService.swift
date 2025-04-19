import Foundation

// Definiere den APIError Enum (wie zuvor bereitgestellt)
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponseStatus(statusCode: Int, responseBody: String?)
    case decodingError(Error)
    case encodingError(Error)
    case unauthorized
    case serverError(message: String?)
    case operationFailed(message: String) // Generischer Fehler

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige API URL."
        case .requestFailed(let error): return "Netzwerkanfrage fehlgeschlagen: \(error.localizedDescription)"
        case .invalidResponseStatus(let statusCode, let body): return "Ungültiger Server-Status: \(statusCode).\n\(body ?? "")"
        case .decodingError(let error): return "Fehler beim Dekodieren der Antwort: \(error.localizedDescription)\n\(error)" // Mehr Details
        case .encodingError(let error): return "Fehler beim Kodieren der Anfrage: \(error.localizedDescription)"
        case .unauthorized: return "Nicht autorisiert (Token ungültig oder fehlt)."
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

    // !!! WICHTIG: Ersetze dies mit der URL deines deploysten Workers !!!
    private var baseURL: URL? = URL(string: "https://debtapi.siewert-albrecht.workers.dev/api") // <- DEINE WORKER URL HIER, optional machen

    private var apiToken: String? {
        KeychainService.shared.loadToken() // Token immer frisch aus Keychain laden
    }

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        // TODO: Datumsstrategie setzen, wenn Daten als Date statt String benötigt werden
        // decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        // encoder.dateEncodingStrategy = .iso8601 // Falls nötig
    }

    // Funktion zum Setzen/Aktualisieren der Basis-URL (optional)
    func setBaseURL(urlString: String) {
        self.baseURL = URL(string: urlString)
        // TODO: Gültigkeit prüfen?
    }

    // MARK: - Helper für Requests
    private func buildRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let currentBaseURL = baseURL else {
            throw APIError.operationFailed(message: "API Base URL ist nicht konfiguriert.")
        }
        guard let url = URL(string: path, relativeTo: currentBaseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let token = apiToken, !token.isEmpty else {
            print("API Service: API Token fehlt im Keychain!")
            throw APIError.unauthorized
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = body
        }
        print("[\(method)] Requesting URL: \(request.url?.absoluteString ?? "INVALID URL")")
        return request
    }

    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("No HTTP Response received from \(request.url?.absoluteString ?? "?")")
                throw APIError.invalidResponseStatus(statusCode: 0, responseBody: "Keine HTTP Response")
            }

            // Versuche immer, den Body zu loggen, besonders bei Fehlern
            let responseBodyString = String(data: data, encoding: .utf8) ?? "Body not UTF-8 decodable"
            print("[\(httpResponse.statusCode)] Response from \(request.url?.path ?? ""):\n\(responseBodyString)")


            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 { throw APIError.unauthorized }

                var serverErrorMessage: String? = nil
                // Versuche, Standard-Fehlerstruktur zu parsen: { "error": "Nachricht" }
                if let errorJson = try? decoder.decode([String: String].self, from: data), let msg = errorJson["error"] {
                    serverErrorMessage = msg
                } else {
                    // Fallback auf den rohen Body als Fehlermeldung, wenn er nicht leer ist
                    serverErrorMessage = responseBodyString.isEmpty ? nil : responseBodyString
                }

                throw APIError.invalidResponseStatus(statusCode: httpResponse.statusCode, responseBody: serverErrorMessage)
            }

            // Spezieller Fall für 204 No Content (z.B. bei DELETE)
            if httpResponse.statusCode == 204 {
                // Erwarte T == EmptyResponse. Wenn nicht, ist es ein Fehler im aufrufenden Code.
                if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T {
                     return empty
                } else if T.self != EmptyResponse.self {
                    // Unerwartet 204 für einen Typ, der Daten erwartet
                    print("Warning: Received 204 No Content but expected Decodable type \(T.self)")
                    throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received 204 No Content but expected Decodable type \(T.self)")))
                }
                // Wenn T == EmptyResponse ist, ist es ok
                 if let empty = EmptyResponse() as? T {
                      return empty
                 }
            }

            // Fallback für leere Daten bei Status 200/201
            if data.isEmpty {
                 if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T {
                      return empty // Erlaube EmptyResponse bei leerem Body (sollte nicht vorkommen für 200/201)
                 } else {
                    print("Error: Received empty data for status \(httpResponse.statusCode) but expected Decodable type \(T.self)")
                    throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received empty data but expected non-empty Decodable type \(T.self)")))
                 }
            }


            // Versuche zu dekodieren
            do {
                let decodedObject = try decoder.decode(T.self, from: data)
                return decodedObject
            } catch {
                print("--- Decoding Error ---")
                print("Error: \(error)")
                print("Localized Description: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    print("Decoding Error Details: \(decodingError)")
                    // Hier detaillierte Ausgabe hinzufügen
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                         print("Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug: \(context.debugDescription)")
                    case .keyNotFound(let key, let context):
                         print("Key not found: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                         print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - Debug: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error.")
                    }
                }
                print("Raw Response Body String: \(responseBodyString)")
                print("--- End Decoding Error ---")
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error // APIError weiterwerfen
        } catch {
            print("URLSession Error / Other Error: \(error)")
            throw APIError.requestFailed(error) // Andere Fehler (Netzwerk etc.)
        }
    }

    // MARK: - Mandanten Endpunkte (Vollständig)

    func fetchMandanten() async throws -> [Mandant] {
        let request = try buildRequest(path: "mandanten")
        return try await performRequest(request: request)
    }

    func fetchMandant(id: String) async throws -> Mandant {
        let request = try buildRequest(path: "mandanten/\(id)")
        return try await performRequest(request: request)
    }

    func createMandant(payload: CreateMandantPayloadDTO) async throws -> Mandant {
        do {
            let body = try encoder.encode(payload)
            let request = try buildRequest(path: "mandanten", method: "POST", body: body)
            // API gibt den erstellten Mandanten zurück (Status 201)
            return try await performRequest(request: request)
        } catch let error where !(error is APIError) { // Fange spezifisch EncodingError ab
            print("Encoding Error: \(error)")
            throw APIError.encodingError(error)
        } // Andere Fehler (buildRequest, performRequest) werden durchgereicht
    }

    func updateMandant(id: String, payload: UpdateMandantPayloadDTO) async throws -> Mandant {
        do {
            let body = try encoder.encode(payload)
            let request = try buildRequest(path: "mandanten/\(id)", method: "PUT", body: body)
            // API gibt den aktualisierten Mandanten zurück
            return try await performRequest(request: request)
        } catch let error where !(error is APIError) {
            print("Encoding Error: \(error)")
            throw APIError.encodingError(error)
        }
    }

    func deleteMandant(id: String) async throws {
        let request = try buildRequest(path: "mandanten/\(id)", method: "DELETE")
        // Expliziter Typ für performRequest, wenn 'T' nicht inferiert werden kann:
        let _: EmptyResponse = try await performRequest(request: request) // Erwarte leere Antwort (Status 204)
    }

    // MARK: - Auftraege Endpunkte (Skelette/Teilimplementiert)

    func fetchAuftraege(mandantId: String? = nil) async throws -> [Auftrag] {
        let path = mandantId == nil ? "auftraege" : "mandanten/\(mandantId!)/auftraege"
        // TODO: Optional Query Parameter für weitere Filter
        let request = try buildRequest(path: path)
        return try await performRequest(request: request)
    }

    func fetchAuftrag(id: String) async throws -> Auftrag { // Annahme: API liefert hier ggf. JOIN-Daten mit
        let request = try buildRequest(path: "auftraege/\(id)")
        return try await performRequest(request: request) // Typ muss ggf. angepasst werden, falls JOIN
    }

    func createAuftrag(payload: CreateAuftragPayloadDTO) async throws -> Auftrag {
        do {
            let body = try encoder.encode(payload)
            let request = try buildRequest(path: "auftraege", method: "POST", body: body)
            return try await performRequest(request: request)
        } catch let error where !(error is APIError) {
            throw APIError.encodingError(error)
        }
    }
    func updateAuftrag(id: String, payload: UpdateAuftragPayloadDTO) async throws -> Auftrag {
        do {
            let body = try encoder.encode(payload)
            let request = try buildRequest(path: "auftraege/\(id)", method: "PUT", body: body)
            return try await performRequest(request: request)
        } catch let error where !(error is APIError) {
            throw APIError.encodingError(error)
        }
    }
    func deleteAuftrag(id: String) async throws {
        let request = try buildRequest(path: "auftraege/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request: request)
    }

    // MARK: - Cases Endpunkte (Skelette/Teilimplementiert)

    func fetchCases(auftragId: String? = nil, debtorId: String? = nil, status: String? = nil, limit: Int = 50, offset: Int = 0) async throws -> [Case] {
        var queryItems: [URLQueryItem] = []
        if let auftragId = auftragId { queryItems.append(URLQueryItem(name: "auftragId", value: auftragId)) }
        if let debtorId = debtorId { queryItems.append(URLQueryItem(name: "debtorId", value: debtorId)) }
        if let status = status { queryItems.append(URLQueryItem(name: "status", value: status)) }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        // TODO: Weitere Filter...

        var components = URLComponents()
        components.path = "cases" // Pfad ohne / am Anfang für relativeTo
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let path = components.string else { throw APIError.invalidURL } // Pfad inkl. Query erstellen

        let request = try buildRequest(path: path) // path enthält jetzt query string
        return try await performRequest(request: request) // API muss JOIN für Namen machen oder es gibt separate Aufrufe
    }
    func fetchCase(id: String) async throws -> Case { // Annahme: API liefert hier JOIN-Daten mit
        let request = try buildRequest(path: "cases/\(id)")
        return try await performRequest(request: request) // Case Struct muss optionale Namen haben
    }
    func createCase(payload: CreateCasePayloadDTO) async throws -> Case {
        do {
            let body = try encoder.encode(payload)
            let request = try buildRequest(path: "cases", method: "POST", body: body)
            return try await performRequest(request: request)
        } catch let error where !(error is APIError) {
            throw APIError.encodingError(error)
        }
    }
     func updateCase(id: String, payload: UpdateCasePayloadDTO) async throws -> Case {
        do {
             let body = try encoder.encode(payload)
             let request = try buildRequest(path: "cases/\(id)", method: "PUT", body: body)
             return try await performRequest(request: request)
        } catch let error where !(error is APIError) {
            throw APIError.encodingError(error)
        }
     }
     func deleteCase(id: String) async throws {
          // In der Regel nicht empfohlen, daher nicht standardmäßig implementiert
         print("API Service: deleteCase wurde aufgerufen, ist aber nicht empfohlen/implementiert.")
         throw APIError.operationFailed(message: "Löschen von Fällen wird nicht unterstützt. Bitte archivieren.")
     }

    // MARK: - Payments Endpunkte (Skelette/Teilimplementiert)
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
    // Update/Delete für Payments nicht sinnvoll

    // MARK: - Actions Endpunkte (Skelette/Teilimplementiert)
     func fetchActions(caseId: String) async throws -> [Action] {
         let request = try buildRequest(path: "cases/\(caseId)/actions")
          return try await performRequest(request: request)
     }
     func createAction(payload: CreateActionPayloadDTO) async throws -> Action {
         do {
             let body = try encoder.encode(payload)
             let request = try buildRequest(path: "actions", method: "POST", body: body)
             return try await performRequest(request: request)
         } catch let error where !(error is APIError) {
             throw APIError.encodingError(error)
         }
     }
     func updateAction(id: String, payload: UpdateActionPayloadDTO) async throws -> Action {
          do {
             let body = try encoder.encode(payload)
             let request = try buildRequest(path: "actions/\(id)", method: "PUT", body: body) // PUT oder PATCH?
             return try await performRequest(request: request)
         } catch let error where !(error is APIError) {
             throw APIError.encodingError(error)
         }
     }
      func deleteAction(id: String) async throws {
         let request = try buildRequest(path: "actions/\(id)", method: "DELETE")
         let _: EmptyResponse = try await performRequest(request: request)
     }


    // MARK: - Workflows Endpunkte (Skelette)
     func fetchWorkflows() async throws -> [Workflow] {
         let request = try buildRequest(path: "workflows")
         return try await performRequest(request: request)
     }
     func fetchWorkflow(id: String) async throws -> Workflow {
         let request = try buildRequest(path: "workflows/\(id)")
         return try await performRequest(request: request)
     }
     func createWorkflow(payload: CreateWorkflowPayloadDTO) async throws -> Workflow {
         // TODO: Implementieren
         throw APIError.operationFailed(message: "createWorkflow noch nicht implementiert.")
     }
      func updateWorkflow(id: String, payload: UpdateWorkflowPayloadDTO) async throws -> Workflow {
         // TODO: Implementieren
         throw APIError.operationFailed(message: "updateWorkflow noch nicht implementiert.")
     }
       func deleteWorkflow(id: String) async throws {
          // TODO: Implementieren
         throw APIError.operationFailed(message: "deleteWorkflow noch nicht implementiert.")
     }


    // MARK: - WorkflowSteps Endpunkte (Skelette)
     func fetchWorkflowSteps(workflowId: String) async throws -> [WorkflowStep] {
         let request = try buildRequest(path: "workflows/\(workflowId)/steps")
         return try await performRequest(request: request)
     }
     // TODO: CRUD für Steps...
     func createWorkflowStep(workflowId: String, payload: CreateWorkflowStepPayloadDTO) async throws -> WorkflowStep {
          throw APIError.operationFailed(message: "createWorkflowStep noch nicht implementiert.")
     }
      func updateWorkflowStep(id: String, payload: UpdateWorkflowStepPayloadDTO) async throws -> WorkflowStep {
           throw APIError.operationFailed(message: "updateWorkflowStep noch nicht implementiert.")
      }
       func deleteWorkflowStep(id: String) async throws {
            throw APIError.operationFailed(message: "deleteWorkflowStep noch nicht implementiert.")
       }

    // MARK: - Debtors Endpunkte (TODO: Implementieren)
     func fetchDebtors(/* TODO: Filter? */) async throws -> [Debtor] {
         let request = try buildRequest(path: "debtors") // Annahme: Endpunkt existiert
         return try await performRequest(request: request)
     }
     func createDebtor(payload: CreateDebtorPayloadDTO) async throws -> Debtor {
          throw APIError.operationFailed(message: "createDebtor noch nicht implementiert.")
     }
     // ... (fetchDebtorById, updateDebtor, deleteDebtor) ...

}
