//
//  AllAdminsListView.swift
//  HaliSahaApp
//
//  Süper admin için tüm işletmecileri listeleyen ekran.
//  Statüye göre filtreleme + arama + detaya gidip aksiyon alma.
//

import SwiftUI

// MARK: - All Admins List View
struct AllAdminsListView: View {

    @StateObject private var adminService = AdminService.shared

    @State private var allAdmins: [AdminProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var statusFilter: AdminApprovalStatus? = nil
    @State private var searchText: String = ""

    private let primaryColor = Color(hex: "2E7D32")

    var body: some View {
        VStack(spacing: 0) {
            filterChips

            SwiftUI.Group {
                if isLoading && allAdmins.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredAdmins.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
        }
        .navigationTitle("İşletmeciler")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.appBackground.ignoresSafeArea())
        .searchable(text: $searchText, prompt: "İşletme adı veya vergi no")
        .refreshable {
            await loadAdmins()
        }
        .task {
            await loadAdmins()
        }
        .alert("Hata", isPresented: .constant(errorMessage != nil)) {
            Button("Tamam") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "Hepsi", filter: nil)
                filterChip(label: "Onay Bekleyen", filter: .pending)
                filterChip(label: "Onaylı", filter: .approved)
                filterChip(label: "Reddedilen", filter: .rejected)
                filterChip(label: "Askıdaki", filter: .suspended)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.appBackground)
    }

    private func filterChip(label: String, filter: AdminApprovalStatus?) -> some View {
        let isSelected = statusFilter == filter
        return Button {
            statusFilter = filter
            Task { await loadAdmins() }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? primaryColor : Color.appCardBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - List Content
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredAdmins, id: \.id) { admin in
                    NavigationLink {
                        AdminReviewDetailView(adminId: admin.id ?? "") {
                            Task { await loadAdmins() }
                        }
                    } label: {
                        adminCard(for: admin)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Admin Card
    private func adminCard(for admin: AdminProfile) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(badgeColor(for: admin.approvalStatus).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: iconFor(status: admin.approvalStatus))
                    .foregroundColor(badgeColor(for: admin.approvalStatus))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(admin.businessName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("VKN: \(admin.taxNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(admin.approvalStatus.displayName)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(badgeColor(for: admin.approvalStatus).opacity(0.15))
                    .foregroundColor(badgeColor(for: admin.approvalStatus))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "Sonuç yok" : "\"\(searchText)\" için sonuç yok")
                .font(.headline)
            if statusFilter != nil {
                Text("Farklı bir filtre seçin veya filtreyi kaldırın.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtered Admins
    private var filteredAdmins: [AdminProfile] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return allAdmins }
        return allAdmins.filter { admin in
            admin.businessName.lowercased().contains(trimmed)
                || admin.taxNumber.lowercased().contains(trimmed)
        }
    }

    private func badgeColor(for status: AdminApprovalStatus) -> Color {
        switch status {
        case .pending:   return .orange
        case .approved:  return primaryColor
        case .rejected:  return .red
        case .suspended: return .red
        }
    }

    private func iconFor(status: AdminApprovalStatus) -> String {
        switch status {
        case .pending:   return "clock.fill"
        case .approved:  return "checkmark.seal.fill"
        case .rejected:  return "xmark.octagon.fill"
        case .suspended: return "lock.fill"
        }
    }

    // MARK: - Load
    @MainActor
    private func loadAdmins() async {
        isLoading = true
        defer { isLoading = false }

        do {
            allAdmins = try await adminService.fetchAllAdmins(status: statusFilter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AllAdminsListView()
    }
}
