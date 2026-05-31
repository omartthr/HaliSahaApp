//
//  OnboardingAvailabilityScreen.swift
//  HaliSahaApp
//
//  Ekran 7/9 — Hangi gün/saatlerde oynamayı tercih ediyorsun?
//

import SwiftUI

struct OnboardingAvailabilityScreen: View {

    @ObservedObject var viewModel: OnboardingViewModel

    private let dayColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 4
    )

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                emoji: "⏰",
                title: "Ne zaman oynamak istersin?",
                subtitle: "Uygun olduğun gün ve saatleri seç."
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Days
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Günler")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: dayColumns, spacing: 8) {
                            ForEach(Weekday.allCases) { day in
                                OnboardingChip(
                                    title: day.shortName,
                                    isSelected: viewModel.preferredDays.contains(day),
                                    action: { toggle(day) }
                                )
                            }
                        }
                    }

                    // Time slots
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Saat aralığı")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        VStack(spacing: 10) {
                            ForEach(PlayTimeSlot.allCases) { slot in
                                OnboardingOptionCard(
                                    title: slot.displayName,
                                    subtitle: slot.subtitle,
                                    systemImage: slot.icon,
                                    isSelected: viewModel.preferredTimeSlots.contains(slot),
                                    action: { toggle(slot) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer(minLength: 8)

            PrimaryButton(
                title: "Devam",
                icon: "arrow.right",
                isDisabled: viewModel.preferredDays.isEmpty || viewModel.preferredTimeSlots.isEmpty
            ) {
                viewModel.goNext()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func toggle(_ day: Weekday) {
        if viewModel.preferredDays.contains(day) {
            viewModel.preferredDays.remove(day)
        } else {
            viewModel.preferredDays.insert(day)
        }
        viewModel.persistCurrentAnswer()
    }

    private func toggle(_ slot: PlayTimeSlot) {
        if viewModel.preferredTimeSlots.contains(slot) {
            viewModel.preferredTimeSlots.remove(slot)
        } else {
            viewModel.preferredTimeSlots.insert(slot)
        }
        viewModel.persistCurrentAnswer()
    }
}

#Preview {
    OnboardingAvailabilityScreen(viewModel: OnboardingViewModel())
}
