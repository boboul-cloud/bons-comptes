//
//  CampaignListView.swift
//  Bons Comptes
//

import SwiftUI

struct CampaignListView: View {
    @EnvironmentObject var store: CampaignStore
    @State private var showingAddCampaign = false
    @State private var showingImport = false
    @State private var importCode = ""
    @State private var showArchived = false

    var filteredCampaigns: [Campaign] {
        store.campaigns.filter { $0.isArchived == showArchived }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                if filteredCampaigns.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(filteredCampaigns.enumerated()), id: \.element.id) { index, campaign in
                                NavigationLink(destination: CampaignDetailView(campaign: campaign)) {
                                    CampaignCardView(campaign: campaign)
                                }
                                .buttonStyle(.plain)
                                .animatedAppear(delay: Double(index) * 0.08)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation { store.deleteCampaign(campaign) }
                                    } label: {
                                        Label(NSLocalizedString("delete", comment: ""), systemImage: "trash")
                                    }
                                    Button {
                                        store.archiveCampaign(campaign)
                                    } label: {
                                        Label(NSLocalizedString("archive_campaign", comment: ""), systemImage: "archivebox")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("app_title", comment: ""))
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: {
                            withAnimation(.spring()) { showArchived.toggle() }
                        }) {
                            Label(
                                showArchived
                                    ? NSLocalizedString("show_active", comment: "")
                                    : NSLocalizedString("show_archived", comment: ""),
                                systemImage: showArchived ? "tray.full" : "archivebox"
                            )
                        }
                        Button(action: { showingImport = true }) {
                            Label(NSLocalizedString("import_campaign", comment: ""), systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(AppTheme.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddCampaign = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            })
            .sheet(isPresented: $showingAddCampaign) {
                AddCampaignView()
            }
            .alert(NSLocalizedString("import_campaign", comment: ""), isPresented: $showingImport) {
                TextField(NSLocalizedString("paste_json_or_url", comment: ""), text: $importCode)
                Button(NSLocalizedString("import_button", comment: "")) {
                    let input = importCode.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let url = URL(string: input), (url.scheme == "bonscomptes" || url.scheme == "https" || url.fragment != nil) {
                        _ = store.importFromURL(url)
                    } else {
                        _ = store.importJSON(input)
                    }
                    importCode = ""
                }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "banknote")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.headerGradient)
            Text(NSLocalizedString("no_campaigns", comment: ""))
                .font(.title2)
                .fontWeight(.bold)
            Text(NSLocalizedString("no_campaigns_desc", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showingAddCampaign = true }) {
                Label(NSLocalizedString("new_campaign", comment: ""), systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppTheme.headerGradient)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(40)
        .animatedAppear()
    }
}

// MARK: - Campaign Card
struct CampaignCardView: View {
    @EnvironmentObject var store: CampaignStore
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(campaign.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        if campaign.isArchived {
                            GradientBadge(text: "ARCHIVÉ", gradient: LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        }
                    }
                    if !campaign.location.isEmpty {
                        Label(campaign.location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Stats row
            HStack(spacing: 0) {
                miniStat(
                    icon: "banknote",
                    value: String(format: "%.0f %@", store.totalExpenses(for: campaign), campaign.currency),
                    color: AppTheme.negative
                )
                Spacer()
                miniStat(
                    icon: "person.2",
                    value: "\(store.participantsFor(campaign: campaign).count)",
                    color: AppTheme.primary
                )
                Spacer()
                miniStat(
                    icon: "calendar",
                    value: campaign.createdAt.formatted(.dateTime.day().month(.abbreviated)),
                    color: AppTheme.info
                )
            }
        }
        .cardStyle()
    }

    func miniStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}
