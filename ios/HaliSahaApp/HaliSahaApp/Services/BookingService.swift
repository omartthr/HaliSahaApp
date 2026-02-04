//
//  BookingService.swift
//  HaliSahaApp
//
//  Rezervasyon işlemleri servisi
//
//  Created by Mehmet Mert Mazıcı on 13.01.2026.
//

import FirebaseFirestore
import Foundation

// MARK: - Booking Service
final class BookingService: ObservableObject {

    // MARK: - Singleton
    static let shared = BookingService()

    // MARK: - Published Properties
    @Published var userBookings: [Booking] = []
    @Published var isLoading = false

    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared

    // Cache
    private var timeSlotsCache: [String: [TimeSlot]] = [:]  // key: "facilityId_pitchId_date"

    // MARK: - Private Init
    private init() {}

    // MARK: - Fetch User Bookings
    @MainActor
    func fetchUserBookings() async throws -> [Booking] {
        guard let userId = firebaseService.currentUserId else {
            print("❌ fetchUserBookings: User not authenticated")
            throw BookingError.notAuthenticated
        }

        print("🔍 fetchUserBookings: Fetching for userId: \(userId)")
        isLoading = true

        do {
            let query = firebaseService.bookingsCollection
                .whereField(FirestoreField.userId, isEqualTo: userId)
                .order(by: FirestoreField.createdAt, descending: true)

            let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)
            print("✅ fetchUserBookings: Found \(bookings.count) bookings")
            self.userBookings = bookings
            isLoading = false
            return bookings

        } catch {
            print("❌ fetchUserBookings Error: \(error)")
            isLoading = false
            throw BookingError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Fetch Upcoming Bookings
    @MainActor
    func fetchUpcomingBookings() async throws -> [Booking] {
        guard let userId = firebaseService.currentUserId else {
            throw BookingError.notAuthenticated
        }

        let today = Calendar.current.startOfDay(for: Date())

        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.userId, isEqualTo: userId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField(FirestoreField.status, isEqualTo: BookingStatus.confirmed.rawValue)
            .order(by: FirestoreField.date, descending: false)

        let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)
        return bookings
    }

    // MARK: - Fetch Booking by ID
    @MainActor
    func fetchBooking(id: String) async throws -> Booking {
        do {
            let booking: Booking = try await firebaseService.fetchDocument(
                from: firebaseService.bookingsCollection,
                documentId: id
            )
            return booking
        } catch {
            throw BookingError.notFound
        }
    }

    // MARK: - Create Booking
    @MainActor
    func createBooking(
        facility: Facility,
        pitch: Pitch,
        date: Date,
        startHour: Int,
        endHour: Int,
        user: User
    ) async throws -> Booking {
        guard let userId = firebaseService.currentUserId,
            let facilityId = facility.id,
            let pitchId = pitch.id
        else {
            throw BookingError.notAuthenticated
        }

        // Müsaitlik kontrolü
        let isAvailable = try await checkAvailability(
            facilityId: facilityId,
            pitchId: pitchId,
            date: date,
            startHour: startHour,
            endHour: endHour
        )

        guard isAvailable else {
            throw BookingError.slotNotAvailable
        }

        // Fiyat hesapla
        let duration = endHour - startHour
        let totalPrice = pitch.pricing.calculatePrice(
            startHour: startHour,
            duration: duration,
            isWeekend: date.isWeekend
        )
        let depositAmount = pitch.pricing.calculateDeposit(totalPrice: totalPrice)

        let remainingAmount = totalPrice - depositAmount

        // Booking oluştur
        var booking = Booking(
            userId: userId,
            facilityId: facilityId,
            pitchId: pitchId,
            facilityName: facility.name,
            pitchName: pitch.name,
            facilityAddress: facility.address,
            facilityPhone: facility.phone,
            userFullName: user.fullName,
            userPhone: user.phone,
            date: date,
            startHour: startHour,
            endHour: endHour,
            totalPrice: totalPrice,
            depositAmount: depositAmount,
            remainingAmount: remainingAmount,
            currency: pitch.pricing.currency
        )

        // QR kod ve bilet numarası oluştur
        booking.ticketNumber = Booking.generateTicketNumber()
        booking.qrCode = generateQRCodeData(for: booking)

        // Firestore'a kaydet
        let documentId = try await firebaseService.createDocument(
            in: firebaseService.bookingsCollection,
            data: booking
        )

        booking.id = documentId

        // Cache'i temizle
        clearTimeSlotCache(facilityId: facilityId, pitchId: pitchId, date: date)

        return booking
    }

