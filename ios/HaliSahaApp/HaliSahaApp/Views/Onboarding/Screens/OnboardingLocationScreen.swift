//
//  OnboardingLocationScreen.swift
//  HaliSahaApp
//
//  Ekran 2/9 — Konum izni context screen
//

import SwiftUI

struct OnboardingLocationScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isRequesting = false

    private var accent: Color { Color(hex: "2E7D32") }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            OnboardingLottieView(animationName: "Location_Pin")
                .frame(width: 220, height: 220)

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                Text("Yakındaki sahaları görelim")
                    .font(.system(size: 26, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Konumunu kullanarak sana en yakın halı sahaları ve maçları öneriyoruz.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                bulletRow(icon: "mappin.and.ellipse", text: "En yakın sahaları listele")
                bulletRow(icon: "figure.run", text: "Mesafe bazlı maç önerileri")
                bulletRow(icon: "lock.shield.fill", text: "Arka planda asla takip etmiyoruz")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
            )
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Konuma izin ver",
                    icon: "location.fill",
                    isLoading: isRequesting
                ) {
                    Task {
                        isRequesting = true
                        await viewModel.requestLocationPermission()
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
    OnboardingLocationScreen(viewModel: OnboardingViewModel())
}
