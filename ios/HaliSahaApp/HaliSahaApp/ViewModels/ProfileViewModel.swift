//
//  ProfileViewModel.swift
//  HaliSahaApp
//
//  Profil ekranı view model
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Profile View Model
@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - Published State
    @Published var bookingStats: ProfileBookingStats = .empty
    @Published var favoriteFacilities: [Facility] = []
    @Published var isLoadingStats = false
    @Published var isLoadingFavorites = false
    @Published var isUploadingPhoto = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Dependencies
    private let profileService = ProfileService.shared
    private let authService = AuthService.shared
    private let facilityService = FacilityService.shared

    // MARK: - Computed
    var currentUser: User? {
        authService.currentUser
    }

    var memberSinceText: String {
        guard let date = authService.currentUser?.createdAt else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalizedFirstLetter
    }

    // MARK: - Load
    func loadAll() async {
        async let stats: () = loadStats()
        async let favorites: () = loadFavorites()
        _ = await (stats, favorites)
    }

    func loadStats() async {
        isLoadingStats = true
        do {
            bookingStats = try await profileService.fetchBookingStats()
        } catch {
            // Sessiz hata - istatistikler boş kalır
        }
        isLoadingStats = false
    }

    func loadFavorites() async {
        guard let user = currentUser else {
            favoriteFacilities = []
            return
        }

        isLoadingFavorites = true
        do {
            favoriteFacilities = try await profileService.fetchFavoriteFacilities(
                ids: user.favoriteFields
            )
        } catch {
            favoriteFacilities = []
        }
        isLoadingFavorites = false
    }

    // MARK: - Profile Photo
    func updateProfilePhoto(_ image: UIImage) async {
        isUploadingPhoto = true
        do {
            let url = try await profileService.updateProfilePhoto(image)
            if var user = authService.currentUser {
                user.profileImageURL = url
                authService.currentUser = user
            }
        } catch {
            present(error: error.localizedDescription)
        }
        isUploadingPhoto = false
    }

    func removeProfilePhoto() async {
        let currentURL = currentUser?.profileImageURL
        isUploadingPhoto = true
        do {
            try await profileService.removeProfilePhoto(currentURL: currentURL)
            if var user = authService.currentUser {
                user.profileImageURL = nil
                authService.currentUser = user
            }
        } catch {
            present(error: error.localizedDescription)
        }
        isUploadingPhoto = false
    }

    // MARK: - Favorites
    func removeFavorite(_ facility: Facility) async {
        guard let id = facility.id else { return }
        do {
            try await facilityService.removeFromFavorites(facilityId: id)
            favoriteFacilities.removeAll { $0.id == id }
            if var user = authService.currentUser {
                user.favoriteFields.removeAll { $0 == id }
                authService.currentUser = user
            }
        } catch {
            present(error: error.localizedDescription)
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            present(error: error.localizedDescription)
        }
    }

    // MARK: - Delete Account
    func deleteAccount() async {
        do {
            try await authService.deleteAccount()
        } catch {
            present(error: error.localizedDescription)
        }
    }

    // MARK: - Helpers
    private func present(error message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - String Extension
private extension String {
    var capitalizedFirstLetter: String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
}
