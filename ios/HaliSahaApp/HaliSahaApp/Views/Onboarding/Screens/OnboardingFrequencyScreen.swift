//
//  OnboardingFrequencyScreen.swift
//  HaliSahaApp
//
//  Ekran 5/9 — Haftada kaç kez oynuyorsun?
//

import SwiftUI

struct OnboardingFrequencyScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                emoji: "📅",
                title: "Ne sıklıkla oynuyorsun?",
                subtitle: "Genelde haftada kaç kez halı saha maçı yaparsın?"
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(PlayFrequency.allCases) { frequency in
                        OnboardingOptionCard(
                            title: frequency.displayName,
                            subtitle: frequency.subtitle,
                            systemImage: frequency.icon,
                            isSelected: viewModel.frequency == frequency,
                            action: { select(frequency) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer(minLength: 8)

            PrimaryButton(title: "Devam", icon: "arrow.right", isDisabled: viewModel.frequency == nil) {
                viewModel.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func select(_ frequency: PlayFrequency) {
        viewModel.frequency = frequency
        viewModel.persistCurrentAnswer()
    }
}

#Preview {
    OnboardingFrequencyScreen(viewModel: OnboardingViewModel())
}
