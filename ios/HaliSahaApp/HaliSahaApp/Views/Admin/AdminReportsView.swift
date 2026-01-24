//
//  AdminReportsView.swift
//  HaliSahaApp
//
//  Admin Raporlar
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import SwiftUI
import Charts

// MARK: - Admin Reports View
struct AdminReportsView: View {
    
    @StateObject private var viewModel = AdminReportsViewModel()
    @State private var selectedPeriod: ReportPeriod = .thisMonth
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period Selector
                periodSelector
                
                // Revenue Chart
                revenueChart
                
                // Key Metrics
                keyMetrics
                
                // Booking Distribution
                bookingDistribution
                
                // Top Hours
                topHoursSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
                        .background(selectedPeriod == period ? Color(hex: "2E7D32") : Color(.systemGray6))
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
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                        Text("+12%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.green)
                    
                    Text("Geçen aya göre")
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
        .background(Color(.systemBackground))
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
                // Pie Chart Placeholder
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 20)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: 0.68)
                        .stroke(Color(hex: "2E7D32"), lineWidth: 20)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("68%")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Doluluk")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    DistributionRow(color: Color(hex: "2E7D32"), label: "Tamamlanan", value: "68%")
                    DistributionRow(color: .orange, label: "Bekleyen", value: "12%")
                    DistributionRow(color: .red, label: "İptal", value: "8%")
                    DistributionRow(color: .gray, label: "Boş", value: "12%")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Top Hours Section
    private var topHoursSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En Popüler Saatler")
                .font(.headline)
            
            VStack(spacing: 8) {
                PopularHourRow(hour: "19:00 - 20:00", percentage: 85)
                PopularHourRow(hour: "20:00 - 21:00", percentage: 78)
                PopularHourRow(hour: "21:00 - 22:00", percentage: 72)
                PopularHourRow(hour: "18:00 - 19:00", percentage: 65)
                PopularHourRow(hour: "17:00 - 18:00", percentage: 45)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Admin Reports ViewModel
@MainActor
final class AdminReportsViewModel: ObservableObject {
    
    @Published var revenueData: [RevenueDataPoint] = []
    @Published var totalRevenue: Double = 15750
    @Published var totalBookings: Int = 48
    @Published var averageRevenue: Double = 328
    @Published var occupancyRate: Int = 68
    @Published var cancellationRate: Int = 8
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        revenueData = [
            RevenueDataPoint(day: "Pzt", revenue: 2100),
            RevenueDataPoint(day: "Sal", revenue: 1800),
            RevenueDataPoint(day: "Çar", revenue: 2400),
            RevenueDataPoint(day: "Per", revenue: 1950),
            RevenueDataPoint(day: "Cum", revenue: 2800),
            RevenueDataPoint(day: "Cmt", revenue: 3200),
            RevenueDataPoint(day: "Paz", revenue: 1500)
        ]
    }
    
    func exportReport() {
        // Export logic
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
        .background(Color(.systemBackground))
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
    
    @StateObject private var authService = AuthService.shared
    @State private var notificationsEnabled = true
    @State private var emailNotifications = true
    @State private var autoConfirm = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        Form {
            // Profile Section
            Section {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2E7D32").opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Text(authService.currentUser?.firstName.prefix(1).uppercased() ?? "A")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.fullName ?? "Admin")
                            .font(.headline)
                        
                        Text("İşletme Hesabı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                
                NavigationLink {
                    Text("Profil Düzenleme")
                } label: {
                    Label("Profili Düzenle", systemImage: "person.circle")
                }
            }
            
            // Notifications
            Section("Bildirimler") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Push Bildirimleri", systemImage: "bell.fill")
                }
                
                Toggle(isOn: $emailNotifications) {
                    Label("E-posta Bildirimleri", systemImage: "envelope.fill")
                }
            }
            
            // Business Settings
            Section("İşletme Ayarları") {
                Toggle(isOn: $autoConfirm) {
                    Label("Otomatik Onay", systemImage: "checkmark.circle")
                }
                
                NavigationLink {
                    Text("Ödeme Ayarları")
                } label: {
                    Label("Ödeme Ayarları", systemImage: "creditcard")
                }
                
                NavigationLink {
                    Text("İptal Politikası")
                } label: {
                    Label("İptal Politikası", systemImage: "doc.text")
                }
            }
            
            // Support
            Section("Destek") {
                NavigationLink {
                    Text("Yardım Merkezi")
                } label: {
                    Label("Yardım Merkezi", systemImage: "questionmark.circle")
                }
                
                NavigationLink {
                    Text("İletişim")
                } label: {
                    Label("Bize Ulaşın", systemImage: "envelope")
                }
                
                NavigationLink {
                    Text("Sözleşmeler")
                } label: {
                    Label("Kullanım Koşulları", systemImage: "doc.plaintext")
                }
            }
            
            // Logout
            Section {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Çıkış Yap")
                        Spacer()
                    }
                }
            }
            
            // App Info
            Section {
                HStack {
                    Text("Versiyon")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Ayarlar")
        .tint(Color(hex: "2E7D32"))
        .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
            Button("İptal", role: .cancel) {}
            Button("Çıkış Yap", role: .destructive) {
                try? authService.signOut()
            }
        } message: {
            Text("Çıkış yapmak istediğinizden emin misiniz?")
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
