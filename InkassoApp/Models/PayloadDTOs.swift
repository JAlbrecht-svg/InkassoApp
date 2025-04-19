//
//  PayloadDTOs.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//
import Foundation

// Data Transfer Objects (DTOs) für Create/Update Payloads

struct CreateMandantPayloadDTO: Codable {
    var mandantNumber: String
    var name: String
    var contactPerson: String?
    var email: String?
    var phone: String?
    var isActive: Int?

    enum CodingKeys: String, CodingKey {
        case mandantNumber = "mandant_number"
        case name
        case contactPerson = "contact_person"
        case email, phone
        case isActive = "is_active"
    }
}

struct UpdateMandantPayloadDTO: Codable {
    var mandantNumber: String?
    var name: String?
    var contactPerson: String?
    var email: String?
    var phone: String?
    var isActive: Int?

     enum CodingKeys: String, CodingKey {
        case mandantNumber = "mandant_number"
        case name
        case contactPerson = "contact_person"
        case email, phone
        case isActive = "is_active"
    }
}

// --- DTOs für andere Entitäten (Beispiele/TODO) ---

struct CreateAuftragPayloadDTO: Codable {
    var mandantId: String
    var auftragSubId: String
    var name: String
    var workflowId: String?
    var startDate: String? // ISO Date String
    var endDate: String?   // ISO Date String
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, notes
        case mandantId = "mandant_id"
        case auftragSubId = "auftrag_sub_id"
        case workflowId = "workflow_id"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}
struct UpdateAuftragPayloadDTO: Codable {
    var name: String?
    var workflowId: String? // Erlaube auch null zum Entfernen
    var startDate: String?
    var endDate: String?
    var notes: String?

     enum CodingKeys: String, CodingKey {
        case name, notes
        case workflowId = "workflow_id"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct CreateCasePayloadDTO: Codable {
     var debtorId: String
     var auftragId: String
     var caseReference: String
     var originalAmount: Double
     var currency: String?
     var status: String?
     var reasonForClaim: String?
     var openedAt: String? // ISO Date String
     var dueDate: String?  // ISO Date String

      enum CodingKeys: String, CodingKey {
        case currency, status
        case debtorId = "debtor_id"
        case auftragId = "auftrag_id"
        case caseReference = "case_reference"
        case originalAmount = "original_amount"
        case reasonForClaim = "reason_for_claim"
        case openedAt = "opened_at"
        case dueDate = "due_date"
    }
 }
 struct UpdateCasePayloadDTO: Codable {
     var status: String?
     var reasonForClaim: String?
     var dueDate: String?
     var closedAt: String? // Erlaube null
     // Betragsänderungen sollten über dedizierte Endpunkte gehen!
     // var feesAmount: Double? // Nicht hier ändern!
     // var interestAmount: Double? // Nicht hier ändern!

      enum CodingKeys: String, CodingKey {
         case status
         case reasonForClaim = "reason_for_claim"
         case dueDate = "due_date"
         case closedAt = "closed_at"
     }
  }


struct CreatePaymentPayloadDTO: Codable {
    var caseId: String
    var amount: Double
    var paymentDate: String // ISO Date String
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
    var actionType: String
    var actionDate: String? // ISO Date String
    var notes: String?
    var cost: Double?
    var createdByUser: String?

    enum CodingKeys: String, CodingKey {
         case notes, cost
         case caseId = "case_id"
         case actionType = "action_type"
         case actionDate = "action_date"
         case createdByUser = "created_by_user"
     }
}

struct UpdateActionPayloadDTO: Codable {
    var notes: String?
}

// ... (Payloads für Workflow und WorkflowStep nach Bedarf) ...
