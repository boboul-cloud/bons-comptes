//
//  SEPAQRCodeView.swift
//  Bons Comptes
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct SEPAQRCodeView: View {
    let fromName: String
    let toName: String
    let amount: Double
    let currency: String
    let toEmoji: String

    @State private var iban = ""
    @State private var bic = ""
    @State private var beneficiaryName = ""
    @State private var reference = ""
    @State private var showQR = false
    @State private var showingShareSheet = false
    @State private var qrImage: UIImage?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.reimbursementGradient)
                            VStack(spacing: 12) {
                                AvatarView(toEmoji, size: 56)
                                Text(String(format: "%.2f %@", amount, currency))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(String(format: NSLocalizedString("qr_from_to", comment: ""), fromName, toName))
                                    .font(.subheadline).foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.vertical, 24)
                        }
                        .padding(.horizontal)

                        if showQR, let qr = qrImage {
                            VStack(spacing: 16) {
                                Image(uiImage: qr)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 220, height: 220)
                                    .padding(16)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.1), radius: 10)

                                Text(NSLocalizedString("qr_scan_hint", comment: ""))
                                    .font(.caption).foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)

                                Button(action: { showingShareSheet = true }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text(NSLocalizedString("qr_share", comment: ""))
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.headerGradient)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .padding(.horizontal)
                                .sheet(isPresented: $showingShareSheet) {
                                    let text = String(format: NSLocalizedString("qr_share_message", comment: ""), fromName, String(format: "%.2f %@", amount, currency), toName)
                                    ShareSheet(items: [qr, text])
                                }
                            }
                            .animatedAppear()
                        } else {
                            // Form
                            VStack(alignment: .leading, spacing: 16) {
                                Text(NSLocalizedString("qr_bank_details", comment: ""))
                                    .font(.headline).fontWeight(.bold)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("IBAN").font(.caption).foregroundColor(.secondary)
                                    TextField("FR76 1234 5678 9012 3456 7890 123", text: $iban)
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.characters)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(12)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("BIC").font(.caption).foregroundColor(.secondary)
                                    TextField("BNPAFRPP", text: $bic)
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.characters)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(12)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(NSLocalizedString("qr_beneficiary", comment: "")).font(.caption).foregroundColor(.secondary)
                                    TextField(toName, text: $beneficiaryName)
                                        .padding(12)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(NSLocalizedString("qr_reference", comment: "")).font(.caption).foregroundColor(.secondary)
                                    TextField(NSLocalizedString("qr_reference_placeholder", comment: ""), text: $reference)
                                        .padding(12)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                Button(action: {
                                    qrImage = generateEPCQRCode()
                                    withAnimation { showQR = true }
                                }) {
                                    HStack {
                                        Image(systemName: "qrcode")
                                        Text(NSLocalizedString("qr_generate", comment: ""))
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(cleanIBAN.count >= 15 ? AppTheme.reimbursementGradient : LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .disabled(cleanIBAN.count < 15)
                            }
                            .cardStyle()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(NSLocalizedString("qr_sepa_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
            .onAppear { beneficiaryName = toName }
        }
    }

    private var cleanIBAN: String {
        iban.replacingOccurrences(of: " ", with: "").uppercased()
    }

    private func generateEPCQRCode() -> UIImage? {
        // EPC069-12 standard for SEPA Credit Transfer QR codes
        let name = beneficiaryName.isEmpty ? toName : beneficiaryName
        let ref = reference.isEmpty ? "Bons Comptes" : reference
        let epcData = [
            "BCD",                          // Service Tag
            "002",                          // Version
            "1",                            // Character set (UTF-8)
            "SCT",                          // Identification
            bic.replacingOccurrences(of: " ", with: "").uppercased(), // BIC
            String(name.prefix(70)),        // Beneficiary name (max 70)
            cleanIBAN,                      // IBAN
            String(format: "EUR%.2f", amount), // Amount
            "",                             // Purpose
            String(ref.prefix(140)),        // Reference
            "",                             // Display text
        ].joined(separator: "\n")

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(epcData.utf8)
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return nil }
        let scale = 10.0
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
