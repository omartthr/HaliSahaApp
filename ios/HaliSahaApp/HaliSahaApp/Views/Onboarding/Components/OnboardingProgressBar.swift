//
//  OnboardingProgressBar.swift
//  HaliSahaApp
//
//  Faz bazlı segment progress göstergesi (welcome/permissions/profile).
//

import SwiftUI

struct OnboardingProgressBar: View {

    let currentStep: Int   // 1-based
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index < currentStep ? Color(hex: "2E7D32") : Color.gray.opacity(0.25))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 24) {
        OnboardingProgressBar(currentStep: 1, totalSteps: 9)
        OnboardingProgressBar(currentStep: 5, totalSteps: 9)
        OnboardingProgressBar(currentStep: 9, totalSteps: 9)
    }
    .padding()
}
