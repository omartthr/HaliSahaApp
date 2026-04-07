//
//  Booking.swift
//  HaliSahaApp
//
//  Rezervasyon veri modeli
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - Booking Model
struct Booking: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var userId: String               // Rezervasyonu yapan kullanıcı
    var facilityId: String           // Tesis ID
    var pitchId: String              // Alt saha ID
    var groupId: String?             // İlişkili grup (opsiyonel)
    
    // Denormalize edilmiş veriler (Sorgu performansı için)
    var facilityName: String
    var pitchName: String
    var facilityAddress: String
    var facilityPhone: String
    var userFullName: String
    var userPhone: String
    
    // Rezervasyon detayları
    var date: Date                   // Maç tarihi
    var startHour: Int               // Başlangıç saati (0-23)
    var endHour: Int                 // Bitiş saati (0-23)
    var duration: Int                // Süre (saat)
    
    // Fiyatlandırma
    var totalPrice: Double           // Toplam ücret
    var depositAmount: Double        // Kapora miktarı
    var remainingAmount: Double      // Kalan miktar (sahada ödenecek)
    var currency: String
    
    // Durum bilgileri
    var status: BookingStatus
    var paymentStatus: PaymentStatus
    var cancellationReason: String?
    
    // QR Kod / Bilet
    var qrCode: String               // Unique QR kod değeri
    var ticketNumber: String         // Bilet numarası (Örn: HS-2024-001234)
    
    // Tarihler
    var createdAt: Date
    var updatedAt: Date
    var cancelledAt: Date?
    
    // MARK: - Computed Properties
    var timeSlotString: String {
        String(format: "%02d:00 - %02d:00", startHour, endHour)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    var isPast: Bool {
        let calendar = Calendar.current
        let bookingEnd = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: date) ?? date
        return bookingEnd < Date()
    }
    
    var canBeCancelled: Bool {
        guard status != .cancelled else { return false }
        let calendar = Calendar.current
        let bookingStart = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) ?? date
        let hoursUntilMatch = calendar.dateComponents([.hour], from: Date(), to: bookingStart).hour ?? 0
        return hoursUntilMatch >= 24
    }
    
    var isRefundable: Bool {
        return canBeCancelled && paymentStatus == .depositPaid
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        userId: String,
        facilityId: String,
        pitchId: String,
        groupId: String? = nil,
        facilityName: String,
        pitchName: String,
        facilityAddress: String,
        facilityPhone: String,
        userFullName: String,
        userPhone: String,
        date: Date,
        startHour: Int,
        endHour: Int,
        duration: Int = 1,
        totalPrice: Double,
        depositAmount: Double,
        remainingAmount: Double,
        currency: String = "TRY",
        status: BookingStatus = .pending,
        paymentStatus: PaymentStatus = .pending,
        cancellationReason: String? = nil,
        qrCode: String = UUID().uuidString,
        ticketNumber: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        cancelledAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.facilityId = facilityId
        self.pitchId = pitchId
        self.groupId = groupId
        self.facilityName = facilityName
        self.pitchName = pitchName
        self.facilityAddress = facilityAddress
        self.facilityPhone = facilityPhone
        self.userFullName = userFullName
        self.userPhone = userPhone
        self.date = date
        self.startHour = startHour
        self.endHour = endHour
        self.duration = duration
        self.totalPrice = totalPrice
        self.depositAmount = depositAmount
        self.remainingAmount = remainingAmount
        self.currency = currency
        self.status = status
        self.paymentStatus = paymentStatus
        self.cancellationReason = cancellationReason
        self.qrCode = qrCode
        self.ticketNumber = ticketNumber.isEmpty ? Booking.generateTicketNumber() : ticketNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.cancelledAt = cancelledAt
    }
    
    // MARK: - Helper Methods
    static func generateTicketNumber() -> String {
        let year = Calendar.current.component(.year, from: Date())
        let random = String(format: "%06d", Int.random(in: 1...999999))
        return "HS-\(year)-\(random)"
    }
}

