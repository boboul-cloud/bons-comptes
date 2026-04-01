//
//  BalanceView.swift
//  Bons Comptes
//

import SwiftUI

struct BalanceView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss

    let campaign: Campaign
    @State private var selectedSection = 0
    @State private var selectedSettlement: CampaignStore.Settlement?

    var balances: [(participant: Participant, balance: Double)] {
        store.allBalances(for: campaign).sorted { $0.balance > $1.balance }
    }

    var settlements: [CampaignStore.Settlement] {
        store.computeSettlements(for: campaign)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        summaryCard.animatedAppear()

                        sectionPicker

                        switch selectedSection {
                        case 0: balancesSection
                        case 1: settlementsSection
                        case 2: categorySection
                        case 3: paymentMethodSection
                        default: EmptyView()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(NSLocalizedString("balance_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
            .sheet(item: $selectedSettlement) { s in
                SEPAQRCodeView(
                    fromName: s.from.name,
                    toName: s.to.name,
                    amount: s.amount,
                    currency: campaign.currency,
                    toEmoji: s.to.avatarEmoji
                )
            }
        }
    }

    private var sectionTabs: [(Int, String, String)] {
        [
            (0, "chart.bar.fill", NSLocalizedString("individual_balances", comment: "")),
            (1, "arrow.left.arrow.right", NSLocalizedString("settlements", comment: "")),
            (2, "tag.fill", NSLocalizedString("by_category", comment: "")),
            (3, "banknote.fill", NSLocalizedString("by_payment_method", comment: ""))
        ]
    }

    var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(sectionTabs, id: \.0) { tag, icon, label in
                    Button {
                        withAnimation(.spring(duration: 0.3)) { selectedSection = tag }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon).font(.caption)
                            Text(label).font(.caption).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedSection == tag ? .white : AppTheme.primary)
                        .background(selectedSection == tag ? AppTheme.primary : AppTheme.primary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    var summaryCard: some View {
        let count = store.participantsFor(campaign: campaign).count
        let total = store.totalExpenses(for: campaign)
        let avg = count > 0 ? total / Double(count) : 0

        return ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.headerGradient)
                .frame(height: 160)
            VStack(spacing: 12) {
                Text(NSLocalizedString("total_expenses_label", comment: ""))
                    .font(.caption).foregroundColor(.white.opacity(0.8))
                Text(String(format: "%.2f %@", total, campaign.currency))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("\(store.expensesFor(campaign: campaign).count)")
                            .font(.headline).foregroundColor(.white)
                        Text(NSLocalizedString("expense_count", comment: ""))
                            .font(.caption2).foregroundColor(.white.opacity(0.7))
                    }
                    Divider().frame(height: 30).background(.white.opacity(0.3))
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%@", avg, campaign.currency))
                            .font(.headline).foregroundColor(.white)
                        Text(NSLocalizedString("per_person_avg", comment: ""))
                            .font(.caption2).foregroundColor(.white.opacity(0.7))
                    }
                    Divider().frame(height: 30).background(.white.opacity(0.3))
                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(.headline).foregroundColor(.white)
                        Text(NSLocalizedString("participants_count", comment: ""))
                            .font(.caption2).foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    var balancesSection: some View {
        let maxAbs = balances.map { abs($0.balance) }.max() ?? 1

        return LazyVStack(spacing: 12) {
            ForEach(Array(balances.enumerated()), id: \.element.participant.id) { i, item in
                let displayBalance = -item.balance
                HStack(spacing: 14) {
                    AvatarView(item.participant.avatarEmoji, size: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.participant.name).font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text(String(format: "%+.2f %@", displayBalance, campaign.currency))
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundColor(displayBalance <= 0 ? AppTheme.positive : AppTheme.negative)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.15)).frame(height: 6)
                                Capsule()
                                    .fill(displayBalance <= 0 ? AppTheme.positive : AppTheme.negative)
                                    .frame(width: maxAbs > 0 ? geo.size.width * abs(item.balance) / maxAbs : 0, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .cardStyle()
                .animatedAppear(delay: Double(i) * 0.05)
            }
        }
        .padding(.horizontal)
    }

    var settlementsSection: some View {
        LazyVStack(spacing: 12) {
            if settlements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48)).foregroundColor(AppTheme.positive)
                    Text(NSLocalizedString("all_settled", comment: ""))
                        .font(.headline).foregroundColor(AppTheme.positive)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
                .animatedAppear()
            } else {
                ForEach(Array(settlements.enumerated()), id: \.element.id) { i, s in
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            AvatarView(s.from.avatarEmoji, size: 40)
                            Text(s.from.name).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                        }

                        VStack(spacing: 4) {
                            Image(systemName: "arrow.right")
                                .font(.title3).fontWeight(.bold).foregroundColor(AppTheme.negative)
                            Text(String(format: "%.2f %@", s.amount, campaign.currency))
                                .font(.caption).fontWeight(.bold).foregroundColor(AppTheme.negative)
                        }

                        VStack(spacing: 4) {
                            AvatarView(s.to.avatarEmoji, size: 40)
                            Text(s.to.name).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                        }

                        Button(action: { selectedSettlement = s }) {
                            ZStack {
                                Circle().fill(AppTheme.accent.opacity(0.12)).frame(width: 36, height: 36)
                                Image(systemName: "qrcode").font(.system(size: 14)).foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .cardStyle()
                    .animatedAppear(delay: Double(i) * 0.05)
                }
            }
        }
        .padding(.horizontal)
    }

    var categorySection: some View {
        let expenses = store.expensesFor(campaign: campaign)
        let grouped = Dictionary(grouping: expenses) { $0.categoryID }
        let total = expenses.reduce(0) { $0 + $1.amount }

        return LazyVStack(spacing: 12) {
            ForEach(Array(grouped.keys.sorted(by: { ($0?.uuidString ?? "") < ($1?.uuidString ?? "") }).enumerated()), id: \.element) { i, catID in
                let catExpenses = grouped[catID] ?? []
                let catTotal = catExpenses.reduce(0) { $0 + $1.amount }
                let cat = catID.flatMap { id in store.categories.first { $0.id == id } }
                let catName = cat?.name ?? NSLocalizedString("no_category", comment: "")
                let catIcon = cat?.icon ?? "questionmark.circle"
                let percentage = total > 0 ? catTotal / total : 0

                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(AppTheme.info.opacity(0.12)).frame(width: 44, height: 44)
                        Image(systemName: catIcon).foregroundColor(AppTheme.info)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(catName).font(.subheadline).fontWeight(.semibold)
                            Spacer()
                            Text(String(format: "%.2f %@", catTotal, campaign.currency))
                                .font(.subheadline).fontWeight(.bold).foregroundColor(AppTheme.info)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.gray.opacity(0.15)).frame(height: 6)
                                Capsule().fill(AppTheme.info).frame(width: geo.size.width * percentage, height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text(String(format: "%d %@ \u{2022} %.0f%%", catExpenses.count, NSLocalizedString("expenses_tab", comment: "").lowercased(), percentage * 100))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                .cardStyle()
                .animatedAppear(delay: Double(i) * 0.05)
            }
        }
        .padding(.horizontal)
    }

    var paymentMethodSection: some View {
        let reimbursements = store.reimbursementsFor(campaign: campaign)
        let total = reimbursements.reduce(0) { $0 + $1.amount }
        let grouped = Dictionary(grouping: reimbursements) { $0.paymentMethodID }

        return LazyVStack(spacing: 12) {
            if reimbursements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "banknote").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.5))
                    Text(NSLocalizedString("no_reimbursements", comment: "")).font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
                .animatedAppear()
            } else {
                // Total reimbursed
                HStack {
                    Text(NSLocalizedString("total_reimbursed", comment: ""))
                        .font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f %@", total, campaign.currency))
                        .font(.headline).fontWeight(.bold).foregroundColor(AppTheme.positive)
                }
                .cardStyle()
                .animatedAppear()

                ForEach(Array(grouped.keys.sorted(by: { ($0?.uuidString ?? "") < ($1?.uuidString ?? "") }).enumerated()), id: \.element) { i, methodID in
                    let items = grouped[methodID] ?? []
                    let methodTotal = items.reduce(0) { $0 + $1.amount }
                    let method = methodID.flatMap { id in store.paymentMethods.first { $0.id == id } }
                    let methodName = method?.name ?? NSLocalizedString("no_payment_method", comment: "")
                    let methodIcon = method?.icon ?? "questionmark.circle"
                    let percentage = total > 0 ? methodTotal / total : 0

                    VStack(spacing: 10) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(AppTheme.positive.opacity(0.12)).frame(width: 44, height: 44)
                                Image(systemName: methodIcon).foregroundColor(AppTheme.positive)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(methodName).font(.subheadline).fontWeight(.semibold)
                                    Spacer()
                                    Text(String(format: "%.2f %@", methodTotal, campaign.currency))
                                        .font(.subheadline).fontWeight(.bold).foregroundColor(AppTheme.positive)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.gray.opacity(0.15)).frame(height: 6)
                                        Capsule().fill(AppTheme.positive).frame(width: geo.size.width * percentage, height: 6)
                                    }
                                }
                                .frame(height: 6)

                                Text(String(format: "%d %@ \u{2022} %.0f%%", items.count, NSLocalizedString("reimbursements_tab", comment: "").lowercased(), percentage * 100))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }

                        // Detail per reimbursement
                        ForEach(items.sorted(by: { $0.date > $1.date })) { r in
                            HStack(spacing: 8) {
                                Text(store.participant(byID: r.fromID)?.name ?? "?")
                                    .font(.caption).fontWeight(.medium)
                                Image(systemName: "arrow.right").font(.caption2).foregroundColor(.secondary)
                                Text(store.participant(byID: r.toID)?.name ?? "?")
                                    .font(.caption).fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.2f %@", r.amount, campaign.currency))
                                    .font(.caption).fontWeight(.semibold).foregroundColor(AppTheme.positive)
                                Text(r.date.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            .padding(.leading, 58)
                        }
                    }
                    .cardStyle()
                    .animatedAppear(delay: Double(i) * 0.05)
                }
            }
        }
        .padding(.horizontal)
    }
}
