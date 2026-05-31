//
//  ProfileSettingsView.swift
//  HaliSahaApp
//
//  Profil ayarları - hesap, bildirimler, gizlilik, hakkında
//

import FirebaseAuth
import SwiftUI
import UserNotifications

// MARK: - Profile Settings View
struct ProfileSettingsView: View {

    // MARK: - Dependencies
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    // MARK: - Settings (UserDefaults backed)
    @AppStorage("settings.matchReminders") private var matchReminders = true

    // MARK: - Notification permission state
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - UI State
    @State private var showLogoutAlert = false
    @State private var showDeleteConfirm = false
    @State private var showFinalDeleteConfirm = false
    @State private var showResetOnboardingAlert = false
    @State private var isProcessing = false
    @State private var errorMessage = ""
    @State private var showError = false

    // MARK: - Body
    var body: some View {
        Form {
            // Account Section
            accountSection

            // Notifications Section
            notificationsSection

            // App Section
            appSection

            // Support Section
            supportSection

            // Danger Zone
            dangerZoneSection

            // Debug / Test
            debugSection

            // App Info
            appInfoSection
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .tint(Color(hex: "2E7D32"))
        .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
            Button("Vazgeç", role: .cancel) {}
            Button("Çıkış Yap", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Hesabınızdan çıkış yapmak istediğinizden emin misiniz?")
        }
        .alert("Hesabı Sil", isPresented: $showDeleteConfirm) {
            Button("Vazgeç", role: .cancel) {}
            Button("Devam Et", role: .destructive) {
                showFinalDeleteConfirm = true
            }
        } message: {
            Text(
                "Hesabınızı silmek üzeresiniz. Tüm verileriniz kalıcı olarak silinecek ve bu işlem geri alınamaz."
            )
        }
        .alert("Son Onay", isPresented: $showFinalDeleteConfirm) {
            Button("Vazgeç", role: .cancel) {}
            Button("Hesabı Sil", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("Bu işlemi onaylamak için \"Hesabı Sil\" seçeneğine dokunun.")
        }
        .alert("Onboarding'i Sıfırla", isPresented: $showResetOnboardingAlert) {
            Button("Vazgeç", role: .cancel) {}
            Button("Sıfırla ve Çıkış Yap", role: .destructive) {
                Task { await resetOnboardingAndSignOut() }
            }
        } message: {
            Text(
                "Onboarding cevapların silinecek ve hesabından çıkış yapılacaksın. Tekrar giriş yaptığında onboarding'i baştan göreceksin."
            )
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isProcessing {
                LoadingView()
            }
        }
        .task {
            await loadAuthStatus()
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section {
            NavigationLink {
                EditProfileView()
            } label: {
                SettingsRow(icon: "person.fill", iconColor: Color(hex: "2E7D32"), title: "Profili Düzenle")
            }

            NavigationLink {
                EditBillingAddressView()
            } label: {
                HStack {
                    SettingsRow(
                        icon: "creditcard.fill",
                        iconColor: Color(hex: "2E7D32"),
                        title: "Fatura Adresi",
                        chevron: false
                    )
                    Spacer()
                    if authService.currentUser?.billingAddress?.isComplete != true {
                        Text("Eksik")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.18))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            NavigationLink {
                ChangePasswordView()
            } label: {
                SettingsRow(icon: "lock.fill", iconColor: Color(hex: "2E7D32"), title: "Şifre Değiştir")
            }
        } header: {
            Text("Hesap")
        }
    }

    private var notificationsSection: some View {
        Section {
            // Maç hatırlatması toggle'ı (24/2 saat öncesi)
            Toggle(isOn: $matchReminders) {
                VStack(alignment: .leading, spacing: 2) {
                    SettingsRow(
                        icon: "calendar.badge.clock",
                        iconColor: .purple,
                        title: "Maç Hatırlatmaları",
                        chevron: false
                    )
                    Text("Maçtan 24 ve 2 saat önce hatırlatma alırsın")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 44)
                }
            }
            .onChange(of: matchReminders) { _, _ in
                Task { await syncRemindersAfterToggle() }
            }

            // İzin durumu satırı
            permissionStatusRow
        } header: {
            Text("Bildirimler")
        } footer: {
            Text(
                "Push ve sohbet bildirimleri yakında eklenecek."
            )
            .font(.caption2)
        }
    }

    // MARK: - Permission Status Row
    @ViewBuilder
    private var permissionStatusRow: some View {
        switch notificationAuthStatus {
        case .denied:
            Button {
                openSystemSettings()
            } label: {
                HStack {
                    SettingsRow(
                        icon: "exclamationmark.bubble.fill",
                        iconColor: .red,
                        title: "Bildirimler Kapalı",
                        chevron: false,
                        titleColor: .red
                    )
                    Spacer()
                    Text("Ayarları Aç")
                        .font(.caption)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }

        case .notDetermined:
            Button {
                Task { await requestPermission() }
            } label: {
                HStack {
                    SettingsRow(
                        icon: "bell.badge",
                        iconColor: .orange,
                        title: "Bildirim İzni Ver",
                        chevron: false
                    )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        case .authorized, .provisional, .ephemeral:
            HStack {
                SettingsRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Bildirimler Açık",
                    chevron: false
                )
                Spacer()
            }

        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Notification Helpers
    private func loadAuthStatus() async {
        notificationAuthStatus = await NotificationService.shared.authorizationStatus()
    }

    private func requestPermission() async {
        _ = await NotificationService.shared.requestPermission()
        await loadAuthStatus()
        await syncRemindersAfterToggle()
    }

    private func syncRemindersAfterToggle() async {
        do {
            let upcoming = try await BookingService.shared.fetchUpcomingBookings()
            await NotificationService.shared.syncReminders(for: upcoming)
        } catch {
            // Bildirimler önemsiz hata — yutar
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private var appSection: some View {
        Section {
            HStack {
                SettingsRow(icon: "globe", iconColor: .indigo, title: "Dil", chevron: false)
                Spacer()
                Text("Türkçe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            NavigationLink {
                StaticInfoView(
                    title: "Veri Kullanımı",
                    icon: "internaldrive.fill",
                    sections: [
                        .init(
                            heading: "Ön Bellek",
                            body:
                                "Uygulama, fotoğrafları ve sık kullanılan verileri cihazınızda önbelleğe alır. Bu, daha hızlı yükleme süresi sağlar."
                        ),
                        .init(
                            heading: "Veri Tasarrufu",
                            body:
                                "Mobil veri kullanırken yüksek çözünürlüklü görseller otomatik olarak optimize edilir."
                        ),
                    ]
                )
            } label: {
                SettingsRow(icon: "internaldrive.fill", iconColor: .gray, title: "Veri ve Depolama")
            }
        } header: {
            Text("Uygulama")
        }
    }

    private var supportSection: some View {
        Section {
            Button {
                openExternalLink(AppConstants.Links.helpCenter)
            } label: {
                SettingsRow(icon: "questionmark.circle.fill", iconColor: .blue, title: "Yardım Merkezi")
            }

            Button {
                openMail()
            } label: {
                SettingsRow(icon: "paperplane.fill", iconColor: .blue, title: "Bize Ulaşın")
            }

            Button {
                openExternalLink(AppConstants.Links.termsOfUse)
            } label: {
                SettingsRow(icon: "doc.text.fill", iconColor: .gray, title: "Kullanım Koşulları")
            }

            Button {
                openExternalLink(AppConstants.Links.privacyPolicy)
            } label: {
                SettingsRow(icon: "hand.raised.fill", iconColor: .green, title: "Gizlilik Politikası")
            }
        } header: {
            Text("Destek ve Sözleşmeler")
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    SettingsRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        iconColor: .orange,
                        title: "Çıkış Yap",
                        chevron: false,
                        titleColor: .orange
                    )
                    Spacer()
                }
            }

            Button {
                showDeleteConfirm = true
            } label: {
                HStack {
                    SettingsRow(
                        icon: "trash.fill",
                        iconColor: .red,
                        title: "Hesabı Sil",
                        chevron: false,
                        titleColor: .red
                    )
                    Spacer()
                }
            }
        }
    }

    private var debugSection: some View {
        Section {
            Button {
                showResetOnboardingAlert = true
            } label: {
                HStack {
                    SettingsRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        iconColor: .purple,
                        title: "Onboarding'i Sıfırla (Test)",
                        chevron: false,
                        titleColor: .purple
                    )
                    Spacer()
                }
            }
        } header: {
            Text("Geliştirici")
        } footer: {
            Text(
                "Onboarding cevaplarını siler ve çıkış yapar. Tekrar giriş yaptığında onboarding'i baştan görürsün."
            )
            .font(.caption2)
        }
    }

    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Versiyon")
                    .foregroundColor(.primary)
                Spacer()
                Text("\(AppConstants.appVersion) (\(AppConstants.buildNumber))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } footer: {
            HStack {
                Spacer()
                Text("\(AppConstants.appName) © \(currentYear)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Actions
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func resetOnboardingAndSignOut() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await ProfileService.shared.resetOnboarding()
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func deleteAccount() async {
        isProcessing = true
        do {
            try await authService.deleteAccount()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            // Firebase Auth özel hata kodlarını yakalamak
            let nsError = error as NSError
            if let code = AuthErrorCode(rawValue: nsError.code), code == .requiresRecentLogin {
                errorMessage =
                    "Güvenlik nedeniyle yakın zamanda giriş yapmanız gerekiyor. Lütfen çıkış yapıp tekrar giriş yaptıktan sonra deneyin."
            } else {
                errorMessage = error.localizedDescription
            }
            showError = true
        }
        isProcessing = false
    }

    private func openMail() {
        guard let url = URL(string: "mailto:\(AppConstants.supportEmail)") else { return }
        openURL(url)
    }
    
    private func openExternalLink(_ url: URL) {
        openURL(url)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var chevron: Bool = true
    var titleColor: Color = .primary

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 30, height: 30)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(titleColor)

            Spacer()
        }
    }
}

// MARK: - Static Info View
struct StaticInfoView: View {
    let title: String
    let icon: String
    let sections: [Section]

    struct Section: Identifiable {
        let id = UUID()
        let heading: String
        let body: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2E7D32").opacity(0.12))
                            .frame(width: 56, height: 56)

                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "2E7D32"))
                    }

                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 8)

                // Sections
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.heading)
                            .font(.headline)
                        Text(section.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
}
