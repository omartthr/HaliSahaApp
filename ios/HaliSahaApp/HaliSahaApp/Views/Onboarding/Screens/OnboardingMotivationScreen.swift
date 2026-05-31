//
//  OnboardingMotivationScreen.swift
//  HaliSahaApp
//
//  Ekran 8/9 — Halı sahaya neden geliyorsun? (kişisel)
//

import SwiftUI

struct OnboardingMotivationScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel

    private let maxSelections = 2

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                emoji: "✨",
                title: "Neden geliyorsun?",
                subtitle: "Halı sahaya gelme amacın ne? En fazla \(maxSelections) tane seçebilirsin."
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Motivation.allCases) { motivation in
                        OnboardingOptionCard(
                            title: motivation.displayName,
                            emoji: motivation.emoji,
                            isSelected: viewModel.motivations.contains(motivation),
                            action: { toggle(motivation) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer(minLength: 8)

            PrimaryButton(
                title: "Devam",
                icon: "arrow.right",
                isDisabled: viewModel.motivations.isEmpty
            ) {
                viewModel.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func toggle(_ motivation: Motivation) {
        if viewModel.motivations.contains(motivation) {
            viewModel.motivations.remove(motivation)
        } else {
            guard viewModel.motivations.count < maxSelections else {
                // Limit aşımı için kibar haptic feedback
                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(.warning)
                return
            }
            viewModel.motivations.insert(motivation)
        }
        viewModel.persistCurrentAnswer()
    }
}

#Preview {
    OnboardingMotivationScreen(viewModel: OnboardingViewModel())
}
