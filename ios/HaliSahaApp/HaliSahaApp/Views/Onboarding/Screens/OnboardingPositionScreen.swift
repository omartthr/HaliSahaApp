//
//  OnboardingPositionScreen.swift
//  HaliSahaApp
//
//  Ekran 4/9 — Mevki seçimi
//

import SwiftUI

struct OnboardingPositionScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel

    private let positions: [PlayerPosition] = [.goalkeeper, .defender, .midfielder, .forward]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                emoji: "⚽",
                title: "Hangi mevkide oynarsın?",
                subtitle: "Sahada en çok hangi pozisyonu seversin?"
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(positions, id: \.self) { position in
                            OnboardingPositionTile(
                                emoji: position.icon,
                                title: position.displayName,
                                isSelected: viewModel.position == position,
                                action: { select(position) }
                            )
                        }
                    }

                    OnboardingOptionCard(
                        title: "Fark etmez",
                        subtitle: "Her mevkide oynayabilirim",
                        systemImage: "shuffle",
                        isSelected: viewModel.position == .unspecified,
                        action: { select(.unspecified) }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer(minLength: 8)

            PrimaryButton(title: "Devam", icon: "arrow.right", isDisabled: viewModel.position == nil) {
                viewModel.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func select(_ position: PlayerPosition) {
        viewModel.position = position
        viewModel.persistCurrentAnswer()
    }
}

// MARK: - Shared header
struct OnboardingHeader: View {

    var emoji: String? = nil
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let emoji = emoji {
                Text(emoji)
                    .font(.system(size: 36))
            }
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingPositionScreen(viewModel: OnboardingViewModel())
}
