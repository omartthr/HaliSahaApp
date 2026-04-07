//
//  AdminRegisterView.swift
//  HaliSahaApp
//
//  Saha sahibi (Admin) kayıt ekranı
//
//  Created by Mehmet Mert Mazıcı on 24.12.2025.
//


import SwiftUI

// MARK: - Admin Register View
struct AdminRegisterView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    private let totalSteps = 2
    
    @State private var agreedToTerms = false
    
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
        .navigationTitle("İşletme Kaydı")
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
        .alert("Başarılı", isPresented: $viewModel.showSuccessAlert) {
            Button("Tamam", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage)
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
        case 0: return "Adım 1/2: Hesap Bilgileri"
        case 1: return "Adım 2/2: İşletme Bilgileri"
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
            businessInfoStep
        default:
            EmptyView()
        }
    }
    
    // MARK: - Step 1: Account Info
    private var accountInfoStep: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "2E7D32").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 35))
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                
                Text("Saha Sahibi Hesabı Oluştur")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("İşletmenizi yönetmek ve rezervasyon almak için kayıt olun")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
                
                CustomTextField.email(text: $viewModel.email)
                
                CustomTextField.password(text: $viewModel.password)
                
                // Password Strength
                if !viewModel.password.isEmpty {
                    PasswordStrengthView(strength: viewModel.passwordStrength)
                }
                
                CustomTextField.password(
                    title: "Şifre Tekrar",
                    text: $viewModel.confirmPassword
                )
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
    
    // MARK: - Step 2: Business Info
    private var businessInfoStep: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "2E7D32").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 35))
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                
                Text("İşletme Bilgilerinizi Girin")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 12)
            
            // Form
            VStack(spacing: 16) {
                CustomTextField(
                    title: "İşletme Adı",
                    placeholder: "Halı Saha İşletmesi",
                    text: $viewModel.businessName,
                    icon: "building.2.fill"
                )
                
                CustomTextField(
                    title: "Vergi Numarası",
                    placeholder: "1234567890",
                    text: $viewModel.taxNumber,
                    icon: "doc.badge.gearshape.fill",
                    keyboardType: .numberPad
                )
                
                CustomTextField.phone(text: $viewModel.phone)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
            
            // Terms Agreement
            VStack(spacing: 12) {
                Toggle(isOn: $agreedToTerms) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kullanım koşullarını kabul ediyorum")
                            .font(.subheadline)
                        
                        Button {
                            // Kullanım koşulları sayfası
                        } label: {
                            Text("Koşulları oku")
                                .font(.caption)
                                .foregroundColor(Color(hex: "2E7D32"))
                        }
                    }
                }
                .tint(Color(hex: "2E7D32"))
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            
            // Info Box
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Onay Süreci")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("Kaydınız incelendikten sonra hesabınız aktif edilecektir. Bu süre genellikle 1-2 iş günü sürmektedir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
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
                    title: "İşletme Kaydı Oluştur",
                    icon: "checkmark",
                    isLoading: viewModel.isLoading,
                    isDisabled: !isFormValid
                ) {
                    Task {
                        await viewModel.registerAsAdmin()
                    }
                }
            }
        }
    }
    
    // MARK: - Validation
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0:
            return !viewModel.firstName.trimmed.isEmpty &&
            !viewModel.lastName.trimmed.isEmpty &&
            FormValidator.validateEmail(viewModel.email).isValid &&
            FormValidator.validatePassword(viewModel.password).isValid &&
            viewModel.passwordsMatch
        case 1:
            return !viewModel.businessName.trimmed.isEmpty &&
            FormValidator.taxNumber.validate(viewModel.taxNumber).isValid &&
            FormValidator.validatePhone(viewModel.phone).isValid &&
            agreedToTerms
        default:
            return false
        }
    }
    
    private var isFormValid: Bool {
        viewModel.isAdminRegisterFormValid && agreedToTerms
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AdminRegisterView(viewModel: AuthViewModel())
    }
}
