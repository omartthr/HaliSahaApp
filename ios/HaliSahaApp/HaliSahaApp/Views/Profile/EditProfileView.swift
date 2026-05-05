//
//  EditProfileView.swift
//  HaliSahaApp
//
//  Profil bilgilerini düzenleme ekranı
//

import SwiftUI

// MARK: - Edit Profile View
struct EditProfileView: View {

    // MARK: - Dependencies
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form State
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var phone: String = ""
    @State private var preferredPosition: PlayerPosition = .unspecified

    // MARK: - UI State
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    private let profileService = ProfileService.shared

    // MARK: - Validation
    private var firstNameError: String? {
        firstName.trimmingCharacters(in: .whitespaces).isEmpty ? "Ad gerekli" : nil
    }

    private var lastNameError: String? {
        lastName.trimmingCharacters(in: .whitespaces).isEmpty ? "Soyad gerekli" : nil
    }

    private var usernameError: String? {
        let result = FormValidator.validateUsername(username)
        return result.isValid ? nil : result.errorMessage
    }

    private var phoneError: String? {
        let result = FormValidator.validatePhone(phone)
        return result.isValid ? nil : result.errorMessage
    }

    private var isFormValid: Bool {
        firstNameError == nil
            && lastNameError == nil
            && usernameError == nil
            && phoneError == nil
    }

    private var hasChanges: Bool {
        guard let user = authService.currentUser else { return false }
        return user.firstName != firstName.trimmed
            || user.lastName != lastName.trimmed
            || user.username != username.trimmed.lowercased()
            || user.phone != phone.trimmed
            || user.preferredPosition != preferredPosition
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Personal Info
                personalInfoCard

                // Position
                positionCard

                // Save button
                PrimaryButton(
                    title: "Değişiklikleri Kaydet",
                    icon: "checkmark.circle.fill",
                    isLoading: isSaving,
                    isDisabled: !isFormValid || !hasChanges
                ) {
                    Task { await saveProfile() }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profili Düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentUser()
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Başarılı", isPresented: $showSuccess) {
            Button("Tamam", role: .cancel) { dismiss() }
        } message: {
            Text("Profil bilgileriniz güncellendi.")
        }
    }

    // MARK: - Personal Info Card
    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Kişisel Bilgiler")
                    .font(.headline)
            } icon: {
                Image(systemName: "person.text.rectangle.fill")
                    .foregroundColor(Color(hex: "2E7D32"))
            }

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    CustomTextField(
                        title: "Ad",
                        placeholder: "Adınız",
                        text: $firstName,
                        icon: "person.fill",
                        textContentType: .givenName,
                        errorMessage: nil
                    )

                    CustomTextField(
                        title: "Soyad",
                        placeholder: "Soyadınız",
                        text: $lastName,
                        textContentType: .familyName,
                        errorMessage: nil
                    )
                }

                CustomTextField(
                    title: "Kullanıcı Adı",
                    placeholder: "kullanici_adi",
                    text: $username,
                    icon: "at",
                    autocapitalization: .never,
                    errorMessage: !username.isEmpty ? usernameError : nil
                )

                CustomTextField.phone(
                    text: $phone,
                    errorMessage: !phone.isEmpty ? phoneError : nil
                )

                // E-posta (read-only)
                emailReadOnlyRow
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Email Read Only
    private var emailReadOnlyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("E-posta")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24)

                Text(authService.currentUser?.email ?? "—")
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadiusMedium)
                    .fill(Color(.systemGray6).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadiusMedium)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            Text("E-posta adresi güvenlik nedeniyle değiştirilemez.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Position Card
    private var positionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Tercih Ettiğin Mevki")
                    .font(.headline)
            } icon: {
                Image(systemName: "sportscourt.fill")
                    .foregroundColor(Color(hex: "2E7D32"))
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(PlayerPosition.allCases, id: \.self) { position in
                    PositionChip(
                        position: position,
                        isSelected: preferredPosition == position
                    ) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            preferredPosition = position
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Helpers
    private func loadCurrentUser() {
        guard let user = authService.currentUser else { return }
        firstName = user.firstName
        lastName = user.lastName
        username = user.username
        phone = user.phone
        preferredPosition = user.preferredPosition
    }

    @MainActor
    private func saveProfile() async {
        isSaving = true
        do {
            let updated = try await profileService.updateProfile(
                firstName: firstName.trimmed,
                lastName: lastName.trimmed,
                username: username.trimmed.lowercased(),
                phone: phone.trimmed,
                preferredPosition: preferredPosition
            )
            authService.currentUser = updated
            isSaving = false
            showSuccess = true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Position Chip
struct PositionChip: View {
    let position: PlayerPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(position.icon)
                    .font(.title3)

                Text(position.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "2E7D32") : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(hex: "2E7D32") : Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EditProfileView()
    }
}
