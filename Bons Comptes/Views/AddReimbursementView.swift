//
//  AddReimbursementView.swift
//  Bons Comptes
//

import SwiftUI

struct AddReimbursementView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss

    let campaign: Campaign

    @State private var amount = ""
    @State private var date = Date()
    @State private var fromID: UUID?
    @State private var toID: UUID?
    @State private var paymentMethodID: UUID?
    @State private var notes = ""
    @State private var isPartial = false
    @State private var showingNewPaymentMethod = false
    @State private var newPaymentMethodName = ""

    var participants: [Participant] {
        store.participantsFor(campaign: campaign)
    }

    var debtAmount: Double {
        guard let from = fromID, let to = toID, from != to else { return 0 }
        let settlements = store.computeSettlements(for: campaign)
        if let s = settlements.first(where: { $0.from.id == from && $0.to.id == to }) {
            return s.amount
        }
        return 0
    }

    var canSave: Bool {
        let val = Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
        return val > 0 && fromID != nil && toID != nil && fromID != toID
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        amountHeader.animatedAppear()

                        // Participants selection
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(icon: "arrow.right.circle.fill", title: NSLocalizedString("from_participant", comment: ""), color: AppTheme.negative)
                            participantPicker(selectedID: $fromID, highlight: AppTheme.negative)

                            HStack {
                                Spacer()
                                ZStack {
                                    Circle().fill(AppTheme.positive.opacity(0.15)).frame(width: 40, height: 40)
                                    Image(systemName: "arrow.down").font(.title3).fontWeight(.bold).foregroundColor(AppTheme.positive)
                                }
                                Spacer()
                            }

                            sectionHeader(icon: "arrow.left.circle.fill", title: NSLocalizedString("to_participant", comment: ""), color: AppTheme.positive)
                            participantPicker(selectedID: $toID, highlight: AppTheme.positive)
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.05)

                        if debtAmount > 0 {
                            HStack {
                                Image(systemName: "info.circle.fill").foregroundColor(AppTheme.negative)
                                Text(NSLocalizedString("total_debt", comment: ""))
                                    .font(.subheadline).foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f %@", debtAmount, campaign.currency))
                                    .font(.headline).fontWeight(.bold).foregroundColor(AppTheme.negative)
                            }
                            .cardStyle()
                            .animatedAppear(delay: 0.1)
                        }

                        // Options
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(icon: "gearshape.fill", title: NSLocalizedString("reimbursement_details", comment: ""), color: AppTheme.info)

                            Toggle(isOn: $isPartial) {
                                HStack(spacing: 8) {
                                    Image(systemName: "divide.circle").foregroundColor(AppTheme.warning)
                                    Text(NSLocalizedString("partial_reimbursement", comment: "")).font(.subheadline)
                                }
                            }
                            .tint(AppTheme.primary)
                            .onChange(of: isPartial) { _, partial in
                                if !partial { amount = debtAmount > 0 ? String(format: "%.2f", debtAmount) : "" }
                            }

                            DatePicker(NSLocalizedString("date_field", comment: ""), selection: $date, displayedComponents: .date)
                                .tint(AppTheme.primary)
                                .padding(14).background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            modernTextField(icon: "note.text", placeholder: NSLocalizedString("notes_field", comment: ""), text: $notes)
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.15)

                        // Payment method
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "creditcard.fill", title: NSLocalizedString("payment_method_section", comment: ""), color: AppTheme.accent)
                            paymentMethodGrid
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.2)

                        // Suggested settlements
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "lightbulb.fill", title: NSLocalizedString("suggested_settlements", comment: ""), color: AppTheme.warning)
                            let settlements = store.computeSettlements(for: campaign)
                            if settlements.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.positive)
                                    Text(NSLocalizedString("all_settled", comment: ""))
                                        .foregroundColor(AppTheme.positive).fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity).padding()
                            } else {
                                ForEach(settlements) { s in
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            fromID = s.from.id
                                            toID = s.to.id
                                            amount = String(format: "%.2f", s.amount)
                                        }
                                    }) {
                                        HStack {
                                            AvatarView(s.from.avatarEmoji, size: 30)
                                            Image(systemName: "arrow.right").font(.caption).foregroundColor(.secondary)
                                            AvatarView(s.to.avatarEmoji, size: 30)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(s.from.name) \u{2192} \(s.to.name)").font(.caption).foregroundColor(.primary)
                                            }
                                            Spacer()
                                            Text(String(format: "%.2f %@", s.amount, campaign.currency))
                                                .font(.subheadline).fontWeight(.bold).foregroundColor(AppTheme.negative)
                                        }
                                        .padding(10)
                                        .background(AppTheme.negative.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.25)
                    }
                    .padding()
                    .padding(.bottom, 80)
                }

                VStack {
                    Spacer()
                    Button(action: saveReimbursement) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(NSLocalizedString("save", comment: ""))
                        }
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(canSave ? AppTheme.reimbursementGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: canSave ? AppTheme.positive.opacity(0.3) : .clear, radius: 10, y: 5)
                    }
                    .disabled(!canSave)
                    .padding(.horizontal).padding(.bottom, 8)
                }
            }
            .navigationTitle(NSLocalizedString("add_reimbursement", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
            .alert(NSLocalizedString("new_payment_method", comment: ""), isPresented: $showingNewPaymentMethod) {
                TextField(NSLocalizedString("method_name", comment: ""), text: $newPaymentMethodName)
                Button(NSLocalizedString("add", comment: "")) {
                    if !newPaymentMethodName.trimmingCharacters(in: .whitespaces).isEmpty {
                        let method = PaymentMethod(name: newPaymentMethodName)
                        store.addPaymentMethod(method)
                        paymentMethodID = method.id
                        newPaymentMethodName = ""
                    }
                }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
            }
        }
    }

    var amountHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.reimbursementGradient)
                .frame(height: 120)
            VStack(spacing: 8) {
                Text(NSLocalizedString("amount_field", comment: ""))
                    .font(.caption).foregroundColor(.white.opacity(0.8))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 200)
                        .disabled(!isPartial && debtAmount > 0)
                    Text(campaign.currency)
                        .font(.title2).fontWeight(.semibold).foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal)
    }

    func participantPicker(selectedID: Binding<UUID?>, highlight: Color) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(participants) { p in
                let isSelected = selectedID.wrappedValue == p.id
                Button(action: {
                    withAnimation(.spring()) {
                        selectedID.wrappedValue = p.id
                        updateAmount()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(p.avatarEmoji).font(.caption)
                        Text(p.name).font(.caption).fontWeight(.medium)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .foregroundColor(isSelected ? .white : .primary)
                    .background(isSelected ? highlight : highlight.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
    }

    var paymentMethodGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 80))]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(store.paymentMethods) { method in
                Button(action: {
                    withAnimation(.spring()) {
                        paymentMethodID = paymentMethodID == method.id ? nil : method.id
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: method.icon)
                            .font(.title3)
                            .foregroundColor(paymentMethodID == method.id ? .white : AppTheme.accent)
                        Text(method.name)
                            .font(.caption2).foregroundColor(paymentMethodID == method.id ? .white : .secondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(paymentMethodID == method.id ? AppTheme.accent : AppTheme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            Button(action: { showingNewPaymentMethod = true }) {
                VStack(spacing: 6) {
                    Image(systemName: "plus").font(.title3).foregroundColor(AppTheme.primary)
                    Text("+").font(.caption2).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(AppTheme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.headline).fontWeight(.bold)
        }
    }

    func modernTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(AppTheme.primary.opacity(0.6)).frame(width: 20)
            TextField(placeholder, text: text)
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func updateAmount() {
        if !isPartial && debtAmount > 0 {
            amount = String(format: "%.2f", debtAmount)
        }
    }

    func saveReimbursement() {
        guard let from = fromID,
              let to = toID,
              let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else { return }

        let reimbursement = Reimbursement(
            amount: amountValue,
            date: date,
            fromID: from,
            toID: to,
            paymentMethodID: paymentMethodID,
            notes: notes,
            campaignID: campaign.id,
            isPartial: isPartial
        )
        store.addReimbursement(reimbursement)
        dismiss()
    }
}
