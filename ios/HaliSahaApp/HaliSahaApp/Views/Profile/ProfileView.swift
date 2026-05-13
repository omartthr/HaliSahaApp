//
//  ProfileView.swift
//  HaliSahaApp
//
//  Profil sekmesi - Modern ve kullanıcı odaklı tasarım
//

import PhotosUI
import SwiftUI

// MARK: - Profile View
struct ProfileView: View {

    // MARK: - Properties
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var authService = AuthService.shared

    // Photo picker
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var showPhotoOptions = false
    @State private var showRemovePhotoConfirm = false

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero (avatar + isim + pozisyon)
                heroSection

                // İstatistikler
                statsCard

                // Hızlı erişim grid
                quickActionsGrid

                // Hesap bilgileri
                accountInfoSection

                // Versiyon
                versionFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profil")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ProfileSettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.primary)
                }
            }
        }
        .refreshable {
            await viewModel.loadAll()
        }
        .task {
            await viewModel.loadAll()
        }
        .onChange(of: authService.currentUser?.favoriteFields) { _, _ in
            Task { await viewModel.loadFavorites() }
        }
        .confirmationDialog(
            "Profil Fotoğrafı",
            isPresented: $showPhotoOptions,
            titleVisibility: .visible
        ) {
            Button("Galeriden Seç") {
                presentPhotoPicker()
            }
            if hasProfilePhoto {
                Button("Fotoğrafı Kaldır", role: .destructive) {
                    showRemovePhotoConfirm = true
                }
            }
            Button("Vazgeç", role: .cancel) {}
        }
        .alert("Fotoğrafı Kaldır", isPresented: $showRemovePhotoConfirm) {
            Button("Vazgeç", role: .cancel) {}
            Button("Kaldır", role: .destructive) {
                Task { await viewModel.removeProfilePhoto() }
            }
        } message: {
            Text("Profil fotoğrafınız kaldırılacak.")
        }
        .photosPicker(
            isPresented: $isPhotoPickerPresented,
            selection: $photoPickerItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                {
                    await viewModel.updateProfilePhoto(image)
                }
                photoPickerItem = nil
            }
        }
    }

    private func presentPhotoPicker() {
        showPhotoOptions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPhotoPickerPresented = true
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .top) {
            heroCardBackground
                .frame(height: 240)
                .padding(.top, 58)

            VStack(spacing: 0) {
                avatarButton

                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text(authService.currentUser?.fullName ?? "Kullanıcı")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let username = authService.currentUser?.username, !username.isEmpty {
                            Text("@\(username)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.68))
                                .lineLimit(1)
                        }
                    }

                    if let user = authService.currentUser {
                        HStack(spacing: 6) {
                            Text(user.preferredPosition.icon)
                                .font(.caption)
                            Text(user.preferredPosition.displayName)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.16))
                        .foregroundColor(.white.opacity(0.85))
                        .clipShape(Capsule())
                    }

                    NavigationLink {
                        EditProfileView()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                            Text("Profili Düzenle")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2E7D32"))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                        .shadow(color: .black.opacity(0.14), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .padding(.top, 20)
            }
            .padding(.top, 0)
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .padding(.top, 18)
    }

    private var heroCardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "3E7F37"),
                    Color(hex: "28652A"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 220, height: 220)
                .offset(x: 160, y: -25)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: -150, y: 95)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var avatarButton: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarView
                .frame(width: 124, height: 124)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.appBackground, lineWidth: 5)
                }
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)

            Button {
                showPhotoOptions = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "69A95B"))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(Color.appBackground, lineWidth: 4)
                        }

                    if viewModel.isUploadingPhoto {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(viewModel.isUploadingPhoto)
            .offset(x: -3, y: -4)
        }
    }

    // MARK: - Avatar View
    @ViewBuilder
    private var avatarView: some View {
        if let url = authService.currentUser?.profileImageURL, !url.isEmpty {
            CachedAsyncImage(
                url: url,
                targetSize: CGSize(width: 220, height: 220)
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                avatarPlaceholder
            }
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4CAF50"), Color(hex: "2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(initials)
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var initials: String {
        guard let user = authService.currentUser else { return "?" }
        let first = user.firstName.first.map { String($0) } ?? ""
        let last = user.lastName.first.map { String($0) } ?? ""
        let combined = (first + last).uppercased()
        return combined.isEmpty ? "?" : combined
    }

    private var hasProfilePhoto: Bool {
        if let url = authService.currentUser?.profileImageURL {
            return !url.isEmpty
        }
        return false
    }

    // MARK: - Stats Card
    private var statsCard: some View {
        HStack(spacing: 0) {
            ProfileStatTile(
                value: "\(viewModel.bookingStats.completed + viewModel.bookingStats.upcoming)",
                label: "Toplam Maç",
                icon: "sportscourt.fill"
            )

            Divider()
                .frame(height: 50)

            ProfileStatTile(
                value: attendanceText,
                label: "Katılım",
                icon: "person.fill.checkmark"
            )

            Divider()
                .frame(height: 50)

            ProfileStatTile(
                value: String(format: "%.1f", authService.currentUser?.reliabilityScore ?? 0),
                label: "Güvenilirlik",
                icon: "star.fill",
                valueColor: .orange
            )
        }
        .padding(.vertical, 16)
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var attendanceText: String {
        let stats = viewModel.bookingStats
        let total = stats.completed + stats.cancelled
        guard total > 0 else { return "—" }
        return "%\(Int(Double(stats.completed) / Double(total) * 100))"
    }

    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı Erişim")
                .font(.headline)
                .padding(.horizontal, 4)

            // Favorilerim + Geçmişim yan yana
            HStack(spacing: 12) {
                NavigationLink {
                    FavoritesView()
                } label: {
                    QuickActionTile(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Favorilerim",
                        subtitle: favoritesSubtitle,
                        badge: authService.currentUser?.favoriteFields.count ?? 0
                    )
                }
                .buttonStyle(.plain)

                Button {
                    NotificationCenter.default.post(name: .switchToBookingsTab, object: nil)
                } label: {
                    MatchesTile(stats: viewModel.bookingStats)
                }
                .buttonStyle(.plain)
            }

            // Randevularım tek başına tam genişlikte, ortalı
            Button {
                NotificationCenter.default.post(name: .switchToBookingsTab, object: nil)
            } label: {
                QuickActionTile(
                    icon: "ticket.fill",
                    iconColor: .blue,
                    title: "Randevularım",
                    subtitle: bookingsSubtitle,
                    badge: viewModel.bookingStats.upcoming,
                    centered: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var favoritesSubtitle: String {
        let count = authService.currentUser?.favoriteFields.count ?? 0
        return count == 0 ? "Henüz favori yok" : "\(count) saha"
    }

    private var bookingsSubtitle: String {
        let upcoming = viewModel.bookingStats.upcoming
        return upcoming == 0 ? "Yaklaşan yok" : "\(upcoming) yaklaşan"
    }

    // MARK: - Account Info
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hesap Bilgileri")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                AccountInfoRow(
                    icon: "envelope.fill",
                    iconColor: Color(hex: "2E7D32"),
                    title: "E-posta",
                    value: authService.currentUser?.email ?? "—"
                )

                Divider().padding(.leading, 56)

                AccountInfoRow(
                    icon: "phone.fill",
                    iconColor: Color(hex: "2E7D32"),
                    title: "Telefon",
                    value: formattedPhone
                )

                Divider().padding(.leading, 56)

                AccountInfoRow(
                    icon: "calendar",
                    iconColor: Color(hex: "2E7D32"),
                    title: "Üyelik",
                    value: viewModel.memberSinceText
                )
            }
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var formattedPhone: String {
        let phone = authService.currentUser?.phone ?? ""
        guard !phone.isEmpty else { return "—" }
        return phone
    }

    // MARK: - Version Footer
    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text(AppConstants.appName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("Versiyon \(AppConstants.appVersion)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 16)
    }
}

// MARK: - Profile Stat Tile
struct ProfileStatTile: View {
    let value: String
    let label: String
    let icon: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "2E7D32"))

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(valueColor)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Action Tile
struct QuickActionTile: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var badge: Int = 0
    var centered: Bool = false

    var body: some View {
        if centered {
            centeredLayout
        } else {
            leadingLayout
        }
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(iconColor.opacity(0.15))
                .frame(width: 44, height: 44)

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
        }
        .overlay(alignment: .topTrailing) {
            if badge > 0 {
                Text("\(badge)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 18, minHeight: 18)
                    .padding(.horizontal, 4)
                    .background(Capsule().fill(Color.red))
                    .overlay(Capsule().stroke(Color.appCardBackground, lineWidth: 2))
                    .offset(x: 6, y: -6)
            }
        }
    }

    private var leadingLayout: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.appCardBackground)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var centeredLayout: some View {
        HStack(spacing: 16) {
            Spacer(minLength: 0)

            iconView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.appCardBackground)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Matches Tile
private struct MatchesTile: View {
    let stats: ProfileBookingStats

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Geçmişim")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("\(stats.completed) tamamlandı")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.appCardBackground)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Account Info Row
struct AccountInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ProfileView()
    }
}
