// Services/APIService.swift
import Foundation
import SwiftUI

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
                 case .typeMismatch(let type, let context): details = "Typkonflikt für \(type) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .valueNotFound(let type, let context): details = "Wert nicht gefunden für Typ \(type) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .keyNotFound(let key, let context): details = "Schlüssel nicht gefunden: \(key.stringValue) bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 case .dataCorrupted(let context): details = "Daten beschädigt bei Pfad: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")). Debug: \(context.debugDescription)"
                 @unknown default: details = "Unbekannter Decoding-Fehler."
                 }
             } else { details = error.localizedDescription }
             return "Fehler beim Verarbeiten der Serverantwort: \(details)"
        case .encodingError(let error): return "Fehler beim Vorbereiten der Anfrage: \(error.localizedDescription)"
        case .unauthorized: return "Nicht autorisiert. Bitte API Token in den Einstellungen prüfen oder neu eingeben."
        case .serverError(let message): return "Serverfehler: \(message ?? "Unbekannter Fehler")"
        case .operationFailed(let message): return message
        }
    }
}

struct EmptyResponse: Decodable {}

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    private var baseURL: URL?
    var currentBaseURLString: String? { baseURL?.absoluteString }
    private var apiToken: String? { KeychainService.shared.loadToken() }
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder(); encoder = JSONEncoder()
        let defaultUrlString = "https://wild-thunder-d361.siewertservices.workers.dev"
        let savedUrlString = UserDefaults.standard.string(forKey: "apiBaseURL")
        if let urlStr = savedUrlString, !urlStr.isEmpty { self.baseURL = URL(string: urlStr) } else { self.baseURL = URL(string: defaultUrlString) }
        print("APIService initialized. BaseURL: \(self.baseURL?.absoluteString ?? "Not Set")")
    }

    func setBaseURL(urlString: String) {
         let cleanedUrlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/api", with: "")
         let finalUrlString = cleanedUrlString.hasSuffix("/") ? String(cleanedUrlString.dropLast()) : cleanedUrlString
         self.baseURL = URL(string: finalUrlString); if self.baseURL != nil { UserDefaults.standard.set(finalUrlString, forKey: "apiBaseURL"); print("API Base URL set to: \(finalUrlString)") } else { UserDefaults.standard.removeObject(forKey: "apiBaseURL"); print("API Base URL invalid.") }
    }
    var isConfigured: Bool { baseURL != nil && apiToken != nil && !(apiToken?.isEmpty ?? true) }

    private func buildRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let currentBaseURL = baseURL else { throw APIError.operationFailed(message: "API Basis-URL ist nicht konfiguriert.") }
        let relativePath = path.starts(with: "/") ? String(path.dropFirst()) : path; guard let url = URL(string: relativePath, relativeTo: currentBaseURL)?.absoluteURL else { throw APIError.invalidURL }
        var request = URLRequest(url: url); request.httpMethod = method; request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.timeoutInterval = 30
        guard let token = apiToken, !token.isEmpty else { throw APIError.unauthorized }
        print(">>>> [Auth Header] Using Token: Bearer \(token.prefix(4))...\(token.suffix(4))")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); if let body = body { request.httpBody = body }; print("[\(method)] Requesting URL: \(request.url!.absoluteString)"); return request
    }
    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponseStatus(statusCode: 0, responseBody: "Keine HTTP Response erhalten") }
            let responseBodyString = String(data: data, encoding: .utf8) ?? "Body nicht als UTF-8 dekodierbar"; if !(200...299).contains(httpResponse.statusCode) { print("[\(httpResponse.statusCode)] Response ERROR from \(request.url?.path ?? ""):\n\(responseBodyString)") } else { let preview = responseBodyString.prefix(1000); print("[\(httpResponse.statusCode)] Response OK from \(request.url?.path ?? ""):\n\(preview)\(responseBodyString.count > 1000 ? "..." : "")") }
            guard (200...299).contains(httpResponse.statusCode) else { if httpResponse.statusCode == 401 { throw APIError.unauthorized }; var errMsg: String? = nil; if let json = try? decoder.decode([String: String].self, from: data), let msg = json["error"] { errMsg = msg } else { errMsg = responseBodyString.isEmpty ? nil : responseBodyString }; throw APIError.invalidResponseStatus(statusCode: httpResponse.statusCode, responseBody: errMsg) }
            if httpResponse.statusCode == 204 { if T.self == EmptyResponse.self, let e = EmptyResponse() as? T { return e } else if T.self != EmptyResponse.self { throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received 204 No Content but expected Decodable type \(T.self)"))) } else if let e = EmptyResponse() as? T { return e } else { throw APIError.operationFailed(message: "Inkonsistenter Zustand bei 204 Response Handling für \(T.self)") }}
            if data.isEmpty { if T.self == EmptyResponse.self, let e = EmptyResponse() as? T { return e } else { throw APIError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Received empty data but expected non-empty Decodable type \(T.self)"))) } }
            do { return try decoder.decode(T.self, from: data) } catch { print("--- Decoding Error ---\nFailed to decode type: \(T.self)\nRaw Body: \(responseBodyString)\nError: \(error)\nLocalized: \(error.localizedDescription)"); if let de = error as? DecodingError{print("Details: \(de)")}; print("--- End Decoding Error ---"); throw APIError.decodingError(error) }
        } catch let error as APIError { throw error }
        catch { let nsError = error as NSError; print("URLSession Error/Other: Code \(nsError.code), Domain: \(nsError.domain), Desc: \(error.localizedDescription)"); throw APIError.requestFailed(error) }
    }

    // MARK: - Mandanten Endpunkte (Nur Lesen)
    func fetchMandanten() async throws -> [Mandant] { let r = try buildRequest(path: "mandanten"); return try await performRequest(request: r) }
    func fetchMandant(id: String) async throws -> Mandant { let r = try buildRequest(path: "mandanten/\(id)"); return try await performRequest(request: r) }

    // MARK: - Auftraege Endpunkte (Nur Lesen)
    func fetchAuftraege(mandantId: String? = nil) async throws -> [Auftrag] { let p = mandantId == nil ? "auftraege" : "mandanten/\(mandantId!)/auftraege"; let r = try buildRequest(path: p); return try await performRequest(request: r) }
    func fetchAuftrag(id: String) async throws -> Auftrag { let r = try buildRequest(path: "auftraege/\(id)"); return try await performRequest(request: r) }

    // MARK: - Cases Endpunkte (Lesen + Status Update)
    func fetchCases(auftragId: String? = nil, debtorId: String? = nil, status: String? = nil, limit: Int = 50, offset: Int = 0, searchTerm: String? = nil) async throws -> [Case] { var q=[URLQueryItem]();if let v=auftragId{q.append(.init(name:"auftragId",value:v))};if let v=debtorId{q.append(.init(name:"debtorId",value:v))};if let v=status,!v.isEmpty{q.append(.init(name:"status",value:v))};if let v=searchTerm,!v.isEmpty{q.append(.init(name:"search",value:v))};q.append(.init(name:"limit",value:"\(limit)"));q.append(.init(name:"offset",value:"\(offset)"));var c=URLComponents();c.path="cases";c.queryItems=q.isEmpty ? nil:q;guard let p=c.string else{throw APIError.invalidURL};let r=try buildRequest(path:p);return try await performRequest(request:r)}
    func fetchCase(id: String) async throws -> Case { let r = try buildRequest(path: "cases/\(id)"); return try await performRequest(request: r) }
    func updateCase(id: String, payload: UpdateCasePayloadDTO) async throws -> Case { guard payload.status != nil || payload.reasonForClaim != nil else { throw APIError.operationFailed(message: "Keine änderbaren Felder für updateCase.") }; do { let b = try encoder.encode(payload); let r = try buildRequest(path: "cases/\(id)", method: "PUT", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) } }

    // MARK: - Payments Endpunkte (Lesen, Erstellen)
    func fetchPayments(caseId: String) async throws -> [Payment] { let r = try buildRequest(path: "cases/\(caseId)/payments"); return try await performRequest(request: r) }
    func createPayment(payload: CreatePaymentPayloadDTO) async throws -> Payment { do { let b = try encoder.encode(payload); let r = try buildRequest(path: "payments", method: "POST", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) } }

    // MARK: - Actions Endpunkte (Lesen, Erstellen, Update Notes)
    func fetchActions(caseId: String) async throws -> [Action] { let r = try buildRequest(path: "cases/\(caseId)/actions"); return try await performRequest(request: r) }
    func createAction(payload: CreateActionPayloadDTO) async throws -> Action { do { let b = try encoder.encode(payload); let r = try buildRequest(path: "actions", method: "POST", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) } }
    func updateActionNotes(id: String, notes: String?) async throws -> Action { let p = UpdateActionPayloadDTO(notes: notes); do { let b = try encoder.encode(p); let r = try buildRequest(path: "actions/\(id)", method: "PUT", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) } }

    // MARK: - Debtors Endpunkte (Lesen + Update)
    func fetchDebtors(searchTerm: String? = nil, limit: Int = 50, offset: Int = 0) async throws -> [Debtor] { var q=[URLQueryItem]();if let v=searchTerm,!v.isEmpty{q.append(.init(name:"search",value:v))};q.append(.init(name:"limit",value:"\(limit)"));q.append(.init(name:"offset",value:"\(offset)"));var c=URLComponents();c.path="debtors";c.queryItems=q.isEmpty ? nil:q;guard let p=c.string else{throw APIError.invalidURL};let r=try buildRequest(path:p);return try await performRequest(request:r)}
    func fetchDebtor(id: String) async throws -> Debtor { let r = try buildRequest(path: "debtors/\(id)"); return try await performRequest(request: r) }
    func updateDebtor(id: String, payload: UpdateDebtorPayloadDTO) async throws -> Debtor { guard !id.isEmpty else { throw APIError.operationFailed(message: "Debtor ID darf nicht leer sein.")}; do { let b = try encoder.encode(payload); let r = try buildRequest(path: "debtors/\(id)", method: "PUT", body: b); return try await performRequest(request: r) } catch let e where !(e is APIError) { throw APIError.encodingError(e) } }

    // MARK: - Workflows & Steps Endpunkte (Nur Lesen)
    func fetchWorkflows() async throws -> [Workflow] { let r = try buildRequest(path: "workflows"); return try await performRequest(request: r) }
    func fetchWorkflowSteps(workflowId: String) async throws -> [WorkflowStep] { let r = try buildRequest(path: "workflows/\(workflowId)/steps"); return try await performRequest(request: r) }
}
