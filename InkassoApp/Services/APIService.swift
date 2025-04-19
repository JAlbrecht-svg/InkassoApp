import Foundation
import SwiftUI

// APIError Enum (Definition bleibt wie in den vorherigen Antworten)
enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponseStatus(statusCode: Int, responseBody: String?)
    case decodingError(Error)
    case encodingError(Error)
    case unauthorized
    case serverError(message: String?)
    case operationFailed(message: String)

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
                 // Detaillierte Decoding-Fehler-Logik von oben hier einfügen...
                 switch decodingError {
                 case .typeMismatch(let type, let context): details = "Typkonflikt für \(type) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .valueNotFound(let type, let context): details = "Wert nicht gefunden für Typ \(type) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .keyNotFound(let key, let context): details = "Schlüssel nicht gefunden: \(key.stringValue) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .dataCorrupted(let context): details = "Daten beschädigt bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 @unknown default: details = "Unbekannter Decoding-Fehler."
                 }
             } else { details = error.localizedDescription }
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


@MainActor
class APIService: ObservableObject {
    static let shared = APIService()

    // Basis-URL (privat)
    private var baseURL: URL?

    // !!! KORREKTUR / WICHTIG: Diese Computed Property muss existieren !!!
    // ÖFFENTLICHE Computed Property zum sicheren Lesen der URL als String
    var currentBaseURLString: String? {
        baseURL?.absoluteString
    }
    // !!! ENDE KORREKTUR !!!

    // API Token
    private var apiToken: String? {
        KeychainService.shared.loadToken()
    }

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        let defaultUrlString = "https://wild-thunder-d361.siewertservices.workers.dev/api"
        let savedUrlString = UserDefaults.standard.string(forKey: "apiBaseURL")

