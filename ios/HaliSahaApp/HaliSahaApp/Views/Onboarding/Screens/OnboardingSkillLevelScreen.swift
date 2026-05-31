//
//  OnboardingSkillLevelScreen.swift
//  HaliSahaApp
//
//  Ekran 6/9 — Seviye seçimi
//

import SwiftUI

struct OnboardingSkillLevelScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                emoji: "🎯",
                title: "Kendini nasıl tanımlarsın?",
                subtitle: "Seviyene uygun oyuncularla eşleştirebilelim."
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(SkillLevel.onboardingCases, id: \.self) { level in
                        OnboardingOptionCard(
                            title: level.displayName,
                            subtitle: level.onboardingSubtitle,
                            emoji: level.onboardingEmoji,
                            isSelected: viewModel.skillLevel == level,
                            action: { select(level) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer(minLength: 8)

            PrimaryButton(title: "Devam", icon: "arrow.right", isDisabled: viewModel.skillLevel == nil) {
                viewModel.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func select(_ level: SkillLevel) {
        viewModel.skillLevel = level
        viewModel.persistCurrentAnswer()
    }
}

#Preview {
    OnboardingSkillLevelScreen(viewModel: OnboardingViewModel())
}
