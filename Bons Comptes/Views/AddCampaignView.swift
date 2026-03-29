//
//  AddCampaignView.swift
//  Bons Comptes
//

import SwiftUI

struct AddCampaignView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var currency = "EUR"
    @State private var creatorName = ""
    @State private var creatorPhone = ""
    @State private var participantNames: [String] = [""]
    @State private var currentStep = 0

    let currencies = ["EUR", "USD", "GBP", "CHF", "CAD", "JPY", "AUD"]

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !creatorName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                scrollContent
                createButton
            }
            .navigationTitle(NSLocalizedString("new_campaign", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { cancelToolbar }
        }
    }

    @ToolbarContentBuilder
    var cancelToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                .foregroundColor(AppTheme.primary)
        }
    }

    var scrollContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                stepIndicator
                campaignInfoSection
                creatorSection
                participantsSection
            }
            .padding()
            .padding(.bottom, 80)
        }
    }

    var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? AppTheme.primary : AppTheme.primary.opacity(0.2))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .animatedAppear()
    }

    var campaignInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "doc.text.fill", title: NSLocalizedString("campaign_info", comment: ""), color: AppTheme.primary)

            VStack(spacing: 12) {
                modernTextField(icon: "textformat", placeholder: NSLocalizedString("title_field", comment: ""), text: $title)
                    .onChange(of: title) { _, _ in updateStep() }
                modernTextField(icon: "text.alignleft", placeholder: NSLocalizedString("description_field", comment: ""), text: $description)
                modernTextField(icon: "mappin.and.ellipse", placeholder: NSLocalizedString("location_field", comment: ""), text: $location)

                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(AppTheme.warning)
                        .frame(width: 20)
                    Picker(NSLocalizedString("currency_field", comment: ""), selection: $currency) {
                        ForEach(currencies, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.primary)
                    Spacer()
                }
                .padding(14)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
        .animatedAppear(delay: 0.05)
    }

    var creatorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "crown.fill", title: NSLocalizedString("creator", comment: ""), color: AppTheme.warning)
            modernTextField(icon: "person.fill", placeholder: NSLocalizedString("your_name", comment: ""), text: $creatorName)
                .onChange(of: creatorName) { _, _ in updateStep() }
            HStack(spacing: 12) {
                Image(systemName: "phone.fill").foregroundColor(AppTheme.primary.opacity(0.6)).frame(width: 20)
                TextField(NSLocalizedString("your_phone", comment: ""), text: $creatorPhone)
                    .keyboardType(.phonePad)
            }
            .padding(14)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(NSLocalizedString("phone_hint", comment: ""))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .cardStyle()
        .animatedAppear(delay: 0.1)
    }

    var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "person.3.fill", title: NSLocalizedString("initial_participants", comment: ""), color: AppTheme.accent)

            ForEach(participantNames.indices, id: \.self) { index in
                HStack(spacing: 10) {
                    AvatarView(["🧑","👩","👨","🧓","👧","👦"][index % 6], size: 36)
                    TextField(NSLocalizedString("participant_name", comment: ""), text: $participantNames[index])
                        .padding(10)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    if participantNames.count > 1 {
                        Button(action: { withAnimation(.spring()) { _ = participantNames.remove(at: index) } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(AppTheme.negative)
                                .font(.title3)
                        }
                    }
                }
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }

            Button(action: { withAnimation(.spring()) { participantNames.append("") } }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(NSLocalizedString("add_participant", comment: ""))
                }
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(AppTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(AppTheme.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
        .animatedAppear(delay: 0.15)
    }

    var createButton: some View {
        VStack {
            Spacer()
            Button(action: createCampaign) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(NSLocalizedString("create", comment: ""))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canSave ? AppTheme.headerGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: canSave ? AppTheme.primary.opacity(0.3) : .clear, radius: 10, y: 5)
            }
            .disabled(!canSave)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    func updateStep() {
        withAnimation(.spring()) {
            if !title.isEmpty && !creatorName.isEmpty { currentStep = 2 }
            else if !title.isEmpty { currentStep = 1 }
            else { currentStep = 0 }
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

    func createCampaign() {
        let creator = Participant(name: creatorName)
        store.participants.append(creator)

        var allParticipantIDs = [creator.id]

        for name in participantNames where !name.trimmingCharacters(in: .whitespaces).isEmpty {
            let p = Participant(name: name)
            store.participants.append(p)
            allParticipantIDs.append(p.id)
        }

        let campaign = Campaign(
            title: title,
            description: description,
            location: location,
            currency: currency,
            creatorName: creatorName,
            participantIDs: allParticipantIDs,
            managerPhone: creatorPhone.trimmingCharacters(in: .whitespaces)
        )
        store.addCampaign(campaign)
        dismiss()
    }
}
