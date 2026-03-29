//
//  PrivacyPolicyView.swift
//  Bons Comptes
//

import SwiftUI

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
