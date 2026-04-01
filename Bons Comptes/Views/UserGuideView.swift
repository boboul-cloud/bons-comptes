//
//  UserGuideView.swift
//  Bons Comptes
//

import SwiftUI

struct UserGuideView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                    gettingStartedSection
                    expensesSection
                    balancesSection
                    sharingSection
                    advancedSection
                    tipsSection
                }
                .padding()
            }
        }
        .navigationTitle(NSLocalizedString("user_guide", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(colors: [.white, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text(NSLocalizedString("guide_welcome_title", comment: ""))
                .font(.title2).fontWeight(.bold)
            Text(NSLocalizedString("guide_welcome_desc", comment: ""))
                .font(.subheadline).multilineTextAlignment(.center).opacity(0.9)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppTheme.headerGradient)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animatedAppear()
    }

    // MARK: - Getting Started

    private var gettingStartedSection: some View {
        guideSection(
            icon: "1.circle.fill",
            title: NSLocalizedString("guide_start_title", comment: ""),
            color: AppTheme.primary,
            delay: 0.05
        ) {
            guideStep(emoji: "📝", text: NSLocalizedString("guide_start_step1", comment: ""))
            guideStep(emoji: "👥", text: NSLocalizedString("guide_start_step2", comment: ""))
            guideStep(emoji: "💶", text: NSLocalizedString("guide_start_step3", comment: ""))
        }
    }

    // MARK: - Expenses

    private var expensesSection: some View {
        guideSection(
            icon: "2.circle.fill",
            title: NSLocalizedString("guide_expenses_title", comment: ""),
            color: AppTheme.negative,
            delay: 0.1
        ) {
            guideStep(emoji: "➕", text: NSLocalizedString("guide_expenses_step1", comment: ""))
            guideStep(emoji: "⚖️", text: NSLocalizedString("guide_expenses_step2", comment: ""))
            guideStep(emoji: "🏷️", text: NSLocalizedString("guide_expenses_step3", comment: ""))
            guideStep(emoji: "🧾", text: NSLocalizedString("guide_expenses_step4", comment: ""))
        }
    }

    // MARK: - Balances

    private var balancesSection: some View {
        guideSection(
            icon: "3.circle.fill",
            title: NSLocalizedString("guide_balances_title", comment: ""),
            color: AppTheme.positive,
            delay: 0.15
        ) {
            guideStep(emoji: "📊", text: NSLocalizedString("guide_balances_step1", comment: ""))
            guideStep(emoji: "💳", text: NSLocalizedString("guide_balances_step2", comment: ""))
            guideStep(emoji: "📱", text: NSLocalizedString("guide_balances_step3", comment: ""))
        }
    }

    // MARK: - Sharing

    private var sharingSection: some View {
        guideSection(
            icon: "4.circle.fill",
            title: NSLocalizedString("guide_sharing_title", comment: ""),
            color: AppTheme.info,
            delay: 0.2
        ) {
            guideStep(emoji: "🔗", text: NSLocalizedString("guide_sharing_step1", comment: ""))
            guideStep(emoji: "💬", text: NSLocalizedString("guide_sharing_step2", comment: ""))
            guideStep(emoji: "📡", text: NSLocalizedString("guide_sharing_step3", comment: ""))
            guideStep(emoji: "🌐", text: NSLocalizedString("guide_sharing_step4", comment: ""))
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        guideSection(
            icon: "5.circle.fill",
            title: NSLocalizedString("guide_advanced_title", comment: ""),
            color: AppTheme.accent,
            delay: 0.25
        ) {
            guideStep(emoji: "🏝️", text: NSLocalizedString("guide_advanced_step1", comment: ""))
            guideStep(emoji: "🧩", text: NSLocalizedString("guide_advanced_step2", comment: ""))
            guideStep(emoji: "💾", text: NSLocalizedString("guide_advanced_step3", comment: ""))
            guideStep(emoji: "📄", text: NSLocalizedString("guide_advanced_step4", comment: ""))
        }
    }

    // MARK: - Tips

    private var tipsSection: some View {
        guideSection(
            icon: "lightbulb.fill",
            title: NSLocalizedString("guide_tips_title", comment: ""),
            color: AppTheme.warning,
            delay: 0.3
        ) {
            guideTip(text: NSLocalizedString("guide_tip1", comment: ""))
            guideTip(text: NSLocalizedString("guide_tip2", comment: ""))
            guideTip(text: NSLocalizedString("guide_tip3", comment: ""))
        }
    }

    // MARK: - Helpers

    private func guideSection<Content: View>(
        icon: String, title: String, color: Color, delay: Double,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(color)
                Text(title).font(.headline).fontWeight(.bold)
            }
            content()
        }
        .cardStyle()
        .animatedAppear(delay: delay)
    }

    private func guideStep(emoji: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.title3)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func guideTip(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.warning)
                .font(.subheadline)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
