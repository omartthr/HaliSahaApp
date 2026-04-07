//
//  AuthViewModel.swift
//  HaliSahaApp
//
//  Authentication ViewModel - Giriş/Kayıt iş mantığı
//
//  Created by Mehmet Mert Mazıcı on 24.12.2025.
//


import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - Auth ViewModel
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var username = ""
    @Published var phone = ""
    @Published var preferredPosition: PlayerPosition = .unspecified
    
    // Admin kayıt için
    @Published var businessName = ""
    @Published var taxNumber = ""
    
    // UI State
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showSuccessAlert = false
    @Published var successMessage = ""
    
    // Navigation
    @Published var isAuthenticated = false
    @Published var showRegisterView = false
    @Published var showForgotPassword = false
    @Published var showAdminRegister = false
    
    // Apple Sign In
    @Published var currentNonce: String?
    
    // MARK: - Private Properties
    private let authService = AuthService.shared
    
    // MARK: - Computed Properties
    var isLoginFormValid: Bool {
        FormValidator.validateEmail(email).isValid  &&
        FormValidator.validatePassword(password).isValid
    }
    
    var isRegisterFormValid: Bool {
        FormValidator.validateEmail(email).isValid &&
        FormValidator.validatePassword(password).isValid &&
        passwordsMatch &&
        !firstName.trimmed.isEmpty &&
        !lastName.trimmed.isEmpty &&
        FormValidator.validateUsername(username).isValid &&
        FormValidator.validatePhone(phone).isValid
    }
    
    var isAdminRegisterFormValid: Bool {
        FormValidator.validateEmail(email).isValid &&
        FormValidator.validatePassword(password).isValid &&
        passwordsMatch &&
        !firstName.trimmed.isEmpty &&
        !lastName.trimmed.isEmpty &&
        !businessName.trimmed.isEmpty &&
        FormValidator.taxNumber.validate(taxNumber).isValid && // 10 veya 11 hane kontrolü
        FormValidator.validatePhone(phone).isValid // 5XX XXX XX XX kontrolü
    }
    
    var passwordStrength: PasswordStrength {
        PasswordStrength.evaluate(password)
    }
    
    var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }
    
    // MARK: - Init
    init() {
        setupAuthStateObserver()
    }
    
    // MARK: - Auth State Observer
    private func setupAuthStateObserver() {
        // AuthService'deki değişiklikleri dinle
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)
    }
    
    // MARK: - Email/Password Login
    func login() async {
        guard isLoginFormValid else {
            showError(message: "Lütfen tüm alanları doldurun.")
            return
        }
        
        guard email.isValidEmail else {
            showError(message: "Geçerli bir e-posta adresi girin.")
            return
        }
        
        isLoading = true
        
        do {
            try await authService.signIn(email: email.trimmed, password: password)
            clearForm()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "Giriş yapılırken bir hata oluştu.")
        }
        
        isLoading = false
    }
    
    // MARK: - Email/Password Register
    func register() async {
        guard isRegisterFormValid else {
            showError(message: "Lütfen tüm alanları doğru şekilde doldurun.")
            return
        }
        
        guard email.isValidEmail else {
            showError(message: "Geçerli bir e-posta adresi girin.")
            return
        }
        
        guard password == confirmPassword else {
            showError(message: "Şifreler eşleşmiyor.")
            return
        }
        
        isLoading = true
        
        do {
            try await authService.signUp(
                email: email.trimmed,
                password: password,
                firstName: firstName.trimmed,
                lastName: lastName.trimmed,
                username: username.trimmed.lowercased(),
                phone: phone.trimmed,
                preferredPosition: preferredPosition
            )
            clearForm()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "Kayıt olurken bir hata oluştu.")
        }
        
        isLoading = false
    }
    
    // MARK: - Admin Register
    func registerAsAdmin() async {
        guard isAdminRegisterFormValid else {
            showError(message: "Lütfen tüm alanları doğru şekilde doldurun.")
            return
        }
        
        isLoading = true
        
        do {
            try await authService.registerAsAdmin(
                email: email.trimmed,
                password: password,
                firstName: firstName.trimmed,
                lastName: lastName.trimmed,
                phone: phone.trimmed,
                businessName: businessName.trimmed,
                taxNumber: taxNumber.trimmed
            )
            
            showSuccess(message: "Kayıt başarılı! İşletmeniz onay sürecindedir.")
            clearForm()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "Kayıt olurken bir hata oluştu.")
        }
        
        isLoading = false
    }
    
    // MARK: - Forgot Password
    func sendPasswordReset() async {
        guard !email.trimmed.isEmpty else {
            showError(message: "Lütfen e-posta adresinizi girin.")
            return
        }
        
        guard email.isValidEmail else {
            showError(message: "Geçerli bir e-posta adresi girin.")
            return
        }
        
        isLoading = true
        
        do {
            try await authService.sendPasswordReset(to: email.trimmed)
            showSuccess(message: "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.")
            showForgotPassword = false
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "Şifre sıfırlama e-postası gönderilemedi.")
        }
        
        isLoading = false
    }
    
    // MARK: - Apple Sign In
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce else {
                showError(message: "Apple ile giriş yapılamadı.")
                return
            }
            
            isLoading = true
            
            do {
                try await authService.signInWithApple(credential: appleIDCredential, nonce: nonce)
            } catch let error as AuthError {
                showError(message: error.localizedDescription)
            } catch {
                showError(message: "Apple ile giriş yapılamadı.")
            }
            
            isLoading = false
            
        case .failure(let error):
            // Kullanıcı iptal ettiyse hata gösterme
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showError(message: "Apple ile giriş yapılamadı.")
            }
        }
    }
    
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async {
        isLoading = true
        
        do {
            try await authService.signInWithGoogle()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "Google ile giriş yapılamadı.")
        }
        
        isLoading = false
    }
    
    // MARK: - Guest Mode
    func continueAsGuest() {
        authService.continueAsGuest()
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try authService.signOut()
            clearForm()
        } catch {
            showError(message: "Çıkış yapılırken bir hata oluştu.")
        }
    }
    
    // MARK: - Helper Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func showSuccess(message: String) {
        successMessage = message
        showSuccessAlert = true
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        firstName = ""
        lastName = ""
        username = ""
        phone = ""
        businessName = ""
        taxNumber = ""
        preferredPosition = .unspecified
    }
    
    // MARK: - Nonce Helpers (Apple Sign In)
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce.")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Password Strength
enum PasswordStrength: Int, CaseIterable {
    case weak = 1
    case medium = 2
    case strong = 3
    
    var displayName: String {
        switch self {
        case .weak: return "Zayıf"
        case .medium: return "Orta"
        case .strong: return "Güçlü"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    static func evaluate(_ password: String) -> PasswordStrength {
        var score = 0
        
        if password.count >= 6 { score += 1 }
        if password.count >= 10 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
        switch score {
        case 0...2: return .weak
        case 3...4: return .medium
        default: return .strong
        }
    }
}
