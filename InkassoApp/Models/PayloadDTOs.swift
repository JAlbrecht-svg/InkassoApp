import Foundation

// Nur noch Payloads für Aktionen, die der Sachbearbeiter durchführt

// Nur relevante Felder für Update durch Sachbearbeiter (z.B. Status)
struct UpdateCasePayloadDTO: Codable {
    var status: String?
    var reasonForClaim: String? // Evtl. Notizfeld für Statusänderung?
    // Weitere bearbeitbare Felder hier hinzufügen, falls erlaubt

     enum CodingKeys: String, CodingKey {
        case status
        case reasonForClaim = "reason_for_claim"
        // Füge hier weitere bearbeitbare Felder hinzu
     }
 }

struct CreatePaymentPayloadDTO: Codable {
    var caseId: String
    var amount: Double
    var paymentDate: String // ISO Date String (YYYY-MM-DD)
    var paymentMethod: String?
    var reference: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case amount, reference, notes
        case caseId = "case_id"
        case paymentDate = "payment_date"
        case paymentMethod = "payment_method"
    }
}

struct CreateActionPayloadDTO: Codable {
    var caseId: String
    var actionType: String // Sachbearbeiter muss Typ auswählen/eingeben
    var actionDate: String? // ISO Date String (optional, Default = now)
    var notes: String?
    var cost: Double? // Kosten manuell eingebbar?
    var createdByUser: String? // TODO: Vom eingeloggten Benutzer setzen?

    enum CodingKeys: String, CodingKey {
         case notes, cost
         case caseId = "case_id"
         case actionType = "action_type"
         case actionDate = "action_date"
         case createdByUser = "created_by_user"
     }
}

// Evtl. Payload zum Aktualisieren von Action-Notizen
struct UpdateActionPayloadDTO: Codable {
    var notes: String?
}

// DTOs für Mandant, Auftrag, Debtor, Workflow etc. werden nicht mehr benötigt
