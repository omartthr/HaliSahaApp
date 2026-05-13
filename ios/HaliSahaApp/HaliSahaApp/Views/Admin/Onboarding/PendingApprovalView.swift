//
//  PendingApprovalView.swift
//  HaliSahaApp
//
//  Belge yüklemiş ama henüz onaylanmamış admin'in karşılaştığı bekleme ekranı.
//  Listener sayesinde super admin onayladığında otomatik olarak AdminTabView'a geçer.
//

import SwiftUI

// MARK: - Pending Approval View
struct PendingApprovalView: View {

    // MARK: - Properties
    let profile: AdminProfile?
    @StateObject private var authService = AuthService.shared
    @State private var showSignOutConfirm = false

    private let primaryColor = Color(hex: "2E7D32")

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerIcon

                    titleBlock

                    timelineCard

                    summaryCard

                    contactCard

                    signOutButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .confirmationDialog(
                "Çıkış yapmak istediğinize emin misiniz?",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Çıkış Yap", role: .destructive) {
                    try? authService.signOut()
                }
                Button("Vazgeç", role: .cancel) {}
            }
        }
    }

    // MARK: - Header Icon
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.12))
                .frame(width: 110, height: 110)
            Image(systemName: "hourglass")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .symbolEffect(.pulse, options: .repeating)
        }
        .padding(.top, 8)
    }

    // MARK: - Title Block
    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Belgeleriniz İnceleniyor")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Başvurunuz alındı. Yetkili ekibimiz belgelerinizi inceliyor.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Timeline Card
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Süreç")
                .font(.headline)

            timelineRow(
                icon: "checkmark.circle.fill",
                color: primaryColor,
                title: "Hesap oluşturuldu",
                subtitle: profile.map { formatDate($0.createdAt) } ?? "—",
                isDone: true
            )

            timelineRow(
                icon: "checkmark.circle.fill",
                color: primaryColor,
                title: "Belgeler gönderildi",
                subtitle: (profile?.documentsSubmittedAt).map(formatDate) ?? "—",
                isDone: true
            )

            timelineRow(
                icon: "magnifyingglass.circle.fill",
                color: .orange,
                title: "İnceleme aşamasında",
                subtitle: "Genellikle 1-2 iş günü sürer",
                isDone: false,
                isCurrent: true
            )

            timelineRow(
                icon: "circle",
                color: .gray.opacity(0.5),
                title: "Onay & hesap aktivasyonu",
                subtitle: "Bildirim ile haberdar edileceksiniz",
                isDone: false
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    private func timelineRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        isDone: Bool,
        isCurrent: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isDone || isCurrent ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Başvuru Özeti")
                .font(.headline)

            summaryRow(label: "İşletme", value: profile?.businessName ?? "—")
            Divider()
            summaryRow(label: "Vergi No", value: profile?.taxNumber ?? "—")
            Divider()
            summaryRow(
                label: "Yüklenen Belge",
                value: documentCountText
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }

    private var documentCountText: String {
        guard let docs = profile?.documents else { return "—" }
        var count = 0
        if docs.taxCertificateURL?.isEmpty == false { count += 1 }
        if docs.businessLicenseURL?.isEmpty == false { count += 1 }
        if docs.idFrontURL?.isEmpty == false { count += 1 }
        if docs.idBackURL?.isEmpty == false { count += 1 }
        count += docs.facilityPhotoURLs.count
        return "\(count) belge"
    }

    // MARK: - Contact Card
    private var contactCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "envelope.fill")
                .foregroundColor(primaryColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Sorunuz mu var?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(AppConstants.supportEmail) adresinden bize ulaşabilirsiniz.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(primaryColor.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        PrimaryButton(
            title: "Çıkış Yap",
            icon: "arrow.left.square",
            style: .outline
        ) {
            showSignOutConfirm = true
        }
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    PendingApprovalView(profile: AdminProfile(
        id: "preview",
        businessName: "Yıldız Halı Saha",
        taxNumber: "1234567890",
        approvalStatus: .pending,
        documents: VerificationDocuments(
            taxCertificateURL: "url",
            businessLicenseURL: "url",
            idFrontURL: "url",
            idBackURL: "url",
            facilityPhotoURLs: ["a", "b", "c"]
        ),
        documentsSubmittedAt: Date(),
        createdAt: Date()
    ))
}
