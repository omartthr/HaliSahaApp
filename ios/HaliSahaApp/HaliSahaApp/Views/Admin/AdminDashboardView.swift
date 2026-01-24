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
    @State private var selectedFacility: Facility?
    
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
                QuickActionButton(
                    title: "Yeni Saha",
                    icon: "plus.circle.fill",
                    color: Color(hex: "2E7D32")
                ) {
                    // Add new pitch
                }
                
                NavigationLink {
                    AdminBookingsView()
                } label: {
                    QuickActionButton(
                        title: "Rezervasyonlar",
                        icon: "list.clipboard.fill",
                        color: .blue
                    )
                }
                
                NavigationLink {
                    AdminReportsView()
                } label: {
                    QuickActionButton(
                        title: "Raporlar",
                        icon: "chart.bar.fill",
                        color: .purple
                    )
                }
            }
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
                // Add new facility
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

// MARK: - Admin Dashboard ViewModel
@MainActor
final class AdminDashboardViewModel: ObservableObject {
    
    @Published var stats = AdminService.DashboardStats()
    @Published var todayBookings: [Booking] = []
    @Published var facilities: [Facility] = []
    @Published var isLoading = false
    
    private let adminService = AdminService.shared
    
    func loadData() async {
        isLoading = true
        
        // Mock data yükle
        facilities = adminService.loadMockAdminFacilities()
        todayBookings = adminService.loadMockAdminBookings().filter {
            Calendar.current.isDateInToday($0.date)
        }
        
        // Stats güncelle
        stats.totalFacilities = facilities.count
        stats.todayBookings = todayBookings.count
        stats.pendingBookings = adminService.loadMockAdminBookings().filter { $0.status == .pending }.count
        stats.monthlyRevenue = 15750
        stats.averageRating = 4.8
        
        isLoading = false
    }
    
    func completeBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        try? await adminService.completeBooking(bookingId: id)
        await loadData()
    }
    
    func markAsNoShow(_ booking: Booking) async {
        guard let id = booking.id else { return }
        try? await adminService.markAsNoShow(bookingId: id)
        await loadData()
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

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
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
