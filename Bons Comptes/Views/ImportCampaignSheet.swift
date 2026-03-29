//
//  ImportCampaignSheet.swift
//  Bons Comptes
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportCampaignSheet: View {
    let store: CampaignStore
    @Binding var importResult: Bool?
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var clipboardStatus: ClipboardStatus = .checking
    @State private var errorMessage = ""
    @State private var showingFilePicker = false

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
                    fileImportButton
                    if !errorMessage.isEmpty {
                        ScrollView {
                            Text(errorMessage)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(maxHeight: 200)
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
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.json, .plainText]) { result in
                switch result {
                case .success(let url):
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) {
                        inputText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        doImport()
                    } else {
                        errorMessage = NSLocalizedString("file_read_error", comment: "")
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
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

    private var fileImportButton: some View {
        Button(action: { showingFilePicker = true }) {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                Text(NSLocalizedString("import_from_file", comment: ""))
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(AppTheme.primary)
            .background(AppTheme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func readClipboard() {
        // Always prefer string — UIPasteboard.general.url can truncate long fragments
        if let clipboard = UIPasteboard.general.string, !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            inputText = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
            clipboardStatus = .found
        } else {
            clipboardStatus = .empty
        }
    }

    private func doImport() {
        let input = inputText
        errorMessage = ""
        let success: Bool

        if input.contains("#"), let hashIndex = input.firstIndex(of: "#") {
            let fragment = String(input[input.index(after: hashIndex)...])
            if !fragment.isEmpty {
                success = store.importFromFragment(fragment)
            } else {
                success = store.importJSON(input)
            }
        } else if input.hasPrefix("{") {
            success = store.importJSON(input)
        } else {
            success = store.importJSON(input)
        }

        if success {
            importResult = true
            dismiss()
        } else {
            importResult = false
            errorMessage = "Échec: \(store.lastImportError)\nDonnées: \(input.count) chars"
        }
    }
}
