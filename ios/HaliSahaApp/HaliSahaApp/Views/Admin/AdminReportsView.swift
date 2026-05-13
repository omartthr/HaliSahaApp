//
//  AdminReportsView.swift
//  HaliSahaApp
//
//  Admin Raporlar
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import PhotosUI
import SwiftUI
import Charts
import UIKit
import UserNotifications

// MARK: - Admin Reports View
struct AdminReportsView: View {

    @StateObject private var viewModel = AdminReportsViewModel()
    @State private var selectedPeriod: ReportPeriod = .thisMonth

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period Selector
                periodSelector

                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    ProgressView()
                        .padding(.vertical, 60)
                } else {
                    // Revenue Chart
                    revenueChart

                    // Key Metrics
                    keyMetrics

                    // Booking Distribution
                    bookingDistribution

                    // Top Hours
                    topHoursSection
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Raporlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.exportReport()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            await viewModel.loadReport(period: selectedPeriod)
        }
        .onChange(of: selectedPeriod) { _, newValue in
            Task {
                await viewModel.loadReport(period: newValue)
            }
        }
        .refreshable {
            await viewModel.loadReport(period: selectedPeriod)
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(ReportPeriod.allCases) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color(hex: "2E7D32") : Color.appElevatedBackground)
                        .cornerRadius(20)
                }
            }
        }
    }
    
    // MARK: - Revenue Chart
    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Toplam Gelir")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.totalRevenue.asCurrency)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    let change = viewModel.revenueChangePercent
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text("\(change >= 0 ? "+" : "")\(change)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(change >= 0 ? .green : .red)

                    Text(viewModel.comparisonLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Chart
            Chart {
                ForEach(viewModel.revenueData) { item in
                    BarMark(
                        x: .value("Gün", item.day),
                        y: .value("Gelir", item.revenue)
                    )
                    .foregroundStyle(Color(hex: "2E7D32").gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue / 1000)K")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Key Metrics
    private var keyMetrics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Temel Metrikler")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Toplam Rezervasyon",
                    value: "\(viewModel.totalBookings)",
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                
                MetricCard(
                    title: "Ortalama Gelir",
                    value: viewModel.averageRevenue.asShortCurrency,
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                MetricCard(
                    title: "Doluluk Oranı",
                    value: "\(viewModel.occupancyRate)%",
                    icon: "percent",
                    color: .purple
                )
                
                MetricCard(
                    title: "İptal Oranı",
                    value: "\(viewModel.cancellationRate)%",
                    icon: "xmark.circle",
                    color: .red
                )
            }
        }
    }
    
    // MARK: - Booking Distribution
    private var bookingDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rezervasyon Dağılımı")
                .font(.headline)

            HStack(spacing: 20) {
                let occupancy = viewModel.distribution.completedPercent

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 20)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: CGFloat(min(occupancy, 100)) / 100)
                        .stroke(Color(hex: "2E7D32"), lineWidth: 20)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack {
                        Text("\(occupancy)%")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Doluluk")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    DistributionRow(
                        color: Color(hex: "2E7D32"),
                        label: "Tamamlanan",
                        value: "\(viewModel.distribution.completedPercent)%"
                    )
                    DistributionRow(
                        color: .orange,
                        label: "Bekleyen",
                        value: "\(viewModel.distribution.pendingPercent)%"
                    )
                    DistributionRow(
                        color: .red,
                        label: "İptal",
                        value: "\(viewModel.distribution.cancelledPercent)%"
                    )
                    DistributionRow(
                        color: .gray,
                        label: "Boş",
                        value: "\(viewModel.distribution.emptyPercent)%"
                    )
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Top Hours Section
    private var topHoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En Popüler Saatler")
                .font(.headline)

            VStack(spacing: 8) {
                if viewModel.topHours.isEmpty {
                    HStack {
                        Spacer()
                        Text("Henüz veri yok")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                        Spacer()
                    }
                } else {
                    ForEach(viewModel.topHours) { item in
                        PopularHourRow(
                            hour: item.hourString,
                            percentage: item.percentage
                        )
                    }
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Admin Reports ViewModel
@MainActor
final class AdminReportsViewModel: ObservableObject {

    @Published var revenueData: [RevenueDataPoint] = []
    @Published var totalRevenue: Double = 0
    @Published var totalBookings: Int = 0
    @Published var averageRevenue: Double = 0
    @Published var occupancyRate: Int = 0
    @Published var cancellationRate: Int = 0
    @Published var distribution: BookingDistribution = BookingDistribution()
    @Published var topHours: [PopularHour] = []
    @Published var revenueChangePercent: Int = 0
    @Published var comparisonLabel: String = "Geçen aya göre"
    @Published var isLoading: Bool = false
    @Published var hasLoadedOnce: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false

    private let adminService = AdminService.shared
    private var loadTask: Task<Void, Never>?

    func loadReport(period: ReportPeriod) async {
        loadTask?.cancel()

        let task = Task { [weak self] in
            guard let self = self else { return }
            self.isLoading = true

            do {
                let report = try await self.adminService.fetchReportData(period: period)
                if Task.isCancelled { return }

                self.revenueData = report.revenueData
                self.totalRevenue = report.totalRevenue
                self.totalBookings = report.totalBookings
                self.averageRevenue = report.averageRevenue
                self.occupancyRate = report.occupancyRate
                self.cancellationRate = report.cancellationRate
                self.distribution = report.distribution
                self.topHours = report.topHours
                self.revenueChangePercent = report.revenueChangePercent
                self.comparisonLabel = report.comparisonLabel
            } catch is CancellationError {
                // ignore
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }

            self.isLoading = false
            self.hasLoadedOnce = true
        }

        loadTask = task
        await task.value
    }

    func exportReport() {
    }
}

// MARK: - Revenue Data Point
struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let day: String
    let revenue: Double
}

// MARK: - Report Period
enum ReportPeriod: String, CaseIterable, Identifiable {
    case thisWeek = "Bu Hafta"
    case thisMonth = "Bu Ay"
    case lastMonth = "Geçen Ay"
    case custom = "Özel"
    
    var id: String { rawValue }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
}

struct DistributionRow: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.caption)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct PopularHourRow: View {
    let hour: String
    let percentage: Int
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(hour)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color(hex: "2E7D32"))
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Admin Settings View
struct AdminSettingsView: View {

    @StateObject private var viewModel = AdminSettingsViewModel()
    @StateObject private var authService = AuthService.shared
    @Environment(\.openURL) private var openURL
    @State private var showLogoutAlert = false

    // Photo picker
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isPhotoPickerPresented = false
    @State private var showPhotoOptions = false
    @State private var showRemovePhotoConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                statsCard
                businessPreferencesSection
                accountSection
                supportSection
                versionFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Ayarlar")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .tint(Color(hex: "2E7D32"))
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
        .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
            Button("Vazgeç", role: .cancel) {}
            Button("Çıkış Yap", role: .destructive) {
                signOut()
            }
        } message: {
            Text("İşletme hesabınızdan çıkış yapmak istediğinizden emin misiniz?")
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .overlay {
            if viewModel.isLoading && !viewModel.hasLoadedOnce {
                LoadingView()
            }
        }
        .confirmationDialog(
            "Profil Fotoğrafı",
            isPresented: $showPhotoOptions,
            titleVisibility: .visible
        ) {
            Button("Galeriden Seç") {
                showPhotoOptions = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPhotoPickerPresented = true
                }
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

    private var hasProfilePhoto: Bool {
        if let url = authService.currentUser?.profileImageURL {
            return !url.isEmpty
        }
        return false
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .top) {
            AdminSettingsHeroBackground()
                .frame(height: 236)
                .padding(.top, 56)

            VStack(spacing: 0) {
                avatarButton

                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text(viewModel.settings.businessName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text(authService.currentUser?.fullName ?? "Saha Sahibi")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.72))
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: approvalIcon)
                            .font(.caption)
                        Text(viewModel.settings.approvalStatus.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.16))
                    .foregroundColor(.white.opacity(0.88))
                    .clipShape(Capsule())

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
                        .background(Capsule().fill(Color.white))
                        .shadow(color: .black.opacity(0.14), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .padding(.top, 18)
    }

    private var avatarButton: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarView
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.appBackground, lineWidth: 5)
                }
                .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)

            Button {
                showPhotoOptions = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "69A95B"))
                        .frame(width: 38, height: 38)
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(viewModel.isUploadingPhoto)
            .offset(x: -2, y: -4)
        }
    }

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
        guard let user = authService.currentUser else { return "A" }
        let first = user.firstName.first.map { String($0) } ?? ""
        let last = user.lastName.first.map { String($0) } ?? ""
        let combined = (first + last).uppercased()
        return combined.isEmpty ? "A" : combined
    }

    private var approvalIcon: String {
        switch viewModel.settings.approvalStatus {
        case .approved: return "checkmark.seal.fill"
        case .pending: return "clock.fill"
        case .rejected: return "xmark.seal.fill"
        case .suspended: return "pause.circle.fill"
        }
    }

    // MARK: - Stats
    private var statsCard: some View {
        HStack(spacing: 0) {
            AdminSettingsStatTile(
                value: "\(viewModel.stats.totalFacilities)",
                label: "Tesis",
                icon: "building.2.fill"
            )

            Divider()
                .frame(height: 50)

            AdminSettingsStatTile(
                value: "\(viewModel.stats.totalPitches)",
                label: "Saha",
                icon: "sportscourt.fill"
            )

            Divider()
                .frame(height: 50)

            AdminSettingsStatTile(
                value: "\(viewModel.stats.pendingBookings)",
                label: "Bekleyen",
                icon: "clock.badge.fill"
            )
        }
        .padding(.vertical, 16)
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Business Preferences
    private var businessPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İşletme Ayarları")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Toggle(isOn: $viewModel.pushNotificationsEnabled) {
                    AdminSettingsToggleLabel(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Push Bildirimleri",
                        subtitle: viewModel.notificationPermissionText
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: viewModel.pushNotificationsEnabled) { _, newValue in
                    guard viewModel.hasLoadedOnce else { return }
                    Task { await viewModel.updatePushNotifications(newValue) }
                }

                if viewModel.notificationAuthStatus == .denied {
                    Divider().padding(.leading, 72)

                    Button {
                        openSystemSettings()
                    } label: {
                        AdminSettingsRow(
                            icon: "gearshape.fill",
                            iconColor: .red,
                            title: "Bildirim İzinlerini Aç",
                            subtitle: "iOS Ayarları üzerinden izin ver",
                            titleColor: .red
                        )
                    }
                    .buttonStyle(.plain)
                }

                Divider().padding(.leading, 72)

                Toggle(isOn: $viewModel.emailNotificationsEnabled) {
                    AdminSettingsToggleLabel(
                        icon: "envelope.fill",
                        iconColor: .blue,
                        title: "E-posta Bildirimleri",
                        subtitle: "Rezervasyon ve işletme duyuruları"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: viewModel.emailNotificationsEnabled) { _, newValue in
                    guard viewModel.hasLoadedOnce else { return }
                    Task { await viewModel.updateEmailNotifications(newValue) }
                }

                Divider().padding(.leading, 72)

                Toggle(isOn: $viewModel.autoConfirmBookings) {
                    AdminSettingsToggleLabel(
                        icon: "checkmark.circle.fill",
                        iconColor: Color(hex: "2E7D32"),
                        title: "Otomatik Onay",
                        subtitle: "Ödeme sonrası rezervasyonları otomatik onayla"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: viewModel.autoConfirmBookings) { _, newValue in
                    guard viewModel.hasLoadedOnce else { return }
                    Task { await viewModel.updateAutoConfirm(newValue) }
                }

                Divider().padding(.leading, 72)

                NavigationLink {
                    StaticInfoView(
                        title: "Ödeme Ayarları",
                        icon: "creditcard.fill",
                        sections: [
                            .init(
                                heading: "Kapora ile Rezervasyon",
                                body: "Kullanıcı rezervasyon sırasında kapora öder. Kalan tutar tesisinizde tahsil edilir."
                            ),
                            .init(
                                heading: "Otomatik Onay",
                                body: "Otomatik onay açıkken başarılı ödeme sonrası rezervasyon hemen onaylanır. Kapalıyken rezervasyon, admin onayı bekleyen listeye düşer."
                            ),
                            .init(
                                heading: "Tahsilat Notu",
                                body: "Uygulamadaki ödeme akışı simülasyon modundadır. Gerçek ödeme sağlayıcısı bağlandığında bu alan sağlayıcı bilgileriyle genişletilebilir."
                            ),
                        ]
                    )
                } label: {
                    AdminSettingsRow(
                        icon: "creditcard.fill",
                        iconColor: .green,
                        title: "Ödeme Ayarları",
                        subtitle: viewModel.autoConfirmBookings ? "Otomatik onay açık" : "Manuel onay açık"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                NavigationLink {
                    StaticInfoView(
                        title: "İptal Politikası",
                        icon: "doc.text.fill",
                        sections: [
                            .init(
                                heading: "Kullanıcı İptali",
                                body: "Kullanıcılar maç saatinden en az 24 saat önce rezervasyonunu iptal edebilir."
                            ),
                            .init(
                                heading: "Kapora Durumu",
                                body: "İptal edilebilir rezervasyonlarda kapora iade edilebilir olarak işaretlenir. Daha geç iptallerde kısmi iade akışı uygulanır."
                            ),
                            .init(
                                heading: "Admin İptali",
                                body: "Admin tarafında reddedilen rezervasyonlar kullanıcıya bildirimle iletilir ve rezervasyon takvimden düşer."
                            ),
                        ]
                    )
                } label: {
                    AdminSettingsRow(
                        icon: "doc.text.fill",
                        iconColor: .indigo,
                        title: "İptal Politikası",
                        subtitle: "24 saat öncesine kadar esnek iptal"
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            .disabled(viewModel.isSaving)
        }
    }

    // MARK: - Account
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hesap Bilgileri")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                NavigationLink {
                    EditProfileView()
                } label: {
                    AdminSettingsRow(
                        icon: "person.fill",
                        iconColor: Color(hex: "2E7D32"),
                        title: "Profili Düzenle",
                        subtitle: "Ad, soyad ve telefon bilgileri"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    AdminSettingsRow(
                        icon: "lock.fill",
                        iconColor: .purple,
                        title: "Şifre Değiştir",
                        subtitle: "Hesap güvenliğini güncelle"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                AccountInfoRow(
                    icon: "envelope.fill",
                    iconColor: Color(hex: "2E7D32"),
                    title: "E-posta",
                    value: authService.currentUser?.email ?? "-"
                )

                Divider().padding(.leading, 56)

                AccountInfoRow(
                    icon: "phone.fill",
                    iconColor: Color(hex: "2E7D32"),
                    title: "Telefon",
                    value: authService.currentUser?.phone.isEmpty == false ? authService.currentUser?.phone ?? "-" : "-"
                )

                Divider().padding(.leading, 56)

                AccountInfoRow(
                    icon: "number",
                    iconColor: Color(hex: "2E7D32"),
                    title: "Vergi No",
                    value: viewModel.settings.taxNumber
                )
            }
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: - Support
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Destek")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Button {
                    openExternalLink(AppConstants.Links.helpCenter)
                } label: {
                    AdminSettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .blue,
                        title: "Yardım Merkezi",
                        subtitle: "Sık sorulan sorular ve rehberler"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                Button {
                    openMail()
                } label: {
                    AdminSettingsRow(
                        icon: "paperplane.fill",
                        iconColor: .blue,
                        title: "Bize Ulaşın",
                        subtitle: AppConstants.supportEmail
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                Button {
                    openExternalLink(AppConstants.Links.termsOfUse)
                } label: {
                    AdminSettingsRow(
                        icon: "doc.text.fill",
                        iconColor: .gray,
                        title: "Kullanım Koşulları",
                        subtitle: "Hizmet şartları"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                Button {
                    openExternalLink(AppConstants.Links.privacyPolicy)
                } label: {
                    AdminSettingsRow(
                        icon: "hand.raised.fill",
                        iconColor: .green,
                        title: "Gizlilik Politikası",
                        subtitle: "Veri kullanımı ve gizlilik"
                    )
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 72)

                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    AdminSettingsRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        iconColor: .orange,
                        title: "Çıkış Yap",
                        subtitle: "Bu cihazdaki oturumu kapat",
                        titleColor: .orange,
                        showsChevron: false
                    )
                }
                .buttonStyle(.plain)
            }
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text(AppConstants.appName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("Versiyon \(AppConstants.appVersion) (\(AppConstants.buildNumber))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Actions
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            viewModel.present(error: error.localizedDescription)
        }
    }

    private func openMail() {
        guard let url = URL(string: "mailto:\(AppConstants.supportEmail)") else { return }
        openURL(url)
    }

    private func openExternalLink(_ url: URL) {
        openURL(url)
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

// MARK: - Admin Settings ViewModel
@MainActor
final class AdminSettingsViewModel: ObservableObject {

    @Published var settings = AdminSettingsData()
    @Published var stats = AdminService.DashboardStats()
    @Published var pushNotificationsEnabled = true
    @Published var emailNotificationsEnabled = true
    @Published var autoConfirmBookings = true
    @Published var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var hasLoadedOnce = false
    @Published var isUploadingPhoto = false
    @Published var errorMessage = ""
    @Published var showError = false

    private let adminService = AdminService.shared
    private let profileService = ProfileService.shared
    private let authService = AuthService.shared

    var notificationPermissionText: String {
        switch notificationAuthStatus {
        case .authorized, .provisional, .ephemeral:
            return "Cihaz bildirimi açık"
        case .denied:
            return "Cihaz izni kapalı"
        case .notDetermined:
            return "Açınca izin istenecek"
        @unknown default:
            return "Durum bilinmiyor"
        }
    }

    func load() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoadedOnce = true
        }

        notificationAuthStatus = await NotificationService.shared.authorizationStatus()

        do {
            settings = try await adminService.fetchAdminSettings()
            stats = try await adminService.fetchDashboardStats()
            pushNotificationsEnabled = settings.pushNotificationsEnabled
            emailNotificationsEnabled = settings.emailNotificationsEnabled
            autoConfirmBookings = settings.autoConfirmBookings
        } catch {
            present(error: error.localizedDescription)
        }
    }

    func updatePushNotifications(_ enabled: Bool) async {
        isSaving = true
        defer { isSaving = false }

        var finalValue = enabled

        if enabled {
            let granted = await NotificationService.shared.requestPermission()
            notificationAuthStatus = await NotificationService.shared.authorizationStatus()

            if !granted && notificationAuthStatus == .denied {
                finalValue = false
                pushNotificationsEnabled = false
                present(error: "Push bildirimleri için iOS Ayarları üzerinden izin vermeniz gerekiyor.")
            }
        }

        do {
            try await adminService.updateAdminPreferences(pushNotificationsEnabled: finalValue)
            settings.pushNotificationsEnabled = finalValue
        } catch {
            pushNotificationsEnabled = settings.pushNotificationsEnabled
            present(error: error.localizedDescription)
        }
    }

    func updateEmailNotifications(_ enabled: Bool) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await adminService.updateAdminPreferences(emailNotificationsEnabled: enabled)
            settings.emailNotificationsEnabled = enabled
        } catch {
            emailNotificationsEnabled = settings.emailNotificationsEnabled
            present(error: error.localizedDescription)
        }
    }

    func updateAutoConfirm(_ enabled: Bool) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await adminService.updateAdminPreferences(autoConfirmBookings: enabled)
            settings.autoConfirmBookings = enabled
        } catch {
            autoConfirmBookings = settings.autoConfirmBookings
            present(error: error.localizedDescription)
        }
    }

    func updateProfilePhoto(_ image: UIImage) async {
        isUploadingPhoto = true
        do {
            let url = try await profileService.updateProfilePhoto(image)
            if var user = authService.currentUser {
                user.profileImageURL = url
                authService.currentUser = user
            }
        } catch {
            present(error: error.localizedDescription)
        }
        isUploadingPhoto = false
    }

    func removeProfilePhoto() async {
        let currentURL = authService.currentUser?.profileImageURL
        isUploadingPhoto = true
        do {
            try await profileService.removeProfilePhoto(currentURL: currentURL)
            if var user = authService.currentUser {
                user.profileImageURL = nil
                authService.currentUser = user
            }
        } catch {
            present(error: error.localizedDescription)
        }
        isUploadingPhoto = false
    }

    func present(error message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Admin Settings Supporting Views
private struct AdminSettingsHeroBackground: View {
    var body: some View {
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
}

private struct AdminSettingsStatTile: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "2E7D32"))

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AdminSettingsToggleLabel: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            AdminSettingsIcon(icon: icon, iconColor: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

private struct AdminSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var titleColor: Color = .primary
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 14) {
            AdminSettingsIcon(icon: icon, iconColor: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct AdminSettingsIcon: View {
    let icon: String
    let iconColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(iconColor.opacity(0.12))
                .frame(width: 40, height: 40)

            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconColor)
        }
    }
}

// MARK: - Preview
#Preview("Reports") {
    NavigationStack {
        AdminReportsView()
    }
}

#Preview("Settings") {
    NavigationStack {
        AdminSettingsView()
    }
}
