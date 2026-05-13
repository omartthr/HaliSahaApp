//
//  SuperAdminStatsView.swift
//  HaliSahaApp
//
//  Süper admin için basit özet istatistikler.
//  Status'a göre işletmeci sayısı + son aktiviteler.
//

import SwiftUI

// MARK: - Super Admin Stats View
struct SuperAdminStatsView: View {

    @StateObject private var adminService = AdminService.shared
    @StateObject private var authService = AuthService.shared

    @State private var stats: AdminStats = AdminStats()
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let primaryColor = Color(hex: "2E7D32")

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                }

                statusGrid

                pendingHighlight

                signOutCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("İstatistik")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.appBackground.ignoresSafeArea())
        .refreshable {
            await loadStats()
        }
        .task {
            await loadStats()
        }
        .alert("Hata", isPresented: .constant(errorMessage != nil)) {
            Button("Tamam") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Status Grid (4 kart)
    private var statusGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                title: "Toplam İşletmeci",
                value: "\(stats.total)",
                icon: "person.3.fill",
                color: primaryColor
            )
            statCard(
                title: "Onay Bekleyen",
                value: "\(stats.pending)",
                icon: "hourglass",
                color: .orange
            )
            statCard(
                title: "Onaylı",
                value: "\(stats.approved)",
                icon: "checkmark.seal.fill",
                color: primaryColor
            )
            statCard(
                title: "Reddedilen",
                value: "\(stats.rejected)",
                icon: "xmark.octagon.fill",
                color: .red
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(color)
                }
                Spacer()
            }

            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Pending Highlight
    private var pendingHighlight: some View {
        SwiftUI.Group {
            if stats.pending > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(stats.pending) başvuru inceleme bekliyor")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\"Onay Bekleyenler\" sekmesinden inceleyebilirsin.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Sign Out
    private var signOutCard: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .foregroundColor(primaryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Süper Admin Hesabı")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(authService.currentUser?.email ?? "—")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            PrimaryButton(
                title: "Çıkış Yap",
                icon: "arrow.left.square",
                style: .outline
            ) {
                try? authService.signOut()
            }
        }
        .padding(14)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Load
    @MainActor
    private func loadStats() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let admins = try await adminService.fetchAllAdmins()
            var s = AdminStats()
            s.total = admins.count
            s.pending = admins.filter { $0.approvalStatus == .pending && $0.documentsSubmittedAt != nil }.count
            s.approved = admins.filter { $0.approvalStatus == .approved }.count
            s.rejected = admins.filter { $0.approvalStatus == .rejected }.count
            stats = s
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Stats Model
private struct AdminStats {
    var total: Int = 0
    var pending: Int = 0
    var approved: Int = 0
    var rejected: Int = 0
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SuperAdminStatsView()
    }
}
