//
//  PremiumUpgradeView.swift
//  Bons Comptes
//

import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @ObservedObject private var premium = PremiumManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var isPurchasing = false
    @State private var showThankYou = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                            }

                            Text(NSLocalizedString("premium_title", comment: ""))
                                .font(.title).fontWeight(.bold)

                            Text(NSLocalizedString("premium_subtitle", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)

                        // Features list
                        VStack(spacing: 0) {
                            premiumFeature(icon: "infinity", color: AppTheme.primary, title: "premium_unlimited_campaigns", desc: "premium_unlimited_campaigns_desc")
                            Divider().padding(.leading, 56)
                            premiumFeature(icon: "doc.richtext", color: AppTheme.negative, title: "premium_pdf", desc: "premium_pdf_desc")
                            Divider().padding(.leading, 56)
                            premiumFeature(icon: "doc.text.viewfinder", color: AppTheme.warning, title: "premium_scanner", desc: "premium_scanner_desc")
                            Divider().padding(.leading, 56)
                            premiumFeature(icon: "qrcode", color: AppTheme.accent, title: "premium_sepa", desc: "premium_sepa_desc")
                            Divider().padding(.leading, 56)
                            premiumFeature(icon: "antenna.radiowaves.left.and.right", color: AppTheme.info, title: "premium_proximity", desc: "premium_proximity_desc")
                            Divider().padding(.leading, 56)
                            premiumFeature(icon: "clock.arrow.circlepath", color: AppTheme.primary, title: "premium_backups", desc: "premium_backups_desc")
                            Divider().padding(.leading, 56)
                            premiumFeature(icon: "bolt.circle.fill", color: AppTheme.warning, title: "premium_live_activity", desc: "premium_live_activity_desc")
                        }
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)

                        // Price + Buy button
                        VStack(spacing: 12) {
                            Button(action: {
                                isPurchasing = true
                                Task {
                                    await premium.purchase()
                                    isPurchasing = false
                                    if premium.isPremium { showThankYou = true }
                                }
                            }) {
                                HStack(spacing: 10) {
                                    if isPurchasing {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "crown.fill")
                                    }
                                    Text(premium.product?.displayPrice ?? "4,99 €")
                                        .fontWeight(.bold)
                                    Text("—")
                                    Text(NSLocalizedString("premium_buy_once", comment: ""))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .font(.headline)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .disabled(isPurchasing)

                            Button(action: {
                                Task { await premium.restore() }
                            }) {
                                Text(NSLocalizedString("premium_restore", comment: ""))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if let error = premium.purchaseError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.negative)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("close", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
            .fullScreenCover(isPresented: $showThankYou) {
                dismiss()
            } content: {
                PremiumThankYouView()
            }
        }
    }

    func premiumFeature(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(title, comment: ""))
                    .font(.subheadline).fontWeight(.semibold)
                Text(NSLocalizedString(desc, comment: ""))
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.positive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Premium gate modifier

struct PremiumGateModifier: ViewModifier {
    @ObservedObject private var premium = PremiumManager.shared
    @State private var showUpgrade = false

    func body(content: Content) -> some View {
        Button(action: {
            if premium.isPremium {
                // Handled by the wrapped content
            } else {
                showUpgrade = true
            }
        }) {
            content
        }
        .sheet(isPresented: $showUpgrade) {
            PremiumUpgradeView()
        }
        .disabled(premium.isPremium) // Disable this wrapper when premium (pass-through)
    }
}

/// A view that shows a lock badge over a feature button when not premium
struct PremiumBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 8))
            .foregroundColor(.white)
            .padding(3)
            .background(AppTheme.primary)
            .clipShape(Circle())
    }
}
