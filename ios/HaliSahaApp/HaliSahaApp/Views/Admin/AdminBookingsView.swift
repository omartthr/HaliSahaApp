//
//  AdminBookingsView.swift
//  HaliSahaApp
//
//  Admin Rezervasyon Yönetimi
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import SwiftUI

// MARK: - Admin Bookings View
struct AdminBookingsView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = AdminBookingsViewModel()
    @State private var selectedFilter: AdminBookingFilter = .all
    @State private var selectedBooking: Booking?
    @State private var showActionSheet = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Filter Tabs
            filterTabs
            
            // Date Picker
            datePicker
            
            // Content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if viewModel.filteredBookings.isEmpty {
                emptyState
            } else {
                bookingsList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Rezervasyonlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.exportBookings()
                    } label: {
                        Label("Dışa Aktar", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        // Print
                    } label: {
                        Label("Yazdır", systemImage: "printer")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Rezervasyon İşlemleri",
            isPresented: $showActionSheet,
            presenting: selectedBooking
        ) { booking in
            if booking.status == .confirmed {
                Button("Tamamlandı Olarak İşaretle") {
                    Task {
                        await viewModel.completeBooking(booking)
                    }
                }
                
                Button("Gelmedi Olarak İşaretle", role: .destructive) {
                    Task {
                        await viewModel.markAsNoShow(booking)
                    }
                }
            }
            
            if booking.status == .pending {
                Button("Onayla") {
                    Task {
                        await viewModel.confirmBooking(booking)
                    }
                }
                
                Button("Reddet", role: .destructive) {
                    Task {
                        await viewModel.rejectBooking(booking)
                    }
                }
            }
            
            Button("İptal", role: .cancel) {}
        }
        .task {
            await viewModel.loadBookings()
        }
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AdminBookingFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        count: viewModel.countForFilter(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        viewModel.applyFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Date Picker
    private var datePicker: some View {
        HStack {
            Button {
                viewModel.previousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            Spacer()
            
            DatePicker(
                "",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .labelsHidden()
            .onChange(of: viewModel.selectedDate) { _, _ in
                Task {
                    await viewModel.loadBookings()
                }
            }
            
            Spacer()
            
            Button {
                viewModel.nextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Rezervasyon Bulunamadı")
                .font(.headline)
            
            Text("Seçili tarih ve filtre için rezervasyon bulunmuyor.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Bookings List
    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Summary Card
                bookingSummary
                
                // Bookings
                ForEach(viewModel.filteredBookings) { booking in
                    AdminBookingDetailCard(booking: booking) {
                        selectedBooking = booking
                        showActionSheet = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Booking Summary
    private var bookingSummary: some View {
        HStack(spacing: 16) {
            SummaryItem(
                value: "\(viewModel.filteredBookings.count)",
                label: "Toplam",
                color: .blue
            )
            
            SummaryItem(
                value: "\(viewModel.confirmedCount)",
                label: "Onaylı",
                color: .green
            )
            
            SummaryItem(
                value: "\(viewModel.pendingCount)",
                label: "Bekleyen",
                color: .orange
            )
            
            SummaryItem(
                value: viewModel.totalRevenue.asShortCurrency,
                label: "Gelir",
                color: Color(hex: "2E7D32")
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Admin Bookings ViewModel
@MainActor
final class AdminBookingsViewModel: ObservableObject {
    
    @Published var allBookings: [Booking] = []
    @Published var filteredBookings: [Booking] = []
    @Published var selectedDate = Date()
    @Published var isLoading = false
    
    private let adminService = AdminService.shared
    private var currentFilter: AdminBookingFilter = .all
    
    var confirmedCount: Int {
        filteredBookings.filter { $0.status == .confirmed }.count
    }
    
    var pendingCount: Int {
        filteredBookings.filter { $0.status == .pending }.count
    }
    
    var totalRevenue: Double {
        filteredBookings.reduce(0) { $0 + $1.depositAmount }
    }
    
    func loadBookings() async {
        isLoading = true
        
        // Mock data
        allBookings = adminService.loadMockAdminBookings()
        applyFilter(currentFilter)
        
        isLoading = false
    }
    
    func applyFilter(_ filter: AdminBookingFilter) {
        currentFilter = filter
        
        switch filter {
        case .all:
            filteredBookings = allBookings
        case .today:
            filteredBookings = allBookings.filter { Calendar.current.isDateInToday($0.date) }
        case .pending:
            filteredBookings = allBookings.filter { $0.status == .pending }
        case .confirmed:
            filteredBookings = allBookings.filter { $0.status == .confirmed }
        case .completed:
            filteredBookings = allBookings.filter { $0.status == .completed }
        case .cancelled:
            filteredBookings = allBookings.filter { $0.status == .cancelled }
        }
    }
    
    func countForFilter(_ filter: AdminBookingFilter) -> Int {
        switch filter {
        case .all: return allBookings.count
        case .today: return allBookings.filter { Calendar.current.isDateInToday($0.date) }.count
        case .pending: return allBookings.filter { $0.status == .pending }.count
        case .confirmed: return allBookings.filter { $0.status == .confirmed }.count
        case .completed: return allBookings.filter { $0.status == .completed }.count
        case .cancelled: return allBookings.filter { $0.status == .cancelled }.count
        }
    }
    
    func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    func confirmBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        try? await adminService.confirmBooking(bookingId: id)
        await loadBookings()
    }
    
    func rejectBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        try? await adminService.rejectBooking(bookingId: id, reason: "Admin tarafından reddedildi")
        await loadBookings()
    }
    
    func completeBooking(_ booking: Booking) async {
        guard let id = booking.id else { return }
        try? await adminService.completeBooking(bookingId: id)
        await loadBookings()
    }
    
    func markAsNoShow(_ booking: Booking) async {
        guard let id = booking.id else { return }
        try? await adminService.markAsNoShow(bookingId: id)
        await loadBookings()
    }
    
    func exportBookings() {
        // Export logic
    }
}

// MARK: - Admin Booking Filter
enum AdminBookingFilter: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case today = "Bugün"
    case pending = "Bekleyen"
    case confirmed = "Onaylı"
    case completed = "Tamamlanan"
    case cancelled = "İptal"
    
    var id: String { rawValue }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? Color(hex: "2E7D32") : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white : Color(.systemGray5))
                        .cornerRadius(10)
                }
            }
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "2E7D32") : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

struct SummaryItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AdminBookingDetailCard: View {
    let booking: Booking
    let onAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.userFullName)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.caption2)
                        Text(booking.userPhone)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: booking.status)
            }
            
            Divider()
            
            // Details
            HStack {
                DetailColumn(icon: "sportscourt", title: booking.pitchName)
                
                Spacer()
                
                DetailColumn(icon: "calendar", title: booking.formattedDate)
                
                Spacer()
                
                DetailColumn(icon: "clock", title: booking.timeSlotString)
            }
            
            Divider()
            
            // Footer
            HStack {
                // Price
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ödenen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(booking.depositAmount.asCurrency)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                
                if !booking.ticketNumber.isEmpty {
                    Text(booking.ticketNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action Button
                Button(action: onAction) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8)
    }
}

struct DetailColumn: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AdminBookingsView()
    }
}
