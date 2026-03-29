//
//  ImportCampaignSheet.swift
//  Bons Comptes
//

import SwiftUI

struct ImportCampaignSheet: View {
    let store: CampaignStore
    @Binding var importResult: Bool?
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var clipboardStatus: ClipboardStatus = .checking

    enum ClipboardStatus {
        case checking, found, empty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()
                    statusIcon
                    statusMessage
                    if clipboardStatus == .found {
                        importButton
                    } else if clipboardStatus == .empty {
                        emptyAction
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("import_campaign", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
            .onAppear {
                readClipboard()
            }
        }
    }

    private var statusIcon: some View {
        Image(systemName: clipboardStatus == .found ? "doc.on.clipboard.fill" : "clipboard")
            .font(.system(size: 48))
            .foregroundStyle(clipboardStatus == .found ? AnyShapeStyle(AppTheme.headerGradient) : AnyShapeStyle(Color.secondary.opacity(0.5)))
    }

    private var statusMessage: some View {
        VStack(spacing: 8) {
            Text(clipboardStatus == .found
                 ? NSLocalizedString("clipboard_ready", comment: "")
                 : NSLocalizedString("clipboard_empty", comment: ""))
                .font(.headline)
                .foregroundColor(clipboardStatus == .found ? .primary : .secondary)
                .multilineTextAlignment(.center)
            if clipboardStatus == .found {
                Text(clipboardPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
        }
    }

    private var clipboardPreview: String {
        let text = inputText
        if text.hasPrefix("http") {
            if text.contains("#") {
                return NSLocalizedString("clipboard_link_ok", comment: "")
            } else {
                return NSLocalizedString("clipboard_link_no_data", comment: "")
            }
        } else if text.hasPrefix("{") {
            return "JSON"
        }
        return String(text.prefix(80))
    }

    private var importButton: some View {
        Button(action: doImport) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                Text(NSLocalizedString("import_button", comment: ""))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AnyShapeStyle(AppTheme.headerGradient))
            }
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var emptyAction: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("clipboard_hint", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { readClipboard() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(NSLocalizedString("retry", comment: ""))
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.primary)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }

    private func readClipboard() {
        // Try URL first (preserves fragment better on iOS)
        if let url = UIPasteboard.general.url, let fragment = url.fragment, !fragment.isEmpty {
            inputText = url.absoluteString
            clipboardStatus = .found
        } else if let clipboard = UIPasteboard.general.string, !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputText = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
            clipboardStatus = .found
        } else {
            clipboardStatus = .empty
        }
    }

    private func doImport() {
        let input = inputText
        let success: Bool

        // If it's a URL with a fragment, extract fragment manually for reliability
        if input.contains("#"), let hashIndex = input.firstIndex(of: "#") {
            let fragment = String(input[input.index(after: hashIndex)...])
            if !fragment.isEmpty {
                // Build a clean URL with the fragment
                let baseURL = String(input[..<hashIndex])
                if let url = URL(string: baseURL + "#" + fragment) {
                    success = store.importFromURL(url)
                } else {
                    // Fallback: treat fragment as encoded data directly
                    success = store.importFromURL(URL(string: "bonscomptes://import#" + fragment)!)
                }
            } else {
                success = store.importJSON(input)
            }
        } else if let url = URL(string: input), url.scheme == "bonscomptes" {
            success = store.importFromURL(url)
        } else {
            success = store.importJSON(input)
        }
        importResult = success
        dismiss()
    }
}
