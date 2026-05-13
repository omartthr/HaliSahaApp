//
//  FavoritesView.swift
//  HaliSahaApp
//
//  Kullanıcının favori sahaları
//

import SwiftUI

// MARK: - Favorites View
struct FavoritesView: View {

    // MARK: - Properties
    @StateObject private var viewModel = FavoritesViewModel()
    @StateObject private var authService = AuthService.shared

    @State private var pendingRemoveFacility: Facility?

    // MARK: - Body
    var body: some View {
        SwiftUI.Group {
            if viewModel.isLoading && viewModel.facilities.isEmpty {
                LoadingView()
            } else if viewModel.facilities.isEmpty {
                EmptyStateView(
                    icon: "heart.slash",
                    title: "Henüz Favori Yok",
                    message:
                        "Beğendiğin sahaları kalp ikonuna dokunarak favorilerine ekleyebilirsin.",
                    buttonTitle: nil
                )
            } else {
                contentList
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Favorilerim")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onChange(of: authService.currentUser?.favoriteFields) { _, _ in
            Task { await viewModel.load() }
        }
        .alert(
            "Favorilerden Çıkar",
            isPresented: Binding(
                get: { pendingRemoveFacility != nil },
                set: { if !$0 { pendingRemoveFacility = nil } }
            )
        ) {
            Button("Vazgeç", role: .cancel) { pendingRemoveFacility = nil }
            Button("Çıkar", role: .destructive) {
                if let facility = pendingRemoveFacility {
                    Task {
                        await viewModel.remove(facility)
                        pendingRemoveFacility = nil
                    }
                }
            }
        } message: {
            if let name = pendingRemoveFacility?.name {
                Text("\(name) favorilerinizden çıkarılacak.")
            }
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Content List
    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Header summary
                HStack {
                    Text("\(viewModel.facilities.count) saha")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)

                ForEach(viewModel.facilities) { facility in
                    NavigationLink {
                        FacilityDetailView(facility: facility)
                    } label: {
                        FavoriteFacilityCard(facility: facility) {
                            pendingRemoveFacility = facility
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Favorite Facility Card
struct FavoriteFacilityCard: View {
    let facility: Facility
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            FacilityImageView(
                url: facility.images.first,
                size: CGSize(width: 90, height: 90),
                cornerRadius: 12,
                placeholder: "sportscourt.fill"
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(facility.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(facility.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(facility.formattedRating)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("(\(facility.totalReviews))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    if facility.amenities.isIndoor {
                        TagPill(text: "Kapalı", icon: "house.fill")
                    } else {
                        TagPill(text: "Açık", icon: "sun.max.fill")
                    }

                    if facility.amenities.hasParking {
                        TagPill(text: "Otopark", icon: "car.fill")
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.appCardBackground)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Tag Pill
private struct TagPill: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.appElevatedBackground)
        .clipShape(Capsule())
    }
}

// MARK: - Favorites View Model
@MainActor
final class FavoritesViewModel: ObservableObject {

    @Published var facilities: [Facility] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?

    private let profileService = ProfileService.shared
    private let facilityService = FacilityService.shared
    private let authService = AuthService.shared

    func load() async {
        guard let user = authService.currentUser else {
            facilities = []
            return
        }

        isLoading = true
        do {
            let fetched = try await profileService.fetchFavoriteFacilities(ids: user.favoriteFields)
            facilities = fetched

            // Firestore'da artık bulunmayan (silinmiş) saha ID'lerini temizle
            let fetchedIds = Set(fetched.compactMap { $0.id })
            let staleIds = user.favoriteFields.filter { !fetchedIds.contains($0) }
            for staleId in staleIds {
                try? await facilityService.removeFromFavorites(facilityId: staleId)
            }
            if !staleIds.isEmpty, var updatedUser = authService.currentUser {
                updatedUser.favoriteFields.removeAll { staleIds.contains($0) }
                authService.currentUser = updatedUser
            }
        } catch {
            facilities = []
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }

    func remove(_ facility: Facility) async {
        guard let id = facility.id else { return }
        do {
            try await facilityService.removeFromFavorites(facilityId: id)
            facilities.removeAll { $0.id == id }
            if var user = authService.currentUser {
                user.favoriteFields.removeAll { $0 == id }
                authService.currentUser = user
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FavoritesView()
    }
}
