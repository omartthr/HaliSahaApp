//
//  ChangePasswordView.swift
//  HaliSahaApp
//
//  Şifre değiştirme ekranı (mevcut şifre ile reauthentication)
//

import SwiftUI

// MARK: - Change Password View
struct ChangePasswordView: View {

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    private let profileService = ProfileService.shared

    // MARK: - State
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    // MARK: - Validation
    private var newPasswordStrength: PasswordStrength {
        PasswordStrength.evaluate(newPassword)
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && newPassword == confirmPassword
    }

    private var newPasswordError: String? {
        guard !newPassword.isEmpty else { return nil }
        if newPassword.count < AppConstants.minPasswordLength {
            return "Yeni şifre en az \(AppConstants.minPasswordLength) karakter olmalı"
        }
        if newPassword == currentPassword {
            return "Yeni şifre eskisinden farklı olmalı"
        }
        return nil
    }

    private var confirmPasswordError: String? {
        guard !confirmPassword.isEmpty else { return nil }
        return passwordsMatch ? nil : "Şifreler eşleşmiyor"
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty
            && !newPassword.isEmpty
            && newPassword.count >= AppConstants.minPasswordLength
            && passwordsMatch
            && newPassword != currentPassword
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2E7D32").opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "2E7D32"))
                    }

                    Text("Şifre Değiştir")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Güvenliğiniz için yeni bir şifre belirleyin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                // Form
                VStack(spacing: 16) {
                    CustomTextField.password(
                        title: "Mevcut Şifre",
                        text: $currentPassword
                    )

                    CustomTextField.password(
                        title: "Yeni Şifre",
                        text: $newPassword,
                        errorMessage: newPasswordError
                    )

                    if !newPassword.isEmpty {
                        PasswordStrengthView(strength: newPasswordStrength)
                    }

                    CustomTextField.password(
                        title: "Yeni Şifre (Tekrar)",
                        text: $confirmPassword,
                        errorMessage: confirmPasswordError
                    )

                    if !confirmPassword.isEmpty && passwordsMatch {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Şifreler eşleşiyor")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)

                // Save Button
                PrimaryButton(
                    title: "Şifreyi Güncelle",
                    icon: "checkmark",
                    isLoading: isSaving,
                    isDisabled: !isFormValid
                ) {
                    Task { await changePassword() }
                }

                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Güçlü Şifre İpuçları")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TipRow(text: "En az 8 karakter kullanın")
                        TipRow(text: "Büyük ve küçük harf birlikte olsun")
                        TipRow(text: "En az bir rakam veya özel karakter ekleyin")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Şifre Değiştir")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Başarılı", isPresented: $showSuccess) {
            Button("Tamam", role: .cancel) { dismiss() }
        } message: {
            Text("Şifreniz başarıyla güncellendi.")
        }
    }

    // MARK: - Actions
    @MainActor
    private func changePassword() async {
        isSaving = true
        do {
            try await profileService.changePassword(
                current: currentPassword,
                new: newPassword
            )
            isSaving = false
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            showSuccess = true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Tip Row
private struct TipRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ChangePasswordView()
    }
}
