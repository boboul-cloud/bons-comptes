//
//  ProximityShareView.swift
//  Bons Comptes
//

import SwiftUI
import MultipeerConnectivity

struct ProximityShareView: View {
    @EnvironmentObject var store: CampaignStore
    let campaign: Campaign
    let syncDeletions: Bool
    @Environment(\.dismiss) var dismiss

    @StateObject private var manager = ProximityShareManager()
    @State private var mode: Mode = .choose

    enum Mode {
        case choose, send, receive
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                    statusView
                    Spacer()

                    if case .choose = mode {
                        chooseButtons
                    } else if case .completed(true) = manager.state {
                        importButton
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("proximity_share", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("close", comment: "")) {
                        manager.stop()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
    }

    @ViewBuilder
    var statusView: some View {
        switch manager.state {
        case .idle:
            VStack(spacing: 16) {
                pulsingIcon("antenna.radiowaves.left.and.right", color: AppTheme.info)
                Text(NSLocalizedString("proximity_choose", comment: ""))
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

        case .searching:
            VStack(spacing: 16) {
                pulsingIcon("antenna.radiowaves.left.and.right", color: AppTheme.accent, animate: true)
                Text(NSLocalizedString("proximity_searching", comment: ""))
                    .font(.headline)
                Text(NSLocalizedString("proximity_keep_close", comment: ""))
                    .font(.caption).foregroundColor(.secondary)
                if !manager.nearbyPeers.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(manager.nearbyPeers, id: \.displayName) { peer in
                            HStack {
                                Image(systemName: "iphone").foregroundColor(AppTheme.primary)
                                Text(peer.displayName).font(.subheadline)
                            }
                            .padding(10)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }

        case .connecting(let name):
            VStack(spacing: 16) {
                pulsingIcon("link", color: AppTheme.accent, animate: true)
                Text(String(format: NSLocalizedString("proximity_connecting", comment: ""), name))
                    .font(.headline).multilineTextAlignment(.center)
            }

        case .sending:
            VStack(spacing: 16) {
                pulsingIcon("arrow.up.circle.fill", color: AppTheme.positive, animate: true)
                Text(NSLocalizedString("proximity_sending", comment: ""))
                    .font(.headline)
            }

        case .receiving:
            VStack(spacing: 16) {
                pulsingIcon("arrow.down.circle.fill", color: AppTheme.info, animate: true)
                Text(NSLocalizedString("proximity_receiving", comment: ""))
                    .font(.headline)
            }

        case .completed(let received):
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(AppTheme.positive.opacity(0.12)).frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52)).foregroundColor(AppTheme.positive)
                }
                Text(received
                     ? NSLocalizedString("proximity_received", comment: "")
                     : NSLocalizedString("proximity_sent", comment: ""))
                    .font(.headline)
            }

        case .failed(let error):
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(AppTheme.negative.opacity(0.12)).frame(width: 100, height: 100)
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 52)).foregroundColor(AppTheme.negative)
                }
                Text(NSLocalizedString("proximity_failed", comment: ""))
                    .font(.headline)
                Text(error).font(.caption).foregroundColor(.secondary)
            }
        }
    }

    var chooseButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                mode = .send
                let data = store.encodeV2(for: campaign, syncDeletions: syncDeletions)
                manager.startSharing(campaignData: data)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("proximity_send", comment: ""))
                            .fontWeight(.bold)
                        Text(NSLocalizedString("proximity_send_desc", comment: ""))
                            .font(.caption2).opacity(0.8)
                    }
                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(AppTheme.headerGradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button(action: {
                mode = .receive
                manager.startReceiving()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("proximity_receive", comment: ""))
                            .fontWeight(.bold)
                        Text(NSLocalizedString("proximity_receive_desc", comment: ""))
                            .font(.caption2).opacity(0.8)
                    }
                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(AppTheme.accent.opacity(0.15))
                .foregroundColor(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    var importButton: some View {
        Button(action: importReceived) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down.fill")
                Text(NSLocalizedString("proximity_import", comment: ""))
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.headerGradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    func pulsingIcon(_ name: String, color: Color, animate: Bool = false) -> some View {
        ZStack {
            if animate {
                Circle().fill(color.opacity(0.08)).frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }
            Circle().fill(color.opacity(0.12)).frame(width: 100, height: 100)
            Image(systemName: name).font(.system(size: 44)).foregroundColor(color)
        }
    }

    func importReceived() {
        guard let data = manager.receivedCampaignData else { return }
        _ = store.importV2(data)
        manager.stop()
        dismiss()
    }
}
