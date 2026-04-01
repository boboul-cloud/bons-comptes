//
//  CampaignStore.swift
//  Bons Comptes
//

import Foundation
import SwiftUI
import Combine
import Compression

@MainActor
class CampaignStore: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var participants: [Participant] = []
    @Published var expenses: [Expense] = []
    @Published var reimbursements: [Reimbursement] = []
    @Published var categories: [ExpenseCategory] = []
    @Published var paymentMethods: [PaymentMethod] = []
    var lastImportError = ""

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
        var categories: [ExpenseCategory]?
        var paymentMethods: [PaymentMethod]?
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

    func createBackup() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let name = "BonsComptes_\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(AppData(
                campaigns: campaigns,
                participants: participants,
                expenses: expenses,
                reimbursements: reimbursements,
                categories: categories,
                paymentMethods: paymentMethods
            ))
            try encoded.write(to: url)
            return url
        } catch {
            print("Backup error: \(error)")
            return nil
        }
    }

    // MARK: - Internal Backups

    struct BackupInfo: Identifiable {
        let id = UUID()
        let name: String
        let date: Date
        let url: URL
        let size: Int64
    }

    private var backupsDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func saveInternalBackup() -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH'h'mm"
        let name = "Backup_\(formatter.string(from: Date())).json"
        let url = backupsDirectory.appendingPathComponent(name)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(AppData(
                campaigns: campaigns,
                participants: participants,
                expenses: expenses,
                reimbursements: reimbursements,
                categories: categories,
                paymentMethods: paymentMethods
            ))
            try encoded.write(to: url)
            return true
        } catch {
            print("Internal backup error: \(error)")
            return false
        }
    }

    func listBackups() -> [BackupInfo] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]) else { return [] }
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                let attrs = try? fm.attributesOfItem(atPath: url.path)
                let size = attrs?[.size] as? Int64 ?? 0
                let date = attrs?[.creationDate] as? Date ?? Date()
                let name = url.deletingPathExtension().lastPathComponent
                return BackupInfo(name: name, date: date, url: url, size: size)
            }
            .sorted { $0.date > $1.date }
    }

    func restoreBackup(_ backup: BackupInfo) -> Bool {
        guard let data = try? Data(contentsOf: backup.url),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else { return false }
        campaigns = decoded.campaigns
        participants = decoded.participants
        expenses = decoded.expenses
        reimbursements = decoded.reimbursements
        categories = decoded.categories ?? ExpenseCategory.defaults
        paymentMethods = decoded.paymentMethods ?? PaymentMethod.defaults
        saveData()
        return true
    }

    func deleteBackup(_ backup: BackupInfo) {
        try? FileManager.default.removeItem(at: backup.url)
    }

    func loadData() {
        guard let data = try? Data(contentsOf: savePath),
              let decoded = try? JSONDecoder().decode(AppData.self, from: data) else { return }
        campaigns = decoded.campaigns
        participants = decoded.participants
        expenses = decoded.expenses
        reimbursements = decoded.reimbursements
        categories = decoded.categories ?? ExpenseCategory.defaults
        paymentMethods = decoded.paymentMethods ?? PaymentMethod.defaults
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

    func closeCampaign(_ campaign: Campaign) {
        if let idx = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[idx].isClosed = true
            saveData()
        }
    }

    func reopenCampaign(_ campaign: Campaign) {
        if let idx = campaigns.firstIndex(where: { $0.id == campaign.id }) {
            campaigns[idx].isClosed = false
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
    static let appScheme = "bonscomptes"

    func appURL(for campaign: Campaign, syncDeletions: Bool = false) -> String {
        let v2Text = encodeV2(for: campaign, syncDeletions: syncDeletions)
        guard let textData = v2Text.data(using: .utf8) else { return "\(Self.appScheme)://import" }

        if let compressed = Self.rawDeflateCompress(textData) {
            let base64 = compressed.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
            return "\(Self.appScheme)://import#z" + base64
        }
        let base64 = textData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "\(Self.appScheme)://import#" + base64
    }

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

    func webURL(for campaign: Campaign, syncDeletions: Bool = false) -> String {
        let v2Text = encodeV2(for: campaign, syncDeletions: syncDeletions)
        guard let textData = v2Text.data(using: .utf8) else { return Self.webBaseURL }

        if let compressed = Self.rawDeflateCompress(textData) {
            let base64 = compressed.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
            return Self.webBaseURL + "#z" + base64
        }
        let base64 = textData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return Self.webBaseURL + "#" + base64
    }

    func webURL(for campaign: Campaign, participantID: UUID, syncDeletions: Bool = false) -> String {
        let base = webURL(for: campaign, syncDeletions: syncDeletions)
        let dashless = Self.dashlessUUID(participantID)
        if let hashIndex = base.firstIndex(of: "#") {
            return String(base[..<hashIndex]) + "?me=\(dashless)" + String(base[hashIndex...])
        }
        return base + "?me=\(dashless)"
    }

    // MARK: - V3 Compact Format (pipe-delimited with UUIDs for merge)

    private static func dashlessUUID(_ id: UUID) -> String {
        id.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }

    private static func uuidFromDashless(_ s: String) -> UUID? {
        guard s.count == 32, s.allSatisfy({ $0.isHexDigit }) else { return nil }
        var u = s
        u.insert("-", at: u.index(u.startIndex, offsetBy: 8))
        u.insert("-", at: u.index(u.startIndex, offsetBy: 13))
        u.insert("-", at: u.index(u.startIndex, offsetBy: 18))
        u.insert("-", at: u.index(u.startIndex, offsetBy: 23))
        return UUID(uuidString: u.uppercased())
    }

    func encodeV2(for campaign: Campaign, syncDeletions: Bool = false) -> String {
        let parts = participantsFor(campaign: campaign)
        let exps = expensesFor(campaign: campaign)
        let reimbs = reimbursementsFor(campaign: campaign)
        let pIdx: [UUID: Int] = Dictionary(uniqueKeysWithValues: parts.enumerated().map { ($1.id, $0) })
        let allPIDs = Set(parts.map { $0.id })
        let df = DateFormatter()
        df.dateFormat = "yyMMdd"
        df.locale = Locale(identifier: "en_US_POSIX")

        var lines: [String] = [syncDeletions ? "v3s" : "v3"]

        // Campaign: id|title[|currency[|description[|location[|phone]]]]
        lines.append(Self.trimV2([
            Self.dashlessUUID(campaign.id),
            Self.escV2(campaign.title),
            campaign.currency == "EUR" ? "" : campaign.currency,
            Self.escV2(campaign.description),
            Self.escV2(campaign.location),
            campaign.managerPhone
        ]))

        // Participants: id|name[|emoji]\tid|name[|emoji]\t...
        lines.append(parts.map { p in
            let base = p.avatarEmoji == "🧑" ? Self.escV2(p.name) : "\(Self.escV2(p.name))|\(p.avatarEmoji)"
            return "\(Self.dashlessUUID(p.id))|\(base)"
        }.joined(separator: "\t"))

        // Expenses: id|title|amount|YYMMDD|payerIdx|splitIdxs[|splitType[|customSplits[|location[|notes]]]]
        lines.append(exps.map { e -> String in
            var f = [Self.dashlessUUID(e.id), Self.escV2(e.title), Self.fmtNum(e.amount), df.string(from: e.date), String(pIdx[e.paidByID] ?? 0)]
            if Set(e.splitAmongIDs) == allPIDs {
                f.append("*")
            } else {
                f.append(e.splitAmongIDs.compactMap { pIdx[$0] }.sorted().map { String($0) }.joined(separator: ","))
            }
            let st = e.splitType == .equal ? "" : (e.splitType == .custom ? "c" : "p")
            let cs: String = e.customSplits.isEmpty ? "" : e.customSplits
                .sorted(by: { (pIdx[$0.key] ?? 0) < (pIdx[$1.key] ?? 0) })
                .map { "\(pIdx[$0.key] ?? 0):\(Self.fmtNum($0.value))" }
                .joined(separator: ",")
            f.append(contentsOf: [st, cs, Self.escV2(e.location), Self.escV2(e.notes)])
            return Self.trimV2(f)
        }.joined(separator: "\t"))

        // Reimbursements (if any)
        if !reimbs.isEmpty {
            lines.append(reimbs.map { r -> String in
                Self.trimV2([
                    Self.dashlessUUID(r.id),
                    String(pIdx[r.fromID] ?? 0), String(pIdx[r.toID] ?? 0),
                    Self.fmtNum(r.amount), df.string(from: r.date),
                    Self.escV2(r.notes), r.isPartial ? "1" : ""
                ])
            }.joined(separator: "\t"))
        }

        return lines.joined(separator: "\n")
    }

    func importV2(_ text: String) -> Bool {
        let lines = text.components(separatedBy: "\n")
        guard lines.count >= 4, lines[0] == "v2" || lines[0] == "v3" || lines[0] == "v3s" else { return false }
        let hasIDs = lines[0] == "v3" || lines[0] == "v3s"
        let syncDeletions = lines[0] == "v3s"
        let o = hasIDs ? 1 : 0 // field offset for ID prefix

        // Campaign
        let cf = lines[1].components(separatedBy: "|")
        let campaignID = hasIDs ? (Self.uuidFromDashless(cf[0]) ?? UUID()) : UUID()
        var campaign = Campaign(
            id: campaignID,
            title: cf.count > o ? cf[o] : "",
            description: cf.count > o + 2 ? cf[o + 2] : "",
            location: cf.count > o + 3 ? cf[o + 3] : "",
            currency: (cf.count > o + 1 && !cf[o + 1].isEmpty) ? cf[o + 1] : "EUR",
            creatorName: "",
            managerPhone: cf.count > o + 4 ? cf[o + 4] : ""
        )

        // Participants
        let parts: [Participant] = lines[2].components(separatedBy: "\t").filter { !$0.isEmpty }.map { item in
            let pf = item.components(separatedBy: "|")
            if hasIDs && pf.count >= 2 {
                let pid = Self.uuidFromDashless(pf[0]) ?? UUID()
                return Participant(id: pid, name: pf[1], avatarEmoji: pf.count > 2 && !pf[2].isEmpty ? pf[2] : "🧑")
            } else {
                return Participant(name: pf[0], avatarEmoji: pf.count > 1 && !pf[1].isEmpty ? pf[1] : "🧑")
            }
        }

        // First participant is the creator
        if let first = parts.first {
            campaign.creatorName = first.name
        }

        // Expenses
        let df = DateFormatter()
        df.dateFormat = "yyMMdd"
        df.locale = Locale(identifier: "en_US_POSIX")

        let exps: [Expense] = lines[3].components(separatedBy: "\t").filter { !$0.isEmpty }.compactMap { item in
            let ef = item.components(separatedBy: "|")
            guard ef.count >= o + 5, let amount = Double(ef[o + 1]) else { return nil }
            let expID = hasIDs ? (Self.uuidFromDashless(ef[0]) ?? UUID()) : UUID()
            let date = df.date(from: ef[o + 2]) ?? Date()
            let payerIdx = Int(ef[o + 3]) ?? 0
            guard payerIdx < parts.count else { return nil }
            let splitIdxs: [Int]
            if ef[o + 4] == "*" {
                splitIdxs = Array(0..<parts.count)
            } else {
                splitIdxs = ef[o + 4].components(separatedBy: ",").compactMap { Int($0) }
            }
            var splitType: SplitType = .equal
            if ef.count > o + 5 && !ef[o + 5].isEmpty {
                splitType = ef[o + 5] == "c" ? .custom : .percentage
            }
            var customSplits: [UUID: Double] = [:]
            if ef.count > o + 6 && !ef[o + 6].isEmpty {
                for pair in ef[o + 6].components(separatedBy: ",") {
                    let kv = pair.components(separatedBy: ":")
                    if kv.count == 2, let idx = Int(kv[0]), let val = Double(kv[1]), idx < parts.count {
                        customSplits[parts[idx].id] = val
                    }
                }
            }
            return Expense(
                id: expID, title: ef[o], amount: amount, date: date,
                paidByID: parts[payerIdx].id,
                splitAmongIDs: splitIdxs.filter { $0 < parts.count }.map { parts[$0].id },
                splitType: splitType, customSplits: customSplits,
                location: ef.count > o + 7 ? ef[o + 7] : "",
                notes: ef.count > o + 8 ? ef[o + 8] : "",
                campaignID: campaignID
            )
        }

        // Reimbursements
        var reimbs: [Reimbursement] = []
        if lines.count > 4 && !lines[4].isEmpty {
            reimbs = lines[4].components(separatedBy: "\t").filter { !$0.isEmpty }.compactMap { item in
                let rf = item.components(separatedBy: "|")
                guard rf.count >= o + 4, let amount = Double(rf[o + 2]) else { return nil }
                let rID = hasIDs ? (Self.uuidFromDashless(rf[0]) ?? UUID()) : UUID()
                let fromIdx = Int(rf[o]) ?? 0
                let toIdx = Int(rf[o + 1]) ?? 0
                guard fromIdx < parts.count, toIdx < parts.count else { return nil }
                return Reimbursement(
                    id: rID, amount: amount, date: df.date(from: rf[o + 3]) ?? Date(),
                    fromID: parts[fromIdx].id, toID: parts[toIdx].id,
                    notes: rf.count > o + 4 ? rf[o + 4] : "",
                    campaignID: campaignID,
                    isPartial: rf.count > o + 5 && rf[o + 5] == "1"
                )
            }
        }

        campaign.participantIDs = parts.map { $0.id }
        campaign.expenseIDs = exps.map { $0.id }
        campaign.reimbursementIDs = reimbs.map { $0.id }

        let appData = AppData(campaigns: [campaign], participants: parts, expenses: exps, reimbursements: reimbs)
        return mergeAppData(appData, syncDeletions: syncDeletions)
    }

    private static func escV2(_ s: String) -> String {
        s.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\t", with: " ")
    }

    private static func fmtNum(_ d: Double) -> String {
        d == d.rounded() && abs(d) < 1e15 ? String(Int(d)) : String(d)
    }

    private static func trimV2(_ fields: [String]) -> String {
        var f = fields
        while f.last == "" { f.removeLast() }
        return f.joined(separator: "|")
    }

    func importJSON(_ jsonString: String) -> Bool {
        lastImportError = ""
        guard var data = jsonString.data(using: .utf8) else {
            lastImportError = "String→Data failed"
            return false
        }
        // Expand short keys and UUID indices if present
        data = Self.expandShortFormat(data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            // Try YYYY-MM-DD first (short format from web/compact URLs)
            if str.count == 10, let _ = str.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                df.locale = Locale(identifier: "en_US_POSIX")
                if let date = df.date(from: str) { return date }
            }
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = f.date(from: str) { return date }
            f.formatOptions = [.withInternetDateTime]
            if let date = f.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        do {
            let appData = try decoder.decode(AppData.self, from: data)
            return mergeAppData(appData)
        } catch {
            lastImportError = "\(error)"
            return false
        }
    }

    func importFromFragment(_ hash: String) -> Bool {
        lastImportError = ""
        guard !hash.isEmpty else {
            lastImportError = "Fragment vide"
            return false
        }

        let jsonData: Data?
        if hash.hasPrefix("z") {
            // Compressed format: z + base64url(raw deflate)
            let b64 = String(hash.dropFirst())
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = b64.padding(toLength: ((b64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            guard let compressed = Data(base64Encoded: padded) else { return false }
            // Decompress raw DEFLATE
            if let decompressed = Self.rawDeflateDecompress(compressed) {
                jsonData = decompressed
            } else if let decompressed = try? (compressed as NSData).decompressed(using: .zlib) as Data {
                jsonData = decompressed
            } else {
                jsonData = compressed
            }
        } else {
            // Legacy uncompressed base64
            let b64 = hash
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = b64.padding(toLength: ((b64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            jsonData = Data(base64Encoded: padded)
        }
        guard let jsonData, let text = String(data: jsonData, encoding: .utf8) else { return false }

        // Detect v2/v3 compact format
        if text.hasPrefix("v2\n") || text.hasPrefix("v3\n") {
            return importV2(text)
        }
        // Legacy JSON format
        return importJSON(text)
    }

    func importFromURL(_ url: URL) -> Bool {
        guard let fragment = url.fragment, !fragment.isEmpty else { return false }
        return importFromFragment(fragment)
    }

    // MARK: - Key Shortening (reduce JSON key sizes)

    private static let keyMap: [String: String] = [
        "campaigns": "C", "participants": "P", "expenses": "E", "reimbursements": "R",
        "categories": "K", "paymentMethods": "M", "_u": "_u",
        "id": "i", "title": "t", "amount": "a", "date": "d", "name": "n",
        "paidByID": "pb", "splitAmongIDs": "sa", "splitType": "st",
        "customSplits": "cs", "categoryID": "ci", "location": "lo", "notes": "no",
        "fromID": "fi", "toID": "ti", "paymentMethodID": "mi",
        "isPartial": "ip", "currency": "cu", "createdAt": "ca",
        "description": "de", "creatorName": "cn",
        "isArchived": "ia", "isClosed": "ic",
        "email": "em", "phone": "ph", "joinedAt": "ja",
        "isActive": "ac", "avatarEmoji": "av",
        "icon": "ik", "isDefault": "df",
        "receiptImageData": "ri",
        "managerPhone": "mp"
    ]

    private static let reverseKeyMap: [String: String] = {
        var m: [String: String] = [:]
        for (long, short) in keyMap { m[short] = long }
        return m
    }()

    static func shortenKeys(_ input: Any) -> Any {
        if let dict = input as? [String: Any] {
            var result: [String: Any] = [:]
            for (k, v) in dict {
                let newKey = keyMap[k] ?? k
                result[newKey] = shortenKeys(v)
            }
            return result
        }
        if let arr = input as? [Any] { return arr.map { shortenKeys($0) } }
        return input
    }

    static func expandKeys(_ input: Any) -> Any {
        if let dict = input as? [String: Any] {
            var result: [String: Any] = [:]
            for (k, v) in dict {
                let newKey = reverseKeyMap[k] ?? k
                result[newKey] = expandKeys(v)
            }
            return result
        }
        if let arr = input as? [Any] { return arr.map { expandKeys($0) } }
        return input
    }

    static func expandShortFormat(_ data: Data) -> Data {
        guard var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return data }
        // Detect short format by checking for short top-level keys
        let isShort = dict["C"] != nil || dict["E"] != nil
        if isShort {
            dict = expandKeys(dict) as! [String: Any]
        }
        // Expand UUIDs if present
        if let rawUUIDs = dict["_u"] as? [String] {
            dict.removeValue(forKey: "_u")
            // Re-insert dashes if stored without them (32 hex chars → 8-4-4-4-12)
            let uuids = rawUUIDs.map { u -> String in
                let h = u.replacingOccurrences(of: "-", with: "")
                guard h.count == 32 else { return u }
                let s = Array(h)
                return "\(String(s[0..<8]))-\(String(s[8..<12]))-\(String(s[12..<16]))-\(String(s[16..<20]))-\(String(s[20..<32]))"
            }
            func expand(_ obj: Any) -> Any {
                if let s = obj as? String, s.hasPrefix("$"), let i = Int(s.dropFirst(1)), i < uuids.count {
                    return uuids[i]
                }
                if let arr = obj as? [Any] { return arr.map { expand($0) } }
                if let d = obj as? [String: Any] {
                    var result: [String: Any] = [:]
                    for (k, v) in d {
                        let newKey: String
                        if k.hasPrefix("$"), let i = Int(k.dropFirst(1)), i < uuids.count {
                            newKey = uuids[i]
                        } else { newKey = k }
                        result[newKey] = expand(v)
                    }
                    return result
                }
                return obj
            }
            dict = expand(dict) as! [String: Any]
        }
        return (try? JSONSerialization.data(withJSONObject: dict)) ?? data
    }

    // MARK: - UUID Indexing (compress UUIDs to "$0", "$1" etc.)

    private static let uuidRegex = try! NSRegularExpression(
        pattern: "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$",
        options: .caseInsensitive
    )

    private static func isUUID(_ s: String) -> Bool {
        s.count == 36 && uuidRegex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    static func compactUUIDs(_ input: [String: Any]) -> [String: Any] {
        var uuids: [String] = []
        var uuidMap: [String: Int] = [:]

        func idx(_ u: String) -> String {
            if let i = uuidMap[u] { return "$\(i)" }
            let i = uuids.count
            uuidMap[u] = i
            // Store without dashes to save 4 chars per UUID
            uuids.append(u.replacingOccurrences(of: "-", with: ""))
            return "$\(i)"
        }

        func compact(_ obj: Any) -> Any {
            if let s = obj as? String { return isUUID(s) ? idx(s) : s }
            if let arr = obj as? [Any] { return arr.map { compact($0) } }
            if let dict = obj as? [String: Any] {
                var result: [String: Any] = [:]
                for (k, v) in dict {
                    let newKey = isUUID(k) ? idx(k) : k
                    result[newKey] = compact(v)
                }
                return result
            }
            return obj
        }

        var result = compact(input) as! [String: Any]
        result["_u"] = uuids
        return result
    }

    static func expandUUIDs(_ data: Data) -> Data {
        guard var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuids = dict["_u"] as? [String] else { return data }
        dict.removeValue(forKey: "_u")

        func expand(_ obj: Any) -> Any {
            if let s = obj as? String, s.hasPrefix("$"), let i = Int(s.dropFirst(1)), i < uuids.count {
                return uuids[i]
            }
            if let arr = obj as? [Any] { return arr.map { expand($0) } }
            if let dict = obj as? [String: Any] {
                var result: [String: Any] = [:]
                for (k, v) in dict {
                    let newKey: String
                    if k.hasPrefix("$"), let i = Int(k.dropFirst(1)), i < uuids.count {
                        newKey = uuids[i]
                    } else { newKey = k }
                    result[newKey] = expand(v)
                }
                return result
            }
            return obj
        }

        let expanded = expand(dict) as! [String: Any]
        return (try? JSONSerialization.data(withJSONObject: expanded)) ?? data
    }

    // MARK: - Raw DEFLATE helpers (compatible with web's deflate-raw)

    static func rawDeflateCompress(_ data: Data) -> Data? {
        let sourceSize = data.count
        let destinationSize = sourceSize + 512
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
        defer { destinationBuffer.deallocate() }
        let compressedSize = data.withUnsafeBytes { sourceBuffer -> Int in
            guard let baseAddress = sourceBuffer.baseAddress else { return 0 }
            return compression_encode_buffer(
                destinationBuffer, destinationSize,
                baseAddress.assumingMemoryBound(to: UInt8.self), sourceSize,
                nil, COMPRESSION_ZLIB
            )
        }
        guard compressedSize > 0 else { return nil }
        return Data(bytes: destinationBuffer, count: compressedSize)
    }

    static func rawDeflateDecompress(_ data: Data) -> Data? {
        let sourceSize = data.count
        // JSON compresses heavily (20-50x); try increasing buffer sizes
        let multipliers = [64, 256, 1024]
        for mult in multipliers {
            let destinationSize = max(sourceSize * mult, 1_000_000)
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationSize)
            let decompressedSize = data.withUnsafeBytes { sourceBuffer -> Int in
                guard let baseAddress = sourceBuffer.baseAddress else { return 0 }
                return compression_decode_buffer(
                    destinationBuffer, destinationSize,
                    baseAddress.assumingMemoryBound(to: UInt8.self), sourceSize,
                    nil, COMPRESSION_ZLIB
                )
            }
            if decompressedSize > 0 && decompressedSize < destinationSize {
                let result = Data(bytes: destinationBuffer, count: decompressedSize)
                destinationBuffer.deallocate()
                return result
            }
            destinationBuffer.deallocate()
        }
        return nil
    }

    private func mergeAppData(_ appData: AppData, syncDeletions: Bool = false) -> Bool {
        // Reconstruct missing ID lists (stripped for compact URL sharing)
        var fixedAppData = appData
        let campaignIDs = Set(fixedAppData.campaigns.map { $0.id })
        for i in fixedAppData.campaigns.indices {
            let cid = fixedAppData.campaigns[i].id
            if fixedAppData.campaigns[i].participantIDs.isEmpty {
                fixedAppData.campaigns[i].participantIDs = fixedAppData.participants.map { $0.id }
            }
            if fixedAppData.campaigns[i].expenseIDs.isEmpty {
                fixedAppData.campaigns[i].expenseIDs = fixedAppData.expenses.map { $0.id }
            }
            if fixedAppData.campaigns[i].reimbursementIDs.isEmpty {
                fixedAppData.campaigns[i].reimbursementIDs = fixedAppData.reimbursements.map { $0.id }
            }
            // Fix expenses/reimbursements missing campaignID
            for j in fixedAppData.expenses.indices where !campaignIDs.contains(fixedAppData.expenses[j].campaignID) {
                fixedAppData.expenses[j].campaignID = cid
            }
            for j in fixedAppData.reimbursements.indices where !campaignIDs.contains(fixedAppData.reimbursements[j].campaignID) {
                fixedAppData.reimbursements[j].campaignID = cid
            }
        }
        for p in fixedAppData.participants {
            if let idx = participants.firstIndex(where: { $0.id == p.id }) {
                var merged = p
                // Preserve local fields not in V3 format
                if merged.phone.isEmpty { merged.phone = participants[idx].phone }
                if merged.email.isEmpty { merged.email = participants[idx].email }
                participants[idx] = merged
            } else {
                participants.append(p)
            }
        }
        for c in fixedAppData.campaigns {
            if let idx = campaigns.firstIndex(where: { $0.id == c.id }) {
                // Merge IDs lists (union)
                var merged = c
                merged.participantIDs = Array(Set(campaigns[idx].participantIDs + c.participantIDs))
                merged.expenseIDs = Array(Set(campaigns[idx].expenseIDs + c.expenseIDs))
                merged.reimbursementIDs = Array(Set(campaigns[idx].reimbursementIDs + c.reimbursementIDs))
                // Preserve fields not in V3 format
                if merged.creatorName.isEmpty { merged.creatorName = campaigns[idx].creatorName }
                campaigns[idx] = merged
            } else {
                campaigns.append(c)
            }
        }
        for e in fixedAppData.expenses {
            if let idx = expenses.firstIndex(where: { $0.id == e.id }) {
                expenses[idx] = e
            } else {
                expenses.append(e)
            }
        }
        for r in fixedAppData.reimbursements {
            if let idx = reimbursements.firstIndex(where: { $0.id == r.id }) {
                reimbursements[idx] = r
            } else {
                reimbursements.append(r)
            }
        }
        for cat in fixedAppData.categories ?? [] {
            if !categories.contains(where: { $0.id == cat.id }) {
                categories.append(cat)
            }
        }
        for pm in fixedAppData.paymentMethods ?? [] {
            if !paymentMethods.contains(where: { $0.id == pm.id }) {
                paymentMethods.append(pm)
            }
        }

        // Sync deletions: remove local entities not present in import
        if syncDeletions, let importedCampaign = fixedAppData.campaigns.first {
            let cid = importedCampaign.id
            let importedExpenseIDs = Set(fixedAppData.expenses.map { $0.id })
            let importedReimbIDs = Set(fixedAppData.reimbursements.map { $0.id })
            let importedParticipantIDs = Set(fixedAppData.participants.map { $0.id })

            expenses.removeAll { $0.campaignID == cid && !importedExpenseIDs.contains($0.id) }
            reimbursements.removeAll { $0.campaignID == cid && !importedReimbIDs.contains($0.id) }

            if let idx = campaigns.firstIndex(where: { $0.id == cid }) {
                campaigns[idx].participantIDs = importedCampaign.participantIDs
                campaigns[idx].expenseIDs = importedCampaign.expenseIDs
                campaigns[idx].reimbursementIDs = importedCampaign.reimbursementIDs
            }

            // Remove orphaned participants (not used by any campaign)
            let allUsedIDs = Set(campaigns.flatMap { $0.participantIDs })
            participants.removeAll { !allUsedIDs.contains($0.id) }
        }

        saveData()
        return true
    }
}
