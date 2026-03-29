//
//  PDFGenerator.swift
//  Bons Comptes
//

import UIKit
import PDFKit

struct PDFGenerator {

    static func generate(campaign: Campaign, store: CampaignStore) -> Data {
        let pageWidth: CGFloat = 595.0  // A4
        let pageHeight: CGFloat = 842.0
        let margin: CGFloat = 40.0
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let participants = store.participantsFor(campaign: campaign)
        let expenses = store.expensesFor(campaign: campaign).sorted { $0.date > $1.date }
        let reimbursements = store.reimbursementsFor(campaign: campaign).sorted { $0.date > $1.date }
        let total = store.totalExpenses(for: campaign)
        let settlements = store.computeSettlements(for: campaign)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        let data = renderer.pdfData { context in
            var y: CGFloat = 0

            func newPage() {
                context.beginPage()
                y = margin
            }

            func checkPage(needed: CGFloat) {
                if y + needed > pageHeight - margin {
                    newPage()
                }
            }

            // MARK: - Fonts & Colors
            let titleFont = UIFont.systemFont(ofSize: 22, weight: .bold)
            let headingFont = UIFont.systemFont(ofSize: 16, weight: .bold)
            let bodyFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let bodyBold = UIFont.systemFont(ofSize: 11, weight: .semibold)
            let smallFont = UIFont.systemFont(ofSize: 9, weight: .regular)
            let primaryColor = UIColor(red: 0.35, green: 0.34, blue: 0.84, alpha: 1)
            let textColor = UIColor.darkGray
            let lightGray = UIColor(white: 0.93, alpha: 1)

            func drawText(_ text: String, font: UIFont, color: UIColor, x: CGFloat, maxWidth: CGFloat) -> CGFloat {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let rect = CGRect(x: x, y: y, width: maxWidth, height: .greatestFiniteMagnitude)
                let boundingRect = (text as NSString).boundingRect(with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
                (text as NSString).draw(in: CGRect(x: x, y: y, width: maxWidth, height: boundingRect.height), withAttributes: attrs)
                return boundingRect.height
            }

            func drawLine() {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                UIColor.lightGray.setStroke()
                path.lineWidth = 0.5
                path.stroke()
                y += 8
            }

            func drawSectionHeader(_ title: String) {
                checkPage(needed: 40)
                y += 12

                let bgRect = CGRect(x: margin, y: y, width: contentWidth, height: 28)
                let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 6)
                primaryColor.withAlphaComponent(0.1).setFill()
                bgPath.fill()

                y += 6
                let h = drawText(title, font: headingFont, color: primaryColor, x: margin + 10, maxWidth: contentWidth - 20)
                y += h + 10
            }

            // MARK: - Page 1: Header
            newPage()

            // Title bar
            let headerRect = CGRect(x: 0, y: 0, width: pageWidth, height: 90)
            let headerPath = UIBezierPath(rect: headerRect)
            primaryColor.setFill()
            headerPath.fill()

            y = 20
            let _ = drawText(campaign.title, font: titleFont, color: .white, x: margin, maxWidth: contentWidth)
            y += 28

            var subtitle = ""
            if !campaign.location.isEmpty { subtitle += "📍 \(campaign.location)  " }
            subtitle += "👥 \(participants.count) \(NSLocalizedString("participants_count", comment: ""))  "
            subtitle += "📅 \(dateFormatter.string(from: campaign.createdAt))"
            let _ = drawText(subtitle, font: bodyFont, color: UIColor.white.withAlphaComponent(0.9), x: margin, maxWidth: contentWidth)
            y = 100

            // Total
            checkPage(needed: 50)
            let totalStr = String(format: NSLocalizedString("total_format", comment: ""), total, campaign.currency)
            y += 4
            let h1 = drawText(totalStr, font: UIFont.systemFont(ofSize: 18, weight: .bold), color: primaryColor, x: margin, maxWidth: contentWidth)
            y += h1 + 4

            let avgStr: String
            if participants.count > 0 {
                let avg = total / Double(participants.count)
                avgStr = String(format: "%@ : %.2f %@", NSLocalizedString("per_person_avg", comment: ""), avg, campaign.currency)
            } else {
                avgStr = ""
            }
            if !avgStr.isEmpty {
                let h2 = drawText(avgStr, font: bodyFont, color: textColor, x: margin, maxWidth: contentWidth)
                y += h2
            }
            y += 8
            drawLine()

            // MARK: - Balances
            drawSectionHeader("⚖️ " + NSLocalizedString("individual_balances", comment: ""))

            for p in participants {
                checkPage(needed: 20)
                let balance = -store.balanceFor(participant: p, in: campaign)
                let balanceStr = String(format: "%+.2f %@", balance, campaign.currency)
                let color = balance >= 0 ? UIColor.systemGreen : UIColor.systemRed
                let _ = drawText("\(p.avatarEmoji) \(p.name)", font: bodyBold, color: textColor, x: margin + 8, maxWidth: contentWidth * 0.6)
                let _ = drawText(balanceStr, font: bodyBold, color: color, x: margin + contentWidth * 0.7, maxWidth: contentWidth * 0.3)
                y += 18
            }

            // MARK: - Settlements
            if !settlements.isEmpty {
                drawSectionHeader("💸 " + NSLocalizedString("settlements", comment: ""))
                for s in settlements {
                    checkPage(needed: 20)
                    let line = "\(s.from.name)  →  \(s.to.name)"
                    let amtStr = String(format: "%.2f %@", s.amount, campaign.currency)
                    let _ = drawText(line, font: bodyFont, color: textColor, x: margin + 8, maxWidth: contentWidth * 0.65)
                    let _ = drawText(amtStr, font: bodyBold, color: primaryColor, x: margin + contentWidth * 0.7, maxWidth: contentWidth * 0.3)
                    y += 18
                }
            }

            // MARK: - Expenses detail
            drawSectionHeader("🧾 " + NSLocalizedString("expenses_tab", comment: "") + " (\(expenses.count))")

            for (idx, expense) in expenses.enumerated() {
                let paidBy = participants.first(where: { $0.id == expense.paidByID })
                let splitAmong = participants.filter { expense.splitAmongIDs.contains($0.id) }
                let blockHeight: CGFloat = 62 + (splitAmong.isEmpty ? 0 : CGFloat(splitAmong.count) * 14 + 16)
                checkPage(needed: blockHeight)

                // Alternate background
                if idx % 2 == 0 {
                    let bgRect = CGRect(x: margin, y: y, width: contentWidth, height: blockHeight)
                    let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 4)
                    lightGray.setFill()
                    bgPath.fill()
                }

                y += 4
                // Row 1: title + amount
                let _ = drawText(expense.title, font: bodyBold, color: textColor, x: margin + 8, maxWidth: contentWidth * 0.6)
                let amtStr = String(format: "%.2f %@", expense.amount, campaign.currency)
                let _ = drawText(amtStr, font: bodyBold, color: primaryColor, x: margin + contentWidth * 0.7, maxWidth: contentWidth * 0.3)
                y += 16

                // Row 2: paid by + date + category
                var paidByStr = String(format: "%@ %@", NSLocalizedString("paid_by", comment: ""), paidBy?.name ?? "?")
                if let catID = expense.categoryID, let cat = store.categories.first(where: { $0.id == catID }) {
                    paidByStr += "  •  \(cat.name)"
                }
                let _ = drawText(paidByStr, font: smallFont, color: textColor, x: margin + 8, maxWidth: contentWidth * 0.65)
                let _ = drawText(dateFormatter.string(from: expense.date), font: smallFont, color: .gray, x: margin + contentWidth * 0.7, maxWidth: contentWidth * 0.3)
                y += 13

                // Row 3: split details
                let splitLabel = NSLocalizedString(expense.splitType.displayKey, comment: "")
                let _ = drawText("↳ \(splitLabel) — \(splitAmong.count) pers.", font: smallFont, color: .gray, x: margin + 8, maxWidth: contentWidth)
                y += 13

                // Individual shares
                for sp in splitAmong {
                    let share = expense.shareFor(participantID: sp.id)
                    let shareStr = String(format: "  • %@ : %.2f %@", sp.name, share, campaign.currency)
                    let _ = drawText(shareStr, font: smallFont, color: textColor, x: margin + 16, maxWidth: contentWidth - 24)
                    y += 14
                }

                // Notes
                if !expense.notes.isEmpty {
                    let _ = drawText("📝 \(expense.notes)", font: smallFont, color: .gray, x: margin + 8, maxWidth: contentWidth - 16)
                    y += 13
                }

                y += 6
            }

            // MARK: - Reimbursements detail
            if !reimbursements.isEmpty {
                drawSectionHeader("🔄 " + NSLocalizedString("reimbursements_tab", comment: "") + " (\(reimbursements.count))")

                for (idx, reimb) in reimbursements.enumerated() {
                    let from = participants.first(where: { $0.id == reimb.fromID })
                    let to = participants.first(where: { $0.id == reimb.toID })
                    checkPage(needed: 50)

                    if idx % 2 == 0 {
                        let bgRect = CGRect(x: margin, y: y, width: contentWidth, height: 44)
                        let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 4)
                        lightGray.setFill()
                        bgPath.fill()
                    }

                    y += 4
                    let line = "\(from?.name ?? "?")  →  \(to?.name ?? "?")"
                    let amtStr = String(format: "%.2f %@", reimb.amount, campaign.currency)
                    let _ = drawText(line, font: bodyBold, color: textColor, x: margin + 8, maxWidth: contentWidth * 0.6)
                    let _ = drawText(amtStr, font: bodyBold, color: UIColor.systemGreen, x: margin + contentWidth * 0.7, maxWidth: contentWidth * 0.3)
                    y += 16

                    var detail = dateFormatter.string(from: reimb.date)
                    if let pmID = reimb.paymentMethodID, let pm = store.paymentMethods.first(where: { $0.id == pmID }) {
                        detail += " — 💳 \(pm.name)"
                    }
                    if reimb.isPartial { detail += " — " + NSLocalizedString("partial_reimbursement", comment: "") }
                    if !reimb.notes.isEmpty { detail += " — 📝 \(reimb.notes)" }
                    let _ = drawText(detail, font: smallFont, color: .gray, x: margin + 8, maxWidth: contentWidth - 16)
                    y += 20
                }
            }

            // MARK: - Footer
            checkPage(needed: 40)
            y += 16
            drawLine()
            let footer = "Bons Comptes — \(dateFormatter.string(from: Date()))"
            let _ = drawText(footer, font: smallFont, color: .gray, x: margin, maxWidth: contentWidth)
        }

        return data
    }
}
