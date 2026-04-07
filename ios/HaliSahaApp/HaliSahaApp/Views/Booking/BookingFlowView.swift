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
            .background(Color(.systemGroupedBackground))
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
            .background(Color(.systemBackground))
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
                .background(Color(.systemBackground))
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
                        keyboardType: .numberPad
                    )

                    CustomTextField(
                        title: "Kart Sahibi",
                        placeholder: "AD SOYAD",
                        text: $cardHolder,
                        icon: "person.fill",
                        autocapitalization: .characters
                    )

                    HStack(spacing: 12) {
                        CustomTextField(
                            title: "Son Kullanma",
                            placeholder: "AA/YY",
                            text: $expiryDate,
                            keyboardType: .numberPad
                        )

                        CustomTextField(
                            title: "CVV",
                            placeholder: "123",
                            text: $cvv,
                            keyboardType: .numberPad,
                            isSecure: true
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
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
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Computed Properties
    private var isPaymentFormValid: Bool {
        if selectedPaymentMethod == .wallet {
            return true
        }
        return !cardNumber.isEmpty && !cardHolder.isEmpty && !expiryDate.isEmpty && !cvv.isEmpty
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
                    createdBooking = booking
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
            .background(isSelected ? Color(hex: "2E7D32").opacity(0.1) : Color(.systemBackground))
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

                // QR Code Placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 60, height: 60)

                    Image(systemName: "qrcode")
                        .font(.title)
                        .foregroundColor(.black)
                }
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

                Text(booking.ticketNumber ?? "")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2E7D32"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

// MARK: - Preview
#Preview {
    BookingFlowView(viewModel: FacilityDetailViewModel(facility: Facility.mockFacility))
}
