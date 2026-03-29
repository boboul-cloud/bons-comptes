//
//  AboutView.swift
//  Bons Comptes
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    appHeader
                    infoCard
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(NSLocalizedString("about_section", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "eurosign.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.white, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Bons Comptes")
                .font(.title).fontWeight(.bold)
            Text("v1.0.0")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppTheme.headerGradient)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("about_description", comment: ""))
                .font(.subheadline).foregroundColor(.secondary)

            Divider()

            infoRow(icon: "person.fill", label: NSLocalizedString("developer_label", comment: ""), value: "Robert Oulhen")
            linkRow(icon: "envelope.fill", label: NSLocalizedString("contact_label", comment: ""), value: "bob.oulhen@gmail.com", url: URL(string: "mailto:bob.oulhen@gmail.com")!)
            linkRow(icon: "globe", label: NSLocalizedString("website_label", comment: ""), value: "boboul-cloud.github.io", url: URL(string: "https://boboul-cloud.github.io/bons-comptes/app.html")!)
        }
        .cardStyle()
    }

    func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.primary.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.caption).foregroundColor(AppTheme.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value).font(.subheadline)
            }
            Spacer()
        }
    }

    func linkRow(icon: String, label: String, value: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(AppTheme.primary.opacity(0.1)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.caption).foregroundColor(AppTheme.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption).foregroundColor(.secondary)
                    Text(value).font(.subheadline).foregroundColor(AppTheme.primary)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}
