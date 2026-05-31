//
//  OnboardingReadyScreen.swift
//  HaliSahaApp
//
//  Ekran 9/9 — Hazırsın! (confetti + finalize)
//

import SwiftUI

struct OnboardingReadyScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var authService = AuthService.shared
    @State private var appear = false

    private var accent: Color { Color(hex: "2E7D32") }

    private var firstName: String {
        let name = authService.currentUser?.firstName ?? ""
        return name.isEmpty ? "Hazırsın" : name
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .scaleEffect(appear ? 1 : 0.6)

                Image(systemName: "checkmark")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(accent)
                    .scaleEffect(appear ? 1 : 0.3)
                    .opacity(appear ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appear)

            Spacer(minLength: 32)

            VStack(spacing: 12) {
                Text("Hoş geldin, \(firstName)! 🎉")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)

                Text("Profilini hazırladık. Artık sana uygun sahaları ve maçları önerebiliriz.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.2), value: appear)

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(
                    title: "Keşfetmeye başla",
                    icon: "sparkles",
                    isLoading: viewModel.isFinalizing
                ) {
                    Task {
                        await viewModel.finalize()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            // Confetti, içeriğin üstünde non-interactive overlay olarak; layout'u etkilemiyor.
            OnboardingLottieView(animationName: "confetti", loopMode: .playOnce)
                .frame(height: 360)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
                .opacity(appear ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: appear)
        }
        .onAppear {
            appear = true
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.success)
        }
    }
}

#Preview {
    OnboardingReadyScreen(viewModel: OnboardingViewModel())
}
