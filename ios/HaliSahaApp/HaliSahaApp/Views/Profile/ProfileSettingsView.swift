//
//  ProfileSettingsView.swift
//  HaliSahaApp
//
//  Profil ayarları - hesap, bildirimler, gizlilik, hakkında
//

import FirebaseAuth
import SwiftUI

// MARK: - Profile Settings View
struct ProfileSettingsView: View {

    // MARK: - Dependencies
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss

    // MARK: - Settings (UserDefaults backed)
    @AppStorage("settings.pushNotifications") private var pushNotifications = true
    @AppStorage("settings.emailNotifications") private var emailNotifications = true
    @AppStorage("settings.bookingReminders") private var bookingReminders = true
    @AppStorage("settings.matchInvites") private var matchInvites = true

    // MARK: - UI State
    @State private var showLogoutAlert = false
    @State private var showDeleteConfirm = false
    @State private var showFinalDeleteConfirm = false
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

            // App Info
            appInfoSection
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
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
            Toggle(isOn: $pushNotifications) {
                SettingsRow(icon: "bell.fill", iconColor: .orange, title: "Push Bildirimleri", chevron: false)
            }

            Toggle(isOn: $emailNotifications) {
                SettingsRow(icon: "envelope.fill", iconColor: .blue, title: "E-posta Bildirimleri", chevron: false)
            }

            Toggle(isOn: $bookingReminders) {
                SettingsRow(icon: "calendar.badge.clock", iconColor: .purple, title: "Maç Hatırlatmaları", chevron: false)
            }

            Toggle(isOn: $matchInvites) {
                SettingsRow(icon: "person.badge.plus", iconColor: Color(hex: "2E7D32"), title: "Maç Davetleri", chevron: false)
            }
        } header: {
            Text("Bildirimler")
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
            NavigationLink {
                StaticInfoView(
                    title: "Yardım Merkezi",
                    icon: "questionmark.circle.fill",
                    sections: [
                        .init(
                            heading: "Rezervasyon Nasıl Yapılır?",
                            body:
                                "Keşfet sekmesinden istediğiniz sahayı seçin, tarih ve saat belirleyin, ödemeyi tamamlayarak rezervasyonunuzu oluşturun."
                        ),
                        .init(
                            heading: "İptal Politikası",
                            body:
                                "Rezervasyonunuzu maçtan en az 24 saat önce iptal ederseniz kapora ücreti tam olarak iade edilir. Daha kısa süre içinde iptaller için iade yapılmaz."
                        ),
                        .init(
                            heading: "Ödeme Yöntemleri",
                            body:
                                "Kredi kartı, banka kartı veya uygulama içi cüzdan ile ödeme yapabilirsiniz. Tüm ödemeler 256-bit SSL ile şifrelenir."
                        ),
                    ]
                )
            } label: {
                SettingsRow(icon: "questionmark.circle.fill", iconColor: .blue, title: "Yardım Merkezi")
            }

            Button {
                openMail()
            } label: {
                SettingsRow(icon: "paperplane.fill", iconColor: .blue, title: "Bize Ulaşın")
            }

            NavigationLink {
                StaticInfoView(
                    title: "Kullanım Koşulları",
                    icon: "doc.text.fill",
                    sections: [
                        .init(
                            heading: "Hizmet Koşulları",
                            body:
                                "Bu uygulamayı kullanarak, hizmet koşullarımızı kabul etmiş sayılırsınız. Tüm rezervasyonlar tesis sahibinin onayına tabidir."
                        ),
                        .init(
                            heading: "Kullanıcı Sorumlulukları",
                            body:
                                "Saha kurallarına uymakla, sahayı temiz tutmakla ve diğer kullanıcılara saygılı davranmakla yükümlüsünüz. Aksi davranışlar hesabınızın askıya alınmasına neden olabilir."
                        ),
                    ]
                )
            } label: {
                SettingsRow(icon: "doc.text.fill", iconColor: .gray, title: "Kullanım Koşulları")
            }

            NavigationLink {
                StaticInfoView(
                    title: "Gizlilik Politikası",
                    icon: "hand.raised.fill",
                    sections: [
                        .init(
                            heading: "Veri Toplama",
                            body:
                                "Hesap oluşturmak için ad, soyad, e-posta ve telefon bilgilerinizi topluyoruz. Bu veriler yalnızca hizmet sunmak için kullanılır."
                        ),
                        .init(
                            heading: "Konum Bilgisi",
                            body:
                                "Yakınınızdaki sahaları gösterebilmek için konum izni isteriz. Konum verileriniz yalnızca cihazınızda kalır."
                        ),
                        .init(
                            heading: "KVKK",
                            body:
                                "Kişisel verileriniz 6698 sayılı KVKK kanunu kapsamında korunmaktadır. Verilerinizin silinmesini istediğiniz zaman talep edebilirsiniz."
                        ),
                    ]
                )
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
                Text("HaliSaha © \(currentYear)")
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
        guard let url = URL(string: "mailto:destek@halisaha.app") else { return }
        UIApplication.shared.open(url)
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
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
