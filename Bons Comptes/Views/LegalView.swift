//
//  LegalView.swift
//  Bons Comptes
//

import SwiftUI

// MARK: - About

struct AboutView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // App Header
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
                .padding(.vertical)
            }
        }
        .navigationTitle(NSLocalizedString("about_section", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("privacy_last_updated", comment: ""))
                        .font(.caption).foregroundColor(.secondary)

                    legalSection(
                        title: NSLocalizedString("privacy_intro_title", comment: ""),
                        body: NSLocalizedString("privacy_intro_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("privacy_data_title", comment: ""),
                        body: NSLocalizedString("privacy_data_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("privacy_storage_title", comment: ""),
                        body: NSLocalizedString("privacy_storage_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("privacy_sharing_title", comment: ""),
                        body: NSLocalizedString("privacy_sharing_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("privacy_rights_title", comment: ""),
                        body: NSLocalizedString("privacy_rights_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("privacy_contact_title", comment: ""),
                        body: NSLocalizedString("privacy_contact_body", comment: "")
                    )
                }
                .padding()
            }
        }
        .navigationTitle(NSLocalizedString("privacy_policy", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Use

struct TermsOfUseView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("terms_last_updated", comment: ""))
                        .font(.caption).foregroundColor(.secondary)

                    legalSection(
                        title: NSLocalizedString("terms_acceptance_title", comment: ""),
                        body: NSLocalizedString("terms_acceptance_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("terms_description_title", comment: ""),
                        body: NSLocalizedString("terms_description_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("terms_usage_title", comment: ""),
                        body: NSLocalizedString("terms_usage_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("terms_liability_title", comment: ""),
                        body: NSLocalizedString("terms_liability_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("terms_ip_title", comment: ""),
                        body: NSLocalizedString("terms_ip_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("terms_modifications_title", comment: ""),
                        body: NSLocalizedString("terms_modifications_body", comment: "")
                    )
                }
                .padding()
            }
        }
        .navigationTitle(NSLocalizedString("terms_of_use", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Legal Notices

struct LegalNoticesView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    legalSection(
                        title: NSLocalizedString("legal_publisher_title", comment: ""),
                        body: NSLocalizedString("legal_publisher_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("legal_hosting_title", comment: ""),
                        body: NSLocalizedString("legal_hosting_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("legal_credits_title", comment: ""),
                        body: NSLocalizedString("legal_credits_body", comment: "")
                    )
                    legalSection(
                        title: NSLocalizedString("legal_law_title", comment: ""),
                        body: NSLocalizedString("legal_law_body", comment: "")
                    )
                }
                .padding()
            }
        }
        .navigationTitle(NSLocalizedString("legal_notices", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared Helper

private func legalSection(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.headline).fontWeight(.bold)
        Text(body)
            .font(.subheadline).foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
}
