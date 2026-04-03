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
    @State private var showingDocumentScanner = false
    @State private var showingPhotosPicker = false
    @State private var showingReview = false
    @State private var scannedImage: UIImage?
    @State private var isProcessing = false
    @State private var showNoItemsAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPayerID: UUID?

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
            .sheet(isPresented: $showingDocumentScanner) {
                DocumentScannerView { image in
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
                Button(action: { showingDocumentScanner = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text.viewfinder")
                        Text(NSLocalizedString("scan_document", comment: ""))
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.headerGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 48)

                Button(action: { showingCamera = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                        Text(NSLocalizedString("scan_take_photo", comment: ""))
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(AppTheme.primary)
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

    private var defaultPayerID: UUID {
        let participants = store.participantsFor(campaign: campaign)
        if let creator = participants.first(where: { $0.name == campaign.creatorName }) {
            return creator.id
        }
        return participants.first?.id ?? UUID()
    }

    var reviewView: some View {
        let participants = store.participantsFor(campaign: campaign)
        let selectedTotal = scannedItems.filter { $0.isSelected }.reduce(0.0) { $0 + $1.price }
        let allTotal = scannedItems.reduce(0.0) { $0 + $1.price }
        let payerID = selectedPayerID ?? defaultPayerID
        let hasUnselected = scannedItems.contains { !$0.isSelected }

        return VStack(spacing: 0) {
            // Payer picker
            HStack {
                Text(NSLocalizedString("scan_paid_by", comment: ""))
                    .font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Menu {
                    ForEach(participants) { p in
                        Button(action: { selectedPayerID = p.id }) {
                            HStack {
                                Text("\(p.avatarEmoji) \(p.name)")
                                if p.id == payerID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let payer = participants.first(where: { $0.id == payerID }) {
                            Text(payer.avatarEmoji)
                            Text(payer.name).fontWeight(.medium)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal).padding(.vertical, 10)
            .background(AppTheme.cardBackground)

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

            // Bottom actions
            VStack(spacing: 8) {
                // Create selected items
                Button(action: createSelectedExpenses) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                        Text(hasUnselected
                            ? NSLocalizedString("scan_create_and_continue", comment: "")
                            : NSLocalizedString("scan_create_expenses", comment: ""))
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.headerGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                // Pay all at once (single expense with total)
                if scannedItems.count > 1 {
                    Button(action: createSingleExpense) {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.circle.fill")
                            Text(String(format: NSLocalizedString("scan_pay_all", comment: ""),
                                        String(format: "%.2f", allTotal), campaign.currency))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
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

            // Collect all text blocks with their bounding boxes
            struct TextBlock {
                let text: String
                let midY: CGFloat
                let minX: CGFloat
            }
            var blocks: [TextBlock] = []
            for observation in results {
                guard let text = observation.topCandidates(1).first?.string else { continue }
                let box = observation.boundingBox
                blocks.append(TextBlock(text: text, midY: box.midY, minX: box.minX))
            }

            // Strategy 1: Try parsing each observation as a full line (name + price)
            for block in blocks {
                if let parsed = parseReceiptLine(block.text) {
                    items.append(ScannedItem(name: parsed.name, price: parsed.price, assignedTo: allParticipantIDs))
                }
            }

            // Strategy 2: If no items found, group blocks by vertical position
            // VisionKit often returns name and price as separate observations
            if items.isEmpty && blocks.count >= 2 {
                // Sort by Y descending (VN coordinates: 0=bottom, 1=top)
                let sorted = blocks.sorted { $0.midY > $1.midY }
                let yThreshold: CGFloat = 0.015 // ~1.5% of image height = same line

                var lines: [[TextBlock]] = []
                var currentLine: [TextBlock] = []
                var currentY: CGFloat = sorted[0].midY

                for block in sorted {
                    if abs(block.midY - currentY) < yThreshold {
                        currentLine.append(block)
                    } else {
                        if !currentLine.isEmpty { lines.append(currentLine) }
                        currentLine = [block]
                        currentY = block.midY
                    }
                }
                if !currentLine.isEmpty { lines.append(currentLine) }

                // For each grouped line, sort L→R and try to extract name + price
                for line in lines {
                    let sortedLine = line.sorted { $0.minX < $1.minX }
                    // Combine all texts on this line
                    let combined = sortedLine.map { $0.text }.joined(separator: "  ")
                    if let parsed = parseReceiptLine(combined) {
                        items.append(ScannedItem(name: parsed.name, price: parsed.price, assignedTo: allParticipantIDs))
                        continue
                    }
                    // Try: rightmost block is the price, everything else is the name
                    if sortedLine.count >= 2 {
                        let priceText = sortedLine.last!.text
                            .replacingOccurrences(of: ",", with: ".")
                            .replacingOccurrences(of: "\u{00A0}", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        // Extract price from the rightmost block
                        let pricePattern = #"(\d+[.,]\d{1,2})"#
                        if let regex = try? NSRegularExpression(pattern: pricePattern),
                           let match = regex.firstMatch(in: priceText, range: NSRange(priceText.startIndex..., in: priceText)),
                           let range = Range(match.range(at: 1), in: priceText) {
                            let numStr = String(priceText[range]).replacingOccurrences(of: ",", with: ".")
                            if let price = Double(numStr), price > 0, price < 10000 {
                                let nameParts = sortedLine.dropLast().map { $0.text }
                                let name = nameParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                                if name.count > 1 && !isSkipLine(name) {
                                    items.append(ScannedItem(name: name, price: price, assignedTo: allParticipantIDs))
                                }
                            }
                        }
                    }
                }
            }

            // Strategy 3: If still nothing, look for any standalone prices and pair with nearby text
            if items.isEmpty {
                let priceRegex = try? NSRegularExpression(pattern: #"^\d+[.,]\d{1,2}$"#)
                var priceBlocks: [TextBlock] = []
                var textBlocks: [TextBlock] = []
                for block in blocks {
                    let trimmed = block.text.trimmingCharacters(in: .whitespaces)
                    if let regex = priceRegex,
                       regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {
                        priceBlocks.append(block)
                    } else if trimmed.count > 1 {
                        textBlocks.append(block)
                    }
                }
                // Pair each price with the closest text block at similar Y
                for pb in priceBlocks {
                    let numStr = pb.text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
                    guard let price = Double(numStr), price > 0, price < 10000 else { continue }
                    // Find text block closest in Y and to the left
                    let candidates = textBlocks.filter { abs($0.midY - pb.midY) < 0.02 && $0.minX < pb.minX }
                    if let best = candidates.min(by: { abs($0.midY - pb.midY) < abs($1.midY - pb.midY) }) {
                        let name = best.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !isSkipLine(name) {
                            items.append(ScannedItem(name: name, price: price, assignedTo: allParticipantIDs))
                        }
                    }
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

    private func isSkipLine(_ name: String) -> Bool {
        let lower = name.lowercased()
        let skip = ["total", "subtotal", "sous-total", "tva", "tax", "cb ", "carte", "especes", "espèces",
                    "change", "rendu", "date", "heure", "merci", "thank", "ticket", "facture", "numero",
                    "visa", "mastercard", "paiement", "payment", "brasserie", "restaurant", "adresse",
                    "tel", "siret", "siren", "serveur", "table", "couvert"]
        return skip.contains(where: { lower.contains($0) })
    }

    private func parseReceiptLine(_ line: String) -> (name: String, price: Double)? {
        // Normalize: replace common OCR artifacts
        let cleaned = line
            .replacingOccurrences(of: "\u{00A0}", with: " ") // non-breaking space
            .trimmingCharacters(in: .whitespaces)

        // Match patterns like "Cafe Latte    3.50" or "Pizza 12,90€" or "Dessert ........ 8.00"
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
            guard !isSkipLine(name) else { continue }

            return (name, price)
        }
        return nil
    }

    private func createSelectedExpenses() {
        let selected = scannedItems.filter { $0.isSelected && $0.price > 0 }
        guard !selected.isEmpty else { return }

        let participants = store.participantsFor(campaign: campaign)
        let payerID = selectedPayerID ?? defaultPayerID

        for item in selected {
            let splitIDs = item.assignedTo.isEmpty ? participants.map { $0.id } : Array(item.assignedTo)
            let expense = Expense(
                title: item.name,
                amount: item.price,
                paidByID: payerID,
                splitAmongIDs: splitIDs,
                notes: NSLocalizedString("scan_from_receipt", comment: ""),
                campaignID: campaign.id
            )
            store.addExpense(expense)
        }

        // Remove selected items, keep unselected for next payer
        let remaining = scannedItems.filter { !$0.isSelected && $0.price > 0 }
        if remaining.isEmpty {
            dismiss()
        } else {
            // Reset for next payer: remaining items become selected
            scannedItems = remaining.map { item in
                var newItem = ScannedItem(name: item.name, price: item.price, assignedTo: item.assignedTo)
                newItem.isSelected = true
                return newItem
            }
            selectedPayerID = nil // Reset payer to default
        }
    }

    private func createSingleExpense() {
        let allTotal = scannedItems.reduce(0.0) { $0 + $1.price }
        guard allTotal > 0 else { return }

        let participants = store.participantsFor(campaign: campaign)
        let payerID = selectedPayerID ?? defaultPayerID

        let expense = Expense(
            title: NSLocalizedString("scan_receipt_expense", comment: ""),
            amount: (allTotal * 100).rounded() / 100,
            paidByID: payerID,
            splitAmongIDs: participants.map { $0.id },
            notes: NSLocalizedString("scan_from_receipt", comment: ""),
            campaignID: campaign.id
        )
        store.addExpense(expense)
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

// MARK: - Document Scanner (VNDocumentCameraViewController)
struct DocumentScannerView: UIViewControllerRepresentable {
    let onScan: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(_ parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Use the first scanned page
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                parent.onScan(image)
            }
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.dismiss()
        }
    }
}
