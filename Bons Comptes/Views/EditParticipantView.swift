//
//  EditParticipantView.swift
//  Bons Comptes
//

import SwiftUI

struct EditParticipantView: View {
    @Environment(\.dismiss) var dismiss

    let participant: Participant
    let emojiOptions: [String]
    let onSave: (Participant) -> Void

    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var avatarEmoji: String

    init(participant: Participant, emojiOptions: [String], onSave: @escaping (Participant) -> Void) {
        self.participant = participant
        self.emojiOptions = emojiOptions
        self.onSave = onSave
        _name = State(initialValue: participant.name)
        _email = State(initialValue: participant.email)
        _phone = State(initialValue: participant.phone)
        _avatarEmoji = State(initialValue: participant.avatarEmoji)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar picker
                        VStack(spacing: 12) {
                            AvatarView(avatarEmoji, size: 72)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(emojiOptions, id: \.self) { emoji in
                                        Button(action: { avatarEmoji = emoji }) {
                                            Text(emoji)
                                                .font(.title2)
                                                .padding(8)
                                                .background(avatarEmoji == emoji ? AppTheme.primary.opacity(0.2) : Color.clear)
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .cardStyle()
                        .animatedAppear()

                        // Fields
                        VStack(alignment: .leading, spacing: 16) {
                            fieldRow(icon: "person.fill", placeholder: NSLocalizedString("participant_name", comment: ""), text: $name)
                            fieldRow(icon: "phone.fill", placeholder: NSLocalizedString("participant_phone", comment: ""), text: $phone, keyboard: .phonePad)
                            fieldRow(icon: "envelope.fill", placeholder: NSLocalizedString("email_optional", comment: ""), text: $email, keyboard: .emailAddress)
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.05)
                    }
                    .padding()
                }
            }
            .navigationTitle(NSLocalizedString("edit_participant", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("save", comment: "")) { save() }
                        .foregroundColor(AppTheme.primary)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    func fieldRow(icon: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary.opacity(0.6))
                .frame(width: 20)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func save() {
        var updated = participant
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.email = email.trimmingCharacters(in: .whitespaces)
        updated.phone = phone.trimmingCharacters(in: .whitespaces)
        updated.avatarEmoji = avatarEmoji
        onSave(updated)
        dismiss()
    }
}
