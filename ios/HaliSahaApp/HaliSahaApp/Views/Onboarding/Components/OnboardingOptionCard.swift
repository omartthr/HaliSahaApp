//
//  OnboardingOptionCard.swift
//  HaliSahaApp
//
//  Onboarding ekranlarında seçilebilir kart bileşenleri.
//

import SwiftUI

// MARK: - Selectable Card (with title + subtitle + icon)
struct OnboardingOptionCard: View {

    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var emoji: String? = nil
    let isSelected: Bool
    let action: () -> Void

    private var accent: Color { Color(hex: "2E7D32") }

    var body: some View {
        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                iconView

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .stroke(isSelected ? accent : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(accent)
                            .frame(width: 16, height: 16)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accent.opacity(0.08) : Color.appCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accent : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? accent.opacity(0.15) : Color.gray.opacity(0.1))
                .frame(width: 48, height: 48)

            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: 24))
            } else if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? accent : .secondary)
            }
        }
    }
}

// MARK: - Compact Chip
struct OnboardingChip: View {

    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    private var accent: Color { Color(hex: "2E7D32") }

    var body: some View {
        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            action()
        }) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? accent : Color.appCardBackground)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? accent : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Position Tile (square grid card)
struct OnboardingPositionTile: View {

    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    private var accent: Color { Color(hex: "2E7D32") }

    var body: some View {
        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            action()
        }) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 44))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? accent.opacity(0.1) : Color.appCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? accent : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            OnboardingOptionCard(
                title: "Haftada 1",
                subtitle: "Düzenli olarak oynarım",
                systemImage: "calendar.badge.clock",
                isSelected: true,
                action: {}
            )
            OnboardingOptionCard(
                title: "Ayda 1-2",
                subtitle: "Ara sıra oynuyorum",
                systemImage: "calendar",
                isSelected: false,
                action: {}
            )

            HStack {
                OnboardingChip(title: "Pzt", isSelected: true, action: {})
                OnboardingChip(title: "Sal", isSelected: false, action: {})
                OnboardingChip(title: "Çar", isSelected: false, action: {})
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                OnboardingPositionTile(emoji: "🧤", title: "Kaleci", isSelected: false, action: {})
                OnboardingPositionTile(emoji: "🛡️", title: "Defans", isSelected: true, action: {})
                OnboardingPositionTile(emoji: "⚙️", title: "Orta Saha", isSelected: false, action: {})
                OnboardingPositionTile(emoji: "⚽", title: "Forvet", isSelected: false, action: {})
            }
        }
        .padding()
    }
}
