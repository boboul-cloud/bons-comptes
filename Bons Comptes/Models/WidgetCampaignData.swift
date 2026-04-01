//
//  WidgetCampaignData.swift
//  Bons Comptes
//
//  Shared data model for Widget <-> Main App communication
//

import Foundation

struct WidgetCampaignData: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let currency: String
    let totalExpenses: Double
    let perPerson: Double
    let participantCount: Int
    let expenseCount: Int
    let lastUpdate: Date
}
