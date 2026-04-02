//
//  PremiumThankYouView.swift
//  Bons Comptes
//

import SwiftUI

struct PremiumThankYouView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showContent = false
    @State private var showFeatures = false
    @State private var confettiPhase = 0

    private let features: [(icon: String, color: Color, titleKey: String, descKey: String)] = [
        ("infinity", AppTheme.primary, "premium_unlimited_campaigns", "premium_unlimited_campaigns_desc"),
        ("doc.richtext", AppTheme.negative, "premium_pdf", "premium_pdf_desc"),
        ("doc.text.viewfinder", AppTheme.warning, "premium_scanner", "premium_scanner_desc"),
        ("qrcode", AppTheme.accent, "premium_sepa", "premium_sepa_desc"),
        ("antenna.radiowaves.left.and.right", AppTheme.info, "premium_proximity", "premium_proximity_desc"),
        ("clock.arrow.circlepath", AppTheme.primary, "premium_backups", "premium_backups_desc"),
        ("bolt.circle.fill", AppTheme.warning, "premium_live_activity", "premium_live_activity_desc")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()

                // Confetti particles
                ConfettiOverlay(phase: confettiPhase)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView {
                    VStack(spacing: 28) {
                        // Hero section
                        VStack(spacing: 20) {
                            ZStack {
                                // Pulsing ring
                                Circle()
                                    .stroke(
                                        LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 3
                                    )
                                    .frame(width: 130, height: 130)
                                    .scaleEffect(showContent ? 1.1 : 0.8)
                                    .opacity(showContent ? 0.4 : 0)

                                Circle()
                                    .fill(
                                        LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 110, height: 110)
                                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 20)

                                Image(systemName: "crown.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(showContent ? 0 : -20))
                            }
                            .scaleEffect(showContent ? 1 : 0.3)
                            .opacity(showContent ? 1 : 0)

                            VStack(spacing: 8) {
                                Text(NSLocalizedString("premium_thankyou_title", comment: ""))
                                    .font(.title).fontWeight(.bold)
                                    .multilineTextAlignment(.center)

                                Text(NSLocalizedString("premium_thankyou_subtitle", comment: ""))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1 : 0)
                        }
                        .padding(.top, 30)

                        // Badge
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            Text(NSLocalizedString("premium_thankyou_badge", comment: ""))
                                .font(.headline)
                                .foregroundStyle(
                                    LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .leading, endPoint: .trailing)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.primary.opacity(0.1))
                        )
                        .scaleEffect(showContent ? 1 : 0.8)
                        .opacity(showContent ? 1 : 0)

                        // Unlocked features
                        VStack(spacing: 0) {
                            Text(NSLocalizedString("premium_thankyou_unlocked", comment: ""))
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 8)

                            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                                if index > 0 {
                                    Divider().padding(.leading, 56)
                                }
                                featureRow(
                                    icon: feature.icon,
                                    color: feature.color,
                                    titleKey: feature.titleKey,
                                    descKey: feature.descKey
                                )
                                .offset(x: showFeatures ? 0 : 40)
                                .opacity(showFeatures ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.08),
                                    value: showFeatures
                                )
                            }
                        }
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.cardShadow, radius: AppTheme.cardShadowRadius, x: 0, y: 4)
                        .padding(.horizontal)

                        // Start button
                        Button(action: { dismiss() }) {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                Text(NSLocalizedString("premium_thankyou_start", comment: ""))
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [AppTheme.primary, AppTheme.accent], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .font(.headline)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: AppTheme.primary.opacity(0.3), radius: 10, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .opacity(showFeatures ? 1 : 0)
                        .animation(.easeOut.delay(0.8), value: showFeatures)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("close", comment: "")) { dismiss() }
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showFeatures = true
                confettiPhase += 1
            }
        }
    }

    private func featureRow(icon: String, color: Color, titleKey: String, descKey: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString(titleKey, comment: ""))
                    .font(.subheadline).fontWeight(.semibold)
                Text(NSLocalizedString(descKey, comment: ""))
                    .font(.caption).foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.positive)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    let phase: Int
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: phase) {
            launchConfetti()
        }
    }

    private func launchConfetti() {
        let colors: [Color] = [AppTheme.primary, AppTheme.accent, AppTheme.positive, AppTheme.warning, AppTheme.negative, AppTheme.info]
        var newParticles: [ConfettiParticle] = []
        for _ in 0..<60 {
            newParticles.append(ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 50...350), y: -20),
                opacity: 1.0
            ))
        }
        particles = newParticles

        // Animate falling
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let endY = CGFloat.random(in: 400...900)
            let drift = CGFloat.random(in: -80...80)
            withAnimation(.easeOut(duration: Double.random(in: 1.5...3.0)).delay(delay)) {
                particles[i].position = CGPoint(
                    x: particles[i].position.x + drift,
                    y: endY
                )
                particles[i].opacity = 0
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var position: CGPoint
    var opacity: Double
}
