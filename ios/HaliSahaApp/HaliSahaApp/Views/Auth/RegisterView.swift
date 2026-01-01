//
//  RegisterView.swift
//  HaliSahaApp
//
//  Kullanıcı kayıt ekranı
//
//  Created by Mehmet Mert Mazıcı on 24.12.2025.
//


import SwiftUI

// MARK: - Register View
struct RegisterView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    private let totalSteps = 3
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            progressBar
            
            ScrollView {
                VStack(spacing: 24) {
                    // Step Content
                    stepContent
                    
                    // Navigation Buttons
                    navigationButtons
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Kayıt Ol")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if currentStep > 0 {
                        withAnimation {
                            currentStep -= 1
                        }
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color(hex: "2E7D32") : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            
            Text(stepTitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Step Title
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Adım 1/3: Hesap Bilgileri"
        case 1: return "Adım 2/3: Kişisel Bilgiler"
        case 2: return "Adım 3/3: Tercihler"
        default: return ""
        }
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            accountInfoStep
        case 1:
            personalInfoStep
        case 2:
            preferencesStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Account Info
    private var accountInfoStep: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "2E7D32"))
                
                Text("Hesap Bilgilerinizi Girin")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 12)
            
            // Form
            VStack(spacing: 16) {
                CustomTextField.email(text: $viewModel.email)
                
                CustomTextField.password(
                    title: "Şifre",
                    text: $viewModel.password
                )
                
                // Password Strength
                if !viewModel.password.isEmpty {
                    PasswordStrengthView(strength: viewModel.passwordStrength)
                }
                
                CustomTextField.password(
                    title: "Şifre Tekrar",
                    text: $viewModel.confirmPassword
                )
                
                // Password Match Indicator
                if !viewModel.confirmPassword.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(viewModel.passwordsMatch ? "Şifreler eşleşiyor" : "Şifreler eşleşmiyor")
                    }
                    .font(.caption)
                    .foregroundColor(viewModel.passwordsMatch ? .green : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
    
    // MARK: - Step 2: Personal Info
    private var personalInfoStep: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "2E7D32"))
                
                Text("Kişisel Bilgilerinizi Girin")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 12)
            
            // Form
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CustomTextField(
                        title: "Ad",
                        placeholder: "Adınız",
                        text: $viewModel.firstName,
                        icon: "person.fill",
                        textContentType: .givenName
                    )
                    
                    CustomTextField(
                        title: "Soyad",
                        placeholder: "Soyadınız",
                        text: $viewModel.lastName,
                        textContentType: .familyName
                    )
                }
                
                CustomTextField(
                    title: "Kullanıcı Adı",
                    placeholder: "kullanici_adi",
                    text: $viewModel.username,
                    icon: "at",
                    autocapitalization: .never
                )
                
                CustomTextField.phone(text: $viewModel.phone)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
    
    // MARK: - Step 3: Preferences
    private var preferencesStep: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "2E7D32"))
                
                Text("Tercih Ettiğiniz Mevki")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Maçlarda oynamayı tercih ettiğiniz pozisyonu seçin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 12)
            
            // Position Selection
            VStack(spacing: 12) {
                ForEach(PlayerPosition.allCases, id: \.self) { position in
                    PositionSelectionRow(
                        position: position,
                        isSelected: viewModel.preferredPosition == position
                    ) {
                        viewModel.preferredPosition = position
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
            
            // Info Text
            Text("Bu bilgi, sizi maça davet eden kişilere yardımcı olacaktır.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if currentStep < totalSteps - 1 {
                // Next Button
                PrimaryButton(
                    title: "Devam Et",
                    icon: "arrow.right",
                    isDisabled: !isCurrentStepValid
                ) {
                    withAnimation {
                        currentStep += 1
                    }
                }
            } else {
                // Register Button
                PrimaryButton(
                    title: "Kayıt Ol",
                    icon: "checkmark",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isRegisterFormValid
                ) {
                    Task {
                        await viewModel.register()
                    }
                }
            }
            
            // Admin Register Link
            if currentStep == 0 {
                HStack(spacing: 4) {
                    Text("Saha sahibi misiniz?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    NavigationLink {
                        AdminRegisterView(viewModel: viewModel)
                    } label: {
                        Text("İşletme Kaydı")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Validation
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0:
            return FormValidator.validateEmail(viewModel.email).isValid &&
            FormValidator.validatePassword(viewModel.password).isValid &&
            viewModel.passwordsMatch
        case 1:
            return !viewModel.firstName.trimmed.isEmpty &&
            !viewModel.lastName.trimmed.isEmpty &&
            FormValidator.validateUsername(viewModel.username).isValid &&
            FormValidator.validatePhone(viewModel.phone).isValid
        case 2:
            return true
        default:
            return false
        }
    }
}

// MARK: - Password Strength View
struct PasswordStrengthView: View {
    let strength: PasswordStrength
    
    var body: some View {
        HStack(spacing: 8) {
            // Bars
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { level in
                    Capsule()
                        .fill(level <= strength.rawValue ? strength.color : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .frame(width: 60)
            
            Text(strength.displayName)
                .font(.caption)
                .foregroundColor(strength.color)
            
            Spacer()
        }
    }
}

// MARK: - Position Selection Row
struct PositionSelectionRow: View {
    let position: PlayerPosition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Text(position.icon)
                    .font(.title2)
                
                // Name
                Text(position.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "2E7D32").opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "2E7D32") : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RegisterView(viewModel: AuthViewModel())
    }
}
