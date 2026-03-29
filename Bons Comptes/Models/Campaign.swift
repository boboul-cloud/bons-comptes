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
    var isClosed: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description, location, currency, createdAt
        case shareCode
        case creatorName, participantIDs, expenseIDs, reimbursementIDs
        case isArchived, isClosed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        if !description.isEmpty { try container.encode(description, forKey: .description) }
        if !location.isEmpty { try container.encode(location, forKey: .location) }
        try container.encode(currency, forKey: .currency)
        try container.encode(createdAt, forKey: .createdAt)
        if !creatorName.isEmpty { try container.encode(creatorName, forKey: .creatorName) }
        try container.encode(participantIDs, forKey: .participantIDs)
        try container.encode(expenseIDs, forKey: .expenseIDs)
        try container.encode(reimbursementIDs, forKey: .reimbursementIDs)
        if isArchived { try container.encode(isArchived, forKey: .isArchived) }
        if isClosed { try container.encode(isClosed, forKey: .isClosed) }
        // shareCode intentionally not encoded
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "EUR"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        shareCode = try container.decodeIfPresent(String.self, forKey: .shareCode) ?? ""
        creatorName = try container.decodeIfPresent(String.self, forKey: .creatorName) ?? ""
        participantIDs = try container.decodeIfPresent([UUID].self, forKey: .participantIDs) ?? []
        expenseIDs = try container.decodeIfPresent([UUID].self, forKey: .expenseIDs) ?? []
        reimbursementIDs = try container.decodeIfPresent([UUID].self, forKey: .reimbursementIDs) ?? []
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        isClosed = try container.decodeIfPresent(Bool.self, forKey: .isClosed) ?? false
    }

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
        isArchived: Bool = false,
        isClosed: Bool = false
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
        self.isClosed = isClosed
    }

    static func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}
