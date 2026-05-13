//
//  AdminQRScannerView.swift
//  HaliSahaApp
//
//  Admin için QR kod tarayıcı + rezervasyon doğrulama akışı.
//

import AVFoundation
import SwiftUI

// MARK: - Admin QR Scanner View
struct AdminQRScannerView: View {

    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AdminQRScannerViewModel()

    @State private var isTorchOn = false
    @State private var showPermissionAlert = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // Kamera (rezultat sheet açıkken duraklamalı)
            if viewModel.scannerActive {
                QRCodeScannerView(
                    onCodeScanned: { code in
                        Task { await viewModel.handleScannedCode(code) }
                    },
                    onError: { error in
                        switch error {
                        case .permissionDenied:
                            showPermissionAlert = true
                        case .unavailable, .unknown:
                            viewModel.presentResult(
                                .error(message: "Kamera kullanılamıyor.")
                            )
                        }
                    },
                    isTorchOn: $isTorchOn
                )
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            // Karartma + ortada şeffaf scan çerçevesi
            scannerOverlay

            // Üst bar + alt rehber
            VStack {
                topBar
                Spacer()
                bottomGuide
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
        .preferredColorScheme(.dark)
        .alert("Kamera İzni Gerekli", isPresented: $showPermissionAlert) {
            Button("Vazgeç", role: .cancel) { dismiss() }
            Button("Ayarları Aç") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(
                "QR kod tarayabilmek için Ayarlar > \(AppConstants.appName) bölümünden kamera erişimi vermeniz gerekiyor."
            )
        }
        .sheet(isPresented: $viewModel.showResultSheet) {
            ScanResultSheet(
                result: viewModel.lastResult,
                isProcessing: viewModel.isUpdating,
                onCheckIn: {
                    Task { await viewModel.markAsCompleted() }
                },
                onMarkNoShow: {
                    Task { await viewModel.markAsNoShow() }
                },
                onScanAgain: {
                    viewModel.dismissResult()
                },
                onClose: {
                    viewModel.dismissResult()
                    dismiss()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(viewModel.isUpdating)
        }
        .task {
            await viewModel.preloadFacilityIds()
        }
    }

    // MARK: - Scanner Overlay
    private var scannerOverlay: some View {
        GeometryReader { geo in
            let cutoutSize = min(geo.size.width, geo.size.height) * 0.65

            ZStack {
                // Karartma (cutout dışında)
                Color.black.opacity(0.55)
                    .mask {
                        Rectangle()
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .frame(width: cutoutSize, height: cutoutSize)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                    }
                    .ignoresSafeArea()

                // Köşe çerçeveleri
                ScannerCornerFrame(size: cutoutSize)
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: cutoutSize, height: cutoutSize)

                // Animasyonlu tarama çizgisi
                if viewModel.scannerActive {
                    AnimatedScanLine(width: cutoutSize - 24, height: cutoutSize)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            Text("QR Tara")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Spacer()

            Button {
                isTorchOn.toggle()
            } label: {
                Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(isTorchOn ? .yellow : .white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Bottom Guide
    private var bottomGuide: some View {
        VStack(spacing: 8) {
            Image(systemName: "qrcode.viewfinder")
                .font(.title)
                .foregroundColor(.white)

            Text("QR kodu çerçeveye hizalayın")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Text("Kod otomatik olarak okunacaktır")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.bottom, 40)
        .padding(.horizontal, 32)
    }
}

// MARK: - Scanner Corner Frame Shape
private struct ScannerCornerFrame: Shape {
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerLength: CGFloat = size * 0.18
        let cornerRadius: CGFloat = 22

        // Üst sol
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        // Üst sağ
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        // Alt sağ
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        // Alt sol
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}

// MARK: - Animated Scan Line
private struct AnimatedScanLine: View {
    let width: CGFloat
    let height: CGFloat

    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [Color(hex: "2E7D32").opacity(0), Color(hex: "4CAF50"), Color(hex: "2E7D32").opacity(0)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: width, height: 3)
        .shadow(color: Color(hex: "4CAF50"), radius: 6)
        .offset(y: animate ? height / 2 - 16 : -height / 2 + 16)
        .animation(
            Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear { animate = true }
    }
}

// MARK: - Scan Result Sheet
private struct ScanResultSheet: View {
    let result: AdminQRScannerViewModel.ScanResult?
    let isProcessing: Bool
    let onCheckIn: () -> Void
    let onMarkNoShow: () -> Void
    let onScanAgain: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let result {
                    statusHeader(for: result)

                    if case .success(let booking) = result {
                        bookingCard(booking)
                        if booking.status == .confirmed {
                            actionButtons
                        }
                    }
                }

                Button(role: .cancel) {
                    onScanAgain()
                } label: {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Yeni QR Tara")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "2E7D32"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "2E7D32").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(role: .destructive) {
                    onClose()
                } label: {
                    Text("Kapat")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
            .padding()
        }
        .overlay {
            if isProcessing {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.4)
            }
        }
    }

    // MARK: - Status Header
    @ViewBuilder
    private func statusHeader(for result: AdminQRScannerViewModel.ScanResult) -> some View {
        let style = result.style

        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(style.color.opacity(0.15))
                    .frame(width: 76, height: 76)

                Image(systemName: style.icon)
                    .font(.system(size: 32))
                    .foregroundColor(style.color)
            }

            Text(style.title)
                .font(.title3)
                .fontWeight(.bold)

            Text(style.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Booking Card
    private func bookingCard(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "2E7D32").opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundColor(Color(hex: "2E7D32"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.userFullName)
                        .font(.headline)
                    Text(booking.userPhone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                StatusBadge(status: booking.status)
            }
            .padding()

            Divider()

            // Detaylar
            VStack(spacing: 12) {
                InfoRow(icon: "sportscourt.fill", title: "Saha", value: "\(booking.facilityName) — \(booking.pitchName)")
                InfoRow(icon: "calendar", title: "Tarih", value: booking.formattedDate)
                InfoRow(icon: "clock", title: "Saat", value: booking.timeSlotString)
                InfoRow(icon: "ticket", title: "Bilet No", value: booking.ticketNumber, valueColor: Color(hex: "2E7D32"))
                InfoRow(icon: "turkishlirasign.circle.fill", title: "Ödenen", value: booking.depositAmount.asCurrency, valueColor: .green)
            }
            .padding()
        }
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                onMarkNoShow()
            } label: {
                HStack {
                    Image(systemName: "person.slash")
                    Text("Gelmedi")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                onCheckIn()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Girişi Onayla")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "2E7D32"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Info Row
private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 22)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}

// MARK: - View Model
@MainActor
final class AdminQRScannerViewModel: ObservableObject {

    enum ScanResult: Equatable {
        case success(Booking)
        case wrongFacility
        case alreadyCompleted(Booking)
        case alreadyCancelled(Booking)
        case alreadyNoShow(Booking)
        case pendingApproval(Booking)
        case notFound
        case wrongDate(Booking)
        case error(message: String)

        struct Style {
            let icon: String
            let title: String
            let subtitle: String
            let color: Color
        }

        var style: Style {
            switch self {
            case .success:
                return Style(
                    icon: "checkmark.seal.fill",
                    title: "Geçerli Rezervasyon",
                    subtitle: "Bilet doğrulandı. Müşteri girişi onaylanabilir.",
                    color: Color(hex: "2E7D32")
                )
            case .wrongFacility:
                return Style(
                    icon: "exclamationmark.shield.fill",
                    title: "Yetkisiz Bilet",
                    subtitle: "Bu QR kod sizin tesislerinizden birine ait değil.",
                    color: .orange
                )
            case .alreadyCompleted:
                return Style(
                    icon: "checkmark.circle.fill",
                    title: "Daha Önce Kullanılmış",
                    subtitle: "Bu rezervasyon \"Tamamlandı\" olarak işaretlenmiş.",
                    color: .blue
                )
            case .alreadyCancelled:
                return Style(
                    icon: "xmark.octagon.fill",
                    title: "İptal Edilmiş Rezervasyon",
                    subtitle: "Bu bilet iptal edildiği için geçersizdir.",
                    color: .red
                )
            case .alreadyNoShow:
                return Style(
                    icon: "person.slash.fill",
                    title: "Gelmedi Olarak İşaretli",
                    subtitle: "Bu rezervasyon gelmedi olarak kayıtlı.",
                    color: .red
                )
            case .pendingApproval:
                return Style(
                    icon: "clock.badge.exclamationmark.fill",
                    title: "Onay Bekleyen Rezervasyon",
                    subtitle: "Müşteri girişine geçmeden önce rezervasyonu onaylamanız gerekiyor.",
                    color: .orange
                )
            case .notFound:
                return Style(
                    icon: "questionmark.circle.fill",
                    title: "Rezervasyon Bulunamadı",
                    subtitle: "Bu QR koda eşleşen bir rezervasyon yok. Bilet numarasını kontrol edin.",
                    color: .red
                )
            case .wrongDate(let booking):
                return Style(
                    icon: "calendar.badge.exclamationmark",
                    title: "Tarih Uyumsuz",
                    subtitle: "Bu bilet \(booking.formattedDate) tarihine ait. Bugün için geçerli değil.",
                    color: .orange
                )
            case .error(let message):
                return Style(
                    icon: "exclamationmark.triangle.fill",
                    title: "Bir Hata Oluştu",
                    subtitle: message,
                    color: .red
                )
            }
        }
    }

    // MARK: - Published
    @Published var scannerActive = true
    @Published var showResultSheet = false
    @Published var lastResult: ScanResult?
    @Published var isUpdating = false

    // MARK: - Private
    private let bookingService = BookingService.shared
    private let adminService = AdminService.shared
    private var allowedFacilityIds: Set<String> = []

    // MARK: - Preload
    func preloadFacilityIds() async {
        do {
            let facilities = try await adminService.fetchMyFacilities()
            allowedFacilityIds = Set(facilities.compactMap { $0.id })
        } catch {
            allowedFacilityIds = []
        }
    }

    // MARK: - Scan Handler
    func handleScannedCode(_ code: String) async {
        guard !showResultSheet else { return }

        // Tarayıcıyı duraklat
        scannerActive = false

        guard let ticketNumber = BookingService.parseTicketNumber(fromScannedCode: code) else {
            presentResult(.notFound)
            return
        }

        do {
            let booking = try await bookingService.fetchBookingByTicketNumber(ticketNumber)
            presentResult(validate(booking))
        } catch BookingError.notFound {
            presentResult(.notFound)
        } catch {
            presentResult(.error(message: error.localizedDescription))
        }
    }

    // MARK: - Validate
    private func validate(_ booking: Booking) -> ScanResult {
        // Tesis kontrolü
        if !allowedFacilityIds.isEmpty,
            !allowedFacilityIds.contains(booking.facilityId)
        {
            return .wrongFacility
        }

        // Status kontrolü
        switch booking.status {
        case .cancelled:
            return .alreadyCancelled(booking)
        case .completed:
            return .alreadyCompleted(booking)
        case .noShow:
            return .alreadyNoShow(booking)
        case .pending:
            return .pendingApproval(booking)
        case .confirmed:
            // Tarih kontrolü: bugün veya gelecekte mi?
            let calendar = Calendar.current
            if calendar.isDateInToday(booking.date) {
                return .success(booking)
            } else if booking.date < calendar.startOfDay(for: Date()) {
                return .wrongDate(booking)
            } else {
                // Gelecek tarih — yine de göster ama "wrongDate" tipinde uyarı
                return .wrongDate(booking)
            }
        }
    }

    // MARK: - Present / Dismiss Result
    func presentResult(_ result: ScanResult) {
        lastResult = result
        showResultSheet = true
    }

    func dismissResult() {
        showResultSheet = false
        lastResult = nil
        scannerActive = true
    }

    // MARK: - Status Updates
    func markAsCompleted() async {
        guard case .success(let booking) = lastResult, let id = booking.id else { return }
        isUpdating = true
        do {
            try await adminService.completeBooking(bookingId: id)
            // Yeniden çek
            let updated = try await bookingService.fetchBooking(id: id)
            lastResult = .alreadyCompleted(updated)
        } catch {
            lastResult = .error(message: "İşlem başarısız: \(error.localizedDescription)")
        }
        isUpdating = false
    }

    func markAsNoShow() async {
        guard case .success(let booking) = lastResult, let id = booking.id else { return }
        isUpdating = true
        do {
            try await adminService.markAsNoShow(bookingId: id)
            let updated = try await bookingService.fetchBooking(id: id)
            lastResult = .alreadyNoShow(updated)
        } catch {
            lastResult = .error(message: "İşlem başarısız: \(error.localizedDescription)")
        }
        isUpdating = false
    }
}

// MARK: - Preview
#Preview {
    AdminQRScannerView()
}
