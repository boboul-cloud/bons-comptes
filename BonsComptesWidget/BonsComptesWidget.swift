//
//  BonsComptesWidget.swift
//  BonsComptesWidget
//
//  Widget showing campaign summary on Home Screen
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - App Group Helper

nonisolated private func loadAllCampaigns() -> [WidgetCampaignData] {
    guard let defaults = UserDefaults(suiteName: "group.com.bonscomptes.shared"),
          let data = defaults.data(forKey: "widgetCampaigns"),
          let campaigns = try? JSONDecoder().decode([WidgetCampaignData].self, from: data)
    else { return [] }
    return campaigns
}

// MARK: - AppIntent for Campaign Selection

struct CampaignEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Campaign")
    static var defaultQuery = CampaignEntityQuery()

    var id: String
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct CampaignEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CampaignEntity] {
        let all = loadAllCampaigns()
        return identifiers.compactMap { id in
            guard let c = all.first(where: { $0.id == id }) else { return nil }
            return CampaignEntity(id: c.id, title: c.title)
        }
    }

    func suggestedEntities() async throws -> [CampaignEntity] {
        loadAllCampaigns().map { CampaignEntity(id: $0.id, title: $0.title) }
    }

    func defaultResult() async -> CampaignEntity? {
        guard let first = loadAllCampaigns().first else { return nil }
        return CampaignEntity(id: first.id, title: first.title)
    }
}

struct SelectCampaignIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Campaign"
    static var description: IntentDescription = "Choose which campaign to display"

    @Parameter(title: "Campaign")
    var campaign: CampaignEntity?
}

// MARK: - Provider

struct BonsComptesWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BonsComptesWidgetEntry {
        BonsComptesWidgetEntry(date: Date(), campaign: nil)
    }

    func snapshot(for configuration: SelectCampaignIntent, in context: Context) async -> BonsComptesWidgetEntry {
        BonsComptesWidgetEntry(date: Date(), campaign: resolveCampaign(for: configuration))
    }

    func timeline(for configuration: SelectCampaignIntent, in context: Context) async -> Timeline<BonsComptesWidgetEntry> {
        let entry = BonsComptesWidgetEntry(date: Date(), campaign: resolveCampaign(for: configuration))
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
    }

    private func resolveCampaign(for config: SelectCampaignIntent) -> WidgetCampaignData? {
        let all = loadAllCampaigns()
        if let selected = config.campaign {
            return all.first(where: { $0.id == selected.id })
        }
        return all.first
    }
}

struct BonsComptesWidgetEntry: TimelineEntry {
    let date: Date
    let campaign: WidgetCampaignData?
}

// MARK: - Widget Views

struct BonsComptesWidgetEntryView: View {
    var entry: BonsComptesWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let campaign = entry.campaign {
            switch family {
            case .systemSmall:
                smallView(campaign)
            case .systemMedium:
                mediumView(campaign)
            default:
                smallView(campaign)
            }
        } else {
            placeholderView
        }
    }

    var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "creditcard.fill")
                .font(.title2).foregroundColor(.blue)
            Text("Bons Comptes")
                .font(.caption).fontWeight(.bold)
            Text("Open to see campaigns")
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func smallView(_ c: WidgetCampaignData) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue).font(.caption)
                Text(c.title)
                    .font(.caption).fontWeight(.bold).lineLimit(1)
            }

            Spacer()

            Text(String(format: "%.0f%@", c.totalExpenses, c.currency))
                .font(.title2).fontWeight(.bold)

            HStack(spacing: 4) {
                Image(systemName: "person.2").font(.system(size: 8))
                Text("\(c.participantCount)")
                Text("•")
                Text(String(format: "%.0f%@/p", c.perPerson, c.currency))
            }
            .font(.caption2).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(URL(string: "bonscomptes://campaign/\(c.id)"))
    }

    func mediumView(_ c: WidgetCampaignData) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.blue).font(.caption)
                    Text(c.title)
                        .font(.subheadline).fontWeight(.bold).lineLimit(1)
                }

                Spacer()

                Text(String(format: "%.2f %@", c.totalExpenses, c.currency))
                    .font(.title).fontWeight(.bold)

                Text(c.lastUpdate.formatted(.relative(presentation: .named)))
                    .font(.caption2).foregroundColor(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                statBubble(icon: "person.2", value: "\(c.participantCount)")
                statBubble(icon: "cart", value: "\(c.expenseCount)")
                statBubble(icon: "divide", value: String(format: "%.0f%@", c.perPerson, c.currency))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "bonscomptes://campaign/\(c.id)"))
    }

    func statBubble(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9))
            Text(value).font(.caption2).fontWeight(.medium)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Widget Declaration

struct BonsComptesHomeWidget: Widget {
    let kind = "BonsComptesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCampaignIntent.self, provider: BonsComptesWidgetProvider()) { entry in
            BonsComptesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Bons Comptes")
        .description("Campaign expense summary")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
