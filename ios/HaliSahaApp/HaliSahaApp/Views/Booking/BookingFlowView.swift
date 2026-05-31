//
//  BookingFlowView.swift
//  HaliSahaApp
//
//  Rezervasyon Akışı - Ödeme ve Onay
//
//  Created by Mehmet Mert Mazıcı on 20.01.2026.
//

import FirebaseFirestore
import SwiftUI

// MARK: - Booking Flow View
struct BookingFlowView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: FacilityDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: BookingStep = .summary
    @State private var isProcessingPayment = false
    @State private var paymentError: String?
    @State private var createdBooking: Booking?

    // iyzico ödeme akışı
    @State private var showPaymentSheet = false
    @State private var pendingPaymentUrl: URL?
    @State private var pendingPaymentDocId: String?
    @State private var pendingBookingId: String?

    // Bildirim izni prompt'u (ilk rezervasyon sonrası)
    @State private var showNotificationPrompt = false

    private let bookingService = BookingService.shared
    private let authService = AuthService.shared
    private let paymentService = PaymentService.shared
    private let firebaseService = FirebaseService.shared

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            progressIndicator

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    switch currentStep {
                    case .summary:
                        summaryStep
                    case .payment:
                        paymentStep
                    case .confirmation:
                        confirmationStep
                    }
                }
                .padding()
            }

            // Bottom Bar
            if currentStep != .confirmation {
                bottomBar
            }
        }
        .background(Color.appBackground)
        .navigationTitle(currentStep.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(currentStep == .confirmation)
        .alert("Ödeme Hatası", isPresented: .constant(paymentError != nil)) {
            Button("Tamam") {
                paymentError = nil
            }
        } message: {
            if let error = paymentError {
                Text(error)
            }
        }
        .fullScreenCover(isPresented: $showPaymentSheet) {
            if let url = pendingPaymentUrl, let docId = pendingPaymentDocId {
                IyzicoPaymentView(
                    paymentPageUrl: url,
                    paymentDocId: docId,
                    onFinish: handlePaymentOutcome
                )
            }
        }
    }

    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(BookingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(
                        step.rawValue <= currentStep.rawValue
                            ? Color(hex: "2E7D32") : Color.gray.opacity(0.3)
                    )
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Summary Step
    private var summaryStep: some View {
        VStack(spacing: 20) {
            // Booking Summary Card
            VStack(spacing: 16) {
                // Facility Info
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "2E7D32").opacity(0.1))
                            .frame(width: 60, height: 60)

                        Image(systemName: "sportscourt.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "2E7D32"))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.facility.name)
                            .font(.headline)

                        Text(viewModel.selectedPitch?.name ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Divider()

                // Date & Time
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tarih")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.selectedDate.formattedTurkish)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Saat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let start = viewModel.selectedStartHour,
                            let end = viewModel.selectedEndHour
                        {
                            Text("\(start.asHourString) - \(end.asHourString)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }

                Divider()

                // Duration & Address
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Süre")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.selectedDuration) saat")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Konum")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.facility.address)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .padding()
            .background(Color.appCardBackground)
            .cornerRadius(16)

            // Price Breakdown
            VStack(spacing: 12) {
                Text("Fiyat Detayı")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    PriceRow(
                        title: "Saha Ücreti (\(viewModel.selectedDuration) saat)",
                        amount: viewModel.totalPrice)

                    Divider()

                    PriceRow(
                        title: "Kapora (%20)", amount: viewModel.depositAmount, isHighlighted: true)

                    Text("Kalan tutar sahada ödenecektir")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(12)
            }

            // Info Box
            InfoBanner(
                type: .info,
                message: "Maçtan 24 saat öncesine kadar ücretsiz iptal edebilirsiniz."
            )
        }
    }

    // MARK: - Payment Step
    private var paymentStep: some View {
        VStack(spacing: 20) {
            // iyzico Provider Info
            iyzicoInfoCard

            // Billing Address Status
            billingStatusCard

            // Amount to Pay
            VStack(spacing: 8) {
                Text("Ödenecek Tutar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(viewModel.depositAmount.asCurrency)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2E7D32"))

                Text("Kalan tutar sahada ödenecektir")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "2E7D32").opacity(0.1))
            .cornerRadius(16)

            // Security Note
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.green)
                Text("Ödeme iyzico altyapısı ile 3DS güvencesinde alınır")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    // MARK: - iyzico Info Card
    private var iyzicoInfoCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "2E7D32").opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "creditcard.and.123")
                    .font(.title3)
                    .foregroundColor(Color(hex: "2E7D32"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Güvenli Ödeme")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Kart bilgileriniz iyzico'nun güvenli sayfasında girilir. Uygulama kart verilerinizi saklamaz.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.appCardBackground)
        .cornerRadius(14)
    }

    // MARK: - Billing Status Card
    private var billingStatusCard: some View {
        let isComplete = isBillingComplete
        return NavigationLink {
            EditBillingAddressView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isComplete ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(isComplete ? Color(hex: "2E7D32") : .orange)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(isComplete ? "Fatura Bilgileri Tamam" : "Fatura Bilgileri Eksik")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(
                        isComplete
                            ? "Düzenlemek için dokunun"
                            : "Ödemeye geçmek için TC kimlik ve adres bilgilerinizi girin"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(
                (isComplete ? Color(hex: "2E7D32") : Color.orange)
                    .opacity(0.08)
            )
            .cornerRadius(14)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        (isComplete ? Color(hex: "2E7D32") : Color.orange).opacity(0.4),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirmation Step
    private var confirmationStep: some View {
        VStack(spacing: 24) {
            // Success Animation
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }

            // Success Message
            VStack(spacing: 8) {
                Text("Rezervasyon Başarılı!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Bilet numaranız e-posta adresinize gönderildi.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Ticket Card
            if let booking = createdBooking {
                TicketCardView(booking: booking)
            }

            // Bildirim izni call-to-action (sadece ilk kez)
            if showNotificationPrompt {
                notificationPermissionCard
            }

            // Actions
            VStack(spacing: 12) {
                PrimaryButton(title: "Randevularıma Git", icon: "ticket.fill") {
                    // Post notification to switch tab, then dismiss
                    NotificationCenter.default.post(name: .switchToBookingsTab, object: nil)
                    dismiss()
                }

                PrimaryButton(title: "Ana Sayfaya Dön", style: .outline) {
                    dismiss()
                }
            }
        }
        .task {
            await maybeShowPermissionPrompt()
        }
    }

    // MARK: - Notification Permission Card
    private var notificationPermissionCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "2E7D32").opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "2E7D32"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Maçı kaçırmamak için")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Maçtan 24 ve 2 saat önce hatırlatma gönderelim")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                Task { await handlePermissionTap() }
            } label: {
                Text("İzin Ver")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(hex: "2E7D32")))
            }
        }
        .padding(14)
        .background(Color(hex: "2E7D32").opacity(0.08))
        .cornerRadius(14)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "2E7D32").opacity(0.25), lineWidth: 1)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Notification Permission Helpers
    @MainActor
    private func maybeShowPermissionPrompt() async {
        // Daha önce sorulduysa veya kullanıcı kapalı toggle'ı varsa atla
        guard !NotificationService.shared.hasAskedPermission else { return }
        let status = await NotificationService.shared.authorizationStatus()
        guard status == .notDetermined else { return }

        // Kısa gecikme — kullanıcı önce bilet kartını görsün
        try? await Task.sleep(nanoseconds: 600_000_000)
        withAnimation { showNotificationPrompt = true }
    }

    @MainActor
    private func handlePermissionTap() async {
        let granted = await NotificationService.shared.requestPermission()
        withAnimation { showNotificationPrompt = false }

        // İzin verildiyse henüz schedule edilmediyse bu rezervasyon için reminder kur
        if granted, let booking = createdBooking {
            await NotificationService.shared.scheduleReminders(for: booking)
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                if currentStep == .payment {
                    Button {
                        withAnimation {
                            currentStep = .summary
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundColor(Color(hex: "2E7D32"))
                    }
                }

                Spacer()

                PrimaryButton(
                    title: currentStep == .summary ? "Ödemeye Geç" : "Güvenli Ödemeye Geç",
                    icon: currentStep == .payment ? "lock.fill" : nil,
                    size: .medium,
                    isLoading: isProcessingPayment,
                    isDisabled: currentStep == .payment && !isBillingComplete,
                    fullWidth: false
                ) {
                    handleNextStep()
                }
            }
            .padding()
            .background(Color.appCardBackground)
        }
    }

    // MARK: - Computed Properties
    private var isBillingComplete: Bool {
        authService.currentUser?.billingAddress?.isComplete == true
    }

    // MARK: - Actions
    private func handleNextStep() {
        switch currentStep {
        case .summary:
            withAnimation {
                currentStep = .payment
            }

        case .payment:
            processPayment()

        case .confirmation:
            break
        }
    }

    private func processPayment() {
        guard isBillingComplete else {
            paymentError = "Ödemeye geçmek için profil ayarlarından fatura bilgilerinizi tamamlayın."
            return
        }

        isProcessingPayment = true

        Task {
            do {
                guard let user = authService.currentUser,
                    let pitch = viewModel.selectedPitch,
                    let startHour = viewModel.selectedStartHour,
                    let endHour = viewModel.selectedEndHour
                else {
                    throw BookingError.unknown("Eksik bilgi")
                }

                // 1) Booking'i oluştur (pending durumda).
                let booking = try await bookingService.createBooking(
                    facility: viewModel.facility,
                    pitch: pitch,
                    date: viewModel.selectedDate,
                    startHour: startHour,
                    endHour: endHour,
                    user: user
                )

                guard let bookingId = booking.id else {
                    throw BookingError.unknown("Rezervasyon kimliği oluşturulamadı.")
                }

                // 2) iyzico CheckoutForm'u initialize et.
                let initResult = try await paymentService.initiateDepositPayment(bookingId: bookingId)

                // 3) WebView'i aç. Sonuç IyzicoPaymentView üzerinden Firestore
                //    listener ile gelir (handlePaymentOutcome).
                pendingBookingId = bookingId
                pendingPaymentUrl = initResult.paymentPageUrl
                pendingPaymentDocId = initResult.paymentDocId
                isProcessingPayment = false
                showPaymentSheet = true

            } catch {
                isProcessingPayment = false
                paymentError = error.localizedDescription
            }
        }
    }

    // MARK: - Payment outcome handler
    private func handlePaymentOutcome(_ outcome: IyzicoPaymentOutcome) {
        showPaymentSheet = false

        switch outcome {
        case .success:
            Task { await handlePaymentSuccess() }

        case .failed(let message):
            // Server zaten booking'i cancelled olarak işaretliyor; iOS state
            // sadece reset edilir.
            paymentError = message
            Task { await resetPaymentState() }

        case .cancelled:
            // Kullanıcı WebView'i kapattı: pending booking slotu blokluyor.
            // İptal et ve state'i sıfırla, kullanıcı baştan deneyebilir.
            Task { await abandonPendingBooking() }

        case .expired:
            paymentError = "Ödeme süresi doldu. Lütfen yeniden deneyin."
            Task { await abandonPendingBooking() }
        }
    }

    /// Kullanıcı ödemeden vazgeçtiğinde mevcut pending booking'i iptal eder
    /// (slot bloğunu kaldırır) ve state'i temiz bir başlangıca alır.
    @MainActor
    private func abandonPendingBooking() async {
        guard let bookingId = pendingBookingId else { return }
        try? await firebaseService.updateDocument(
            in: firebaseService.bookingsCollection,
            documentId: bookingId,
            fields: [
                FirestoreField.status: BookingStatus.cancelled.rawValue,
                "cancellationReason": "Kullanıcı ödemeyi tamamlamadı.",
                "cancelledAt": Timestamp(date: Date()),
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )
        bookingService.clearAllCache()
        await resetPaymentState()
    }

    @MainActor
    private func resetPaymentState() async {
        pendingBookingId = nil
        pendingPaymentUrl = nil
        pendingPaymentDocId = nil
    }

    @MainActor
    private func handlePaymentSuccess() async {
        guard let bookingId = pendingBookingId else {
            paymentError = "Ödeme tamamlandı ancak rezervasyon yüklenemedi."
            return
        }

        do {
            // Sunucu zaten booking'i güncelledi; nihai durumu çekiyoruz.
            let updated: Booking = try await firebaseService.fetchDocument(
                from: firebaseService.bookingsCollection,
                documentId: bookingId
            )
            createdBooking = updated

            // Yan etkiler: local reminder + admin bildirimi (eski simüle akışıyla aynı).
            await bookingService.triggerNewBookingSideEffects(
                booking: updated,
                status: updated.status
            )

            withAnimation { currentStep = .confirmation }
        } catch {
            paymentError = "Ödeme alındı ancak rezervasyon yüklenemedi: \(error.localizedDescription)"
        }
    }
}

