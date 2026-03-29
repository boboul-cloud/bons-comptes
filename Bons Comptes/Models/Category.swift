//
//  Category.swift
//  Bons Comptes
//

import Foundation

struct ExpenseCategory: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "tag",
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isDefault = isDefault
    }

    static var defaults: [ExpenseCategory] {
        [
            ExpenseCategory(name: "🍽️ " + NSLocalizedString("category_food", comment: ""), icon: "fork.knife", isDefault: true),
            ExpenseCategory(name: "🚗 " + NSLocalizedString("category_transport", comment: ""), icon: "car", isDefault: true),
            ExpenseCategory(name: "🏨 " + NSLocalizedString("category_lodging", comment: ""), icon: "bed.double", isDefault: true),
            ExpenseCategory(name: "🛒 " + NSLocalizedString("category_groceries", comment: ""), icon: "cart", isDefault: true),
            ExpenseCategory(name: "🎉 " + NSLocalizedString("category_entertainment", comment: ""), icon: "party.popper", isDefault: true),
            ExpenseCategory(name: "💊 " + NSLocalizedString("category_health", comment: ""), icon: "cross.case", isDefault: true),
            ExpenseCategory(name: "🛍️ " + NSLocalizedString("category_shopping", comment: ""), icon: "bag", isDefault: true),
            ExpenseCategory(name: "📦 " + NSLocalizedString("category_other", comment: ""), icon: "shippingbox", isDefault: true),
        ]
    }
}
