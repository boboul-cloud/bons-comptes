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

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        pasteButton
                        textFieldSection
                        importButton
                    }
                    .padding()
                }
            }
            .navigationTitle(NSLocalizedString("import_campaign", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.headerGradient)
            Text(NSLocalizedString("import_desc", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var pasteButton: some View {
        Button(action: {
            if let clipboard = UIPasteboard.general.string {
                inputText = clipboard
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard")
                Text(NSLocalizedString("paste_clipboard", comment: ""))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.primary.opacity(0.1))
            .foregroundColor(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var textFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("paste_json_or_url", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
            TextEditor(text: $inputText)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                )
        }
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
                    .fill(inputText.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(AppTheme.headerGradient))
            }
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(inputText.isEmpty)
    }

    private func doImport() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let success: Bool
        if let url = URL(string: input), url.scheme == "bonscomptes" || url.scheme == "https" || url.fragment != nil {
            success = store.importFromURL(url)
        } else {
            success = store.importJSON(input)
        }
        importResult = success
        dismiss()
    }
}
