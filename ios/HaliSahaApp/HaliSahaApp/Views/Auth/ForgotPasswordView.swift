//
//  ForgotPasswordView.swift
//  HaliSahaApp
//
//  Şifre sıfırlama ekranı
//
//  Created by Mehmet Mert Mazıcı on 24.12.2025.
//


import SwiftUI

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var emailSent = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                if emailSent {
                    successContent
                } else {
                    formContent
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 48)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Şifremi Unuttum")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
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
    
    // MARK: - Form Content
    private var formContent: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "2E7D32").opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            // Title & Description
            VStack(spacing: 12) {
                Text("Şifrenizi mi Unuttunuz?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Email Input
            VStack(spacing: 20) {
                CustomTextField.email(text: $viewModel.email)
                
                PrimaryButton(
                    title: "Sıfırlama Bağlantısı Gönder",
                    icon: "paperplane.fill",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.email.isValidEmail
                ) {
                    Task {
                        await viewModel.sendPasswordReset()
                        if !viewModel.showError {
                            withAnimation {
                                emailSent = true
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
            
            // Back to Login
            Button {
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                    Text("Giriş sayfasına dön")
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "2E7D32"))
            }
        }
    }
    
    // MARK: - Success Content
    private var successContent: some View {
        VStack(spacing: 24) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            // Title & Description
            VStack(spacing: 12) {
                Text("E-posta Gönderildi!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Şifre sıfırlama bağlantısı **\(viewModel.email)** adresine gönderildi.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                InstructionRow(
                    step: 1,
                    text: "E-posta kutunuzu kontrol edin"
                )
                
                InstructionRow(
                    step: 2,
                    text: "\"Şifreyi Sıfırla\" bağlantısına tıklayın"
                )
                
                InstructionRow(
                    step: 3,
                    text: "Yeni şifrenizi belirleyin"
                )
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
            
            // Note
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                
                Text("E-postayı bulamıyorsanız spam/gereksiz klasörünü kontrol edin.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            // Buttons
            VStack(spacing: 12) {
                PrimaryButton(title: "Giriş Sayfasına Dön") {
                    dismiss()
                }
                
                Button {
                    withAnimation {
                        emailSent = false
                    }
                } label: {
                    Text("Farklı bir e-posta dene")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
        }
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let step: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "2E7D32"))
                    .frame(width: 28, height: 28)
                
                Text("\(step)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ForgotPasswordView(viewModel: AuthViewModel())
    }
}

#Preview("Email Sent") {
    NavigationStack {
        ForgotPasswordView(viewModel: {
            let vm = AuthViewModel()
            vm.email = "ornek@email.com"
            return vm
        }())
    }
}
