//
//  OnboardingNotificationScreen.swift
//  HaliSahaApp
//
//  Ekran 3/9 — Bildirim izni context screen (Notification_bell lottie ile)
//

import SwiftUI

struct OnboardingNotificationScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isRequesting = false

    private var accent: Color { Color(hex: "2E7D32") }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            OnboardingLottieView(animationName: "Notification_bell")
                .frame(width: 220, height: 220)

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                Text("Maçını kaçırma")
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Önemli güncellemeleri sana anında ulaştıralım.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                bulletRow(icon: "checkmark.seal.fill", text: "Rezervasyon onayları")
                bulletRow(icon: "clock.badge.fill", text: "Maç hatırlatıcıları (2 saat öncesi)")
                bulletRow(icon: "bubble.left.and.bubble.right.fill", text: "Takım sohbeti mesajları")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
            )
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Bildirimleri aç",
                    icon: "bell.fill",
                    isLoading: isRequesting
                ) {
                    Task {
                        isRequesting = true
                        await viewModel.requestNotificationPermission()
                        isRequesting = false
                    }
                }

                Button("Şimdi değil") {
                    viewModel.goNext()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

#Preview {
    OnboardingNotificationScreen(viewModel: OnboardingViewModel())
}