// MARK: - Booking Status
enum BookingStatus: String, Codable, CaseIterable {
    case pending = "pending"           // Onay bekliyor
    case confirmed = "confirmed"       // Onaylandı
    case completed = "completed"       // Tamamlandı (maç oynandı)
    case cancelled = "cancelled"       // İptal edildi
    case noShow = "noShow"            // Gelmedi
    
    var displayName: String {
        switch self {
        case .pending: return "Onay Bekliyor"
        case .confirmed: return "Onaylandı"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal Edildi"
        case .noShow: return "Gelmedi"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .green
        case .completed: return .blue
        case .cancelled: return .red
        case .noShow: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        case .noShow: return "person.fill.xmark"
        }
    }
}

// MARK: - Payment Status
enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"           // Ödeme bekleniyor
    case depositPaid = "depositPaid"   // Kapora ödendi
    case fullyPaid = "fullyPaid"       // Tam ödendi
    case refunded = "refunded"         // İade edildi
    case partialRefund = "partialRefund" // Kısmi iade
    case failed = "failed"             // Ödeme başarısız
    
    var displayName: String {
        switch self {
        case .pending: return "Ödeme Bekleniyor"
        case .depositPaid: return "Kapora Ödendi"
        case .fullyPaid: return "Ödendi"
        case .refunded: return "İade Edildi"
        case .partialRefund: return "Kısmi İade"
        case .failed: return "Başarısız"
        }
    }
}

// MARK: - Cancellation Policy
struct CancellationPolicy {
    static let freeRefundHoursLimit: Int = 24  // 24 saat öncesine kadar ücretsiz iptal
    
    static func canGetRefund(for booking: Booking) -> (canRefund: Bool, refundPercentage: Double) {
        guard booking.status != .cancelled else {
            return (false, 0)
        }
        
        let calendar = Calendar.current
        let bookingStart = calendar.date(bySettingHour: booking.startHour, minute: 0, second: 0, of: booking.date) ?? booking.date
        let hoursUntilMatch = calendar.dateComponents([.hour], from: Date(), to: bookingStart).hour ?? 0
        
        if hoursUntilMatch >= freeRefundHoursLimit {
            return (true, 1.0)  // %100 iade
        } else if hoursUntilMatch >= 12 {
            return (true, 0.5)  // %50 iade
        } else {
            return (false, 0)   // İade yok
        }
    }
}

// MARK: - Mock Data
extension Booking {
    static let mockBooking = Booking(
        id: "booking123",
        userId: "user123",
        facilityId: "facility123",
        pitchId: "pitch123",
        facilityName: "Yıldız Spor Tesisleri",
        pitchName: "Saha A",
        facilityAddress: "Gölbaşı, Ankara",
        facilityPhone: "+902121234567",
        userFullName: "Ahmet Yılmaz",
        userPhone: "+905551234567",
        date: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        startHour: 20,
        endHour: 21,
        duration: 1,
        totalPrice: 800,
        depositAmount: 160,
        remainingAmount: 640,
        status: .confirmed,
        paymentStatus: .depositPaid
    )
    
    static let mockBookings: [Booking] = [
        mockBooking,
        Booking(
            id: "booking456",
            userId: "user123",
            facilityId: "facility456",
            pitchId: "pitch456",
            facilityName: "Yeşil Vadi Spor",
            pitchName: "1 No'lu Saha",
            facilityAddress: "Çankaya, Ankara",
            facilityPhone: "+902169876543",
            userFullName: "Ahmet Yılmaz",
            userPhone: "+905551234567",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            startHour: 19,
            endHour: 20,
            duration: 1,
            totalPrice: 700,
            depositAmount: 140,
            remainingAmount: 560,
            status: .completed,
            paymentStatus: .fullyPaid
        )
    ]
}
