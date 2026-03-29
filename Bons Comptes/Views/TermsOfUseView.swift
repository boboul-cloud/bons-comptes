//
//  TermsOfUseView.swift
//  Bons Comptes
//

import SwiftUI

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
