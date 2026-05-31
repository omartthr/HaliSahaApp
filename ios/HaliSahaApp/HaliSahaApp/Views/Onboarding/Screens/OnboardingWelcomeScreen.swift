//
//  OnboardingWelcomeScreen.swift
//  HaliSahaApp
//
//  Ekran 1/9 — Hoş geldin + değer önermesi
//

import SwiftUI

struct OnboardingWelcomeScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel
    @State private var appear = false

    private var accent: Color { Color(hex: "2E7D32") }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)

            OnboardingLottieView(animationName: "ball")
                .frame(width: 360, height: 360)
                .scaleEffect(appear ? 1 : 0.85)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.7), value: appear)

            Spacer(minLength: 24)

            VStack(spacing: 16) {
                Text("Saha senin,\ntakım hazır.")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: appear)

                Text("Yakındaki halı sahaları bul, maçını kur, oyna. Hepsi tek bir uygulamada.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: appear)
            }

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(title: "Hadi başlayalım", icon: "arrow.right") {
                    viewModel.goNext()
                }

                Text("Kayıt olurken birkaç hızlı soru soracağız — bu sayede sana özel sahaları ve maçları önerebileceğiz.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(appear ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appear)
        }
        .onAppear { appear = true }
    }
}

#Preview {
    OnboardingWelcomeScreen(viewModel: OnboardingViewModel())
}
