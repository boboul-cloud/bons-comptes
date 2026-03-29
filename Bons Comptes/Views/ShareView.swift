//
//  ShareView.swift
//  Bons Comptes
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct PDFFile: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { pdf in
            SentTransferredFile(pdf.url)
        }
    }
}

struct ShareView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss

    let campaign: Campaign

    @State private var copiedFeedback = false
    @State private var pdfURL: URL?

    var participantsWithPhone: [Participant] {
        store.participantsFor(campaign: campaign).filter { !$0.phone.isEmpty }
    }

    var webLink: String { store.webURL(for: campaign) }

    private func generatePDFURL() -> URL {
        let data = PDFGenerator.generate(campaign: campaign, store: store)
        let name = campaign.title.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).pdf")
        try? data.write(to: url)
        return url
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
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.9))

                                Text(NSLocalizedString("share_link_title", comment: ""))
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(NSLocalizedString("share_link_desc", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                HStack(spacing: 12) {
                                    ShareLink(item: webLink) {
                                        HStack {
                                            Image(systemName: "square.and.arrow.up")
                                            Text(NSLocalizedString("share_button", comment: ""))
                                        }
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundColor(AppTheme.primary)
                                        .padding(.horizontal, 20).padding(.vertical, 10)
                                        .background(.white)
                                        .clipShape(Capsule())
                                    }

                                    Button(action: {
                                        UIPasteboard.general.string = webLink
                                        withAnimation(.spring(response: 0.3)) { copiedFeedback = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation { copiedFeedback = false }
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                                            Text(copiedFeedback
                                                 ? NSLocalizedString("copied", comment: "")
                                                 : NSLocalizedString("copy_button", comment: ""))
                                        }
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20).padding(.vertical, 10)
                                        .background(.white.opacity(0.2))
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.vertical, 24)
                        }
                        .padding(.horizontal)
                        .animatedAppear()

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "square.and.arrow.up.fill", title: NSLocalizedString("export_data", comment: ""), color: AppTheme.info)

                            ShareLink(item: PDFFile(url: generatePDFURL()), preview: SharePreview(campaign.title, image: Image(systemName: "doc.richtext"))) {
                                shareRow(icon: "doc.richtext", title: NSLocalizedString("share_pdf", comment: ""), color: AppTheme.primary)
                            }

                            ShareLink(item: jsonExport) {
                                shareRow(icon: "doc.text", title: NSLocalizedString("share_json", comment: ""), color: AppTheme.accent)
                            }

                            Button(action: {
                                pdfURL = generatePDFURL()
                            }) {
                                shareRow(icon: "eye", title: NSLocalizedString("view_pdf", comment: ""), color: AppTheme.info)
                            }
                        }
                        .cardStyle()
                        .animatedAppear(delay: 0.1)

                        // SMS send to participants
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(icon: "message.fill", title: NSLocalizedString("send_sms_section", comment: ""), color: AppTheme.positive)

                            if participantsWithPhone.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.secondary)
                                    Text(NSLocalizedString("no_phone_numbers", comment: ""))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                            } else {
                                Button(action: sendSMSToAll) {
                                    shareRow(
                                        icon: "paperplane.fill",
                                        title: String(format: NSLocalizedString("send_sms_all_format", comment: ""), participantsWithPhone.count),
                                        color: AppTheme.positive
                                    )
                                }

                                ForEach(participantsWithPhone) { p in
                                    Button(action: { sendSMS(to: [p.phone]) }) {
                                        HStack(spacing: 14) {
                                            AvatarView(p.avatarEmoji, size: 40)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(p.name)
                                                    .font(.subheadline).foregroundColor(.primary)
                                                Text(p.phone)
                                                    .font(.caption2).foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "message.fill")
                                                .foregroundColor(AppTheme.positive)
                                        }
                                        .padding(12)
                                        .background(AppTheme.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
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
            .quickLookPreview($pdfURL)
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

    func sendSMSToAll() {
        let phones = participantsWithPhone.map { $0.phone }
        sendSMS(to: phones)
    }

    func sendSMS(to phones: [String]) {
        let link = webLink
        let body = String(format: NSLocalizedString("sms_campaign_body", comment: ""), campaign.title, link)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let recipients = phones.joined(separator: ",")
        if let url = URL(string: "sms://open?addresses=\(recipients)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }
}
