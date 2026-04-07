//
//  AdminDashboardView.swift
//  HaliSahaApp
//
//  Admin Dashboard - Ana Panel
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import SwiftUI

// MARK: - Admin Dashboard View
struct AdminDashboardView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = AdminDashboardViewModel()
    
    // Sheet States
    @State private var showAddFacility = false
    @State private var showAddPitch = false
    @State private var showFacilitySelector = false
    @State private var selectedFacilityForPitch: Facility?
    @State private var showNoFacilityAlert = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Stats Cards
                statsSection
                
                // Quick Actions
                quickActionsSection
                
                // Today's Bookings
                todayBookingsSection
                
                // My Facilities
                facilitiesSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Admin Paneli")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    AdminSettingsView()
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
        // MARK: - Sheets
        .sheet(isPresented: $showAddFacility) {
            AddFacilityView()
        }
        .sheet(isPresented: $showAddPitch) {
            if let facility = selectedFacilityForPitch, let facilityId = facility.id {
                AddPitchView(facilityId: facilityId)
            }
        }
        .sheet(isPresented: $showFacilitySelector) {
            FacilitySelectorSheet(
                facilities: viewModel.facilities,
                onSelect: { facility in
                    selectedFacilityForPitch = facility
                    showFacilitySelector = false
                    // Küçük bir gecikme ile saha ekleme sheet'ini aç
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showAddPitch = true
                    }
                }
            )
            .presentationDetents([.medium])
        }
        // MARK: - Alerts
        .alert("Tesis Gerekli", isPresented: $showNoFacilityAlert) {
            Button("Tesis Ekle") {
                showAddFacility = true
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Saha ekleyebilmek için önce bir tesis eklemeniz gerekiyor.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hoş Geldiniz 👋")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Notification Bell
            ZStack(alignment: .topTrailing) {
                Button {
                    // Notifications
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 5)
                }
                
                if viewModel.stats.pendingBookings > 0 {
                    Text("\(viewModel.stats.pendingBookings)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 5, y: -5)
                }
            }
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 12) {
            // Top Row
            HStack(spacing: 12) {
                AdminStatCard(
                    title: "Bugün",
                    value: "\(viewModel.stats.todayBookings)",
                    subtitle: "rezervasyon",
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                
                AdminStatCard(
                    title: "Bekleyen",
                    value: "\(viewModel.stats.pendingBookings)",
                    subtitle: "onay",
                    icon: "clock.badge.exclamationmark",
                    color: .orange
                )
            }
            
            // Bottom Row
            HStack(spacing: 12) {
                AdminStatCard(
                    title: "Bu Ay",
                    value: viewModel.stats.monthlyRevenue.asShortCurrency,
                    subtitle: "gelir",
                    icon: "turkishlirasign.circle.fill",
                    color: .green
                )
                
                AdminStatCard(
                    title: "Ortalama",
                    value: String(format: "%.1f", viewModel.stats.averageRating),
                    subtitle: "puan",
                    icon: "star.fill",
                    color: .yellow
                )
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı İşlemler")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Yeni Saha Butonu - Bu action kullanıyor
                QuickActionButton(
                    title: "Yeni Saha",
                    icon: "plus.circle.fill",
                    color: Color(hex: "2E7D32")
                ) {
                    handleAddPitchTapped()
                }
                
                // Rezervasyonlar - NavigationLink ile
                NavigationLink {
                    AdminBookingsView()
                } label: {
                    // QuickActionButtonContent kullan (Button içermeyen versiyon)
                    QuickActionButtonContent(
                        title: "Rezervasyonlar",
                        icon: "list.clipboard.fill",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)
                
                // Raporlar - NavigationLink ile
                NavigationLink {
                    AdminReportsView()
                } label: {
                    // QuickActionButtonContent kullan (Button içermeyen versiyon)
                    QuickActionButtonContent(
                        title: "Raporlar",
                        icon: "chart.bar.fill",
                        color: .purple
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Handle Add Pitch Tapped
    private func handleAddPitchTapped() {
        if viewModel.facilities.isEmpty {
            // Hiç tesis yok - uyarı göster
            showNoFacilityAlert = true
        } else if viewModel.facilities.count == 1 {
            // Tek tesis var - direkt saha ekleme aç
            selectedFacilityForPitch = viewModel.facilities.first
            showAddPitch = true
        } else {
            // Birden fazla tesis var - seçim yaptır
            showFacilitySelector = true
        }
    }
    
    // MARK: - Today's Bookings Section
    private var todayBookingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bugünkü Rezervasyonlar")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    AdminBookingsView()
                } label: {
                    Text("Tümü")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
            
            if viewModel.todayBookings.isEmpty {
                EmptyStateCard(
                    icon: "calendar.badge.minus",
                    message: "Bugün için rezervasyon bulunmuyor"
                )
            } else {
                ForEach(viewModel.todayBookings.prefix(3)) { booking in
                    AdminBookingCard(
                        booking: booking,
                        onComplete: {
                            Task {
                                await viewModel.completeBooking(booking)
                            }
                        },
                        onNoShow: {
                            Task {
                                await viewModel.markAsNoShow(booking)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Facilities Section
    private var facilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tesislerim")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink {
                    AdminFacilitiesView()
                } label: {
                    Text("Yönet")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
            
            ForEach(viewModel.facilities) { facility in
                NavigationLink {
                    AdminFacilityDetailView(facility: facility)
                } label: {
                    AdminFacilityCard(facility: facility)
                }
                .buttonStyle(.plain)
            }
            
            // Add Facility Button
            Button {
                showAddFacility = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni Tesis Ekle")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "2E7D32"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "2E7D32").opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Facility Selector Sheet
struct FacilitySelectorSheet: View {
    let facilities: [Facility]
    let onSelect: (Facility) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(facilities) { facility in
                Button {
                    onSelect(facility)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "2E7D32").opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "sportscourt.fill")
                                .foregroundColor(Color(hex: "2E7D32"))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(facility.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(facility.address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Tesis Seçin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Admin Dashboard ViewModel
@MainActor
final class AdminDashboardViewModel: ObservableObject {
    
    @Published var stats = AdminService.DashboardStats()
    @Published var todayBookings: [Booking] = []
    @Published var facilities: [Facility] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let adminService = AdminService.shared
    
    func loadData() async {
        isLoading = true
        
        do {
            // Gerçek Firebase verileri
            stats = try await adminService.fetchDashboardStats()
            facilities = try await adminService.fetchMyFacilities()
            
            // Bugünkü rezervasyonlar
            todayBookings = adminService.todayBookings
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func completeBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        do {
            try await adminService.completeBooking(bookingId: id)
            await loadData()
        } catch {
            errorMessage = "Rezervasyon tamamlanamadı: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func markAsNoShow(_ booking: Booking) async {
        guard let id = booking.id else { return }
        do {
            try await adminService.markAsNoShow(bookingId: id)
            await loadData()
        } catch {
            errorMessage = "İşlem başarısız: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Supporting Views

struct AdminStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

// MARK: - QuickActionButtonContent (NavigationLink label için - Button içermez)
struct QuickActionButtonContent: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

// MARK: - QuickActionButton (Action callback için - Button içerir)
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
            QuickActionButtonContent(
                title: title,
                icon: icon,
                color: color
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AdminBookingCard: View {
    let booking: Booking
    var onComplete: (() -> Void)?
    var onNoShow: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.userFullName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(booking.pitchName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time
                VStack(alignment: .trailing, spacing: 4) {
                    Text(booking.timeSlotString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2E7D32"))
                    
                    StatusBadge(status: booking.status)
                }
            }
            
            // Actions (sadece bugünkü onaylı rezervasyonlar için)
            if booking.status == .confirmed && Calendar.current.isDateInToday(booking.date) {
                HStack(spacing: 12) {
                    Button {
                        onComplete?()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Tamamlandı")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onNoShow?()
                    } label: {
                        HStack {
                            Image(systemName: "person.slash")
                            Text("Gelmedi")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

struct AdminFacilityCard: View {
    let facility: Facility
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "2E7D32").opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(facility.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(facility.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(facility.formattedRating)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    // Status
                    Text(facility.status.displayName)
                        .font(.caption2)
                        .foregroundColor(facility.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(facility.status.color.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AdminDashboardView()
    }
}
