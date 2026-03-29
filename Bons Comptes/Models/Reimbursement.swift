//
//  Reimbursement.swift
//  Bons Comptes
//

import Foundation

struct Reimbursement: Identifiable, Codable {
    var id: UUID
    var amount: Double
    var date: Date
    var fromID: UUID
    var toID: UUID
    var paymentMethodID: UUID?
    var notes: String
    var campaignID: UUID
    var isPartial: Bool

    enum CodingKeys: String, CodingKey {
        case id, amount, date, fromID, toID, paymentMethodID, notes, campaignID, isPartial
    }

    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date = Date(),
        fromID: UUID,
        toID: UUID,
        paymentMethodID: UUID? = nil,
        notes: String = "",
        campaignID: UUID,
        isPartial: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.fromID = fromID
        self.toID = toID
        self.paymentMethodID = paymentMethodID
        self.notes = notes
        self.campaignID = campaignID
        self.isPartial = isPartial
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        amount = try c.decode(Double.self, forKey: .amount)
        date = try c.decode(Date.self, forKey: .date)
        fromID = try c.decode(UUID.self, forKey: .fromID)
        toID = try c.decode(UUID.self, forKey: .toID)
        paymentMethodID = try c.decodeIfPresent(UUID.self, forKey: .paymentMethodID)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        campaignID = try c.decodeIfPresent(UUID.self, forKey: .campaignID) ?? UUID()
        isPartial = try c.decodeIfPresent(Bool.self, forKey: .isPartial) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(amount, forKey: .amount)
        try c.encode(date, forKey: .date)
        try c.encode(fromID, forKey: .fromID)
        try c.encode(toID, forKey: .toID)
        try c.encodeIfPresent(paymentMethodID, forKey: .paymentMethodID)
        if !notes.isEmpty { try c.encode(notes, forKey: .notes) }
        try c.encode(campaignID, forKey: .campaignID)
        if isPartial { try c.encode(isPartial, forKey: .isPartial) }
    }
}
