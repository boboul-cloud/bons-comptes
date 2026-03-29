//
//  ShareView.swift
//  Bons Comptes
//

import SwiftUI

struct ShareView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss

    let campaign: Campaign

    @State private var showingJSON = false
    @State private var copiedFeedback = false
    @State private var codeScale: CGFloat = 1.0

    var textSummary: String {
        var text = "\u{1F4CA} \(campaign.title)\n"
        if !campaign.location.isEmpty { text += "\u{1F4CD} \(campaign.location)\n" }
        text += "\n"
        let total = store.totalExpenses(for: campaign)
        text += String(format: NSLocalizedString("total_format", comment: ""), total, campaign.currency) + "\n"
        let participants = store.participantsFor(campaign: campaign)
        text += "\(participants.count) \(NSLocalizedString("participants_count", comment: ""))\n\n"
        text += "\u{2500}\u{2500} \(NSLocalizedString("individual_balances", comment: "")) \u{2500}\u{2500}\n"
        for p in participants {
            let balance = -store.balanceFor(participant: p, in: campaign)
            text += String(format: "  %@ : %+.2f %@\n", p.name, balance, campaign.currency)
        }
        let settlements = store.computeSettlements(for: campaign)
        if !settlements.isEmpty {
            text += "\n\u{2500}\u{2500} \(NSLocalizedString("settlements", comment: "")) \u{2500}\u{2500}\n"
            for s in settlements {
                text += String(format: "  %@ \u{2192} %@ : %.2f %@\n", s.from.name, s.to.name, s.amount, campaign.currency)
            }
        }
        text += "\n\(NSLocalizedString("share_code_format", comment: "")): \(campaign.shareCode)"
        return text
    }

    var jsonExport: String {
        store.exportJSON(for: campaign)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.headerGradient)
                            VStack(spacing: 16) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white.opacity(0.8))

                                Text(campaign.shareCode)
                                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                                    .tracking(6)
                                    .foregroundColor(.white)
                                    .scaleEffect(codeScale)

                                Text(NSLocalizedString("share_code_instructions", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button(action: {
                                    UIPasteboard.general.string = campaign.shareCode
                                    withAnimation(.spring(response: 0.3)) {
                                        copiedFeedback = true
                                        codeScale = 1.1
                                    }
                                    withAnimation(.spring(response: 0.3).delay(0.15)) {
                                        codeScale = 1.0
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { copiedFeedback = false }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                                        Text(copiedFeedback
                                             ? NSLocalizedString("copied", comment: "")
                                             : NSLocalizedString("copy_code", comment: ""))
                                    }
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundColor(AppTheme.primary)
                                    .padding(.horizontal, 24).padding(.vertical, 10)
                                    .background(.white)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 24)
                        }
                        .padding(.horizontal)
                        .animatedAppear()

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "square.and.arrow.up.fill", title: NSLocalizedString("export_data", comment: ""), color: AppTheme.info)

                            ShareLink(item: textSummary) {
                                shareRow(icon: "text.alignleft", title: NSLocalizedString("share_summary", comment: ""), color: AppTheme.primary)
                            }

                            ShareLink(item: jsonExport) {
                                shareRow(icon: "doc.text", title: NSLocalizedString("share_json", comment: ""), color: AppTheme.accent)
                            }

                            Button(action: { showingJSON = true }) {
                                shareRow(icon: "eye", title: NSLocalizedString("view_json", comment: ""), color: AppTheme.info)
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.1)

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "globe", title: NSLocalizedString("web_access_section", comment: ""), color: AppTheme.accent)
                            Text(NSLocalizedString("web_access_desc", comment: ""))
                                .font(.subheadline).foregroundColor(.secondary)

                            let webLink = store.webURL(for: campaign)

                            ShareLink(item: webLink) {
                                shareRow(icon: "link", title: NSLocalizedString("share_web_link", comment: ""), color: AppTheme.accent)
                            }

                            Button(action: {
                                UIPasteboard.general.string = webLink
                                withAnimation(.spring(response: 0.3)) { copiedFeedback = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { copiedFeedback = false }
                                }
                            }) {
                                shareRow(icon: "doc.on.doc", title: NSLocalizedString("copy_web_link", comment: ""), color: AppTheme.primary)
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.15)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(NSLocalizedString("share_campaign", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
            .sheet(isPresented: $showingJSON) {
                NavigationStack {
                    ScrollView {
                        Text(store.exportJSON(for: campaign))
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .textSelection(.enabled)
                    }
                    .background(AppTheme.backgroundGradient.ignoresSafeArea())
                    .navigationTitle("JSON")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(content: {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(NSLocalizedString("done", comment: "")) { showingJSON = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { UIPasteboard.general.string = store.exportJSON(for: campaign) }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    })
                }
            }
        }
    }

    func shareRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color)
            }
            Text(title).font(.subheadline).foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.headline).fontWeight(.bold)
        }
    }
}
