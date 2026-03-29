//
//  Expense.swift
//  Bons Comptes
//

import Foundation

struct Expense: Identifiable, Codable {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var paidByID: UUID
    var splitAmongIDs: [UUID]
    var splitType: SplitType
    var customSplits: [UUID: Double]
    var categoryID: UUID?
    var location: String
    var notes: String
    var receiptImageData: Data?
    var campaignID: UUID

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        date: Date = Date(),
        paidByID: UUID,
        splitAmongIDs: [UUID],
        splitType: SplitType = .equal,
        customSplits: [UUID: Double] = [:],
        categoryID: UUID? = nil,
        location: String = "",
        notes: String = "",
        receiptImageData: Data? = nil,
        campaignID: UUID
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.paidByID = paidByID
        self.splitAmongIDs = splitAmongIDs
        self.splitType = splitType
        self.customSplits = customSplits
        self.categoryID = categoryID
        self.location = location
        self.notes = notes
        self.receiptImageData = receiptImageData
        self.campaignID = campaignID
    }

    func shareFor(participantID: UUID) -> Double {
        guard splitAmongIDs.contains(participantID) else { return 0 }
        switch splitType {
        case .equal:
            return amount / Double(splitAmongIDs.count)
        case .custom:
            return customSplits[participantID] ?? 0
        case .percentage:
            let pct = customSplits[participantID] ?? 0
            return amount * pct / 100.0
        }
    }
}

enum SplitType: String, Codable, CaseIterable {
    case equal
    case custom
    case percentage

    var displayKey: String {
        switch self {
        case .equal: return "split_equal"
        case .custom: return "split_custom"
        case .percentage: return "split_percentage"
        }
    }
}
