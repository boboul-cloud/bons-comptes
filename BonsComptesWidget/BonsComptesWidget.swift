//
//  BonsComptesWidget.swift
//  BonsComptesWidget
//
//  Widget showing campaign summary on Home Screen
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data Model (read from App Group UserDefaults)
// WidgetCampaignData is defined in Models/WidgetCampaignData.swift (shared between targets)

struct BonsComptesWidgetProvider: TimelineProvider {
    static let appGroupID = "group.com.bonscomptes.shared"

    func placeholder(in context: Context) -> BonsComptesWidgetEntry {
        BonsComptesWidgetEntry(date: Date(), campaign: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BonsComptesWidgetEntry) -> Void) {
        completion(BonsComptesWidgetEntry(date: Date(), campaign: loadCampaign()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BonsComptesWidgetEntry>) -> Void) {
        let entry = BonsComptesWidgetEntry(date: Date(), campaign: loadCampaign())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }

    private func loadCampaign() -> WidgetCampaignData? {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let data = defaults.data(forKey: "widgetCampaign"),
              let campaign = try? JSONDecoder().decode(WidgetCampaignData.self, from: data)
        else { return nil }
        return campaign
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
        StaticConfiguration(kind: kind, provider: BonsComptesWidgetProvider()) { entry in
            BonsComptesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Bons Comptes")
        .description("Campaign expense summary")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
