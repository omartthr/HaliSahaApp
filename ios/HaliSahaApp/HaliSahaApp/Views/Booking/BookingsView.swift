//
//  BookingsView.swift
//  HaliSahaApp
//
//  Randevularım (Rezervasyonlarım) Görünümü
//
//  Created by Mehmet Mert Mazıcı on 20.01.2026.
//

import SwiftUI

// MARK: - Bookings View
struct BookingsView: View {

    // MARK: - Properties
    @StateObject private var viewModel = BookingsViewModel()
    @State private var selectedFilter: BookingFilter = .upcoming

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Filter Tabs
            filterTabs

            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredBookings.isEmpty {
                emptyView
            } else {
                bookingsList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Randevularım")
        .task {
            await viewModel.loadBookings()
        }
        .refreshable {
            await viewModel.loadBookings()
        }
    }

    // MARK: - Filter Tabs
    private var filterTabs: some View {
        HStack(spacing: 0) {
            ForEach(BookingFilter.allCases) { filter in
                Button {
                    withAnimation {
                        selectedFilter = filter
                        viewModel.selectedFilter = filter
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .foregroundColor(
                                selectedFilter == filter ? Color(hex: "2E7D32") : .secondary)

                        Rectangle()
                            .fill(selectedFilter == filter ? Color(hex: "2E7D32") : .clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Yükleniyor...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        EmptyStateView(
            icon: selectedFilter.emptyIcon,
            title: selectedFilter.emptyTitle,
            message: selectedFilter.emptyMessage,
            buttonTitle: selectedFilter == .upcoming ? "Saha Bul" : nil
        ) {
            // Navigate to explore
        }
    }

    // MARK: - Bookings List
    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredBookings) { booking in
                    NavigationLink {
                        BookingDetailView(booking: booking)
                    } label: {
                        BookingCard(booking: booking)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

// MARK: - Bookings ViewModel
@MainActor
final class BookingsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var bookings: [Booking] = []
    @Published var selectedFilter: BookingFilter = .upcoming
    @Published var isLoading = false

    // MARK: - Private Properties
    private let bookingService = BookingService.shared

    // MARK: - Computed Properties
    var filteredBookings: [Booking] {
        switch selectedFilter {
        case .upcoming:
            return bookings.filter { !$0.isPast && $0.status == .confirmed }
        case .past:
            return bookings.filter { $0.isPast || $0.status == .completed }
        case .cancelled:
            return bookings.filter { $0.status == .cancelled }
        }
    }

    // MARK: - Load Bookings
    func loadBookings() async {
        isLoading = true

        do {
            bookings = try await bookingService.fetchUserBookings()
            print("📋 Loaded \(bookings.count) bookings from Firestore")
            for booking in bookings {
                print(
                    "📌 Booking: \(booking.facilityName) - Status: \(booking.status.rawValue) - isPast: \(booking.isPast)"
                )
            }
            print(
                "📊 Filtered for 'Yaklaşan': \(filteredBookings.count) bookings (status==confirmed && !isPast)"
            )
        } catch {
            print("❌ Error loading bookings: \(error)")
            bookings = []
        }

        isLoading = false
    }
}

// MARK: - Booking Filter
enum BookingFilter: String, CaseIterable, Identifiable {
    case upcoming = "Yaklaşan"
    case past = "Geçmiş"
    case cancelled = "İptal"

    var id: String { rawValue }

    var emptyIcon: String {
        switch self {
        case .upcoming: return "calendar.badge.clock"
        case .past: return "clock.arrow.circlepath"
        case .cancelled: return "xmark.circle"
        }
    }

    var emptyTitle: String {
        switch self {
        case .upcoming: return "Yaklaşan Randevu Yok"
        case .past: return "Geçmiş Randevu Yok"
        case .cancelled: return "İptal Edilen Randevu Yok"
        }
    }

    var emptyMessage: String {
        switch self {
        case .upcoming: return "Henüz bir randevunuz bulunmuyor. Hemen yeni bir saha keşfedin!"
        case .past: return "Henüz tamamlanmış bir randevunuz bulunmuyor."
        case .cancelled: return "İptal edilmiş randevunuz bulunmuyor."
        }
    }
}

// MARK: - Booking Card
struct BookingCard: View {
    let booking: Booking

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                // Facility Image Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "2E7D32").opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: "sportscourt.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.facilityName)
                        .font(.headline)

                    Text(booking.pitchName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status Badge
                StatusBadge(status: booking.status)
            }

            Divider()

            // Details
            HStack {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Label(booking.formattedDate, systemImage: "calendar")
                        .font(.subheadline)
                }

                Spacer()

                // Time
                VStack(alignment: .trailing, spacing: 2) {
                    Label(booking.timeSlotString, systemImage: "clock")
                        .font(.subheadline)
                }
            }
            .foregroundColor(.secondary)

            // Countdown (for upcoming bookings)
            if !booking.isPast && booking.status == .confirmed {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(Color(hex: "2E7D32"))

                    Text(countdownText(for: booking))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if !booking.ticketNumber.isEmpty {
                        Text(booking.ticketNumber)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    private func countdownText(for booking: Booking) -> String {
        let now = Date()
        let bookingDate =
            Calendar.current.date(
                bySettingHour: booking.startHour, minute: 0, second: 0, of: booking.date)
            ?? booking.date
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: bookingDate)

        if let days = components.day, days > 0 {
            return "\(days) gün sonra"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) saat sonra"
        } else {
            return "Bugün"
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: BookingStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Booking Detail View
struct BookingDetailView: View {

    let booking: Booking
    @Environment(\.dismiss) private var dismiss
    @State private var showCancelAlert = false
    @State private var showQRCode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Ticket Card
                ticketCard

                // Details
                detailsSection

                // Location
                locationSection

                // Actions
                if !booking.isPast && booking.status == .confirmed {
                    actionsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Randevu Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Randevuyu İptal Et", isPresented: $showCancelAlert) {
            Button("Vazgeç", role: .cancel) {}
            Button("İptal Et", role: .destructive) {
                cancelBooking()
            }
        } message: {
            Text(
                booking.isRefundable
                    ? "Randevunuz iptal edilecek ve kapora iade edilecektir."
                    : "Randevunuz iptal edilecek. 24 saatten az kaldığı için kapora iade edilmeyecektir."
            )
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeView(booking: booking)
        }
    }

    // MARK: - Ticket Card
    private var ticketCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(booking.facilityName)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(booking.pitchName)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: booking.status)
            }

            // QR Code
            Button {
                showQRCode = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.1), radius: 5)

                    VStack(spacing: 4) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 50))
                            .foregroundColor(.black)

                        Text("Büyütmek için tıkla")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Dashed Line
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(.gray.opacity(0.5))
                .frame(height: 1)

            // Details Row
            HStack {
                VStack(spacing: 4) {
                    Text("Tarih")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(booking.formattedDate)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("Saat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(booking.timeSlotString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("Süre")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(booking.duration) saat")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            HStack {
                Text("Bilet No:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(booking.ticketNumber)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }

    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ödeme Detayı")
                .font(.headline)

            VStack(spacing: 12) {
                DetailRow(title: "Toplam Tutar", value: booking.totalPrice.asCurrency)
                DetailRow(
                    title: "Ödenen Kapora", value: booking.depositAmount.asCurrency,
                    valueColor: .green)
                DetailRow(
                    title: "Kalan Tutar", value: booking.remainingAmount.asCurrency,
                    valueColor: .orange)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Konum")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                    Text(booking.facilityAddress)
                        .font(.subheadline)
                }

                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                    Text(booking.facilityPhone)
                        .font(.subheadline)
                }

                Button {
                    // Open in maps
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        Text("Yol Tarifi Al")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "2E7D32"))
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if booking.canBeCancelled {
                PrimaryButton(
                    title: "Randevuyu İptal Et",
                    icon: "xmark.circle",
                    style: .destructive
                ) {
                    showCancelAlert = true
                }
            }
        }
    }

    // MARK: - Actions
    private func cancelBooking() {
        Task {
            // Cancel booking logic
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - QR Code View
struct QRCodeView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Spacer()

            // QR Code
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 250, height: 250)
                    .shadow(color: .black.opacity(0.1), radius: 10)

                Image(systemName: "qrcode")
                    .font(.system(size: 150))
                    .foregroundColor(.black)
            }

            // Ticket Info
            VStack(spacing: 8) {
                Text(booking.facilityName)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(booking.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(booking.timeSlotString)
                    .font(.headline)
                    .foregroundColor(Color(hex: "2E7D32"))

                Text(booking.ticketNumber)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            Spacer()

            Text("Bu QR kodu saha girişinde gösterin")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        BookingsView()
    }
}
