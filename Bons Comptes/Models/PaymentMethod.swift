//
//  PaymentMethod.swift
//  Bons Comptes
//

import Foundation

struct PaymentMethod: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "banknote",
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isDefault = isDefault
    }

    static var defaults: [PaymentMethod] {
        [
            PaymentMethod(name: NSLocalizedString("payment_cash", comment: ""), icon: "banknote", isDefault: true),
            PaymentMethod(name: NSLocalizedString("payment_card", comment: ""), icon: "creditcard", isDefault: true),
            PaymentMethod(name: NSLocalizedString("payment_check", comment: ""), icon: "doc.text", isDefault: true),
            PaymentMethod(name: NSLocalizedString("payment_transfer", comment: ""), icon: "arrow.left.arrow.right", isDefault: true),
            PaymentMethod(name: NSLocalizedString("payment_other", comment: ""), icon: "ellipsis.circle", isDefault: true),
        ]
    }
}
