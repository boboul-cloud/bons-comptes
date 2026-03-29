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

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, joinedAt, isActive, avatarEmoji
    }

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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        phone = try c.decodeIfPresent(String.self, forKey: .phone) ?? ""
        joinedAt = try c.decode(Date.self, forKey: .joinedAt)
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        avatarEmoji = try c.decodeIfPresent(String.self, forKey: .avatarEmoji) ?? "🧑"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        if !email.isEmpty { try c.encode(email, forKey: .email) }
        if !phone.isEmpty { try c.encode(phone, forKey: .phone) }
        try c.encode(joinedAt, forKey: .joinedAt)
        if !isActive { try c.encode(isActive, forKey: .isActive) }
        try c.encode(avatarEmoji, forKey: .avatarEmoji)
    }
}