// MARK: - Booking Step
enum BookingStep: Int, CaseIterable {
    case summary = 0
    case payment = 1
    case confirmation = 2

    var title: String {
        switch self {
        case .summary: return "Rezervasyon Özeti"
        case .payment: return "Ödeme"
        case .confirmation: return "Onay"
        }
    }
}

// MARK: - Supporting Views

struct PriceRow: View {
    let title: String
    let amount: Double
    var isHighlighted: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(isHighlighted ? .subheadline.weight(.semibold) : .subheadline)

            Spacer()

            Text(amount.asCurrency)
                .font(isHighlighted ? .headline : .subheadline)
                .fontWeight(isHighlighted ? .bold : .regular)
                .foregroundColor(isHighlighted ? Color(hex: "2E7D32") : .primary)
        }
    }
}

struct TicketCardView: View {
    let booking: Booking

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(booking.facilityName)
                        .font(.headline)
                    Text(booking.pitchName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // QR Code (gerçek)
                QRCodeImage(
                    data: booking.qrCode.isEmpty ? booking.ticketNumber : booking.qrCode,
                    size: 60
                )
            }

            // Dashed Divider
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(.gray.opacity(0.5))
                .frame(height: 1)

            // Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tarih")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(booking.formattedDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Saat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(booking.timeSlotString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Süre")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(booking.duration) saat")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Ticket Number
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
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - Preview
#Preview {
    BookingFlowView(viewModel: FacilityDetailViewModel(facility: Facility.mockFacility))
}
