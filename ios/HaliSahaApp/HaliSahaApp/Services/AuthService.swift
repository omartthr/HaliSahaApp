//
//  AuthService.swift
//  HaliSahaApp
//
//  Firebase Authentication servisi
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices // Apple Sign In için
import GoogleSignIn // Google Sign In için
import CryptoKit
import UIKit

// MARK: - Auth Service
final class AuthService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthService()
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var hasCompletedInitialAuthCheck: Bool = false
    @Published var authError: AuthError?
    
    // MARK: - Private Properties
    private let auth = Auth.auth()
    private let firebaseService = FirebaseService.shared
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // MARK: - Init
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                Task {
                    await self.handleAuthenticatedUser(firebaseUser.uid)
                }
            } else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.hasCompletedInitialAuthCheck = true
                }
            }
        }
    }
    
    // MARK: - Handle Authenticated User
    @MainActor
    private func handleAuthenticatedUser(_ userId: String) async {
        isLoading = true
        defer {
            isLoading = false
            hasCompletedInitialAuthCheck = true
        }

        do {
            try await fetchUserProfile(userId: userId)
        } catch let error as AuthError {
            authError = error
            try? auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            authError = .unknown(error.localizedDescription)
            try? auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Fetch User Profile
    @MainActor
    private func fetchUserProfile(userId: String) async throws {
        do {
            let user: User = try await firebaseService.fetchDocument(
                from: firebaseService.usersCollection,
                documentId: userId
            )

            guard user.isActive else {
                throw AuthError.accountDisabled
            }

            self.currentUser = user
            self.isAuthenticated = true
            self.authError = nil
        } catch let error as AuthError {
            currentUser = nil
            isAuthenticated = false
            throw error
        } catch let error as FirebaseError {
            currentUser = nil
            isAuthenticated = false

            switch error {
            case .documentNotFound, .decodingError:
                throw AuthError.profileNotFound
            case .networkError:
                throw AuthError.networkError
            default:
                throw AuthError.unknown(error.localizedDescription)
            }
        } catch {
            currentUser = nil
            isAuthenticated = false
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Email/Password Sign Up
    @MainActor
    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        username: String,
        phone: String,
        preferredPosition: PlayerPosition = .unspecified
    ) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            // 1. Firebase Auth ile kullanıcı oluştur
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let userId = authResult.user.uid
            
            // 2. Firestore'da kullanıcı profili oluştur
            let newUser = User(
                id: userId,
                email: email,
                firstName: firstName,
                lastName: lastName,
                username: username,
                phone: phone,
                preferredPosition: preferredPosition,
                userType: .player
            )
            
            _ = try await firebaseService.createDocument(
                in: firebaseService.usersCollection,
                data: newUser,
                documentId: userId
            )
            
            self.currentUser = newUser
            self.isAuthenticated = true
            self.hasCompletedInitialAuthCheck = true
            
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Email/Password Sign In
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            try await fetchUserProfile(userId: authResult.user.uid)
            hasCompletedInitialAuthCheck = true
        } catch let error as AuthError {
            try? auth.signOut()
            throw error
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Sign Out
    @MainActor
    func signOut() throws {
        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isAuthenticated = false
            hasCompletedInitialAuthCheck = true
        } catch {
            throw AuthError.signOutFailed
        }
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(to email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Apple Sign In
    @MainActor
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        guard let appleIDToken = credential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }
        
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        do {
            let authResult = try await auth.signIn(with: firebaseCredential)
            let userId = authResult.user.uid
            
            // Yeni kullanıcı mı kontrol et
            let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
            
            if isNewUser {
                // Yeni kullanıcı profili oluştur
                let firstName = credential.fullName?.givenName ?? ""
                let lastName = credential.fullName?.familyName ?? ""
                let email = credential.email ?? authResult.user.email ?? ""
                
                let newUser = User(
                    id: userId,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    username: generateUsername(from: email),
                    phone: ""
                )
                
                _ = try await firebaseService.createDocument(
                    in: firebaseService.usersCollection,
                    data: newUser,
                    documentId: userId
                )
                
                self.currentUser = newUser
            } else {
                try await fetchUserProfile(userId: userId)
            }
            
            self.isAuthenticated = true
            self.hasCompletedInitialAuthCheck = true
            
        } catch let error as AuthError {
            try? auth.signOut()
            throw error
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Google Sign In
    @MainActor
    func signInWithGoogle() async throws {
        // Root view controller'ı al
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.unknown("Uygulama penceresi bulunamadı.")
        }
        
        // Google Sign In configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown("Firebase client ID bulunamadı.")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            // Google Sign In akışını başlat
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.invalidCredential
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            // Firebase credential oluştur
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            
            // Firebase ile giriş yap
            let authResult = try await auth.signIn(with: credential)
            let userId = authResult.user.uid
            
            // Yeni kullanıcı mı kontrol et
            let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
            
            if isNewUser {
                // Yeni kullanıcı profili oluştur
                let profile = result.user.profile
                let firstName = profile?.givenName ?? ""
                let lastName = profile?.familyName ?? ""
                let email = profile?.email ?? authResult.user.email ?? ""
                
                let newUser = User(
                    id: userId,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    username: generateUsername(from: email),
                    phone: "",
                    profileImageURL: profile?.imageURL(withDimension: 200)?.absoluteString
                )
                
                _ = try await firebaseService.createDocument(
                    in: firebaseService.usersCollection,
                    data: newUser,
                    documentId: userId
                )
                
                self.currentUser = newUser
            } else {
                try await fetchUserProfile(userId: userId)
            }
            
            self.isAuthenticated = true
            self.hasCompletedInitialAuthCheck = true
            
        } catch let error as AuthError {
            try? auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            throw error
        } catch let error as GIDSignInError {
            // Kullanıcı iptal ettiyse hata fırlatma
            if error.code == .canceled {
                return
            }
            throw AuthError.unknown(error.localizedDescription)
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Guest Mode
    @MainActor
    func continueAsGuest() {
        GIDSignIn.sharedInstance.signOut()

        let guestUser = User(
            id: "guest_\(UUID().uuidString)",
            email: "",
            firstName: "Misafir",
            lastName: "",
            username: "guest",
            phone: "",
            userType: .guest
        )
        currentUser = guestUser
        isAuthenticated = false // Misafir gerçek auth değil
        hasCompletedInitialAuthCheck = true
    }
    
    // MARK: - Admin Registration (Saha Sahibi)
    @MainActor
    func registerAsAdmin(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String,
        businessName: String,
        taxNumber: String
    ) async throws {
        isLoading = true
        authError = nil

        defer { isLoading = false }

        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let userId = authResult.user.uid

            // 1. users/{uid} — genel kullanıcı profili (auth akışı buradan okur)
            let adminUser = User(
                id: userId,
                email: email,
                firstName: firstName,
                lastName: lastName,
                username: generateUsername(from: email),
                phone: phone,
                userType: .admin
            )

            _ = try await firebaseService.createDocument(
                in: firebaseService.usersCollection,
                data: adminUser,
                documentId: userId
            )

            // 2. admins/{uid} — işletme verileri ve onay durumu
            let adminProfile = AdminProfile(
                id: userId,
                businessName: businessName,
                taxNumber: taxNumber,
                approvalStatus: .pending
            )

            _ = try await firebaseService.createDocument(
                in: firebaseService.adminsCollection,
                data: adminProfile,
                documentId: userId
            )

            self.currentUser = adminUser
            self.isAuthenticated = true
            self.hasCompletedInitialAuthCheck = true

        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Update FCM Token
    func updateFCMToken(_ token: String) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: [FirestoreField.fcmToken: token]
        )
    }
    
    // MARK: - Delete Account
    @MainActor
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        let userId = user.uid
        
        // 1. Firestore'dan kullanıcı verisini sil
        try await firebaseService.deleteDocument(
            from: firebaseService.usersCollection,
            documentId: userId
        )
        
        // 2. Firebase Auth'dan kullanıcıyı sil
        try await user.delete()
        
        currentUser = nil
        isAuthenticated = false
        hasCompletedInitialAuthCheck = true
    }
    
    // MARK: - Helper Methods
    private func generateUsername(from email: String) -> String {
        let base = email.components(separatedBy: "@").first ?? "user"
        let random = String(Int.random(in: 1000...9999))
        return "\(base)_\(random)"
    }
    
    private func mapAuthError(_ error: NSError) -> AuthError {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return .unknown(error.localizedDescription)
        }
        
        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .wrongPassword, .invalidCredential:
            return .invalidCredential
        case .userNotFound:
            return .userNotFound
        case .networkError:
            return .networkError
        case .tooManyRequests:
            return .tooManyRequests
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Auth Error
enum AuthError: LocalizedError {
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case invalidCredential
    case userNotFound
    case networkError
    case tooManyRequests
    case notAuthenticated
    case profileNotFound
    case accountDisabled
    case signOutFailed
    case notImplemented
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Geçersiz e-posta adresi."
        case .emailAlreadyInUse:
            return "Bu e-posta adresi zaten kullanımda."
        case .weakPassword:
            return "Şifre en az 6 karakter olmalıdır."
        case .invalidCredential:
            return "E-posta veya şifre hatalı."
        case .userNotFound:
            return "Kullanıcı bulunamadı."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin."
        case .tooManyRequests:
            return "Çok fazla deneme. Lütfen bekleyin."
        case .notAuthenticated:
            return "Oturum açmanız gerekiyor."
        case .profileNotFound:
            return "Kullanıcı profili bulunamadı. Lütfen tekrar kayıt olun veya destek ile iletişime geçin."
        case .accountDisabled:
            return "Hesabınız pasif durumda. Lütfen destek ile iletişime geçin."
        case .signOutFailed:
            return "Çıkış yapılamadı."
        case .notImplemented:
            return "Bu özellik henüz aktif değil."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Apple Sign In Helpers
extension AuthService {
    
    /// Nonce oluştur (Apple Sign In için)
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    /// SHA256 hash (Apple Sign In için)
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
