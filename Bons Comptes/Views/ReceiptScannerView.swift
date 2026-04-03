//
//  ReceiptScannerView.swift
//  Bons Comptes
//

import SwiftUI
import PhotosUI
import VisionKit
import Vision

struct ReceiptScannerView: View {
    @EnvironmentObject var store: CampaignStore
    let campaign: Campaign
    @Environment(\.dismiss) var dismiss

    @State private var scannedItems: [ScannedItem] = []
    @State private var showingCamera = false
    @State private var showingPhotosPicker = false
    @State private var showingReview = false
    @State private var scannedImage: UIImage?
    @State private var isProcessing = false
    @State private var showNoItemsAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    struct ScannedItem: Identifiable {
        let id = UUID()
        var name: String
        var price: Double
        var assignedTo: Set<UUID> = []
        var isSelected: Bool = true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                if showingReview {
                    reviewView
                } else {
                    scanPromptView
                }
            }
            .navigationTitle(NSLocalizedString("scan_receipt", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    scannedImage = image
                    processImage(image)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        scannedImage = image
                        processImage(image)
                    }
                    selectedPhotoItem = nil
                }
            }
            .alert(NSLocalizedString("scan_no_items_title", comment: ""), isPresented: $showNoItemsAlert) {
                Button(NSLocalizedString("ok", comment: ""), role: .cancel) {}
            } message: {
                Text(NSLocalizedString("scan_no_items_message", comment: ""))
            }
        }
    }

    var scanPromptView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle().fill(AppTheme.accent.opacity(0.12)).frame(width: 120, height: 120)
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 52)).foregroundColor(AppTheme.accent)
            }

            Text(NSLocalizedString("scan_receipt_title", comment: ""))
                .font(.title2).fontWeight(.bold)

            Text(NSLocalizedString("scan_receipt_desc", comment: ""))
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if isProcessing {
                ProgressView(NSLocalizedString("scan_processing", comment: ""))
                    .padding()
            } else {
                Button(action: { showingCamera = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                        Text(NSLocalizedString("scan_take_photo", comment: ""))
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.headerGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 48)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                        Text(NSLocalizedString("scan_from_library", comment: ""))
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 48)
            }

            Spacer()
        }
    }

    var reviewView: some View {
        let participants = store.participantsFor(campaign: campaign)
        let selectedTotal = scannedItems.filter { $0.isSelected }.reduce(0.0) { $0 + $1.price }

        return VStack(spacing: 0) {
            // Total bar
            HStack {
                Text(NSLocalizedString("scan_total", comment: ""))
                    .font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.2f %@", selectedTotal, campaign.currency))
                    .font(.title3).fontWeight(.bold).foregroundColor(AppTheme.primary)
            }
            .padding()
            .background(AppTheme.cardBackground)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($scannedItems) { $item in
                        VStack(spacing: 8) {
                            HStack {
                                Button(action: { item.isSelected.toggle() }) {
                                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isSelected ? AppTheme.positive : .secondary)
                                }

                                TextField(NSLocalizedString("scan_item_name", comment: ""), text: $item.name)
                                    .font(.subheadline)

                                Spacer()

                                TextField("0.00", value: $item.price, format: .number)
                                    .font(.subheadline).fontWeight(.bold)
                                    .frame(width: 80)
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)

                                Text(campaign.currency).font(.caption).foregroundColor(.secondary)
                            }

                            if item.isSelected {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(participants) { p in
                                            let isAssigned = item.assignedTo.contains(p.id)
                                            Button(action: {
                                                if isAssigned { item.assignedTo.remove(p.id) }
                                                else { item.assignedTo.insert(p.id) }
                                            }) {
                                                HStack(spacing: 4) {
                                                    Text(p.avatarEmoji).font(.caption)
                                                    Text(p.name).font(.caption2)
                                                }
                                                .padding(.horizontal, 10).padding(.vertical, 5)
                                                .background(isAssigned ? AppTheme.primary.opacity(0.15) : Color.gray.opacity(0.1))
                                                .foregroundColor(isAssigned ? AppTheme.primary : .secondary)
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding()
            }

            // Bottom action
            Button(action: createExpenses) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                    Text(NSLocalizedString("scan_create_expenses", comment: ""))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.headerGradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding()
        }
    }

    private func processImage(_ image: UIImage) {
        isProcessing = true
        guard let cgImage = image.cgImage else { isProcessing = false; return }

        let request = VNRecognizeTextRequest { request, error in
            guard let results = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async { isProcessing = false }
                return
            }

            var items: [ScannedItem] = []
            let allParticipantIDs = Set(store.participantsFor(campaign: campaign).map { $0.id })

            for observation in results {
                guard let text = observation.topCandidates(1).first?.string else { continue }
                if let parsed = parseReceiptLine(text) {
                    items.append(ScannedItem(name: parsed.name, price: parsed.price, assignedTo: allParticipantIDs))
                }
            }

            DispatchQueue.main.async {
                scannedItems = items
                isProcessing = false
                if !items.isEmpty {
                    showingReview = true
                } else {
                    showNoItemsAlert = true
                }
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["fr-FR", "en-US"]

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private func parseReceiptLine(_ line: String) -> (name: String, price: Double)? {
        // Normalize: replace common OCR artifacts
        let cleaned = line
            .replacingOccurrences(of: "\u{00A0}", with: " ") // non-breaking space
            .trimmingCharacters(in: .whitespaces)

        // Match patterns like "Cafe Latte    3.50" or "Pizza 12,90€" or "Dessert ........ 8.00"
        // Allow any trailing chars after the price (OCR may garble € symbol)
        let patterns = [
            #"^(.+?)\s{2,}(\d+[.,]\d{1,2})"#,          // Name  (2+ spaces)  price
            #"^(.+?)\s*\.{2,}\s*(\d+[.,]\d{1,2})"#,    // Name.....price
            #"^(.+?)\s+(\d+[.,]\d{1,2})\s*[€$£]"#,     // Name price€
            #"^(.+?)\s+(\d+[.,]\d{1,2})\s*$"#,          // Name price (end of line)
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
                  match.numberOfRanges >= 3 else { continue }

            let nameRange = Range(match.range(at: 1), in: cleaned).map { String(cleaned[$0]) } ?? ""
            let priceStr = Range(match.range(at: 2), in: cleaned).map { String(cleaned[$0]).replacingOccurrences(of: ",", with: ".") } ?? ""

            guard let price = Double(priceStr), price > 0, price < 10000 else { continue }
            let name = nameRange.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count > 1 else { continue }

            // Skip common non-item lines
            let lower = name.lowercased()
            let skip = ["total", "subtotal", "sous-total", "tva", "tax", "cb ", "carte", "especes", "espèces",
                        "change", "rendu", "date", "heure", "merci", "thank", "ticket", "facture", "numero",
                        "visa", "mastercard", "paiement", "payment"]
            if skip.contains(where: { lower.contains($0) }) { continue }

            return (name, price)
        }
        return nil
    }

    private func createExpenses() {
        let selected = scannedItems.filter { $0.isSelected && $0.price > 0 }
        guard !selected.isEmpty else { return }

        let participants = store.participantsFor(campaign: campaign)
        guard let firstParticipant = participants.first else { return }

        for item in selected {
            let splitIDs = item.assignedTo.isEmpty ? participants.map { $0.id } : Array(item.assignedTo)
            let expense = Expense(
                title: item.name,
                amount: item.price,
                paidByID: firstParticipant.id,
                splitAmongIDs: splitIDs,
                notes: NSLocalizedString("scan_from_receipt", comment: ""),
                campaignID: campaign.id
            )
            store.addExpense(expense)
        }
        dismiss()
    }
}

// MARK: - Camera View (UIImagePickerController)
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
