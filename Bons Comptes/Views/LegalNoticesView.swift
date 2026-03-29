//
//  LegalNoticesView.swift
//  Bons Comptes
//

import SwiftUI

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
