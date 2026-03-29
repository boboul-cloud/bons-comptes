//
//  Participant.swift
//  Bons Comptes
//

import Foundation

struct Participant: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var joinedAt: Date
    var isActive: Bool
    var avatarEmoji: String

    init(
        id: UUID = UUID(),
        name: String,
        email: String = "",
        phone: String = "",
        joinedAt: Date = Date(),
        isActive: Bool = true,
        avatarEmoji: String = "🧑"
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.joinedAt = joinedAt
        self.isActive = isActive
        self.avatarEmoji = avatarEmoji
    }
}
