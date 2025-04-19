//
//  ModelTypes.swift
//  InkassoApp
//
//  Created by Jannick Niwat Siewert-Albrecht on 4/19/25.
//
import Foundation

// Identifiable damit es in SwiftUI ForEach verwendet werden kann
// Hashable damit es in NavigationLinks als value verwendet werden kann

struct Mandant: Identifiable, Codable, Hashable {
    let id: String
    var mandantNumber: String
    var name: String
    var contactPerson: String?
    var email: String?
    var phone: String?
    var isActive: Int // 0 oder 1
    var createdAt: String // TODO: Zu Date konvertieren?
    var updatedAt: String // TODO: Zu Date konvertieren?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone
        case mandantNumber = "mandant_number"
        case contactPerson = "contact_person"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Workflow: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String?
    var category: String
    var mandantId: String?
    var createdAt: String
    var updatedAt: String

     enum CodingKeys: String, CodingKey {
         case id, name, description, category
         case mandantId = "mandant_id"
         case createdAt = "created_at"
         case updatedAt = "updated_at"
     }
}

struct WorkflowStep: Identifiable, Codable, Hashable {
    let id: String
    var workflowId: String
    var stepOrder: Int
    var name: String
    var triggerType: String
    var triggerValue: Int
    var actionToPerform: String
    var templateIdentifier: String?
    var feeToCharge: Double // SQL REAL -> Double
    var targetCaseStatus: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case workflowId = "workflow_id"
        case stepOrder = "step_order"
        case triggerType = "trigger_type"
        case triggerValue = "trigger_value"
        case actionToPerform = "action_to_perform"
        case templateIdentifier = "template_identifier"
        case feeToCharge = "fee_to_charge"
        case targetCaseStatus = "target_case_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Auftrag: Identifiable, Codable, Hashable {
    let id: String
    var mandantId: String
    var auftragSubId: String
    var name: String
    var workflowId: String?
    var startDate: String?
    var endDate: String?
    var notes: String?
    var createdAt: String
    var updatedAt: String

     enum CodingKeys: String, CodingKey {
         case id, name, notes
         case mandantId = "mandant_id"
         case auftragSubId = "auftrag_sub_id"
         case workflowId = "workflow_id"
         case startDate = "start_date"
         case endDate = "end_date"
         case createdAt = "created_at"
         case updatedAt = "updated_at"
     }
}

struct Debtor: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var addressStreet: String?
    var addressZip: String?
    var addressCity: String?
    var addressCountry: String?
    var email: String?
    var phone: String?
    var debtorType: String
    var notes: String?
    var createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, notes
        case addressStreet = "address_street"
        case addressZip = "address_zip"
        case addressCity = "address_city"
        case addressCountry = "address_country"
        case debtorType = "debtor_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Case: Identifiable, Codable, Hashable {
    let id: String
    var debtorId: String
    var auftragId: String
    var caseReference: String
    var originalAmount: Double
    var feesAmount: Double
    var interestAmount: Double
    var paidAmount: Double
    var currency: String
    var status: String
    var reasonForClaim: String?
    var openedAt: String
    var dueDate: String?
    var closedAt: String?
    var createdAt: String
    var updatedAt: String

    // Zugehörige Daten (optional, wenn vom API-Endpunkt mitgeliefert, z.B. durch JOIN)
    var debtorName: String?
    var auftragName: String?
    var mandantName: String?

    var totalDue: Double { // Berechnete Eigenschaft
        originalAmount + feesAmount + interestAmount
    }
    var outstandingAmount: Double { // Berechnete Eigenschaft
        totalDue - paidAmount
    }

    enum CodingKeys: String, CodingKey {
        case id, currency, status
        case debtorId = "debtor_id"
        case auftragId = "auftrag_id"
        case caseReference = "case_reference"
        case originalAmount = "original_amount"
        case feesAmount = "fees_amount"
        case interestAmount = "interest_amount"
        case paidAmount = "paid_amount"
        case reasonForClaim = "reason_for_claim"
        case openedAt = "opened_at"
        case dueDate = "due_date"
        case closedAt = "closed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // Zugehörige Daten (optional, passe Namen an API-Antwort an)
        case debtorName = "debtor_name"
        case auftragName = "auftrag_name"
        case mandantName = "mandant_name"
    }
}

struct Payment: Identifiable, Codable, Hashable {
    let id: String
    var caseId: String
    var amount: Double
    var paymentDate: String // ISO Date string
    var paymentMethod: String?
    var reference: String?
    var notes: String?
    var recordedAt: String

    enum CodingKeys: String, CodingKey {
        case id, amount, reference, notes
        case caseId = "case_id"
        case paymentDate = "payment_date"
        case paymentMethod = "payment_method"
        case recordedAt = "recorded_at"
    }
}

struct Action: Identifiable, Codable, Hashable {
    let id: String
    var caseId: String
    var actionType: String
    var actionDate: String // ISO Date string
    var notes: String?
    var cost: Double
    var createdByUser: String? // Optional: Agent ID
    var createdAt: String

     enum CodingKeys: String, CodingKey {
        case id, notes, cost
        case caseId = "case_id"
        case actionType = "action_type"
        case actionDate = "action_date"
        case createdByUser = "created_by_user"
        case createdAt = "created_at"
    }
}
