//
//  SettingsView.swift
//  Bons Comptes
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var store: CampaignStore
    @ObservedObject private var premium = PremiumManager.shared
    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "fr"
    @State private var showingNewCategory = false
    @State private var showingNewPaymentMethod = false
    @State private var newCategoryName = ""
    @State private var newPaymentMethodName = ""
    @State private var showPremiumUpgrade = false
    @State private var showPremiumThankYou = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Language
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "globe", title: NSLocalizedString("language_section", comment: ""), color: AppTheme.info)
                            HStack(spacing: 12) {
                                languageOption(flag: "\u{1F1EB}\u{1F1F7}", name: "Fran\u{00E7}ais", code: "fr")
                                languageOption(flag: "\u{1F1EC}\u{1F1E7}", name: "English", code: "en")
                            }
                            Text(NSLocalizedString("language_restart_hint", comment: ""))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        .cardStyle()
                        .animatedAppear()

                        // Categories
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                sectionHeader(icon: "tag.fill", title: NSLocalizedString("categories_section", comment: ""), color: AppTheme.primary)
                                Spacer()
                                Button(action: { showingNewCategory = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(AppTheme.primary)
                                }
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                                ForEach(store.categories) { cat in
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle().fill(AppTheme.primary.opacity(0.1)).frame(width: 44, height: 44)
                                            Image(systemName: cat.icon).foregroundColor(AppTheme.primary)
                                        }
                                        Text(cat.name).font(.caption2).foregroundColor(.primary).lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background(AppTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .contextMenu {
                                        if !cat.isDefault {
                                            Button(role: .destructive) {
                                                withAnimation { store.deleteCategory(cat) }
                                            } label: {
                                                Label(NSLocalizedString("delete", comment: ""), systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.05)

                        // Payment Methods
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                sectionHeader(icon: "creditcard.fill", title: NSLocalizedString("payment_methods_section", comment: ""), color: AppTheme.accent)
                                Spacer()
                                Button(action: { showingNewPaymentMethod = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(AppTheme.accent)
                                }
                            }

                            ForEach(store.paymentMethods) { method in
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle().fill(AppTheme.accent.opacity(0.12)).frame(width: 40, height: 40)
                                        Image(systemName: method.icon).foregroundColor(AppTheme.accent)
                                    }
                                    Text(method.name).font(.subheadline)
                                    Spacer()
                                    if method.isDefault {
                                        GradientBadge(
                                            text: NSLocalizedString("default_label", comment: ""),
                                            gradient: AppTheme.reimbursementGradient
                                        )
                                    }
                                }
                                .padding(10)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .contextMenu {
                                    if !method.isDefault {
                                        Button(role: .destructive) {
                                            withAnimation { store.deletePaymentMethod(method) }
                                        } label: {
                                            Label(NSLocalizedString("delete", comment: ""), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.1)

                        // Premium
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "crown.fill", title: "Premium", color: AppTheme.warning)

                            if premium.isPremium {
                                Button(action: { showPremiumThankYou = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title2)
                                            .foregroundStyle(
                                                LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(NSLocalizedString("premium_active", comment: ""))
                                                .font(.subheadline).fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text(NSLocalizedString("premium_see_benefits", comment: ""))
                                                .font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.positive.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            } else {
                                Button(action: { showPremiumUpgrade = true }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "crown.fill")
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(NSLocalizedString("premium_unlock", comment: ""))
                                                .font(.subheadline).fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text(NSLocalizedString("premium_unlock_desc", comment: ""))
                                                .font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(premium.product?.displayPrice ?? "4,99 €")
                                            .font(.subheadline).fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(AppTheme.headerGradient)
                                            .clipShape(Capsule())
                                    }
                                    .padding(12)
                                    .background(AppTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                Button(action: {
                                    Task { await premium.restore() }
                                }) {
                                    Text(NSLocalizedString("premium_restore", comment: ""))
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.12)

                        // About & Legal
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "info.circle.fill", title: NSLocalizedString("about_section", comment: ""), color: AppTheme.warning)

                            HStack {
                                Text(NSLocalizedString("version_label", comment: "")).font(.subheadline)
                                Spacer()
                                Text("1.0.0").font(.subheadline).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack {
                                Text(NSLocalizedString("developer_label", comment: "")).font(.subheadline)
                                Spacer()
                                Text("Robert Oulhen").font(.subheadline).foregroundColor(.secondary)
                            }
                            Divider()

                            NavigationLink(destination: UserGuideView()) {
                                legalRow(icon: "book.fill", title: NSLocalizedString("user_guide", comment: ""), color: AppTheme.accent)
                            }
                            NavigationLink(destination: AboutView()) {
                                legalRow(icon: "info.circle", title: NSLocalizedString("about_section", comment: ""), color: AppTheme.info)
                            }
                            NavigationLink(destination: PrivacyPolicyView()) {
                                legalRow(icon: "hand.raised.fill", title: NSLocalizedString("privacy_policy", comment: ""), color: AppTheme.positive)
                            }
                            NavigationLink(destination: TermsOfUseView()) {
                                legalRow(icon: "doc.text.fill", title: NSLocalizedString("terms_of_use", comment: ""), color: AppTheme.primary)
                            }
                            NavigationLink(destination: LegalNoticesView()) {
                                legalRow(icon: "building.columns.fill", title: NSLocalizedString("legal_notices", comment: ""), color: AppTheme.warning)
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.15)
                    }
                    .padding()
                }
            }
            .navigationTitle(NSLocalizedString("settings", comment: ""))
            .alert(NSLocalizedString("new_category", comment: ""), isPresented: $showingNewCategory) {
                TextField(NSLocalizedString("category_name", comment: ""), text: $newCategoryName)
                Button(NSLocalizedString("add", comment: "")) {
                    if !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                        store.addCategory(ExpenseCategory(name: newCategoryName))
                        newCategoryName = ""
                    }
                }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
            }
            .alert(NSLocalizedString("new_payment_method", comment: ""), isPresented: $showingNewPaymentMethod) {
                TextField(NSLocalizedString("method_name", comment: ""), text: $newPaymentMethodName)
                Button(NSLocalizedString("add", comment: "")) {
                    if !newPaymentMethodName.trimmingCharacters(in: .whitespaces).isEmpty {
                        store.addPaymentMethod(PaymentMethod(name: newPaymentMethodName))
                        newPaymentMethodName = ""
                    }
                }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
            }
            .sheet(isPresented: $showPremiumUpgrade) {
                PremiumUpgradeView()
            }
            .fullScreenCover(isPresented: $showPremiumThankYou) {
                PremiumThankYouView()
            }
        }
    }

    func languageOption(flag: String, name: String, code: String) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                appLanguage = code
                UserDefaults.standard.set([code], forKey: "AppleLanguages")
                UserDefaults.standard.synchronize()
            }
        }) {
            HStack(spacing: 8) {
                Text(flag).font(.title2)
                Text(name).font(.subheadline).fontWeight(.medium)
            }
            .frame(maxWidth: .infinity).padding(12)
            .foregroundColor(appLanguage == code ? .white : .primary)
            .background(appLanguage == code ? AppTheme.primary : AppTheme.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.headline).fontWeight(.bold)
        }
    }

    func legalRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.caption).foregroundColor(color)
            }
            Text(title).font(.subheadline).foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
        }
        .padding(8)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
