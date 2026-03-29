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

    enum CodingKeys: String, CodingKey {
        case id, title, amount, date, paidByID, splitAmongIDs, splitType
        case customSplits, categoryID, location, notes, receiptImageData, campaignID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        amount = try c.decode(Double.self, forKey: .amount)
        date = try c.decode(Date.self, forKey: .date)
        paidByID = try c.decode(UUID.self, forKey: .paidByID)
        splitAmongIDs = try c.decode([UUID].self, forKey: .splitAmongIDs)
        splitType = try c.decodeIfPresent(SplitType.self, forKey: .splitType) ?? .equal
        categoryID = try c.decodeIfPresent(UUID.self, forKey: .categoryID)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        receiptImageData = try c.decodeIfPresent(Data.self, forKey: .receiptImageData)
        campaignID = try c.decodeIfPresent(UUID.self, forKey: .campaignID) ?? UUID()

        // customSplits: handle both web format {"uuid": val} and Swift format [uuid, val, ...]
        if let dict = try? c.decode([String: Double].self, forKey: .customSplits) {
            // Web format: JSON object with string keys
            var result: [UUID: Double] = [:]
            for (key, val) in dict {
                if let uuid = UUID(uuidString: key) {
                    result[uuid] = val
                }
            }
            customSplits = result
        } else if let arr = try? c.decode([UUID: Double].self, forKey: .customSplits) {
            // Swift native format: alternating array
            customSplits = arr
        } else {
            customSplits = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(amount, forKey: .amount)
        try c.encode(date, forKey: .date)
        try c.encode(paidByID, forKey: .paidByID)
        try c.encode(splitAmongIDs, forKey: .splitAmongIDs)
        try c.encode(splitType, forKey: .splitType)
        // Encode as JSON object {string: double} for web compatibility, skip if empty
        if !customSplits.isEmpty {
            var dict: [String: Double] = [:]
            for (key, val) in customSplits { dict[key.uuidString] = val }
            try c.encode(dict, forKey: .customSplits)
        }
        try c.encodeIfPresent(categoryID, forKey: .categoryID)
        if !location.isEmpty { try c.encode(location, forKey: .location) }
        if !notes.isEmpty { try c.encode(notes, forKey: .notes) }
        try c.encodeIfPresent(receiptImageData, forKey: .receiptImageData)
        try c.encode(campaignID, forKey: .campaignID)
    }

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
