//
//  LoginView.swift
//  HaliSahaApp
//
//  Kullanıcı giriş ekranı
//
//  Created by Mehmet Mert Mazıcı on 24.12.2025.
//


import SwiftUI
import AuthenticationServices

// MARK: - Login View
struct LoginView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo & Welcome
                    headerSection
                    
                    // Login Form
                    loginFormSection
                    
                    // Divider
                    dividerSection
                    
                    // Social Login
                    socialLoginSection
                    
                    // Guest Mode
                    guestModeSection
                    
                    // Register Link
                    registerLinkSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .alert("Hata", isPresented: $viewModel.showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Başarılı", isPresented: $viewModel.showSuccessAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.successMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView()
                }
            }
            .navigationDestination(isPresented: $viewModel.showRegisterView) {
                RegisterView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $viewModel.showForgotPassword) {
                ForgotPasswordView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(Color(hex: "2E7D32").opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            // Welcome Text
            VStack(spacing: 8) {
                Text("Hoş Geldiniz!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Halı saha kiralayın, takım kurun, maça başlayın!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 20) {
            // Email
            CustomTextField.email(text: $viewModel.email)
            
            // Password
            CustomTextField.password(text: $viewModel.password)
            
            // Forgot Password
            HStack {
                Spacer()
                TextLinkButton(title: "Şifremi Unuttum") {
                    viewModel.showForgotPassword = true
                }
            }
            
            // Login Button
            PrimaryButton(
                title: "Giriş Yap",
                icon: "arrow.right",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isLoginFormValid
            ) {
                Task {
                    await viewModel.login()
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            Text("veya")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Social Login Section
    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            // Apple Sign In
            SignInWithAppleButton(
                onRequest: { request in
                    let nonce = viewModel.prepareAppleSignIn()
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = nonce
                },
                onCompletion: { result in
                    Task {
                        await viewModel.handleAppleSignIn(result: result)
                    }
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 52)
            .cornerRadius(12)
            
            // Google Sign In
            SocialSignInButton(provider: .google, isLoading: viewModel.isLoading) {
                Task {
                    await viewModel.signInWithGoogle()
                }
            }
        }
    }
    
    // MARK: - Guest Mode Section
    private var guestModeSection: some View {
        VStack(spacing: 8) {
            Text("Hemen göz atmak ister misiniz?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.continueAsGuest()
                viewModel.isAuthenticated = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "eye")
                    Text("Misafir Olarak Devam Et")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "2E7D32"))
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Register Link Section
    private var registerLinkSection: some View {
        HStack(spacing: 4) {
            Text("Hesabınız yok mu?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.showRegisterView = true
            } label: {
                Text("Kayıt Ol")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Preview
#Preview {
    LoginView()
}
