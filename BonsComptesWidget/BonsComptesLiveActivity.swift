//
//  BonsComptesLiveActivity.swift
//  BonsComptesWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BonsComptesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BonsComptesActivityAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.campaignTitle)
                            .font(.caption).fontWeight(.bold)
                        Text("\(context.attributes.participantCount) pers.")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f%@", context.state.totalExpenses, context.attributes.currency))
                            .font(.title3).fontWeight(.bold)
                        Text(String(format: "%.0f%@/pers", context.state.perPerson, context.attributes.currency))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.lastExpenseTitle.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "cart.fill").font(.caption2)
                            Text(context.state.lastExpenseTitle)
                                .font(.caption).lineLimit(1)
                            Spacer()
                            Text("\(context.state.expenseCount)")
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(String(format: "%.0f%@", context.state.totalExpenses, context.attributes.currency))
                    .font(.caption).fontWeight(.bold)
            } minimal: {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
            }
        }
    }

    func lockScreenView(context: ActivityViewContext<BonsComptesActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.campaignTitle)
                    .font(.headline).fontWeight(.bold)
                HStack(spacing: 4) {
                    Image(systemName: "person.2").font(.caption2)
                    Text("\(context.attributes.participantCount)")
                        .font(.caption)
                    Text("•").foregroundColor(.secondary)
                    Image(systemName: "cart").font(.caption2)
                    Text("\(context.state.expenseCount)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                if !context.state.lastExpenseTitle.isEmpty {
                    Text(context.state.lastExpenseTitle)
                        .font(.caption2).foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f%@", context.state.totalExpenses, context.attributes.currency))
                    .font(.title2).fontWeight(.bold)
                Text(String(format: "%.0f%@/pers", context.state.perPerson, context.attributes.currency))
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
    }
}
