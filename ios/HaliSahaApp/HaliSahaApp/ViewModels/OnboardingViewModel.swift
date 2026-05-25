//
//  OnboardingViewModel.swift
//  HaliSahaApp
//
//  Onboarding akışı durumu + Firestore'a kademeli kayıt.
//

import Foundation
import SwiftUI
import CoreLocation
import UserNotifications

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Step Index
    @Published var currentStep: Int = 0   // 0..8 (9 ekran)
    let totalSteps: Int = 9

    // MARK: - Answers
    @Published var position: PlayerPosition? = nil
    @Published var frequency: PlayFrequency? = nil
    @Published var skillLevel: SkillLevel? = nil
    @Published var preferredDays: Set<Weekday> = []
    @Published var preferredTimeSlots: Set<PlayTimeSlot> = []
    @Published var motivations: Set<Motivation> = []

    // MARK: - State
    @Published var isFinalizing: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies
    private let profileService = ProfileService.shared
    private let authService = AuthService.shared
    private let locationManager = LocationManager.shared
    private let notificationService = NotificationService.shared

    // MARK: - Navigation
    func goNext() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep += 1
        }
    }

    func goBack() {
        guard currentStep > 0 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep -= 1
        }
    }

    func skipToEnd() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = totalSteps - 1
        }
    }

    // MARK: - Permissions
    func requestLocationPermission() async {
        locationManager.requestPermission()
        // Sistem dialog'u async değil — kullanıcı kararını bekleyip otomatik next.
        try? await Task.sleep(nanoseconds: 600_000_000)
        goNext()
    }

    func requestNotificationPermission() async {
        _ = await notificationService.requestPermission()
        try? await Task.sleep(nanoseconds: 300_000_000)
        goNext()
    }

    // MARK: - Persistence (incremental)
    /// Her cevap seçildiğinde Firestore'a partial update gönder. Guest user için no-op.
    func persistCurrentAnswer() {
        guard let user = authService.currentUser, user.userType != .guest else { return }

        var fields: [String: Any] = [:]
        if let position = position { fields["preferredPosition"] = position.rawValue }
        if let frequency = frequency { fields["playFrequency"] = frequency.rawValue }
        if let skillLevel = skillLevel { fields["skillLevel"] = skillLevel.rawValue }
        if !preferredDays.isEmpty {
            fields["preferredDays"] = preferredDays.map(\.rawValue)
        }
        if !preferredTimeSlots.isEmpty {
            fields["preferredTimeSlots"] = preferredTimeSlots.map(\.rawValue)
        }
        if !motivations.isEmpty {
            fields["motivations"] = motivations.map(\.rawValue)
        }

        guard !fields.isEmpty else { return }

        Task { [weak self] in
            try? await self?.profileService.updateOnboardingFields(fields)
        }
    }

    // MARK: - Finalize
    /// Son ekranda çağrılır: tüm cevapları + completion timestamp'i yazıp ana ekrana yönlendirir.
    func finalize() async {
        isFinalizing = true
        defer { isFinalizing = false }

        guard let user = authService.currentUser, user.userType != .guest else {
            // Guest kullanıcı için sadece local state'i güncelle
            return
        }

        do {
            // Önce tüm cevapları flush et
            var fields: [String: Any] = [:]
            if let position = position { fields["preferredPosition"] = position.rawValue }
            if let frequency = frequency { fields["playFrequency"] = frequency.rawValue }
            if let skillLevel = skillLevel { fields["skillLevel"] = skillLevel.rawValue }
            fields["preferredDays"] = preferredDays.map(\.rawValue)
            fields["preferredTimeSlots"] = preferredTimeSlots.map(\.rawValue)
            fields["motivations"] = motivations.map(\.rawValue)

            if !fields.isEmpty {
                try await profileService.updateOnboardingFields(fields)
            }

            // Sonra tamamlanma damgasını vur ve user'ı refresh et
            let updatedUser = try await profileService.completeOnboarding()
            authService.currentUser = updatedUser
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
