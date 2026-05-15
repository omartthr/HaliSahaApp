//
//  RejectedView.swift
//  HaliSahaApp
//
//  Başvurusu reddedilmiş admin'in karşılaştığı ekran.
//  Red sebebi gösterilir + "Belgeleri Yeniden Yükle" butonu ile
//  AdminDocumentUploadView'a geri döner.
//

import SwiftUI

// MARK: - Rejected View
struct RejectedView: View {

    // MARK: - Properties
    let profile: AdminProfile?
    @StateObject private var authService = AuthService.shared
    @State private var showReupload = false
    @State private var showSignOutConfirm = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerIcon

                    titleBlock

                    rejectionReasonCard

                    nextStepsCard

                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .fullScreenCover(isPresented: $showReupload) {
                AdminDocumentUploadView()
            }
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
                .fill(Color.red.opacity(0.12))
                .frame(width: 110, height: 110)
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
        }
        .padding(.top, 8)
    }

    // MARK: - Title Block
    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("Başvurunuz Reddedildi")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Belgelerinizi gözden geçirip aşağıdaki sebebi düzelttikten sonra tekrar gönderebilirsiniz.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Rejection Reason Card
    private var rejectionReasonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .foregroundColor(.red)
                Text("Red Sebebi")
                    .font(.headline)
            }

            Text(profile?.rejectionReason ?? "Sebep belirtilmedi.")
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.red.opacity(0.08))
                .cornerRadius(10)

            if let reviewedAt = profile?.reviewedAt {
                Text("İnceleme tarihi: \(formatDate(reviewedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    // MARK: - Next Steps
    private var nextStepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yeniden Başvurmadan Önce")
                .font(.headline)

            stepRow(number: 1, text: "Yukarıdaki red sebebini dikkatlice okuyun")
            stepRow(number: 2, text: "İlgili belgeleri yenileyin (örn. tarihi geçmiş ruhsat)")
            stepRow(number: 3, text: "Fotoğrafların okunaklı ve net olduğundan emin olun")
            stepRow(number: 4, text: "Belgeleri yeniden yükleyip tekrar gönderin")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "2E7D32").opacity(0.15))
                    .frame(width: 26, height: 26)
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: "Belgeleri Yeniden Yükle",
                icon: "arrow.clockwise"
            ) {
                showReupload = true
            }

            PrimaryButton(
                title: "Çıkış Yap",
                icon: "arrow.left.square",
                style: .outline
            ) {
                showSignOutConfirm = true
            }
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

// MARK: - Suspended View
struct SuspendedView: View {

    let profile: AdminProfile?
    @StateObject private var authService = AuthService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 110, height: 110)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 16)

                    Text("Hesabınız Askıya Alındı")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    if let reason = profile?.rejectionReason, !reason.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sebep")
                                .font(.headline)
                            Text(reason)
                                .font(.subheadline)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(10)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                    }

                    Text("Hesabınızın yeniden aktive edilmesi için destek ekibiyle iletişime geçmeniz gerekiyor: destek@halisaha.app")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    PrimaryButton(
                        title: "Çıkış Yap",
                        icon: "arrow.left.square",
                        style: .outline
                    ) {
                        try? authService.signOut()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
            .background(Color.appBackground.ignoresSafeArea())
        }
    }
}

// MARK: - Preview
#Preview("Rejected") {
    RejectedView(profile: AdminProfile(
        id: "preview",
        businessName: "Yıldız Halı Saha",
        taxNumber: "1234567890",
        approvalStatus: .rejected,
        rejectionReason: "Vergi levhasındaki unvan başvuru sırasında girdiğiniz işletme adıyla eşleşmiyor. Lütfen güncel ve okunaklı bir belge yükleyin.",
        reviewedAt: Date()
    ))
}

#Preview("Suspended") {
    SuspendedView(profile: AdminProfile(
        id: "preview",
        businessName: "Yıldız Halı Saha",
        taxNumber: "1234567890",
        approvalStatus: .suspended,
        rejectionReason: "Yapılan şikayetler sonucu hesap askıya alındı."
    ))
}
