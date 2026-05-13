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
    @State private var bookingToReview: Booking?

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
        .background(Color.appBackground)
        .navigationTitle("Randevularım")
        .task {
            await viewModel.loadBookings()
        }
        .refreshable {
            await viewModel.loadBookings()
        }
        .sheet(item: $bookingToReview) { booking in
            WriteReviewView(booking: booking) {
                Task { await viewModel.loadBookings() }
            }
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
        .background(Color.appCardBackground)
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
            NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
        }
    }

    // MARK: - Bookings List
    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredBookings) { booking in
                    VStack(spacing: 8) {
                        NavigationLink {
                            BookingDetailView(booking: booking) {
                                Task {
                                    await viewModel.loadBookings()
                                }
                            }
                        } label: {
                            BookingCard(booking: booking)
                        }
                        .buttonStyle(.plain)

                        // Geçmiş rezervasyonlar için aksiyon barı
                        if viewModel.canReview(booking) {
                            ReviewCTABar {
                                bookingToReview = booking
                            }
                        } else if viewModel.isReviewed(booking) {
                            ReviewedBadge()
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Review CTA Bar (Geçmiş randevu için "Değerlendir" butonu)
private struct ReviewCTABar: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "star.bubble.fill")
                    .font(.subheadline)
                Text("Bu rezervasyonu değerlendir")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(Color(hex: "2E7D32"))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2E7D32").opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "2E7D32").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reviewed Badge (Yorumlanmış randevu rozeti)
private struct ReviewedBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
            Text("Bu rezervasyonu değerlendirdin")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Bookings ViewModel
@MainActor
final class BookingsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var bookings: [Booking] = []
    @Published var selectedFilter: BookingFilter = .upcoming
    @Published var isLoading = false

    /// Yorum yapılmış rezervasyonların ID seti (geçmiş tab CTA'sı için).
    @Published var reviewedBookingIds: Set<String> = []

    // MARK: - Private Properties
    private let bookingService = BookingService.shared
    private let reviewService = ReviewService.shared

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

    /// Bir rezervasyon değerlendirilmeye uygun mu?
    /// (Geçmişe kaldı + iptal/noShow değil + zaten yorumlanmamış)
    func canReview(_ booking: Booking) -> Bool {
        guard let id = booking.id else { return false }
        guard booking.isPast else { return false }
        guard booking.status == .confirmed || booking.status == .completed else { return false }
        return !reviewedBookingIds.contains(id)
    }

    /// Bir rezervasyon zaten yorumlanmış mı?
    func isReviewed(_ booking: Booking) -> Bool {
        guard let id = booking.id else { return false }
        return reviewedBookingIds.contains(id)
    }

    // MARK: - Load Bookings
    func loadBookings() async {
        isLoading = true

        async let bookingsTask: () = loadBookingList()
        async let reviewsTask: () = loadReviewedIds()
        _ = await (bookingsTask, reviewsTask)

        isLoading = false
    }

    private func loadBookingList() async {
        do {
            bookings = try await bookingService.fetchUserBookings()
        } catch {
            print("❌ Error loading bookings: \(error)")
            bookings = []
        }
    }

    private func loadReviewedIds() async {
        do {
            let reviews = try await reviewService.fetchReviewsByCurrentUser()
            reviewedBookingIds = Set(reviews.map(\.bookingId).filter { !$0.isEmpty })
        } catch {
            // Yorum listesi yüklenmesi başarısız → CTA'lar yine de gözükür
        }
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
        .background(Color.appCardBackground)
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
    var onBookingUpdated: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var showCancelAlert = false
    @State private var showQRCode = false
    @State private var isCancelling = false
    @State private var showCancelError = false
    @State private var cancelErrorMessage = ""
    @State private var showCreateMatchPost = false

    private let bookingService = BookingService.shared

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
        .background(Color.appBackground)
        .navigationTitle("Randevu Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showCreateMatchPost) {
            CreateMatchPostView(booking: booking)
        }
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
        .alert("İptal Edilemedi", isPresented: $showCancelError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(cancelErrorMessage)
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
                VStack(spacing: 6) {
                    QRCodeImage(
                        data: qrPayload(for: booking),
                        size: 110
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4)

                    Text("Büyütmek için tıkla")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

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
        .background(Color.appCardBackground)
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
            .background(Color.appCardBackground)
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
                    openInMaps()
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
            .background(Color.appCardBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                title: "Oyuncu Ara",
                icon: "person.badge.plus"
            ) {
                showCreateMatchPost = true
            }

            if booking.canBeCancelled {
                PrimaryButton(
                    title: "Randevuyu İptal Et",
                    icon: "xmark.circle",
                    style: .destructive,
                    isLoading: isCancelling
                ) {
                    showCancelAlert = true
                }
            }
        }
    }

    // MARK: - Actions
    private func cancelBooking() {
        Task {
            guard let bookingId = booking.id else {
                cancelErrorMessage = "Rezervasyon ID bulunamadı."
                showCancelError = true
                return
            }

            isCancelling = true

            do {
                try await bookingService.cancelBooking(
                    bookingId: bookingId,
                    reason: "Kullanıcı tarafından iptal edildi"
                )
                isCancelling = false
                onBookingUpdated()
                dismiss()
            } catch {
                isCancelling = false
                cancelErrorMessage = error.localizedDescription
                showCancelError = true
            }
        }
    }

    // MARK: - Open Directions
    private func openInMaps() {
        let query = "\(booking.facilityName), \(booking.facilityAddress)"
        guard
            let encoded = query.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "http://maps.apple.com/?daddr=\(encoded)")
        else {
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - Create Match Post View
struct CreateMatchPostView: View {

    let booking: Booking

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateMatchPostViewModel

    init(booking: Booking) {
        self.booking = booking
        _viewModel = StateObject(wrappedValue: CreateMatchPostViewModel(booking: booking))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroSummary
                playerCountSection
                expectationsSection
                descriptionSection
                publishSection
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle("Maç İlanı")
        .navigationBarTitleDisplayMode(.inline)
        .alert("İlan Oluşturuldu", isPresented: $viewModel.showSuccess) {
            Button("Tamam") {
                dismiss()
            }
        } message: {
            Text("Maç ilanınız Keşfet ekranında oyunculara gösterilecek.")
        }
        .alert("İlan Oluşturulamadı", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var heroSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2E7D32").opacity(0.14))
                        .frame(width: 56, height: 56)

                    Image(systemName: "sportscourt.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "2E7D32"))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.facilityName)
                        .font(.headline)
                        .lineLimit(2)

                    Text(booking.pitchName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Label(booking.facilityAddress, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 10) {
                MatchPostInfoChip(icon: "calendar", title: booking.shortDate)
                MatchPostInfoChip(icon: "clock", title: booking.timeSlotString)
                MatchPostInfoChip(icon: "ticket.fill", title: booking.ticketNumber)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("İlan başlığı")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                TextField("Örn. Akşam maçına 4 oyuncu aranıyor", text: $viewModel.title)
                    .textInputAutocapitalization(.sentences)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Kadro Bilgisi", icon: "person.3.fill")

            VStack(spacing: 14) {
                MatchPostStepperRow(
                    title: "Aranan oyuncu",
                    subtitle: "İlanda görünecek eksik kişi sayısı",
                    value: $viewModel.neededPlayers,
                    range: 1...10
                )

                Divider()

                MatchPostStepperRow(
                    title: "Mevcut oyuncu",
                    subtitle: "Şu an kesinleşen kişi sayısı",
                    value: $viewModel.currentPlayers,
                    range: 1...30
                )

                Divider()

                MatchPostStepperRow(
                    title: "Maksimum kadro",
                    subtitle: "Sahanın toplam oyuncu kapasitesi",
                    value: $viewModel.maxPlayers,
                    range: 2...30
                )
            }

            HStack {
                Image(systemName: viewModel.isRosterValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(viewModel.isRosterValid ? Color(hex: "2E7D32") : .orange)

                Text(viewModel.rosterHint)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var expectationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Oyuncu Beklentisi", icon: "slider.horizontal.3")

            VStack(alignment: .leading, spacing: 10) {
                Text("Seviye")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Picker("Seviye", selection: $viewModel.skillLevel) {
                    ForEach(SkillLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Tercih edilen mevkiler")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                    ForEach(PlayerPosition.allCases.filter { $0 != .unspecified }, id: \.self) { position in
                        MatchPostPositionChip(
                            position: position,
                            isSelected: viewModel.preferredPositions.contains(position)
                        ) {
                            viewModel.togglePosition(position)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $viewModel.hasCostPerPlayer.animation()) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Kişi başı ücret belirt")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Boş bırakırsanız ilanda ücret gösterilmez.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.hasCostPerPlayer {
                    HStack {
                        TextField("100", text: $viewModel.costPerPlayerText)
                            .keyboardType(.decimalPad)
                        Text("₺ / kişi")
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Not", icon: "text.alignleft")

            TextEditor(text: $viewModel.description)
                .frame(minHeight: 110)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .overlay(alignment: .topLeading) {
                    if viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Maç ortamı, aradığınız oyuncu tipi veya özel notlar...")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.75))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var publishSection: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: "İlanı Yayınla",
                icon: "paperplane.fill",
                isLoading: viewModel.isSaving,
                isDisabled: !viewModel.canSubmit
            ) {
                Task {
                    await viewModel.createPost()
                }
            }

            Text("İlan yayınlandıktan sonra oyuncular Keşfet ekranından başvurabilir.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "2E7D32"))
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - Create Match Post ViewModel
@MainActor
final class CreateMatchPostViewModel: ObservableObject {

    @Published var title: String
    @Published var description = ""
    @Published var neededPlayers = 4
    @Published var currentPlayers = 10
    @Published var maxPlayers = 14
    @Published var preferredPositions: [PlayerPosition] = []
    @Published var skillLevel: SkillLevel = .any
    @Published var hasCostPerPlayer = false
    @Published var costPerPlayerText = ""
    @Published var isSaving = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let booking: Booking
    private let authService = AuthService.shared
    private let matchPostService = MatchPostService.shared

    init(booking: Booking) {
        self.booking = booking
        self.title = "\(booking.timeSlotString) maçına oyuncu aranıyor"
    }

    var isRosterValid: Bool {
        currentPlayers < maxPlayers && neededPlayers <= maxPlayers - currentPlayers
    }

    var rosterHint: String {
        guard currentPlayers < maxPlayers else {
            return "Mevcut oyuncu sayısı maksimum kadrodan düşük olmalı."
        }

        let emptySlots = maxPlayers - currentPlayers
        if neededPlayers > emptySlots {
            return "Aranan oyuncu sayısı kalan \(emptySlots) kişilik kapasiteyi aşamaz."
        }
        return "\(emptySlots) kişilik boşluk var, \(neededPlayers) kişi aranacak."
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isRosterValid
            && (!hasCostPerPlayer || parsedCostPerPlayer != nil)
    }

    private var parsedCostPerPlayer: Double? {
        let normalized = costPerPlayerText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else { return nil }
        return value
    }

    func togglePosition(_ position: PlayerPosition) {
        if preferredPositions.contains(position) {
            preferredPositions.removeAll { $0 == position }
        } else {
            preferredPositions.append(position)
        }
    }

    func createPost() async {
        guard canSubmit else { return }
        guard let user = authService.currentUser else {
            errorMessage = "İlan oluşturmak için giriş yapmalısınız."
            showError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await matchPostService.createMatchPost(
                from: booking,
                user: user,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: cleanedDescription,
                neededPlayers: neededPlayers,
                currentPlayers: currentPlayers,
                maxPlayers: maxPlayers,
                preferredPositions: preferredPositions,
                skillLevel: skillLevel,
                costPerPlayer: hasCostPerPlayer ? parsedCostPerPlayer : nil
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private var cleanedDescription: String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Match Post Form Components
private struct MatchPostInfoChip: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title.isEmpty ? "Bilet yok" : title)
                .lineLimit(1)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(Color(hex: "2E7D32"))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(hex: "2E7D32").opacity(0.10))
        .clipShape(Capsule())
    }
}

private struct MatchPostStepperRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2E7D32"))
                    .frame(minWidth: 28)

                Stepper(title, value: $value, in: range)
                    .labelsHidden()
            }
        }
    }
}

private struct MatchPostPositionChip: View {
    let position: PlayerPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(position.icon)
                Text(position.displayName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "2E7D32") : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
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
        ZStack {
            // Karanlık tema (kameraya gösterirken kontrast için ekran parlaklığı önerilir)
            LinearGradient(
                colors: [Color(hex: "1B5E20"), Color(hex: "0D2F0E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Üst bar
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()

                // Ticket card
                VStack(spacing: 0) {
                    // Tesis bilgisi
                    VStack(spacing: 6) {
                        Text(booking.facilityName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text(booking.pitchName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 24)

                    // QR
                    QRCodeImage(
                        data: qrPayload(for: booking),
                        size: 240
                    )
                    .padding(.vertical, 20)

                    // Tarih + saat satırı
                    HStack(spacing: 0) {
                        VStack(spacing: 2) {
                            Text("Tarih")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(booking.shortDate)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 32)

                        VStack(spacing: 2) {
                            Text("Saat")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(booking.timeSlotString)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "2E7D32"))
                        }
                        .frame(maxWidth: .infinity)

                        Divider().frame(height: 32)

                        VStack(spacing: 2) {
                            Text("Süre")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(booking.duration) saat")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.appBackground)

                    // Kesik şerit
                    TicketSeparator()

                    // Bilet no
                    VStack(spacing: 4) {
                        Text("BİLET NO")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        Text(booking.ticketNumber)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "2E7D32"))
                            .monospacedDigit()
                    }
                    .padding(.vertical, 16)
                }
                .background(Color.appCardBackground)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 24)

                Spacer()

                // Alt rehber
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                    Text("Bu QR kodu saha girişinde gösterin")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Ticket Separator (zikzak benzeri kesik şerit görünümü)
private struct TicketSeparator: View {
    var body: some View {
        ZStack {
            HStack {
                Circle()
                    .fill(Color(hex: "0D2F0E"))
                    .frame(width: 24, height: 24)
                    .offset(x: -12)
                Spacer()
                Circle()
                    .fill(Color(hex: "0D2F0E"))
                    .frame(width: 24, height: 24)
                    .offset(x: 12)
            }

            HStack(spacing: 6) {
                ForEach(0..<24, id: \.self) { _ in
                    Capsule()
                        .fill(Color.gray.opacity(0.35))
                        .frame(width: 6, height: 1.5)
                }
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 8)
    }
}

// MARK: - QR Payload (Booking)
fileprivate func qrPayload(for booking: Booking) -> String {
    if !booking.qrCode.isEmpty {
        return booking.qrCode
    }
    // Eski rezervasyonlar için fallback: ticket numarası
    return booking.ticketNumber
}

// MARK: - Preview
#Preview {
    NavigationStack {
        BookingsView()
    }
}
