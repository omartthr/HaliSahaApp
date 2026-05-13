//
//  BookingFlowView.swift
//  HaliSahaApp
//
//  Rezervasyon Akışı - Ödeme ve Onay
//
//  Created by Mehmet Mert Mazıcı on 20.01.2026.
//

import SwiftUI

// MARK: - Booking Flow View
struct BookingFlowView: View {

    // MARK: - Properties
    @ObservedObject var viewModel: FacilityDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: BookingStep = .summary
    @State private var selectedPaymentMethod: PaymentMethod = .creditCard
    @State private var cardNumber = ""
    @State private var cardHolder = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var isProcessingPayment = false
    @State private var paymentError: String?
    @State private var createdBooking: Booking?

    // Bildirim izni prompt'u (ilk rezervasyon sonrası)
    @State private var showNotificationPrompt = false

    private let bookingService = BookingService.shared
    private let authService = AuthService.shared

    // MARK: - Body
    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep != .confirmation {
                        Button("İptal") {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(currentStep == .confirmation)
            .alert("Ödeme Hatası", isPresented: .constant(paymentError != nil)) {
                Button("Tamam") {
                    paymentError = nil
                }
            } message: {
                if let error = paymentError {
                    Text(error)
                }
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
            // Payment Method Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Ödeme Yöntemi")
                    .font(.headline)

                ForEach(PaymentMethod.allCases) { method in
                    PaymentMethodRow(
                        method: method,
                        isSelected: selectedPaymentMethod == method
                    ) {
                        selectedPaymentMethod = method
                    }
                }
            }

            // Card Details (for Credit/Debit Card)
            if selectedPaymentMethod == .creditCard || selectedPaymentMethod == .debitCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Kart Bilgileri")
                        .font(.headline)

                    CustomTextField(
                        title: "Kart Numarası",
                        placeholder: "1234 5678 9012 3456",
                        text: $cardNumber,
                        icon: "creditcard.fill",
                        keyboardType: .numberPad,
                        textContentType: .creditCardNumber,
                        errorMessage: cardNumberError
                    )
                    .onChange(of: cardNumber) { _, newValue in
                        let formattedValue = PaymentInputFormatter.cardNumber(newValue)
                        if formattedValue != newValue {
                            cardNumber = formattedValue
                        }
                    }

                    CustomTextField(
                        title: "Kart Sahibi",
                        placeholder: "AD SOYAD",
                        text: $cardHolder,
                        icon: "person.fill",
                        textContentType: .name,
                        autocapitalization: .characters,
                        errorMessage: cardHolderError
                    )
                    .onChange(of: cardHolder) { _, newValue in
                        let formattedValue = PaymentInputFormatter.cardHolder(newValue)
                        if formattedValue != newValue {
                            cardHolder = formattedValue
                        }
                    }

                    HStack(spacing: 12) {
                        CustomTextField(
                            title: "Son Kullanma",
                            placeholder: "AA/YY",
                            text: $expiryDate,
                            keyboardType: .numberPad,
                            errorMessage: expiryDateError
                        )
                        .onChange(of: expiryDate) { _, newValue in
                            let formattedValue = PaymentInputFormatter.expiryDate(newValue)
                            if formattedValue != newValue {
                                expiryDate = formattedValue
                            }
                        }

                        CustomTextField(
                            title: "CVV",
                            placeholder: "123",
                            text: $cvv,
                            keyboardType: .numberPad,
                            isSecure: true,
                            errorMessage: cvvError
                        )
                        .onChange(of: cvv) { _, newValue in
                            let formattedValue = PaymentInputFormatter.cvv(newValue)
                            if formattedValue != newValue {
                                cvv = formattedValue
                            }
                        }
                    }
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(16)
            }

            // Amount to Pay
            VStack(spacing: 8) {
                Text("Ödenecek Tutar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(viewModel.depositAmount.asCurrency)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "2E7D32").opacity(0.1))
            .cornerRadius(16)

            // Security Note
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.green)
                Text("256-bit SSL ile güvenli ödeme")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
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
                    title: currentStep == .summary ? "Ödemeye Geç" : "Ödemeyi Tamamla",
                    icon: currentStep == .payment ? "lock.fill" : nil,
                    size: .medium,
                    isLoading: isProcessingPayment,
                    isDisabled: currentStep == .payment && !isPaymentFormValid,
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
    private var isPaymentFormValid: Bool {
        if selectedPaymentMethod == .wallet {
            return true
        }
        return PaymentFormValidator.isValidCardNumber(cardNumber)
            && PaymentFormValidator.isValidCardHolder(cardHolder)
            && PaymentFormValidator.isValidExpiryDate(expiryDate)
            && PaymentFormValidator.isValidCVV(cvv, cardNumber: cardNumber)
    }

    private var cardNumberError: String? {
        guard !cardNumber.isEmpty else { return nil }

        let digits = PaymentInputFormatter.digitsOnly(cardNumber)
        if digits.count < PaymentFormValidator.minimumCardNumberLength {
            return "Kart numarası eksik"
        }

        return PaymentFormValidator.isValidCardNumber(cardNumber)
            ? nil : "Kart numarası geçerli değil"
    }

    private var cardHolderError: String? {
        guard !cardHolder.isEmpty else { return nil }
        return PaymentFormValidator.isValidCardHolder(cardHolder) ? nil : "Ad ve soyad girin"
    }

    private var expiryDateError: String? {
        guard !expiryDate.isEmpty else { return nil }

        let digits = PaymentInputFormatter.digitsOnly(expiryDate)
        if digits.count < 4 {
            return "AA/YY formatında girin"
        }

        return PaymentFormValidator.isValidExpiryDate(expiryDate)
            ? nil : "Son kullanma tarihi geçerli değil"
    }

    private var cvvError: String? {
        guard !cvv.isEmpty else { return nil }
        return PaymentFormValidator.isValidCVV(cvv, cardNumber: cardNumber)
            ? nil : "CVV \(PaymentFormValidator.requiredCVVLength(for: cardNumber)) haneli olmalı"
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
        isProcessingPayment = true

        Task {
            do {
                // Rezervasyon oluştur
                guard let user = authService.currentUser,
                    let pitch = viewModel.selectedPitch,
                    let startHour = viewModel.selectedStartHour,
                    let endHour = viewModel.selectedEndHour
                else {
                    throw BookingError.unknown("Eksik bilgi")
                }

                let booking = try await bookingService.createBooking(
                    facility: viewModel.facility,
                    pitch: pitch,
                    date: viewModel.selectedDate,
                    startHour: startHour,
                    endHour: endHour,
                    user: user
                )

                // Ödeme işlemi
                let result = try await bookingService.processPayment(
                    booking: booking,
                    paymentMethod: selectedPaymentMethod
                )

                if result.success {
                    var confirmedBooking = booking
                    confirmedBooking.status = .confirmed
                    confirmedBooking.paymentStatus = .depositPaid
                    createdBooking = confirmedBooking
                    withAnimation {
                        currentStep = .confirmation
                    }
                } else {
                    paymentError = result.message
                }

            } catch {
                paymentError = error.localizedDescription
            }

            isProcessingPayment = false
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

// MARK: - Payment Input Formatting
enum PaymentInputFormatter {
    static func digitsOnly(_ value: String) -> String {
        value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    static func cardNumber(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(PaymentFormValidator.maximumCardNumberLength))
        return stride(from: 0, to: digits.count, by: 4)
            .map { index in
                let start = digits.index(digits.startIndex, offsetBy: index)
                let end = digits.index(start, offsetBy: min(4, digits.distance(from: start, to: digits.endIndex)))
                return String(digits[start..<end])
            }
            .joined(separator: " ")
    }

    static func cardHolder(_ value: String) -> String {
        let allowedCharacters = CharacterSet.letters
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'"))

        let filteredValue = String(value.unicodeScalars.filter { allowedCharacters.contains($0) })
        let normalizedSpacing = filteredValue.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )

        return String(normalizedSpacing.uppercased(with: Locale(identifier: "tr_TR")).prefix(40))
    }

    static func expiryDate(_ value: String) -> String {
        let digits = String(digitsOnly(value).prefix(4))

        guard !digits.isEmpty else { return "" }

        if digits.count == 1 {
            guard let monthFirstDigit = Int(digits), monthFirstDigit > 1 else {
                return digits
            }

            return "0\(digits)/"
        }

        let month = String(digits.prefix(2))
        let year = String(digits.dropFirst(2))

        guard !year.isEmpty else {
            return "\(month)/"
        }

        return "\(month)/\(year)"
    }

    static func cvv(_ value: String) -> String {
        String(digitsOnly(value).prefix(PaymentFormValidator.maximumCVVLength))
    }
}

// MARK: - Payment Form Validation
enum PaymentFormValidator {
    static let minimumCardNumberLength = 13
    static let maximumCardNumberLength = 19
    static let maximumCVVLength = 4

    static func isValidCardNumber(_ value: String) -> Bool {
        let digits = PaymentInputFormatter.digitsOnly(value)

        guard (minimumCardNumberLength...maximumCardNumberLength).contains(digits.count) else {
            return false
        }

        return passesLuhnCheck(digits)
    }

    static func isValidCardHolder(_ value: String) -> Bool {
        let words = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")

        return words.count >= 2 && words.allSatisfy { word in
            word.filter(\.isLetter).count >= 2
        }
    }

    static func isValidExpiryDate(_ value: String, today: Date = Date()) -> Bool {
        let digits = PaymentInputFormatter.digitsOnly(value)

        guard digits.count == 4,
            let month = Int(digits.prefix(2)),
            let yearSuffix = Int(digits.suffix(2)),
            (1...12).contains(month)
        else {
            return false
        }

        let fullYear = 2000 + yearSuffix
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)

        return fullYear > currentYear || (fullYear == currentYear && month >= currentMonth)
    }

    static func isValidCVV(_ value: String, cardNumber: String) -> Bool {
        PaymentInputFormatter.digitsOnly(value).count == requiredCVVLength(for: cardNumber)
    }

    static func requiredCVVLength(for cardNumber: String) -> Int {
        isAmericanExpress(cardNumber) ? 4 : 3
    }

    private static func isAmericanExpress(_ cardNumber: String) -> Bool {
        let digits = PaymentInputFormatter.digitsOnly(cardNumber)
        return digits.hasPrefix("34") || digits.hasPrefix("37")
    }

    private static func passesLuhnCheck(_ digits: String) -> Bool {
        let reversedDigits = digits.reversed().compactMap { Int(String($0)) }

        guard reversedDigits.count == digits.count else {
            return false
        }

        let checksum = reversedDigits.enumerated().reduce(0) { partialResult, item in
            let (index, digit) = item

            guard index.isMultiple(of: 2) == false else {
                return partialResult + digit
            }

            let doubledDigit = digit * 2
            return partialResult + (doubledDigit > 9 ? doubledDigit - 9 : doubledDigit)
        }

        return checksum.isMultiple(of: 10)
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

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: method.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? Color(hex: "2E7D32") : .secondary)
                    .frame(width: 30)

                Text(method.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(hex: "2E7D32") : .gray)
            }
            .padding()
            .background(isSelected ? Color(hex: "2E7D32").opacity(0.1) : Color.appCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(hex: "2E7D32") : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
