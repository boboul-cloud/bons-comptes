//
//  LegalView.swift
//  Bons Comptes
//
//  Shared helper used by legal views
//

import SwiftUI

func legalSection(title: String, body: String) -> some View {
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
