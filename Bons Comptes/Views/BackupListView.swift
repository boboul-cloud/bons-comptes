//
//  BackupListView.swift
//  Bons Comptes
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupListView: View {
    @EnvironmentObject var store: CampaignStore
    @Environment(\.dismiss) var dismiss
    @State private var backups: [CampaignStore.BackupInfo] = []
    @State private var showingRestoreAlert = false
    @State private var selectedBackup: CampaignStore.BackupInfo?
    @State private var restoreResult: Bool?
    @State private var savedFeedback = false
    @State private var showingImporter = false
    @State private var exportItem: ShareableURL?
    @State private var importFeedback = false

    struct ShareableURL: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                scrollContent
            }
            .navigationTitle(NSLocalizedString("backups_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("done", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            })
            .alert(NSLocalizedString("restore_backup_title", comment: ""), isPresented: $showingRestoreAlert) {
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
                Button(NSLocalizedString("restore_confirm", comment: ""), role: .destructive) {
                    if let backup = selectedBackup {
                        restoreResult = store.restoreBackup(backup)
                    }
                }
            } message: {
                Text(NSLocalizedString("restore_backup_message", comment: ""))
            }
            .alert(
                restoreResult == true
                    ? NSLocalizedString("restore_success", comment: "")
                    : NSLocalizedString("restore_error", comment: ""),
                isPresented: Binding(get: { restoreResult != nil }, set: { if !$0 { restoreResult = nil } })
            ) {
                Button("OK") {
                    restoreResult = nil
                    if restoreResult != false { dismiss() }
                }
            }
            .onAppear { backups = store.listBackups() }
        }
    }

    var scrollContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                createBackupButton
                    .padding(.horizontal)

                // Import from Files
                Button(action: { showingImporter = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.subheadline)
                        Text(NSLocalizedString("import_from_files", comment: ""))
                            .fontWeight(.semibold)
                            .font(.subheadline)
                    }
                    .foregroundColor(AppTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)

                if backups.isEmpty {
                    emptyBackupState
                } else {
                    ForEach(backups) { backup in
                        backupRow(backup)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .sheet(item: $exportItem) { item in
            ShareSheetView(items: [item.url])
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    var createBackupButton: some View {
        Button(action: createBackupAction) {
            HStack(spacing: 10) {
                Image(systemName: savedFeedback ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                Text(savedFeedback
                     ? NSLocalizedString("saved_feedback", comment: "")
                     : NSLocalizedString("create_backup", comment: ""))
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(savedFeedback ? Color.green : AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var emptyBackupState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text(NSLocalizedString("no_backups", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }

    func createBackupAction() {
        let success = store.saveInternalBackup()
        if success {
            withAnimation(.spring(response: 0.3)) { savedFeedback = true }
            backups = store.listBackups()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { savedFeedback = false }
            }
        }
    }

    func backupRow(_ backup: CampaignStore.BackupInfo) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AppTheme.primary.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: "clock.arrow.circlepath").foregroundColor(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(backup.date.formatted(.dateTime.day().month(.wide).year().hour().minute()))
                    .font(.subheadline).fontWeight(.medium)
                Text(formatSize(backup.size))
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                exportItem = ShareableURL(url: backup.url)
            }) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.primary)
            }

            Button(action: {
                selectedBackup = backup
                showingRestoreAlert = true
            }) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.accent)
            }

            Button(role: .destructive, action: {
                withAnimation {
                    store.deleteBackup(backup)
                    backups = store.listBackups()
                }
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.negative.opacity(0.7))
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { return }
            let success = store.restoreFromData(data)
            if success {
                withAnimation(.spring(response: 0.3)) { importFeedback = true }
                backups = store.listBackups()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { importFeedback = false }
                    dismiss()
                }
            }
        case .failure:
            break
        }
    }

    func formatSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f Ko", kb)
        } else {
            return String(format: "%.1f Mo", kb / 1024.0)
        }
    }
}
