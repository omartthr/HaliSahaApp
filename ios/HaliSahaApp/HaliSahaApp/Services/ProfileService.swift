//
//  ProfileService.swift
//  HaliSahaApp
//
//  Profil işlemleri: bilgi güncelleme, fotoğraf, parola değiştirme, istatistikler
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import UIKit

// MARK: - Profile Service
@MainActor
final class ProfileService {

    // MARK: - Singleton
    static let shared = ProfileService()

    // MARK: - Dependencies
    private let firebaseService = FirebaseService.shared
    private let storageService = StorageService.shared
    private let auth = Auth.auth()

    private init() {}

    // MARK: - Update Profile Info
    func updateProfile(
        firstName: String,
        lastName: String,
        username: String,
        phone: String,
        preferredPosition: PlayerPosition
    ) async throws -> User {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: [
                "firstName": firstName,
                "lastName": lastName,
                "username": username.lowercased(),
                "phone": phone,
                "preferredPosition": preferredPosition.rawValue,
            ]
        )

        let updatedUser: User = try await firebaseService.fetchDocument(
            from: firebaseService.usersCollection,
            documentId: userId
        )
        return updatedUser
    }

    // MARK: - Update Billing Address
    /// iyzico ödemesi için zorunlu olan fatura adresi alanlarını günceller.
    /// `BillingAddress.validate()` çağıran tarafın sorumluluğunda — buraya gelen
    /// veri formatın doğru olduğu varsayılır (UI tarafında validate ediliyor).
    func updateBillingAddress(_ address: BillingAddress) async throws -> User {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: [
                "billingAddress": [
                    "identityNumber": address.identityNumber,
                    "address": address.address,
                    "city": address.city,
                    "district": address.district,
                    "zipCode": address.zipCode,
                    "country": address.country,
                ],
                "updatedAt": Timestamp(date: Date()),
            ]
        )

        let updatedUser: User = try await firebaseService.fetchDocument(
            from: firebaseService.usersCollection,
            documentId: userId
        )
        return updatedUser
    }

    // MARK: - Profile Photo
    func updateProfilePhoto(_ image: UIImage) async throws -> String {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        let url = try await storageService.uploadUserProfileImage(image, userId: userId)

        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: ["profileImageURL": url]
        )
        return url
    }

    func removeProfilePhoto(currentURL: String?) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        if let url = currentURL, !url.isEmpty {
            try? await storageService.deleteImage(at: url)
        }

        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: ["profileImageURL": FieldValue.delete()]
        )
    }

    // MARK: - Change Password
    func changePassword(current: String, new: String) async throws {
        guard let user = auth.currentUser, let email = user.email else {
            throw ProfileError.notAuthenticated
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: current)

        do {
            try await user.reauthenticate(with: credential)
        } catch let error as NSError {
            if let code = AuthErrorCode(rawValue: error.code) {
                switch code {
                case .wrongPassword, .invalidCredential:
                    throw ProfileError.wrongPassword
                case .tooManyRequests:
                    throw ProfileError.tooManyRequests
                default:
                    throw ProfileError.unknown(error.localizedDescription)
                }
            }
            throw ProfileError.unknown(error.localizedDescription)
        }

        do {
            try await user.updatePassword(to: new)
        } catch let error as NSError {
            if let code = AuthErrorCode(rawValue: error.code) {
                switch code {
                case .weakPassword:
                    throw ProfileError.weakPassword
                case .requiresRecentLogin:
                    throw ProfileError.requiresRecentLogin
                default:
                    throw ProfileError.unknown(error.localizedDescription)
                }
            }
            throw ProfileError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Onboarding

    /// Onboarding sırasında her ekran cevabını anında Firestore'a kaydeder.
    /// Kullanıcı yarıda bırakırsa kaldığı yerden devam edebilsin diye partial update.
    func updateOnboardingFields(_ fields: [String: Any]) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        var payload = fields
        payload["updatedAt"] = Timestamp(date: Date())

        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: payload
        )
    }

    /// (Debug) Onboarding ile ilgili tüm alanları siler — kullanıcı tekrar girişte onboarding'i baştan görür.
    func resetOnboarding() async throws {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: [
                "onboardingCompletedAt": FieldValue.delete(),
                "playFrequency": FieldValue.delete(),
                "skillLevel": FieldValue.delete(),
                "preferredDays": FieldValue.delete(),
                "preferredTimeSlots": FieldValue.delete(),
                "motivations": FieldValue.delete(),
                "updatedAt": Timestamp(date: Date()),
            ]
        )
    }

    /// Onboarding tamamlanma timestamp'ini yazar.
    func completeOnboarding() async throws -> User {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: [
                "onboardingCompletedAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date()),
            ]
        )

        let updatedUser: User = try await firebaseService.fetchDocument(
            from: firebaseService.usersCollection,
            documentId: userId
        )
        return updatedUser
    }

    // MARK: - Favorites
    func fetchFavoriteFacilities(ids: [String]) async throws -> [Facility] {
        guard !ids.isEmpty else { return [] }

        var facilities: [Facility] = []
        for id in ids {
            if let facility = try? await FacilityService.shared.fetchFacility(id: id) {
                facilities.append(facility)
            }
        }
        return facilities
    }

    // MARK: - Booking Stats
    func fetchBookingStats() async throws -> ProfileBookingStats {
        guard let userId = firebaseService.currentUserId else {
            throw ProfileError.notAuthenticated
        }

        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.userId, isEqualTo: userId)

        let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)

        let upcoming = bookings.filter { !$0.isPast && $0.status == .confirmed }.count
        let completed = bookings.filter { $0.status == .completed || ($0.isPast && $0.status == .confirmed) }.count
        let cancelled = bookings.filter { $0.status == .cancelled }.count

        return ProfileBookingStats(
            total: bookings.count,
            upcoming: upcoming,
            completed: completed,
            cancelled: cancelled
        )
    }
}

// MARK: - Profile Booking Stats
struct ProfileBookingStats: Equatable {
    let total: Int
    let upcoming: Int
    let completed: Int
    let cancelled: Int

    static let empty = ProfileBookingStats(total: 0, upcoming: 0, completed: 0, cancelled: 0)
}

// MARK: - Profile Error
enum ProfileError: LocalizedError {
    case notAuthenticated
    case wrongPassword
    case weakPassword
    case requiresRecentLogin
    case tooManyRequests
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Bu işlem için giriş yapmanız gerekiyor."
        case .wrongPassword:
            return "Mevcut şifreniz hatalı."
        case .weakPassword:
            return "Yeni şifre en az 6 karakter olmalı."
        case .requiresRecentLogin:
            return "Güvenlik için lütfen tekrar giriş yapın."
        case .tooManyRequests:
            return "Çok fazla deneme. Lütfen biraz bekleyin."
        case .unknown(let message):
            return message
        }
    }
}
