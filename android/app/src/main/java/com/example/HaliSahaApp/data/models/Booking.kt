package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.Exclude
import com.google.firebase.firestore.PropertyName
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

// MARK: - Booking Model
// NOT: Firestore toObject() ile enum deserialization sorunlu olabiliyor.
// Bu yüzden status ve paymentStatus alanları String olarak saklanıyor
// ve computed property ile enum'a dönüştürülüyor (iOS'taki Codable yaklaşımına benzer).
data class Booking(
    @DocumentId
    val id: String? = null,
    val userId: String = "",
    val facilityId: String = "",
    val pitchId: String = "",
    val groupId: String? = null,

    // Denormalize edilmiş veriler
    val facilityName: String = "",
    val pitchName: String = "",
    val facilityAddress: String = "",
    val facilityPhone: String = "",
    val userFullName: String = "",
    val userPhone: String = "",

    // Rezervasyon detayları
    val date: Date = Date(),
    val startHour: Long = 0,  // Firestore int64 → Long (Int yerine)
    val endHour: Long = 0,    // Firestore int64 → Long (Int yerine)
    val duration: Long = 1,   // Firestore int64 → Long (Int yerine)

    // Fiyatlandırma
    val totalPrice: Double = 0.0,
    val depositAmount: Double = 0.0,
    val remainingAmount: Double = 0.0,
    val currency: String = "TRY",

    // Durum bilgileri — String olarak saklanıyor (Firestore uyumluluğu için)
    @get:PropertyName("status") @set:PropertyName("status")
    var statusRaw: String = "pending",

    @get:PropertyName("paymentStatus") @set:PropertyName("paymentStatus")
    var paymentStatusRaw: String = "pending",

    val cancellationReason: String? = null,

    // QR Kod / Bilet
    val qrCode: String = "",
    val ticketNumber: String = "",

    // Tarihler
    val createdAt: Date = Date(),
    val updatedAt: Date = Date(),
    val cancelledAt: Date? = null
) {
    // MARK: - Enum Computed Properties
    // iOS'taki BookingStatus / PaymentStatus enum dönüşümlerinin Android muadili
    // @Exclude: Firestore serializer'ın bu getter'ları görmezden gelmesini sağlar
    // (yoksa @PropertyName ile çakışır → "conflicting getters" hatası)
    val status: BookingStatus
        @Exclude get() = BookingStatus.entries.find { it.rawValue == statusRaw } ?: BookingStatus.pending

    val paymentStatus: PaymentStatus
        @Exclude get() = PaymentStatus.entries.find { it.rawValue == paymentStatusRaw } ?: PaymentStatus.pending

    // MARK: - Computed Properties (Kotlin Getters)
    val timeSlotString: String
        get() = String.format(Locale.getDefault(), "%02d:00 - %02d:00", startHour, endHour)

    val formattedDate: String
        get() = SimpleDateFormat("d MMMM yyyy, EEEE", Locale("tr", "TR")).format(date)

    val shortDate: String
        get() = SimpleDateFormat("d MMM", Locale("tr", "TR")).format(date)

    val isPast: Boolean
        get() {
            val calendar = Calendar.getInstance()
            calendar.time = date
            calendar.set(Calendar.HOUR_OF_DAY, endHour.toInt())
            calendar.set(Calendar.MINUTE, 0)
            return calendar.time.before(Date())
        }

    val canBeCancelled: Boolean
        get() {
            if (status == BookingStatus.cancelled) return false
            val calendar = Calendar.getInstance()
            calendar.time = date
            calendar.set(Calendar.HOUR_OF_DAY, startHour.toInt())

            val diffInMs = calendar.time.time - Date().time
            val diffInHours = TimeUnit.MILLISECONDS.toHours(diffInMs)
            return diffInHours >= 24
        }

    val isRefundable: Boolean
        get() = canBeCancelled && paymentStatus == PaymentStatus.depositPaid

    // MARK: - Helper Methods & Mock Data
    companion object {
        fun generateTicketNumber(): String {
            val year = Calendar.getInstance().get(Calendar.YEAR)
            val random = (1..999999).random()
            return "HS-$year-${String.format("%06d", random)}"
        }

        val mockBooking = Booking(
            id = "booking123",
            userId = "user123",
            facilityId = "facility123",
            pitchId = "pitch123",
            facilityName = "Yıldız Spor Tesisleri",
            pitchName = "Saha A",
            facilityAddress = "Ataşehir, İstanbul",
            facilityPhone = "+902121234567",
            userFullName = "Ahmet Yılmaz",
            userPhone = "+905551234567",
            date = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 3) }.time,
            startHour = 20,
            endHour = 21,
            totalPrice = 800.0,
            depositAmount = 160.0,
            remainingAmount = 640.0,
            statusRaw = BookingStatus.confirmed.rawValue,
            paymentStatusRaw = PaymentStatus.depositPaid.rawValue,
            ticketNumber = "HS-2024-000123"
        )
    }
}

// MARK: - Booking Status Enum
enum class BookingStatus(val rawValue: String, val displayName: String, val color: String, val icon: String) {
    pending("pending", "Onay Bekliyor", "orange", "schedule"),
    confirmed("confirmed", "Onaylandı", "green", "check_circle"),
    completed("completed", "Tamamlandı", "blue", "sports_score"),
    cancelled("cancelled", "İptal Edildi", "red", "cancel"),
    noShow("noShow", "Gelmedi", "gray", "person_off");
}

// MARK: - Payment Status Enum
enum class PaymentStatus(val rawValue: String, val displayName: String) {
    pending("pending", "Ödeme Bekleniyor"),
    depositPaid("depositPaid", "Kapora Ödendi"),
    fullyPaid("fullyPaid", "Ödendi"),
    refunded("refunded", "İade Edildi"),
    partialRefund("partialRefund", "Kısmi İade"),
    failed("failed", "Başarısız");
}

// MARK: - Cancellation Policy Utility
object CancellationPolicy {
    private const val FREE_REFUND_HOURS_LIMIT = 24

    fun canGetRefund(booking: Booking): Pair<Boolean, Double> {
        if (booking.status == BookingStatus.cancelled) return Pair(false, 0.0)

        val calendar = Calendar.getInstance()
        calendar.time = booking.date
        calendar.set(Calendar.HOUR_OF_DAY, booking.startHour.toInt())

        val diffInMs = calendar.time.time - Date().time
        val diffInHours = TimeUnit.MILLISECONDS.toHours(diffInMs)

        return when {
            diffInHours >= FREE_REFUND_HOURS_LIMIT -> Pair(true, 1.0)  // %100 iade
            diffInHours >= 12 -> Pair(true, 0.5)                     // %50 iade
            else -> Pair(false, 0.0)                                 // İade yok
        }
    }
}
