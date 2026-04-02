//
//  CampaignDetailView.swift
//  Bons Comptes
//

import SwiftUI

struct CampaignDetailView: View {
    @EnvironmentObject var store: CampaignStore
    @State var campaign: Campaign
    @State private var showingAddExpense = false
    @State private var showingAddReimbursement = false
    @State private var showingParticipants = false
    @State private var showingBalance = false
    @State private var showingShare = false
    @State private var showingCloseAlert = false
    @State private var selectedTab = 0
    @State private var editingExpense: Expense?
    @State private var showingReceiptScanner = false
    @State private var isLiveActivityOn = false
    @State private var showPremiumUpgrade = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.backgroundGradient.ignoresSafeArea()
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 20) {
                    if campaign.isClosed {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text(NSLocalizedString("campaign_closed_banner", comment: ""))
                                .font(.subheadline).fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.negative.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal)
                    }
                    heroHeader.animatedAppear()
                    quickActions.animatedAppear(delay: 0.1)
                    statsRow.animatedAppear(delay: 0.15)

                    Picker("", selection: $selectedTab) {
                        Text(NSLocalizedString("expenses_tab", comment: "")).tag(0)
                        Text(NSLocalizedString("reimbursements_tab", comment: "")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 { expensesSection } else { reimbursementsSection }
                }
                .padding(.bottom, 90)
            }

            floatingButton
        }
        .navigationTitle(campaign.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(campaign: campaign).onDisappear { refreshCampaign() }
        }
        .sheet(isPresented: $showingAddReimbursement) {
            AddReimbursementView(campaign: campaign).onDisappear { refreshCampaign() }
        }
        .sheet(isPresented: $showingParticipants) {
            ParticipantsView(campaign: $campaign).onDisappear { refreshCampaign() }
        }
        .sheet(isPresented: $showingBalance) { BalanceView(campaign: campaign) }
        .sheet(isPresented: $showingShare) { ShareView(campaign: campaign) }
        .sheet(item: $editingExpense) { expense in
            EditExpenseView(campaign: campaign, expense: expense).onDisappear { refreshCampaign() }
        }
        .sheet(isPresented: $showingReceiptScanner) {
            ReceiptScannerView(campaign: campaign).onDisappear { refreshCampaign() }
        }
        .sheet(isPresented: $showPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .alert(NSLocalizedString("close_campaign_title", comment: ""), isPresented: $showingCloseAlert) {
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("close_confirm", comment: ""), role: .destructive) {
                store.closeCampaign(campaign)
                refreshCampaign()
            }
        } message: {
            Text(NSLocalizedString("close_campaign_message", comment: ""))
        }
    }

    func refreshCampaign() {
        if let updated = store.campaigns.first(where: { $0.id == campaign.id }) { campaign = updated }
        if isLiveActivityOn { store.updateLiveActivity(for: campaign) }
    }

    var heroHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AppTheme.headerGradient).frame(height: 140)
            VStack(spacing: 8) {
                Text(String(format: "%.2f %@", store.totalExpenses(for: campaign), campaign.currency))
                    .font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(.white)
                HStack(spacing: 16) {
                    if !campaign.location.isEmpty {
                        Label(campaign.location, systemImage: "mappin.and.ellipse").font(.caption).foregroundColor(.white.opacity(0.85))
                    }
                    Label("\(store.participantsFor(campaign: campaign).count) \(NSLocalizedString("participants_count", comment: ""))", systemImage: "person.2").font(.caption).foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .padding(.horizontal)
    }

    var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                quickActionButton(icon: "person.3.fill", label: NSLocalizedString("participants_count", comment: ""), color: AppTheme.primary) { showingParticipants = true }
                quickActionButton(icon: "chart.pie.fill", label: NSLocalizedString("balance_title", comment: ""), color: AppTheme.accent) { showingBalance = true }
                quickActionButton(icon: "square.and.arrow.up.fill", label: NSLocalizedString("share_campaign", comment: ""), color: AppTheme.info) { showingShare = true }
                if !campaign.isClosed {
                    quickActionButton(
                        icon: isLiveActivityOn ? "bolt.circle.fill" : "bolt.circle",
                        label: NSLocalizedString(isLiveActivityOn ? "live_stop" : "live_start", comment: ""),
                        color: AppTheme.warning
                    ) {
                        guard PremiumManager.shared.isPremium else { showPremiumUpgrade = true; return }
                        if isLiveActivityOn {
                            store.stopLiveActivity(for: campaign)
                        } else {
                            store.startLiveActivity(for: campaign)
                        }
                        isLiveActivityOn.toggle()
                    }
                }
                if !campaign.isClosed {
                    quickActionButton(icon: "doc.text.viewfinder", label: NSLocalizedString("scan_receipt", comment: ""), color: AppTheme.warning) {
                        guard PremiumManager.shared.isPremium else { showPremiumUpgrade = true; return }
                        showingReceiptScanner = true
                    }
                }
                if campaign.isClosed {
                    quickActionButton(icon: "lock.open.fill", label: NSLocalizedString("reopen_campaign", comment: ""), color: AppTheme.positive) {
                        store.reopenCampaign(campaign)
                        refreshCampaign()
                    }
                } else {
                    quickActionButton(icon: "lock.fill", label: NSLocalizedString("close_campaign", comment: ""), color: AppTheme.negative) {
                        showingCloseAlert = true
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3).foregroundColor(color)
                Text(label).font(.caption2).foregroundColor(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    var statsRow: some View {
        let participants = store.participantsFor(campaign: campaign)
        let total = store.totalExpenses(for: campaign)
        let avg = participants.count > 0 ? total / Double(participants.count) : 0
        return HStack(spacing: 12) {
            StatCard(title: NSLocalizedString("expense_count", comment: ""), value: "\(store.expensesFor(campaign: campaign).count)", icon: "receipt", color: AppTheme.negative)
            StatCard(title: NSLocalizedString("per_person_avg", comment: ""), value: String(format: "%.0f%@", avg, campaign.currency), icon: "person", color: AppTheme.primary)
            StatCard(title: NSLocalizedString("participants_count", comment: ""), value: "\(participants.count)", icon: "person.2", color: AppTheme.accent)
        }
        .padding(.horizontal)
    }

    var expensesSection: some View {
        let items = store.expensesFor(campaign: campaign).sorted { $0.date > $1.date }
        return LazyVStack(spacing: 12) {
            if items.isEmpty {
                emptySection(icon: "cart.badge.plus", text: NSLocalizedString("no_expenses", comment: ""))
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, expense in
                    ExpenseCardView(expense: expense, currency: campaign.currency)
                        .animatedAppear(delay: Double(i) * 0.05)
                        .onTapGesture { editingExpense = expense }
                        .contextMenu {
                            Button { editingExpense = expense } label: {
                                Label(NSLocalizedString("edit_expense", comment: ""), systemImage: "pencil")
                            }
                            Button(role: .destructive) { withAnimation { store.deleteExpense(expense); refreshCampaign() } } label: {
                                Label(NSLocalizedString("delete", comment: ""), systemImage: "trash")
                            }
                        }
                }
            }
        }.padding(.horizontal)
    }

    var reimbursementsSection: some View {
        let items = store.reimbursementsFor(campaign: campaign).sorted { $0.date > $1.date }
        return LazyVStack(spacing: 12) {
            if items.isEmpty {
                emptySection(icon: "arrow.uturn.left.circle", text: NSLocalizedString("no_reimbursements", comment: ""))
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { i, r in
                    ReimbursementCardView(reimbursement: r, currency: campaign.currency)
                        .animatedAppear(delay: Double(i) * 0.05)
                        .contextMenu {
                            Button(role: .destructive) { withAnimation { store.deleteReimbursement(r); refreshCampaign() } } label: {
                                Label(NSLocalizedString("delete", comment: ""), systemImage: "trash")
                            }
                        }
                }
            }
        }.padding(.horizontal)
    }

    func emptySection(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(.secondary.opacity(0.5))
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 40)
    }

    var floatingButton: some View {
        Group {
            if campaign.isClosed {
                EmptyView()
            } else if selectedTab == 0 {
                Button(action: { showingAddExpense = true }) {
                    Label(NSLocalizedString("add_expense", comment: ""), systemImage: "plus.circle.fill")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(AppTheme.expenseGradient).clipShape(Capsule())
                        .shadow(color: AppTheme.negative.opacity(0.3), radius: 8, y: 4)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: { showingAddReimbursement = true }) {
                    Label(NSLocalizedString("add_reimbursement", comment: ""), systemImage: "plus.circle.fill")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(AppTheme.reimbursementGradient).clipShape(Capsule())
                        .shadow(color: AppTheme.positive.opacity(0.3), radius: 8, y: 4)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: selectedTab)
        .padding(.bottom, 16)
    }
}

struct ExpenseCardView: View {
    @EnvironmentObject var store: CampaignStore
    let expense: Expense
    let currency: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.negative.opacity(0.12)).frame(width: 44, height: 44)
                if let cat = expense.categoryID.flatMap({ id in store.categories.first { $0.id == id } }) {
                    Image(systemName: cat.icon).foregroundColor(AppTheme.negative)
                } else {
                    Image(systemName: "cart").foregroundColor(AppTheme.negative)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title).font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 4) {
                    Text(NSLocalizedString("paid_by", comment: "")).foregroundColor(.secondary)
                    Text(store.participant(byID: expense.paidByID)?.name ?? "?").fontWeight(.medium)
                }.font(.caption)
                if !expense.location.isEmpty {
                    Label(expense.location, systemImage: "mappin").font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.2f %@", expense.amount, currency)).font(.subheadline).fontWeight(.bold).foregroundColor(AppTheme.negative)
                Text(expense.date.formatted(.dateTime.day().month(.abbreviated))).font(.caption2).foregroundColor(.secondary)
                HStack(spacing: 2) { Image(systemName: "person.2").font(.system(size: 9)); Text("\(expense.splitAmongIDs.count)") }.font(.caption2).foregroundColor(.secondary)
            }
        }.cardStyle()
    }
}

struct ReimbursementCardView: View {
    @EnvironmentObject var store: CampaignStore
    let reimbursement: Reimbursement
    let currency: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.positive.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "arrow.right").foregroundColor(AppTheme.positive).fontWeight(.bold)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(store.participant(byID: reimbursement.fromID)?.name ?? "?").fontWeight(.semibold)
                    Image(systemName: "arrow.right").font(.caption2).foregroundColor(.secondary)
                    Text(store.participant(byID: reimbursement.toID)?.name ?? "?").fontWeight(.semibold)
                }.font(.subheadline)
                HStack(spacing: 8) {
                    if let method = store.paymentMethods.first(where: { $0.id == reimbursement.paymentMethodID }) {
                        Label(method.name, systemImage: method.icon).font(.caption).foregroundColor(.secondary)
                    }
                    if reimbursement.isPartial {
                        GradientBadge(text: NSLocalizedString("partial_reimbursement", comment: ""), gradient: LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "%.2f %@", reimbursement.amount, currency)).font(.subheadline).fontWeight(.bold).foregroundColor(AppTheme.positive)
                Text(reimbursement.date.formatted(.dateTime.day().month(.abbreviated))).font(.caption2).foregroundColor(.secondary)
            }
        }.cardStyle()
    }
}