    // MARK: - Check Availability
    @MainActor
    func checkAvailability(
        facilityId: String,
        pitchId: String,
        date: Date,
        startHour: Int,
        endHour: Int
    ) async throws -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        // Aynı saha, tarih ve saat aralığında onaylı rezervasyon var mı?
        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.pitchId, isEqualTo: pitchId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField(FirestoreField.date, isLessThan: Timestamp(date: endOfDay))
            .whereField(FirestoreField.status, isEqualTo: BookingStatus.confirmed.rawValue)

        let existingBookings: [Booking] = try await firebaseService.fetchDocuments(query: query)

        // Çakışma kontrolü
        for booking in existingBookings {
            if startHour < booking.endHour && endHour > booking.startHour {
                return false
            }
        }

        return true
    }

    // MARK: - Get Available Time Slots
    @MainActor
    func getAvailableTimeSlots(
        facility: Facility,
        pitch: Pitch,
        date: Date
    ) async throws -> [TimeSlot] {
        guard let facilityId = facility.id,
            let pitchId = pitch.id
        else {
            return []
        }

        // Cache kontrolü
        let cacheKey = "\(facilityId)_\(pitchId)_\(date.shortFormatted)"
        if let cached = timeSlotsCache[cacheKey] {
            return cached
        }

        // Çalışma saatlerini al
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        let hours = facility.operatingHours.hours(for: dayOfWeek)

        // Mevcut rezervasyonları al
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.pitchId, isEqualTo: pitchId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField(FirestoreField.date, isLessThan: Timestamp(date: endOfDay))
            .whereField(FirestoreField.status, isEqualTo: BookingStatus.confirmed.rawValue)

        let existingBookings: [Booking] = try await firebaseService.fetchDocuments(query: query)

        // Slot listesi oluştur
        var slots: [TimeSlot] = []
        let openHour = hours.open
        let closeHour = hours.close
        let isWeekend = date.isWeekend

        // 2. Metin halindeki saatleri (örn: "09:00") tam sayıya (9) çeviriyoruz
        let openHourInt = Int(hours.open.prefix(2)) ?? 9  // "09" -> 9
        // "00:00" kapanış saati gece yarısı demek, 24 olarak ele al
        var closeHourInt = Int(hours.close.prefix(2)) ?? 23  // "23" -> 23
        if closeHourInt == 0 {
            closeHourInt = 24  // Gece yarısı = 24
        }

        // Guard: Geçersiz saat aralığı kontrolü
        guard openHourInt < closeHourInt else {
            print("⚠️ Invalid hour range: open=\(openHourInt), close=\(closeHourInt)")
            return []
        }

        for hour in openHourInt..<closeHourInt {
            let isBooked = existingBookings.contains { booking in
                hour >= booking.startHour && hour < booking.endHour
            }

            // Geçmiş saatleri kontrol et
            let now = Date()
            let slotDate = Calendar.current.date(
                bySettingHour: hour, minute: 0, second: 0, of: date)!
            let isPast = slotDate < now

            let price = pitch.pricing.calculatePrice(
                startHour: hour,
                duration: 1,
                isWeekend: isWeekend
            )

            let slot = TimeSlot(
                date: date,
                hour: hour,
                isAvailable: !isBooked && !isPast,
                bookingId: isBooked
                    ? existingBookings.first { $0.startHour <= hour && $0.endHour > hour }?.id
                    : nil,
                price: price
            )

            slots.append(slot)
        }

        // Cache'e kaydet
        timeSlotsCache[cacheKey] = slots

        return slots
    }

    // MARK: - Cancel Booking
    @MainActor
    func cancelBooking(bookingId: String, reason: String?) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw BookingError.notAuthenticated
        }

        // Rezervasyonu al
        let booking: Booking = try await firebaseService.fetchDocument(
            from: firebaseService.bookingsCollection,
            documentId: bookingId
        )

        // Yetki kontrolü
        guard booking.userId == userId else {
            throw BookingError.permissionDenied
        }

        // İptal edilebilir mi kontrolü
        guard booking.canBeCancelled else {
            throw BookingError.cannotCancel
        }

        // İade durumu
        let paymentStatus: PaymentStatus = booking.isRefundable ? .refunded : .partialRefund

        // Güncelle
        try await firebaseService.updateDocument(
            in: firebaseService.bookingsCollection,
            documentId: bookingId,
            fields: [
                FirestoreField.status: BookingStatus.cancelled.rawValue,
                "paymentStatus": paymentStatus.rawValue,
                "cancellationReason": reason ?? "",
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )

        // Cache'i temizle
        clearTimeSlotCache(
            facilityId: booking.facilityId, pitchId: booking.pitchId, date: booking.date)
    }

    // MARK: - Process Payment (Simulation)
    @MainActor
    func processPayment(booking: Booking, paymentMethod: PaymentMethod) async throws
        -> PaymentResult
    {
        // Simüle edilmiş ödeme işlemi
        try await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 saniye bekleme

        // %95 başarı oranı simülasyonu
        let isSuccessful = Double.random(in: 0...1) > 0.05

        if isSuccessful {
            // Rezervasyon durumunu güncelle
            guard let bookingId = booking.id else {
                throw BookingError.unknown("Rezervasyon ID bulunamadı")
            }

            try await firebaseService.updateDocument(
                in: firebaseService.bookingsCollection,
                documentId: bookingId,
                fields: [
                    FirestoreField.status: BookingStatus.confirmed.rawValue,
                    "paymentStatus": PaymentStatus.depositPaid.rawValue,
                    FirestoreField.updatedAt: Timestamp(date: Date()),
                ]
            )

            return PaymentResult(
                success: true,
                transactionId: UUID().uuidString,
                message: "Ödeme başarıyla tamamlandı"
            )
        } else {
            return PaymentResult(
                success: false,
                transactionId: nil,
                message: "Ödeme işlemi başarısız oldu. Lütfen tekrar deneyin."
            )
        }
    }

    // MARK: - Generate QR Code Data
    private func generateQRCodeData(for booking: Booking) -> String {
        let data: [String: Any] = [
            "ticketNumber": booking.ticketNumber ?? "",
            "date": booking.date.ISO8601Format(),
            "startHour": booking.startHour,
            "endHour": booking.endHour,
            "facilityId": booking.facilityId,
            "pitchId": booking.pitchId,
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
            let jsonString = String(data: jsonData, encoding: .utf8)
        {
            return jsonString
        }

        return booking.ticketNumber ?? UUID().uuidString
    }

    // MARK: - Clear Cache
    private func clearTimeSlotCache(facilityId: String, pitchId: String, date: Date) {
        let cacheKey = "\(facilityId)_\(pitchId)_\(date.shortFormatted)"
        timeSlotsCache.removeValue(forKey: cacheKey)
    }

    func clearAllCache() {
        timeSlotsCache.removeAll()
    }

}

// MARK: - Booking Error
enum BookingError: LocalizedError {
    case notAuthenticated
    case notFound
    case slotNotAvailable
    case cannotCancel
    case permissionDenied
    case fetchFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Bu işlem için giriş yapmanız gerekiyor."
        case .notFound:
            return "Rezervasyon bulunamadı."
        case .slotNotAvailable:
            return "Seçtiğiniz saat dilimi artık müsait değil."
        case .cannotCancel:
            return "Bu rezervasyon iptal edilemez."
        case .permissionDenied:
            return "Bu işlem için yetkiniz yok."
        case .fetchFailed(let message):
            return "Veriler yüklenemedi: \(message)"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Payment Method
enum PaymentMethod: String, CaseIterable, Identifiable {
    case creditCard = "Kredi Kartı"
    case debitCard = "Banka Kartı"
    case wallet = "Cüzdan"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        case .wallet: return "wallet.pass.fill"
        }
    }
}

// MARK: - Payment Result
struct PaymentResult {
    let success: Bool
    let transactionId: String?
    let message: String
}
