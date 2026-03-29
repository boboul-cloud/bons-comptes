//
//  Theme.swift
//  Bons Comptes
//

import SwiftUI

enum AppTheme {
    // MARK: - Primary Colors
    static let primary = Color(hex: "6C5CE7")
    static let primaryLight = Color(hex: "A29BFE")
    static let primaryDark = Color(hex: "4834D4")

    // MARK: - Accent Colors
    static let accent = Color(hex: "00CEC9")
    static let accentLight = Color(hex: "81ECEC")

    // MARK: - Semantic Colors
    static let positive = Color(hex: "00B894")
    static let negative = Color(hex: "E17055")
    static let warning = Color(hex: "FDCB6E")
    static let info = Color(hex: "74B9FF")

    // MARK: - Background
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "6C5CE7").opacity(0.08), Color(hex: "00CEC9").opacity(0.05), Color(.systemBackground)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color(.secondarySystemBackground)

    // MARK: - Gradients
    static let headerGradient = LinearGradient(
        colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let expenseGradient = LinearGradient(
        colors: [Color(hex: "E17055"), Color(hex: "D63031")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let reimbursementGradient = LinearGradient(
        colors: [Color(hex: "00B894"), Color(hex: "00CEC9")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.08)
    static let cardShadowRadius: CGFloat = 8
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Card Modifier
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppTheme.cardShadow, radius: AppTheme.cardShadowRadius, x: 0, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func animatedAppear(delay: Double = 0) -> some View {
        self.modifier(AnimatedAppearModifier(delay: delay))
    }
}

// MARK: - Animated Appear
struct AnimatedAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Gradient Badge
struct GradientBadge: View {
    let text: String
    let gradient: LinearGradient

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(gradient)
            .clipShape(Capsule())
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    let emoji: String
    let size: CGFloat

    init(_ emoji: String, size: CGFloat = 40) {
        self.emoji = emoji
        self.size = size
    }

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(AppTheme.primaryLight.opacity(0.2))
            .clipShape(Circle())
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
