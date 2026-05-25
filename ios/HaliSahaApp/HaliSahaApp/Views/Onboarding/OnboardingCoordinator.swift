//
//  OnboardingCoordinator.swift
//  HaliSahaApp
//
//  9 ekranlık onboarding akışının ana koordinatörü.
//

import SwiftUI

struct OnboardingCoordinator: View {

    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color { Color(hex: "2E7D32") }

    // İlk ekran (welcome) ve son ekran (ready) için progress bar gizlenir.
    private var showsHeader: Bool {
        viewModel.currentStep > 0 && viewModel.currentStep < viewModel.totalSteps - 1
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                if showsHeader {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                        .transition(.opacity)
                }

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Background
    private var backgroundLayer: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            // Yumuşak yeşil gradient blob — uygulama tonuyla uyumlu, dikkat dağıtmayan
            LinearGradient(
                colors: [
                    accent.opacity(colorScheme == .dark ? 0.18 : 0.08),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Header (progress + back/skip)
    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(Color.appCardBackground)
                        )
                }
                .opacity(viewModel.currentStep == 0 ? 0 : 1)
                .disabled(viewModel.currentStep == 0)

                OnboardingProgressBar(
                    currentStep: viewModel.currentStep + 1,
                    totalSteps: viewModel.totalSteps
                )
                .frame(maxWidth: .infinity)

                Button(action: {
                    let haptic = UIImpactFeedbackGenerator(style: .soft)
                    haptic.impactOccurred()
                    viewModel.goNext()
                }) {
                    Text("Atla")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(height: 36)
                        .padding(.horizontal, 8)
                }
                .opacity(canSkipCurrentStep ? 1 : 0)
                .disabled(!canSkipCurrentStep)
            }
        }
    }

    // Konum + bildirim ekranlarında "Atla" görünmesin — onların kendi "Şimdi değil" butonu var.
    // Welcome ve final ekranda da görünmez (header zaten saklı).
    private var canSkipCurrentStep: Bool {
        switch viewModel.currentStep {
        case 1, 2: return false
        default: return true
        }
    }

    // MARK: - Content (animated screens)
    @ViewBuilder
    private var content: some View {
        ZStack {
            switch viewModel.currentStep {
            case 0:
                OnboardingWelcomeScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 1:
                OnboardingLocationScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 2:
                OnboardingNotificationScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 3:
                OnboardingPositionScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 4:
                OnboardingFrequencyScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 5:
                OnboardingSkillLevelScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 6:
                OnboardingAvailabilityScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 7:
                OnboardingMotivationScreen(viewModel: viewModel)
                    .transition(screenTransition)
            case 8:
                OnboardingReadyScreen(viewModel: viewModel)
                    .transition(screenTransition)
            default:
                EmptyView()
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: viewModel.currentStep)
    }

    private var screenTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

#Preview {
    OnboardingCoordinator()
}