        if let urlStr = savedUrlString, !urlStr.isEmpty {
             self.baseURL = URL(string: urlStr)
             print("APIService initialized. BaseURL loaded from UserDefaults: \(urlStr)")
        } else {
             self.baseURL = URL(string: defaultUrlString)
             print("APIService initialized. BaseURL set to default: \(defaultUrlString)")
        }
        if self.baseURL == nil { print("WARNING: APIService could not initialize baseURL.") }
    }

    // Öffentliche Methode zum Setzen der Basis-URL
    func setBaseURL(urlString: String) {
        let cleanedUrlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        self.baseURL = URL(string: cleanedUrlString)
        if self.baseURL != nil {
            UserDefaults.standard.set(cleanedUrlString, forKey: "apiBaseURL")
            print("API Base URL set and saved to: \(cleanedUrlString)")
        } else {
             print("API Base URL could not be set (invalid URL?): \(cleanedUrlString)")
             UserDefaults.standard.removeObject(forKey: "apiBaseURL")
        }
    }

    var isConfigured: Bool {
        return baseURL != nil && apiToken != nil && !(apiToken?.isEmpty ?? true)
    }

    // MARK: - Helper für Requests
    private func buildRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest { /* ... Implementierung wie zuvor ... */
        guard let currentBaseURL = baseURL else { throw APIError.operationFailed(message: "API Basis-URL ist nicht konfiguriert.") }
        guard let url = URL(string: path, relativeTo: currentBaseURL) else { throw APIError.invalidURL }
        var request = URLRequest(url: url); request.httpMethod = method; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.timeoutInterval = 30
        guard let token = apiToken, !token.isEmpty else { throw APIError.unauthorized }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body = body { request.httpBody = body }
        print("[\(method)] Requesting URL: \(request.url?.absoluteString ?? "INVALID URL")")
        return request
    }

    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T { /* ... Implementierung wie zuvor (inkl. Logging, Fehlerbehandlung) ... */
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponseStatus(statusCode: 0, responseBody: "Keine HTTP Response erhalten") }
            let responseBodyString = String(data: data, encoding: .utf8) ?? "Body nicht als UTF-8 dekodierbar"
            if !(200...299).contains(httpResponse.statusCode) { print("[\(httpResponse.statusCode)] Response ERROR from \(request.url?.path ?? ""):\n\(responseBodyString)") }
            else { let preview = responseBodyString.prefix(500); print("[\(httpResponse.statusCode)] Response OK from \(request.url?.path ?? ""):\n\(preview)\(responseBodyString.count > 500 ? "..." : "")") }
            guard (200...299).contains(httpResponse.statusCode) else { /* ... Fehlerbehandlung Statuscodes ... */
                if httpResponse.statusCode == 401 { throw APIError.unauthorized }
                var serverErrorMessage: String? = nil; if let errorJson = try? decoder.decode([String: String].self, from: data), let msg = errorJson["error"] { serverErrorMessage = msg } else { serverErrorMessage = responseBodyString.isEmpty ? nil : responseBodyString }; throw APIError.invalidResponseStatus(statusCode: httpResponse.statusCode, responseBody: serverErrorMessage)
            }
            if httpResponse.statusCode == 204 { /* ... 204 Handling ... */ if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T { return empty } else if T.self != EmptyResponse.self { throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received 204 No Content but expected Decodable type \(T.self)"))) } else if let empty = EmptyResponse() as? T { return empty } else { throw APIError.operationFailed(message: "Inkonsistenter Zustand bei 204 Response Handling für \(T.self)") }}
            if data.isEmpty { /* ... Empty Data Handling ... */ if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T { return empty } else { throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received empty data but expected non-empty Decodable type \(T.self)"))) } }
            do { return try decoder.decode(T.self, from: data) } catch { /* ... Decoding Fehlerbehandlung ... */ throw APIError.decodingError(error) }
        } catch let error as APIError { throw error }
        catch { throw APIError.requestFailed(error) }
    }

    // MARK: - Mandanten Endpunkte (Nur Lesen)
    func fetchMandanten() async throws -> [Mandant] { let r = try buildRequest(path: "mandanten"); return try await performRequest(request: r) }
    func fetchMandant(id: String) async throws -> Mandant { let r = try buildRequest(path: "mandanten/\(id)"); return try await performRequest(request: r) }

    // MARK: - Auftraege Endpunkte (Nur Lesen)
    func fetchAuftraege(mandantId: String? = nil) async throws -> [Auftrag] { let p = mandantId == nil ? "auftraege" : "mandanten/\(mandantId!)/auftraege"; let r = try buildRequest(path: p); return try await performRequest(request: r) }
    func fetchAuftrag(id: String) async throws -> Auftrag { let r = try buildRequest(path: "auftraege/\(id)"); return try await performRequest(request: r) }

    // MARK: - Cases Endpunkte (Lesen + Status Update)
    func fetchCases(auftragId: String? = nil, debtorId: String? = nil, status: String? = nil, limit: Int = 50, offset: Int = 0, searchTerm: String? = nil) async throws -> [Case] { /* ... Implementierung wie zuvor ... */
        var queryItems: [URLQueryItem] = []; if let v=auftragId{queryItems.append(URLQueryItem(name:"auftragId",value:v))}; if let v=debtorId{queryItems.append(URLQueryItem(name:"debtorId",value:v))}; if let v=status,!v.isEmpty{queryItems.append(URLQueryItem(name:"status",value:v))}; if let v=searchTerm,!v.isEmpty{queryItems.append(URLQueryItem(name:"search",value:v))}; queryItems.append(URLQueryItem(name:"limit",value:String(limit))); queryItems.append(URLQueryItem(name:"offset",value:String(offset))); var c=URLComponents();c.path="cases";c.queryItems=queryItems.isEmpty ? nil:queryItems; guard let p=c.string else{throw APIError.invalidURL}; let r=try buildRequest(path:p); return try await performRequest(request: r)
    }
    func fetchCase(id: String) async throws -> Case { let r = try buildRequest(path: "cases/\(id)"); return try await performRequest(request: r) }
     func updateCase(id: String, payload: UpdateCasePayloadDTO) async throws -> Case { /* ... Implementierung wie zuvor ... */
         guard payload.status != nil || payload.reasonForClaim != nil else { throw APIError.operationFailed(message: "Keine änderbaren Felder im Payload für updateCase gefunden.") }; do { let b = try encoder.encode(payload); let r = try buildRequest(path: "cases/\(id)", method: "PUT", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) }
     }

    // MARK: - Payments Endpunkte (Lesen, Erstellen)
    func fetchPayments(caseId: String) async throws -> [Payment] { let r = try buildRequest(path: "cases/\(caseId)/payments"); return try await performRequest(request: r) }
    func createPayment(payload: CreatePaymentPayloadDTO) async throws -> Payment { /* ... Implementierung wie zuvor ... */
         do { let b = try encoder.encode(payload); let r = try buildRequest(path: "payments", method: "POST", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) }
    }

    // MARK: - Actions Endpunkte (Lesen, Erstellen, Update Notes)
     func fetchActions(caseId: String) async throws -> [Action] { let r = try buildRequest(path: "cases/\(caseId)/actions"); return try await performRequest(request: r) }
     func createAction(payload: CreateActionPayloadDTO) async throws -> Action { /* ... Implementierung wie zuvor ... */
          do { let b = try encoder.encode(payload); let r = try buildRequest(path: "actions", method: "POST", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) }
     }
     func updateActionNotes(id: String, notes: String?) async throws -> Action { /* ... Implementierung wie zuvor ... */
         let p = UpdateActionPayloadDTO(notes: notes); do { let b = try encoder.encode(p); let r = try buildRequest(path: "actions/\(id)", method: "PUT", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) }
     }

    // MARK: - Debtors Endpunkte (Nur Lesen)
     func fetchDebtors(searchTerm: String? = nil, limit: Int = 50, offset: Int = 0) async throws -> [Debtor] { /* ... Implementierung wie zuvor ... */
         var queryItems: [URLQueryItem] = []; if let v=searchTerm,!v.isEmpty{queryItems.append(URLQueryItem(name:"search",value:v))}; queryItems.append(URLQueryItem(name:"limit",value:String(limit))); queryItems.append(URLQueryItem(name:"offset",value:String(offset))); var c=URLComponents();c.path="debtors";c.queryItems=queryItems.isEmpty ? nil:queryItems; guard let p=c.string else{throw APIError.invalidURL}; let r=try buildRequest(path:p); return try await performRequest(request: r)
     }
      func fetchDebtor(id: String) async throws -> Debtor { let r = try buildRequest(path: "debtors/\(id)"); return try await performRequest(request: r) }

     // MARK: - Workflows & Steps Endpunkte (Nur Lesen)
      func fetchWorkflows() async throws -> [Workflow] { let r = try buildRequest(path: "workflows"); return try await performRequest(request: r) }
      func fetchWorkflowSteps(workflowId: String) async throws -> [WorkflowStep] { let r = try buildRequest(path: "workflows/\(workflowId)/steps"); return try await performRequest(request: r) }
}
