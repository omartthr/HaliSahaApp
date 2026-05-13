//
//  PendingApprovalsListView.swift
//  HaliSahaApp
//
//  Süper admin'in inceleme bekleyen başvuruları listelediği ekran.
//  Belge yüklenmiş ve henüz onaylanmamış admin'leri gösterir.
//

import SwiftUI

// MARK: - Pending Approvals List View
struct PendingApprovalsListView: View {

    let onCountChange: (Int) -> Void

    @StateObject private var adminService = AdminService.shared
    @State private var pendingAdmins: [AdminProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let primaryColor = Color(hex: "2E7D32")

    var body: some View {
        SwiftUI.Group {
            if isLoading && pendingAdmins.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pendingAdmins.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .navigationTitle("Onay Bekleyenler")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.appBackground.ignoresSafeArea())
        .refreshable {
            await loadPending()
        }
        .task {
            await loadPending()
        }
        .alert("Hata", isPresented: .constant(errorMessage != nil)) {
            Button("Tamam") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - List Content
    private var listContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                summaryHeader

                ForEach(pendingAdmins, id: \.id) { admin in
                    NavigationLink {
                        AdminReviewDetailView(adminId: admin.id ?? "") {
                            // Onay/red sonrası listeyi yenile
                            Task { await loadPending() }
                        }
                    } label: {
                        pendingCard(for: admin)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Summary Header
    private var summaryHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(pendingAdmins.count) başvuru")
                    .font(.headline)
                Text("incelenmeyi bekliyor")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Pending Card
    private func pendingCard(for admin: AdminProfile) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(primaryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(admin.businessName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("Vergi No: \(admin.taxNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let submitted = admin.documentsSubmittedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("Gönderim: \(formatDate(submitted))")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                statusBadge(admin.approvalStatus)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.appCardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    private func statusBadge(_ status: AdminApprovalStatus) -> some View {
        Text(status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor(for: status).opacity(0.15))
            .foregroundColor(badgeColor(for: status))
            .clipShape(Capsule())
    }

    private func badgeColor(for status: AdminApprovalStatus) -> Color {
        switch status {
        case .pending:   return .orange
        case .approved:  return primaryColor
        case .rejected:  return .red
        case .suspended: return .red
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(primaryColor)
            }
            Text("Bekleyen başvuru yok")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Yeni başvuru geldiğinde burada görünecek.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Load
    @MainActor
    private func loadPending() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let admins = try await adminService.fetchPendingAdmins()
            pendingAdmins = admins
            onCountChange(admins.count)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        PendingApprovalsListView { _ in }
    }
}
