import Foundation

// Nur noch Payloads für Aktionen, die der Sachbearbeiter durchführt

struct UpdateCasePayloadDTO: Codable {
    var status: String?
    var reasonForClaim: String?
     enum CodingKeys: String, CodingKey { case status, reasonForClaim = "reason_for_claim" }
 }

struct CreatePaymentPayloadDTO: Codable {
    var caseId: String; var amount: Double; var paymentDate: String
    var paymentMethod: String?; var reference: String?; var notes: String?
    enum CodingKeys: String, CodingKey { case amount, reference, notes; case caseId = "case_id"; case paymentDate = "payment_date"; case paymentMethod = "payment_method" }
}

struct CreateActionPayloadDTO: Codable {
    var caseId: String; var actionType: String; var actionDate: String?
    var notes: String?; var cost: Double?; var createdByUser: String?
    var costTargetAccount: String? // "main" oder "fees"
    enum CodingKeys: String, CodingKey { case notes, cost; case caseId = "case_id"; case actionType = "action_type"; case actionDate = "action_date"; case createdByUser = "created_by_user"; case costTargetAccount = "cost_target_account" }
}

struct UpdateActionPayloadDTO: Codable {
    var notes: String?
}

// --- DTO für Schuldner-Update ---
struct UpdateDebtorPayloadDTO: Codable {
    var name: String?
    var addressStreet: String?
    var addressZip: String?
    var addressCity: String?
    var addressCountry: String?
    var email: String?
    var phone: String?
    var debtorType: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, email, phone, notes
        case addressStreet = "address_street"
        case addressZip = "address_zip"
        case addressCity = "address_city"
        case addressCountry = "address_country"
        case debtorType = "debtor_type"
    }
}

// DTOs für Mandant, Auftrag, Workflow etc. nicht mehr benötigt
