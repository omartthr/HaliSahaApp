//
//  AdminReviewDetailView.swift
//  HaliSahaApp
//
//  Tek bir başvurunun süper admin tarafından incelendiği ekran.
//  - Başvuru bilgileri (form verisi)
//  - 4 belge + saha fotoğrafları (zoomable)
//  - Manuel checklist (kendi takibin için)
//  - GİB sorgu bağlantısı
//  - Onayla / Reddet / Askıya al aksiyonları
//

import SwiftUI

// MARK: - Admin Review Detail View
struct AdminReviewDetailView: View {

    let adminId: String
    let onActionTaken: () -> Void   // Aksiyon sonrası listeyi yenilemek için callback

    @StateObject private var adminService = AdminService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var profile: AdminProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Inceleme checklist'i (sadece local — DB'ye yazılmıyor)
    @State private var checkTaxMatches = false
    @State private var checkLicenseValid = false
    @State private var checkIdMatches = false
    @State private var checkPhotosReal = false
    @State private var checkGibVerified = false

    // Aksiyon sheet'leri
    @State private var showRejectSheet = false
    @State private var showSuspendSheet = false
    @State private var actionReason = ""
    @State private var isPerformingAction = false

    // Belge görüntüleyici
    @State private var viewingDocURL: String?
    @State private var viewingDocTitle: String = ""

    private let primaryColor = Color(hex: "2E7D32")

    var body: some View {
        SwiftUI.Group {
            if let profile = profile {
                content(for: profile)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyState
            }
        }
        .navigationTitle("Başvuru İncelemesi")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            await loadProfile()
        }
        .sheet(isPresented: $showRejectSheet) {
            actionReasonSheet(
                title: "Başvuruyu Reddet",
                description: "Red sebebini detaylı yazın. Başvuru sahibi bu mesajı görerek belgelerini düzeltebilir.",
                color: .red,
                actionLabel: "Reddet"
            ) {
                await reject()
            }
        }
        .sheet(isPresented: $showSuspendSheet) {
            actionReasonSheet(
                title: "Hesabı Askıya Al",
                description: "Askıya alma sebebini yazın. Bu sebep işletmeciye gösterilecek.",
                color: .red,
                actionLabel: "Askıya Al"
            ) {
                await suspend()
            }
        }
        .fullScreenCover(item: Binding(
            get: { viewingDocURL.map { ViewingDoc(url: $0, title: viewingDocTitle) } },
            set: { viewingDocURL = $0?.url }
        )) { doc in
            DocumentViewerSheet(imageURL: doc.url, title: doc.title)
        }
        .alert("Hata", isPresented: .constant(errorMessage != nil)) {
            Button("Tamam") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Main Content
    private func content(for profile: AdminProfile) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                businessInfoCard(profile)
                documentsSection(profile)
                facilityPhotosSection(profile)
                checklistCard
                gibVerifyCard(profile)
                actionButtons(profile)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Business Info
    private func businessInfoCard(_ profile: AdminProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(primaryColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundColor(primaryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.businessName)
                        .font(.headline)
                    statusBadge(profile.approvalStatus)
                }
                Spacer()
            }

            Divider()

            infoRow(label: "Vergi No", value: profile.taxNumber)
            infoRow(label: "Başvuru", value: formatDate(profile.createdAt))
            if let submitted = profile.documentsSubmittedAt {
                infoRow(label: "Belge Gönderim", value: formatDate(submitted))
            }
            if let reviewed = profile.reviewedAt {
                infoRow(label: "Son İnceleme", value: formatDate(reviewed))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Documents (4 zorunlu belge)
    private func documentsSection(_ profile: AdminProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Belgeler", icon: "doc.text.fill")

            documentRow(
                title: AdminDocumentType.taxCertificate.displayName,
                url: profile.documents.taxCertificateURL,
                icon: "doc.badge.gearshape"
            )
            documentRow(
                title: AdminDocumentType.businessLicense.displayName,
                url: profile.documents.businessLicenseURL,
                icon: "building.columns"
            )
            documentRow(
                title: AdminDocumentType.idFront.displayName,
                url: profile.documents.idFrontURL,
                icon: "person.text.rectangle"
            )
            documentRow(
                title: AdminDocumentType.idBack.displayName,
                url: profile.documents.idBackURL,
                icon: "person.text.rectangle.fill"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    private func documentRow(title: String, url: String?, icon: String) -> some View {
        Button {
            if let url = url, !url.isEmpty {
                viewingDocURL = url
                viewingDocTitle = title
            }
        } label: {
            HStack(spacing: 12) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(primaryColor.opacity(0.1))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: icon)
                                .foregroundColor(primaryColor)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(url != nil ? "Görüntülemek için dokun" : "Yüklenmedi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "magnifyingglass.circle")
                    .font(.title3)
                    .foregroundColor(primaryColor)
            }
            .padding(10)
            .background(Color.appBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Facility Photos
    private func facilityPhotosSection(_ profile: AdminProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "Saha Fotoğrafları (\(profile.documents.facilityPhotoURLs.count))",
                icon: "photo.stack.fill"
            )

            if profile.documents.facilityPhotoURLs.isEmpty {
                Text("Saha fotoğrafı yüklenmedi.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(profile.documents.facilityPhotoURLs, id: \.self) { url in
                        Button {
                            viewingDocURL = url
                            viewingDocTitle = "Saha Fotoğrafı"
                        } label: {
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipped()
                                    .cornerRadius(10)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 100)
                                    .overlay(ProgressView())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Checklist
    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("İnceleme Checklist'i", icon: "checklist")

            Text("Aşağıdaki kontrolleri belgelere bakarak doğrula:")
                .font(.caption)
                .foregroundColor(.secondary)

            checkRow(
                isOn: $checkTaxMatches,
                text: "Vergi numarası ve unvan vergi levhasıyla eşleşiyor"
            )
            checkRow(
                isOn: $checkLicenseValid,
                text: "İşyeri ruhsatı geçerli ve faaliyet konusu spor tesisi"
            )
            checkRow(
                isOn: $checkIdMatches,
                text: "Kimlik adı vergi levhası sahibi/yetkilisiyle aynı"
            )
            checkRow(
                isOn: $checkPhotosReal,
                text: "Saha fotoğrafları gerçek (stock değil) ve tabela uyumlu"
            )
            checkRow(
                isOn: $checkGibVerified,
                text: "GİB üzerinden vergi numarası teyit edildi"
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    private func checkRow(isOn: Binding<Bool>, text: String) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isOn.wrappedValue ? primaryColor : .secondary)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - GİB Verify Card
    private func gibVerifyCard(_ profile: AdminProfile) -> some View {
        Button {
            if let url = URL(string: "https://interaktifvd.gib.gov.tr") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.title3)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("GİB'de Vergi No Sorgula")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("interaktifvd.gib.gov.tr")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.blue)
            }
            .padding(14)
            .background(Color.blue.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // MARK: - Action Buttons
    private func actionButtons(_ profile: AdminProfile) -> some View {
        VStack(spacing: 10) {
            if profile.approvalStatus != .approved {
                PrimaryButton(
                    title: "Başvuruyu Onayla",
                    icon: "checkmark.shield.fill",
                    isLoading: isPerformingAction,
                    isDisabled: !allChecksPassed
                ) {
                    Task { await approve() }
                }

                if !allChecksPassed {
                    Text("Onaylamak için tüm checklist maddelerini işaretleyin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }

            if profile.approvalStatus != .rejected {
                PrimaryButton(
                    title: "Reddet",
                    icon: "xmark.octagon.fill",
                    style: .destructive
                ) {
                    actionReason = ""
                    showRejectSheet = true
                }
            }

            if profile.approvalStatus == .approved {
                PrimaryButton(
                    title: "Askıya Al",
                    icon: "lock.fill",
                    style: .outline
                ) {
                    actionReason = ""
                    showSuspendSheet = true
                }
            }
        }
        .padding(.top, 8)
    }

    private var allChecksPassed: Bool {
        checkTaxMatches && checkLicenseValid && checkIdMatches
            && checkPhotosReal && checkGibVerified
    }

    // MARK: - Reason Sheet
    @ViewBuilder
    private func actionReasonSheet(
        title: String,
        description: String,
        color: Color,
        actionLabel: String,
        action: @escaping () async -> Void
    ) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Sebep yazın...", text: $actionReason, axis: .vertical)
                        .lineLimit(4...10)
                        .padding(12)
                        .background(Color.appCardBackground)
                        .cornerRadius(10)

                    PrimaryButton(
                        title: actionLabel,
                        icon: "paperplane.fill",
                        style: .destructive,
                        isLoading: isPerformingAction,
                        isDisabled: actionReason.trimmingCharacters(in: .whitespacesAndNewlines).count < 10
                    ) {
                        Task {
                            await action()
                        }
                    }

                    if actionReason.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
                        Text("En az 10 karakter girin.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("İptal") {
                        showRejectSheet = false
                        showSuspendSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(primaryColor)
            Text(title)
                .font(.headline)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }

    private func statusBadge(_ status: AdminApprovalStatus) -> some View {
        Text(status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("Başvuru bulunamadı")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions
    @MainActor
    private func loadProfile() async {
        guard !adminId.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            profile = try await adminService.fetchAdminProfile(adminId: adminId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func approve() async {
        guard !adminId.isEmpty else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            try await adminService.approveAdmin(adminId: adminId)
            onActionTaken()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func reject() async {
        guard !adminId.isEmpty else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            try await adminService.rejectAdmin(adminId: adminId, reason: actionReason)
            showRejectSheet = false
            onActionTaken()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func suspend() async {
        guard !adminId.isEmpty else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            try await adminService.suspendAdmin(adminId: adminId, reason: actionReason)
            showSuspendSheet = false
            onActionTaken()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Helper struct for fullScreenCover identity
private struct ViewingDoc: Identifiable {
    let url: String
    let title: String
    var id: String { url }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AdminReviewDetailView(adminId: "preview") {}
    }
}
