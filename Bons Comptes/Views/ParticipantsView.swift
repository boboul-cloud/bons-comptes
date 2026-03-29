//
//  ParticipantsView.swift
//  Bons Comptes
//

import SwiftUI

struct ParticipantsView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss
    @Binding var campaign: Campaign

    @State private var showingAddParticipant = false
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var selectedEmoji = "🧑"

    let emojiOptions = ["🧑", "👩", "👨", "👧", "👦", "🧓", "👴", "👵", "🤴", "👸", "🦸", "🧙", "🎅", "🤠", "👻"]

    var participants: [Participant] {
        store.participantsFor(campaign: campaign)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            StatCard(
                                title: NSLocalizedString("participants_count", comment: ""),
                                value: "\(participants.count)",
                                icon: "person.2.fill",
                                color: AppTheme.primary
                            )
                            StatCard(
                                title: NSLocalizedString("total_expenses_label", comment: ""),
                                value: String(format: "%.0f%@", store.totalExpenses(for: campaign), campaign.currency),
                                icon: "banknote.fill",
                                color: AppTheme.negative
                            )
                        }
                        .padding(.horizontal)
                        .animatedAppear()

                        LazyVStack(spacing: 12) {
                            ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                                let balance = store.balanceFor(participant: participant, in: campaign)
                                let displayBalance = -balance

                                HStack(spacing: 14) {
                                    AvatarView(participant.avatarEmoji, size: 48)

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(participant.name)
                                                .font(.subheadline).fontWeight(.semibold)
                                            if participant.name == campaign.creatorName {
                                                Image(systemName: "crown.fill")
                                                    .foregroundColor(AppTheme.warning)
                                                    .font(.caption2)
                                            }
                                        }
                                        if !participant.email.isEmpty {
                                            Label(participant.email, systemImage: "envelope")
                                                .font(.caption2).foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(String(format: "%+.2f %@", displayBalance, campaign.currency))
                                            .font(.subheadline).fontWeight(.bold)
                                            .foregroundColor(displayBalance <= 0 ? AppTheme.positive : AppTheme.negative)

                                        Text(displayBalance > 0
                                             ? NSLocalizedString("owes", comment: "")
                                             : displayBalance < 0
                                             ? NSLocalizedString("is_owed", comment: "")
                                             : NSLocalizedString("settled", comment: ""))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .cardStyle()
                                .animatedAppear(delay: Double(index) * 0.05)
                                .contextMenu {
                                    if abs(balance) < 0.01 && participant.name != campaign.creatorName {
                                        Button(role: .destructive) {
                                            withAnimation { store.removeParticipant(participant, from: &campaign) }
                                        } label: {
                                            Label(NSLocalizedString("delete", comment: ""), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }

                VStack {
                    Spacer()
                    Button(action: { showingAddParticipant = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus.fill")
                            Text(NSLocalizedString("add_participant", comment: ""))
                        }
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(AppTheme.headerGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal).padding(.bottom, 8)
                }
            }
            .navigationTitle(NSLocalizedString("manage_participants", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
            .alert(NSLocalizedString("add_participant", comment: ""), isPresented: $showingAddParticipant) {
                TextField(NSLocalizedString("participant_name", comment: ""), text: $newName)
                TextField(NSLocalizedString("email_optional", comment: ""), text: $newEmail)
                Button(NSLocalizedString("add", comment: "")) { addParticipant() }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { newName = ""; newEmail = "" }
            } message: {
                Text(NSLocalizedString("add_participant_desc", comment: ""))
            }
        }
    }

    func addParticipant() {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let participant = Participant(
            name: newName,
            email: newEmail,
            avatarEmoji: emojiOptions.randomElement() ?? "🧑"
        )
        store.addParticipant(participant, to: &campaign)
        newName = ""
        newEmail = ""
    }
}
