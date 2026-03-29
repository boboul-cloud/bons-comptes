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
}
