//
//  Campaign.swift
//  Bons Comptes
//

import Foundation

struct Campaign: Identifiable, Codable {
    var id: UUID
    var title: String
    var description: String
    var location: String
    var currency: String
    var createdAt: Date
    var shareCode: String
    var creatorName: String
    var participantIDs: [UUID]
    var expenseIDs: [UUID]
    var reimbursementIDs: [UUID]
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        location: String = "",
        currency: String = "EUR",
        createdAt: Date = Date(),
        shareCode: String = "",
        creatorName: String,
        participantIDs: [UUID] = [],
        expenseIDs: [UUID] = [],
        reimbursementIDs: [UUID] = [],
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.location = location
        self.currency = currency
        self.createdAt = createdAt
        self.shareCode = shareCode.isEmpty ? Campaign.generateShareCode() : shareCode
        self.creatorName = creatorName
        self.participantIDs = participantIDs
        self.expenseIDs = expenseIDs
        self.reimbursementIDs = reimbursementIDs
        self.isArchived = isArchived
    }

    static func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}
