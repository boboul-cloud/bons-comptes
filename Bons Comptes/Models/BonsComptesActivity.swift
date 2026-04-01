//
//  BonsComptesActivity.swift
//  Bons Comptes
//
//  ActivityAttributes for Live Activity + Dynamic Island
//

import Foundation
import ActivityKit

struct BonsComptesActivityAttributes: ActivityAttributes {
    // Static data that won't change during the activity
    let campaignTitle: String
    let currency: String
    let participantCount: Int

    // Dynamic data that updates during the activity
    struct ContentState: Codable, Hashable {
        let totalExpenses: Double
        let perPerson: Double
        let expenseCount: Int
        let lastExpenseTitle: String
    }
}
