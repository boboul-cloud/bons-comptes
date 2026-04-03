//
//  AddExpenseView.swift
//  Bons Comptes
//

import SwiftUI

struct AddExpenseView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss

    let campaign: Campaign

    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var paidByID: UUID?
    @State private var selectedParticipantIDs: Set<UUID> = []
    @State private var splitType: SplitType = .equal
    @State private var customSplits: [UUID: String] = [:]
    @State private var selectedCategoryID: UUID?
    @State private var location = ""
    @State private var notes = ""
    @State private var showingNewCategory = false
    @State private var newCategoryName = ""

    var participants: [Participant] {
        store.participantsFor(campaign: campaign)
    }

    var parsedAmount: Double {
        Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var splitTotal: Double {
        selectedParticipantIDs.reduce(0) { sum, id in
            sum + (Double((customSplits[id] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0)
        }
    }

    var splitTarget: Double {
        splitType == .percentage ? 100 : parsedAmount
    }

    var splitRemaining: Double {
        splitTarget - splitTotal
    }

    var isSplitValid: Bool {
        if splitType == .equal { return true }
        return abs(splitRemaining) < 0.01
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        parsedAmount > 0 &&
        paidByID != nil &&
        !selectedParticipantIDs.isEmpty &&
        isSplitValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Amount hero
                        amountHeader.animatedAppear()

                        // Details
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(icon: "doc.text.fill", title: NSLocalizedString("expense_details", comment: ""), color: AppTheme.negative)
                            modernTextField(icon: "textformat", placeholder: NSLocalizedString("title_field", comment: ""), text: $title)
                            DatePicker(NSLocalizedString("date_field", comment: ""), selection: $date, displayedComponents: .date)
                                .tint(AppTheme.primary)
                                .padding(14)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            modernTextField(icon: "mappin", placeholder: NSLocalizedString("location_field", comment: ""), text: $location)
                            modernTextField(icon: "note.text", placeholder: NSLocalizedString("notes_field", comment: ""), text: $notes)
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.05)

                        // Category
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "tag.fill", title: NSLocalizedString("category_section", comment: ""), color: AppTheme.info)
                            categoryGrid
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.1)

                        // Paid by
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "person.fill.checkmark", title: NSLocalizedString("paid_by_section", comment: ""), color: AppTheme.primary)
                            participantSelector(selected: Binding(
                                get: { paidByID.map { Set([$0]) } ?? [] },
                                set: { paidByID = $0.first }
                            ), single: true)
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.15)

                        // Split among
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                sectionHeader(icon: "person.3.fill", title: NSLocalizedString("split_among", comment: ""), color: AppTheme.accent)
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring()) {
                                        if selectedParticipantIDs.count == participants.count {
                                            selectedParticipantIDs.removeAll()
                                        } else {
                                            selectedParticipantIDs = Set(participants.map { $0.id })
                                        }
                                    }
                                }) {
                                    Text(selectedParticipantIDs.count == participants.count
                                         ? NSLocalizedString("deselect_all", comment: "")
                                         : NSLocalizedString("select_all", comment: ""))
                                        .font(.caption).fontWeight(.semibold)
                                        .foregroundColor(AppTheme.accent)
                                }
                            }
                            participantSelector(selected: $selectedParticipantIDs, single: false)

                            Picker(NSLocalizedString("split_method", comment: ""), selection: $splitType) {
                                ForEach(SplitType.allCases, id: \.self) { type in
                                    Text(NSLocalizedString(type.displayKey, comment: "")).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

                            if splitType != .equal {
                                ForEach(participants.filter { selectedParticipantIDs.contains($0.id) }) { p in
                                    HStack {
                                        AvatarView(p.avatarEmoji, size: 28)
                                        Text(p.name).font(.subheadline)
                                        Spacer()
                                        TextField(splitType == .percentage ? "%" : campaign.currency,
                                                  text: Binding(
                                                    get: { customSplits[p.id] ?? "" },
                                                    set: { customSplits[p.id] = $0 }
                                                  ))
                                            .keyboardType(.decimalPad)
                                            .frame(width: 80)
                                            .multilineTextAlignment(.trailing)
                                            .padding(8)
                                            .background(AppTheme.cardBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }

                                // Split total indicator
                                splitTotalIndicator
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.2)
                    }
                    .padding()
                    .padding(.bottom, 80)
                }

                VStack {
                    Spacer()
                    Button(action: saveExpense) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(NSLocalizedString("save", comment: ""))
                        }
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(canSave ? AppTheme.expenseGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: canSave ? AppTheme.negative.opacity(0.3) : .clear, radius: 10, y: 5)
                    }
                    .disabled(!canSave)
                    .padding(.horizontal).padding(.bottom, 8)
                }
            }
            .navigationTitle(NSLocalizedString("add_expense", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
            .onAppear {
                selectedParticipantIDs = Set(campaign.participantIDs)
                paidByID = participants.first?.id
            }
            .alert(NSLocalizedString("new_category", comment: ""), isPresented: $showingNewCategory) {
                TextField(NSLocalizedString("category_name", comment: ""), text: $newCategoryName)
                Button(NSLocalizedString("add", comment: "")) {
                    if !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                        let cat = ExpenseCategory(name: newCategoryName)
                        store.addCategory(cat)
                        selectedCategoryID = cat.id
                        newCategoryName = ""
                    }
                }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
            }
        }
    }

    var amountHeader: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.expenseGradient)
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
                    Text(campaign.currency)
                        .font(.title2).fontWeight(.semibold).foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal)
    }

    var categoryGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 70))]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(store.categories) { cat in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedCategoryID = selectedCategoryID == cat.id ? nil : cat.id
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: cat.icon)
                            .font(.title3)
                            .foregroundColor(selectedCategoryID == cat.id ? .white : AppTheme.primary)
                        Text(cat.name)
                            .font(.caption2)
                            .foregroundColor(selectedCategoryID == cat.id ? .white : .secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(selectedCategoryID == cat.id ? AppTheme.primary : AppTheme.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            Button(action: { showingNewCategory = true }) {
                VStack(spacing: 6) {
                    Image(systemName: "plus").font(.title3).foregroundColor(AppTheme.accent)
                    Text(NSLocalizedString("new_category", comment: ""))
                        .font(.caption2).foregroundColor(.secondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(AppTheme.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    func participantSelector(selected: Binding<Set<UUID>>, single: Bool) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(participants) { p in
                let isSelected = selected.wrappedValue.contains(p.id)
                Button(action: {
                    withAnimation(.spring()) {
                        if single {
                            selected.wrappedValue = [p.id]
                        } else {
                            if isSelected { selected.wrappedValue.remove(p.id) }
                            else { selected.wrappedValue.insert(p.id) }
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(p.avatarEmoji).font(.caption)
                        Text(p.name).font(.caption).fontWeight(.medium)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .foregroundColor(isSelected ? .white : .primary)
                    .background(isSelected ? AppTheme.primary : AppTheme.primary.opacity(0.08))
                    .clipShape(Capsule())
                }
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

    var splitTotalIndicator: some View {
        let unit = splitType == .percentage ? "%" : campaign.currency
        let isValid = abs(splitRemaining) < 0.01
        let color: Color = isValid ? AppTheme.positive : (splitRemaining < 0 ? AppTheme.negative : AppTheme.warning)

        return VStack(spacing: 8) {
            HStack {
                Text(NSLocalizedString("split_total", comment: ""))
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(String(format: "%.2f / %.2f %@", splitTotal, splitTarget, unit))
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundColor(color)
            }

            if !isValid {
                HStack {
                    Image(systemName: splitRemaining > 0 ? "exclamationmark.triangle.fill" : "xmark.circle.fill")
                        .foregroundColor(color)
                    Text(String(format: NSLocalizedString(splitRemaining > 0 ? "split_remaining" : "split_exceeded", comment: ""), abs(splitRemaining), unit))
                        .font(.caption).foregroundColor(color)
                    Spacer()
                    if splitRemaining > 0.01 {
                        Button(action: autoFillLastParticipant) {
                            Text(NSLocalizedString("split_auto_fill", comment: ""))
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(AppTheme.positive)
                    Text(NSLocalizedString("split_valid", comment: ""))
                        .font(.caption).foregroundColor(AppTheme.positive)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    func autoFillLastParticipant() {
        let selected = participants.filter { selectedParticipantIDs.contains($0.id) }
        // Find the last participant without a value (or the last one overall)
        let emptyParticipant = selected.last { p in
            let val = Double((customSplits[p.id] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0
            return val == 0
        } ?? selected.last
        guard let target = emptyParticipant else { return }
        let remaining = splitRemaining
        guard remaining > 0.01 else { return }
        customSplits[target.id] = String(format: "%.2f", remaining)
    }

    func saveExpense() {
        guard let paidBy = paidByID else { return }
        let amountValue = parsedAmount
        guard amountValue > 0 else { return }

        var splits: [UUID: Double] = [:]
        if splitType != .equal {
            for (id, val) in customSplits {
                splits[id] = Double(val.replacingOccurrences(of: ",", with: ".")) ?? 0
            }
        }

        let expense = Expense(
            title: title,
            amount: amountValue,
            date: date,
            paidByID: paidBy,
            splitAmongIDs: Array(selectedParticipantIDs),
            splitType: splitType,
            customSplits: splits,
            categoryID: selectedCategoryID,
            location: location,
            notes: notes,
            campaignID: campaign.id
        )
        store.addExpense(expense)
        dismiss()
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .init(frame.size))
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
