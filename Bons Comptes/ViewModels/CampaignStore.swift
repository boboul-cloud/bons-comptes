//
//  CampaignStore.swift
//  Bons Comptes
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CampaignStore: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var participants: [Participant] = []
    @Published var expenses: [Expense] = []
    @Published var reimbursements: [Reimbursement] = []
    @Published var categories: [ExpenseCategory] = []
    @Published var paymentMethods: [PaymentMethod] = []

    private let saveKey = "BonsComptes_Data"

    init() {
        loadData()
        if categories.isEmpty {
            categories = ExpenseCategory.defaults
        }
        if paymentMethods.isEmpty {
            paymentMethods = PaymentMethod.defaults
        }
    }

    // MARK: - Persistence

    private var savePath: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bonscomptes.json")
    }

    struct AppData: Codable {
        var campaigns: [Campaign]
        var participants: [Participant]
        var expenses: [Expense]
        var reimbursements: [Reimbursement]
        var categories: [ExpenseCategory]
        var paymentMethods: [PaymentMethod]
    }

    func saveData() {
        let data = AppData(
            campaigns: campaigns,
            participants: participants,
            expenses: expenses,
            reimbursements: reimbursements,
            categories: categories,
            paymentMethods: paymentMethods
        )
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: savePath, options: [.atomic, .completeFileProtection])
        } catch {
            print("Save error: \(error)")
        }
    }

    func loadData() {
        guard let data = try? Data(contentsOf: savePath),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else { return }
        campaigns = decoded.campaigns
        participants = decoded.participants
        expenses = decoded.expenses
        reimbursements = decoded.reimbursements
        categories = decoded.categories
        paymentMethods = decoded.paymentMethods
    }

    // MARK: - Campaign CRUD

    func addCampaign(_ campaign: Campaign) {
        campaigns.append(campaign)
        saveData()
    }

    func updateCampaign(_ campaign: Campaign) {
        if let idx = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[idx] = campaign
            saveData()
        }
    }

    func deleteCampaign(_ campaign: Campaign) {
        expenses.removeAll { $0.campaignID == campaign.id }
        reimbursements.removeAll { $0.campaignID == campaign.id }
        campaigns.removeAll { $0.id == campaign.id }
        saveData()
    }

    func archiveCampaign(_ campaign: Campaign) {
        if let idx = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[idx].isArchived = true
            saveData()
        }
    }

    // MARK: - Participants

    func addParticipant(_ participant: Participant, to campaign: inout Campaign) {
        participants.append(participant)
        campaign.participantIDs.append(participant.id)
        updateCampaign(campaign)
    }

    func removeParticipant(_ participant: Participant, from campaign: inout Campaign) {
        let balance = balanceFor(participant: participant, in: campaign)
        guard abs(balance) < 0.01 else { return }
        campaign.participantIDs.removeAll { $0 == participant.id }
        updateCampaign(campaign)
    }

    func participantsFor(campaign: Campaign) -> [Participant] {
        participants.filter { campaign.participantIDs.contains($0.id) }
    }

    func participant(byID id: UUID) -> Participant? {
        participants.first { $0.id == id }
    }

    // MARK: - Expenses

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        if let idx = campaigns.firstIndex(where: { $0.id == expense.campaignID }) {
            campaigns[idx].expenseIDs.append(expense.id)
        }
        saveData()
    }

    func updateExpense(_ expense: Expense) {
        if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[idx] = expense
            saveData()
        }
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        if let idx = campaigns.firstIndex(where: { $0.id == expense.campaignID }) {
            campaigns[idx].expenseIDs.removeAll { $0 == expense.id }
        }
        saveData()
    }

    func expensesFor(campaign: Campaign) -> [Expense] {
        expenses.filter { $0.campaignID == campaign.id }
    }

    // MARK: - Reimbursements

    func addReimbursement(_ reimbursement: Reimbursement) {
        reimbursements.append(reimbursement)
        if let idx = campaigns.firstIndex(where: { $0.id == reimbursement.campaignID }) {
            campaigns[idx].reimbursementIDs.append(reimbursement.id)
        }
        saveData()
    }

    func deleteReimbursement(_ reimbursement: Reimbursement) {
        reimbursements.removeAll { $0.id == reimbursement.id }
        if let idx = campaigns.firstIndex(where: { $0.id == reimbursement.campaignID }) {
            campaigns[idx].reimbursementIDs.removeAll { $0 == reimbursement.id }
        }
        saveData()
    }

    func reimbursementsFor(campaign: Campaign) -> [Reimbursement] {
        reimbursements.filter { $0.campaignID == campaign.id }
    }

    // MARK: - Categories

    func addCategory(_ category: ExpenseCategory) {
        categories.append(category)
        saveData()
    }

    func deleteCategory(_ category: ExpenseCategory) {
        guard !category.isDefault else { return }
        categories.removeAll { $0.id == category.id }
        saveData()
    }

    // MARK: - Payment Methods

    func addPaymentMethod(_ method: PaymentMethod) {
        paymentMethods.append(method)
        saveData()
    }

    func deletePaymentMethod(_ method: PaymentMethod) {
        guard !method.isDefault else { return }
        paymentMethods.removeAll { $0.id == method.id }
        saveData()
    }

    // MARK: - Balance Calculation

    func balanceFor(participant: Participant, in campaign: Campaign) -> Double {
        let campaignExpenses = expensesFor(campaign: campaign)
        let campaignReimbursements = reimbursementsFor(campaign: campaign)

        var balance: Double = 0

        for expense in campaignExpenses {
            if expense.paidByID == participant.id {
                balance += expense.amount
            }
            balance -= expense.shareFor(participantID: participant.id)
        }

        for reimbursement in campaignReimbursements {
            if reimbursement.fromID == participant.id {
                // from = celui qui rembourse → sa dette diminue (balance augmente)
                balance += reimbursement.amount
            }
            if reimbursement.toID == participant.id {
                // to = celui qui reçoit → son crédit diminue (balance diminue)
                balance -= reimbursement.amount
            }
        }

        return balance
    }

    func allBalances(for campaign: Campaign) -> [(participant: Participant, balance: Double)] {
        participantsFor(campaign: campaign).map { p in
            (participant: p, balance: balanceFor(participant: p, in: campaign))
        }
    }

    func totalExpenses(for campaign: Campaign) -> Double {
        expensesFor(campaign: campaign).reduce(0) { $0 + $1.amount }
    }

    // MARK: - Smart Settlement (minimize transactions)

    struct Settlement: Identifiable {
        let id = UUID()
        let from: Participant
        let to: Participant
        let amount: Double
    }

    func computeSettlements(for campaign: Campaign) -> [Settlement] {
        let balances = allBalances(for: campaign)
        var debtors: [(Participant, Double)] = []
        var creditors: [(Participant, Double)] = []

        for (p, b) in balances {
            if b < -0.01 {
                debtors.append((p, -b))
            } else if b > 0.01 {
                creditors.append((p, b))
            }
        }

        debtors.sort { $0.1 > $1.1 }
        creditors.sort { $0.1 > $1.1 }

        var settlements: [Settlement] = []
        var i = 0, j = 0
        while i < debtors.count && j < creditors.count {
            let amount = min(debtors[i].1, creditors[j].1)
            if amount > 0.01 {
                settlements.append(Settlement(from: debtors[i].0, to: creditors[j].0, amount: (amount * 100).rounded() / 100))
            }
            debtors[i].1 -= amount
            creditors[j].1 -= amount
            if debtors[i].1 < 0.01 { i += 1 }
            if creditors[j].1 < 0.01 { j += 1 }
        }

        return settlements
    }

    // MARK: - Export / Share

    static let webBaseURL = "https://boboul-cloud.github.io/bons-comptes/"

    func exportJSON(for campaign: Campaign) -> String {
        let data = AppData(
            campaigns: [campaign],
            participants: participantsFor(campaign: campaign),
            expenses: expensesFor(campaign: campaign),
            reimbursements: reimbursementsFor(campaign: campaign),
            categories: categories,
            paymentMethods: paymentMethods
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }

    func webURL(for campaign: Campaign) -> String {
        let data = AppData(
            campaigns: [campaign],
            participants: participantsFor(campaign: campaign),
            expenses: expensesFor(campaign: campaign),
            reimbursements: reimbursementsFor(campaign: campaign),
            categories: categories,
            paymentMethods: paymentMethods
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(data) else { return Self.webBaseURL }
        let base64 = jsonData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return Self.webBaseURL + "#" + base64
    }

    func importJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let appData = try? decoder.decode(AppData.self, from: data) else { return false }

        for p in appData.participants where !participants.contains(where: { $0.id == p.id }) {
            participants.append(p)
        }
        for c in appData.campaigns where !campaigns.contains(where: { $0.id == c.id }) {
            campaigns.append(c)
        }
        for e in appData.expenses where !expenses.contains(where: { $0.id == e.id }) {
            expenses.append(e)
        }
        for r in appData.reimbursements where !reimbursements.contains(where: { $0.id == r.id }) {
            reimbursements.append(r)
        }
        for cat in appData.categories where !categories.contains(where: { $0.id == cat.id }) {
            categories.append(cat)
        }
        for pm in appData.paymentMethods where !paymentMethods.contains(where: { $0.id == pm.id }) {
            paymentMethods.append(pm)
        }

        saveData()
        return true
    }
}
