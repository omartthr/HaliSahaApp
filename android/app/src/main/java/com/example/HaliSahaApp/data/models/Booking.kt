package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.TimeUnit

// MARK: - Booking Model
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
    val startHour: Int = 0,
    val endHour: Int = 0,
    val duration: Int = 1,

    // Fiyatlandırma
    val totalPrice: Double = 0.0,
    val depositAmount: Double = 0.0,
    val remainingAmount: Double = 0.0,
    val currency: String = "TRY",

    // Durum bilgileri
    val status: BookingStatus = BookingStatus.PENDING,
    val paymentStatus: PaymentStatus = PaymentStatus.PENDING,
    val cancellationReason: String? = null,

    // QR Kod / Bilet
    val qrCode: String = UUID.randomUUID().toString(),
    val ticketNumber: String = "",

    // Tarihler
    val createdAt: Date = Date(),
    val updatedAt: Date = Date(),
    val cancelledAt: Date? = null
) {
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
            calendar.set(Calendar.HOUR_OF_DAY, endHour)
            calendar.set(Calendar.MINUTE, 0)
            return calendar.time.before(Date())
        }

    val canBeCancelled: Boolean
        get() {
            if (status == BookingStatus.CANCELLED) return false
            val calendar = Calendar.getInstance()
            calendar.time = date
            calendar.set(Calendar.HOUR_OF_DAY, startHour)

            val diffInMs = calendar.time.time - Date().time
            val diffInHours = TimeUnit.MILLISECONDS.toHours(diffInMs)
            return diffInHours >= 24
        }

    val isRefundable: Boolean
        get() = canBeCancelled && paymentStatus == PaymentStatus.DEPOSIT_PAID

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
            status = BookingStatus.CONFIRMED,
            paymentStatus = PaymentStatus.DEPOSIT_PAID,
            ticketNumber = "HS-2024-000123"
        )
    }
}

// MARK: - Booking Status Enum
enum class BookingStatus(val rawValue: String, val displayName: String, val color: String, val icon: String) {
    PENDING("pending", "Onay Bekliyor", "orange", "schedule"),
    CONFIRMED("confirmed", "Onaylandı", "green", "check_circle"),
    COMPLETED("completed", "Tamamlandı", "blue", "sports_score"),
    CANCELLED("cancelled", "İptal Edildi", "red", "cancel"),
    NO_SHOW("noShow", "Gelmedi", "gray", "person_off");
}

// MARK: - Payment Status Enum
enum class PaymentStatus(val rawValue: String, val displayName: String) {
    PENDING("pending", "Ödeme Bekleniyor"),
    DEPOSIT_PAID("depositPaid", "Kapora Ödendi"),
    FULLY_PAID("fullyPaid", "Ödendi"),
    REFUNDED("refunded", "İade Edildi"),
    PARTIAL_REFUND("partialRefund", "Kısmi İade"),
    FAILED("failed", "Başarısız");
}

// MARK: - Cancellation Policy Utility
object CancellationPolicy {
    private const val FREE_REFUND_HOURS_LIMIT = 24

    fun canGetRefund(booking: Booking): Pair<Boolean, Double> {
        if (booking.status == BookingStatus.CANCELLED) return Pair(false, 0.0)

        val calendar = Calendar.getInstance()
        calendar.time = booking.date
        calendar.set(Calendar.HOUR_OF_DAY, booking.startHour)

        val diffInMs = calendar.time.time - Date().time
        val diffInHours = TimeUnit.MILLISECONDS.toHours(diffInMs)

        return when {
            diffInHours >= FREE_REFUND_HOURS_LIMIT -> Pair(true, 1.0)  // %100 iade
            diffInHours >= 12 -> Pair(true, 0.5)                     // %50 iade
            else -> Pair(false, 0.0)                                 // İade yok
        }
    }
}