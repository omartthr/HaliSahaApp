package com.example.HaliSahaApp.data.services

import com.example.HaliSahaApp.data.models.*
import com.example.HaliSahaApp.data.remote.*
import com.example.HaliSahaApp.utils.AppConstants
import com.example.HaliSahaApp.utils.isWeekend
import com.example.HaliSahaApp.utils.shortFormatted
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.gson.Gson
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Calendar
import java.util.Date
import java.util.UUID

// MARK: - Booking Service
object BookingService {

    private val firebaseService = FirebaseService

    // MARK: - UI State
    private val _userBookings = MutableStateFlow<List<Booking>>(emptyList())
    val userBookings: StateFlow<List<Booking>> = _userBookings.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // Cache
    // key: "facilityId_pitchId_date" -> List<TimeSlot>
    private val timeSlotsCache = mutableMapOf<String, List<TimeSlot>>()

    // MARK: - Fetch User Bookings
    suspend fun fetchUserBookings(): List<Booking> {
        val userId = firebaseService.currentUserId ?: throw BookingError.NotAuthenticated

        _isLoading.value = true

        return try {
            val query = firebaseService.bookingsCollection
                .whereEqualTo(FirestoreField.USER_ID, userId)
            //.orderBy(FirestoreField.CREATED_AT, com.google.firebase.firestore.Query.Direction.DESCENDING)
            // Not: İki farklı alana göre sorgu (where + order) index gerektirebilir.
            // Şimdilik client side sıralama yapabiliriz veya Firebase Console'dan index oluşturmalısın.

            val bookings: List<Booking> = firebaseService.fetchDocuments(query)

            // Client side sıralama (En yeniden eskiye)
            val sortedBookings = bookings.sortedByDescending { it.createdAt }

            _userBookings.value = sortedBookings
            _isLoading.value = false
            sortedBookings

        } catch (e: Exception) {
            _isLoading.value = false
            throw BookingError.FetchFailed(e.localizedMessage ?: "Hata")
        }
    }

    // MARK: - Fetch Upcoming Bookings
    suspend fun fetchUpcomingBookings(): List<Booking> {
        val userId = firebaseService.currentUserId ?: throw BookingError.NotAuthenticated

        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.time

        val query = firebaseService.bookingsCollection
            .whereEqualTo(FirestoreField.USER_ID, userId)
            .whereGreaterThanOrEqualTo(FirestoreField.DATE, Timestamp(today))
            .whereEqualTo(FirestoreField.STATUS, BookingStatus.CONFIRMED.rawValue)

        val bookings: List<Booking> = firebaseService.fetchDocuments(query)
        return bookings.sortedBy { it.date }
    }

    // MARK: - Fetch Booking by ID
    suspend fun fetchBooking(id: String): Booking {
        return try {
            firebaseService.fetchDocument(firebaseService.bookingsCollection, id)
        } catch (e: Exception) {
            throw BookingError.NotFound
        }
    }

    // MARK: - Create Booking
    suspend fun createBooking(
        facility: Facility,
        pitch: Pitch,
        date: Date,
        startHour: Int,
        endHour: Int,
        user: User
    ): Booking {
        val userId = firebaseService.currentUserId
        val facilityId = facility.id
        val pitchId = pitch.id

        if (userId == null || facilityId == null || pitchId == null) {
            throw BookingError.NotAuthenticated
        }

        // Müsaitlik kontrolü
        val isAvailable = checkAvailability(
            facilityId = facilityId,
            pitchId = pitchId,
            date = date,
            startHour = startHour,
            endHour = endHour
        )

        if (!isAvailable) {
            throw BookingError.SlotNotAvailable
        }

        // Fiyat hesapla
        val duration = endHour - startHour
        val totalPrice = pitch.pricing.calculatePrice(
            startHour = startHour,
            duration = duration,
            isWeekend = date.isWeekend() // Extension kullanılıyor
        )
        val depositAmount = pitch.pricing.calculateDeposit(totalPrice)
        val remainingAmount = totalPrice - depositAmount

        // Booking objesi oluştur
        var booking = Booking(
            userId = userId,
            facilityId = facilityId,
            pitchId = pitchId,
            facilityName = facility.name,
            pitchName = pitch.name,
            facilityAddress = facility.address,
            facilityPhone = facility.phone,
            userFullName = user.fullName,
            userPhone = user.phone,
            date = date,
            startHour = startHour,
            endHour = endHour,
            duration = duration,
            totalPrice = totalPrice,
            depositAmount = depositAmount,
            remainingAmount = remainingAmount,
            currency = pitch.pricing.currency
        )

        // Bilet ve QR
        val ticketNumber = Booking.generateTicketNumber()
        val qrCode = generateQRCodeData(booking.copy(ticketNumber = ticketNumber))

        // Güncel veriyi tekrar oluştur (val olduğu için copy)
        val finalBooking = booking.copy(ticketNumber = ticketNumber, qrCode = qrCode)

        // Firestore'a kaydet
        val documentId = firebaseService.createDocument(
            collection = firebaseService.bookingsCollection,
            data = finalBooking
        )

        val savedBooking = finalBooking.copy(id = documentId)

        // Cache temizle
        clearTimeSlotCache(facilityId, pitchId, date)

        return savedBooking
    }

    // MARK: - Check Availability
    suspend fun checkAvailability(
        facilityId: String,
        pitchId: String,
        date: Date,
        startHour: Int,
        endHour: Int
    ): Boolean {
        val calendar = Calendar.getInstance()
        calendar.time = date
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        val startOfDay = calendar.time

        calendar.add(Calendar.DAY_OF_YEAR, 1)
        val endOfDay = calendar.time

        val query = firebaseService.bookingsCollection
            .whereEqualTo(FirestoreField.PITCH_ID, pitchId)
            .whereGreaterThanOrEqualTo(FirestoreField.DATE, Timestamp(startOfDay))
            .whereLessThan(FirestoreField.DATE, Timestamp(endOfDay))
            .whereEqualTo(FirestoreField.STATUS, BookingStatus.CONFIRMED.rawValue)

        val existingBookings: List<Booking> = firebaseService.fetchDocuments(query)

        // Çakışma kontrolü
        for (booking in existingBookings) {
            // (start1 < end2 && end1 > start2)
            if (startHour < booking.endHour && endHour > booking.startHour) {
                return false
            }
        }
        return true
    }

    // MARK: - Get Available Time Slots
    suspend fun getAvailableTimeSlots(
        facility: Facility,
        pitch: Pitch,
        date: Date
    ): List<TimeSlot> {
        val facilityId = facility.id ?: return emptyList()
        val pitchId = pitch.id ?: return emptyList()

        // Cache kontrolü
        val cacheKey = "${facilityId}_${pitchId}_${date.shortFormatted()}"
        timeSlotsCache[cacheKey]?.let { return it }

        // Çalışma saatlerini al
        val calendar = Calendar.getInstance()
        calendar.time = date
        // Calendar.DAY_OF_WEEK: Pazar=1, Pazartesi=2...
        val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)

        // Modelimizdeki hoursForDay fonksiyonunu kullan
        val hours = facility.operatingHours.hoursForDay(dayOfWeek)

        // Mevcut rezervasyonları çek
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        val startOfDay = calendar.time

        calendar.add(Calendar.DAY_OF_YEAR, 1)
        val endOfDay = calendar.time

        val query = firebaseService.bookingsCollection
            .whereEqualTo(FirestoreField.PITCH_ID, pitchId)
            .whereGreaterThanOrEqualTo(FirestoreField.DATE, Timestamp(startOfDay))
            .whereLessThan(FirestoreField.DATE, Timestamp(endOfDay))
            .whereEqualTo(FirestoreField.STATUS, BookingStatus.CONFIRMED.rawValue)

        val existingBookings: List<Booking> = firebaseService.fetchDocuments(query)

        // Slot listesi oluştur
        val slots = mutableListOf<TimeSlot>()

        // "09:00" -> 9 dönüşümü
        val openHour = hours.first.take(2).toIntOrNull() ?: 9
        val closeHour = hours.second.take(2).toIntOrNull() ?: 23
        val isWeekend = date.isWeekend()

        for (hour in openHour until closeHour) {
            // Bu saatte rezervasyon var mı?
            val bookingAtHour = existingBookings.find { booking ->
                hour >= booking.startHour && hour < booking.endHour
            }
            val isBooked = bookingAtHour != null

            // Geçmiş zaman kontrolü
            val slotCalendar = Calendar.getInstance()
            slotCalendar.time = date
            slotCalendar.set(Calendar.HOUR_OF_DAY, hour)
            slotCalendar.set(Calendar.MINUTE, 0)
            val isPast = slotCalendar.time.before(Date())

            val price = pitch.pricing.calculatePrice(
                startHour = hour,
                duration = 1,
                isWeekend = isWeekend
            )

            val slot = TimeSlot(
                date = date,
                hour = hour,
                isAvailable = !isBooked && !isPast,
                bookingId = bookingAtHour?.id,
                price = price
            )
            slots.add(slot)
        }

        // Cache'e yaz
        timeSlotsCache[cacheKey] = slots
        return slots
    }

    // MARK: - Cancel Booking
    suspend fun cancelBooking(bookingId: String, reason: String? = null) {
        val userId = firebaseService.currentUserId ?: throw BookingError.NotAuthenticated

        val booking: Booking = firebaseService.fetchDocument(
            firebaseService.bookingsCollection,
            bookingId
        )

        if (booking.userId != userId) {
            throw BookingError.PermissionDenied
        }

        if (!booking.canBeCancelled) {
            throw BookingError.CannotCancel
        }

        val paymentStatus = if (booking.isRefundable) PaymentStatus.REFUNDED else PaymentStatus.PARTIAL_REFUND

        val updates = mapOf(
            FirestoreField.STATUS to BookingStatus.CANCELLED.rawValue,
            "paymentStatus" to paymentStatus.rawValue,
            "cancellationReason" to (reason ?: ""),
            FirestoreField.UPDATED_AT to FieldValue.serverTimestamp()
        )

        firebaseService.updateDocument(firebaseService.bookingsCollection, bookingId, updates)

        // Cache temizle
        clearTimeSlotCache(booking.facilityId, booking.pitchId, booking.date)
    }

    // MARK: - Process Payment (Simulation)
    suspend fun processPayment(booking: Booking, paymentMethod: PaymentMethod): PaymentResult {
        delay(1500) // 1.5 saniye bekle

        // %95 başarı oranı
        val isSuccessful = Math.random() > 0.05

        return if (isSuccessful) {
            val bookingId = booking.id ?: throw BookingError.Unknown("Rezervasyon ID yok")

            val updates = mapOf(
                FirestoreField.STATUS to BookingStatus.CONFIRMED.rawValue,
                "paymentStatus" to PaymentStatus.DEPOSIT_PAID.rawValue,
                FirestoreField.UPDATED_AT to FieldValue.serverTimestamp()
            )

            firebaseService.updateDocument(firebaseService.bookingsCollection, bookingId, updates)

            PaymentResult(true, UUID.randomUUID().toString(), "Ödeme başarıyla tamamlandı")
        } else {
            PaymentResult(false, null, "Ödeme işlemi başarısız oldu. Lütfen tekrar deneyin.")
        }
    }

    // MARK: - Generate QR Code Data (JSON String)
    private fun generateQRCodeData(booking: Booking): String {
        val map = mapOf(
            "ticketNumber" to (booking.ticketNumber),
            "date" to booking.date.toString(), // Basit string
            "startHour" to booking.startHour,
            "endHour" to booking.endHour,
            "facilityId" to booking.facilityId,
            "pitchId" to booking.pitchId
        )
        return Gson().toJson(map)
    }

    // MARK: - Cache Helpers
    private fun clearTimeSlotCache(facilityId: String, pitchId: String, date: Date) {
        val cacheKey = "${facilityId}_${pitchId}_${date.shortFormatted()}"
        timeSlotsCache.remove(cacheKey)
    }

    fun clearAllCache() {
        timeSlotsCache.clear()
    }

    // MARK: - Mock Data (Swift'teki gibi)
    fun loadMockBookings(): List<Booking> {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, 3)
        val futureDate = calendar.time

        val mockBookings = listOf(
            Booking.mockBooking,
            Booking(
                id = "mock2",
                userId = "user123",
                facilityId = "facility1",
                pitchId = "pitch1",
                facilityName = "Elit Arena",
                pitchName = "Saha 2",
                facilityAddress = "Kadıköy, İstanbul",
                facilityPhone = "+902161234567",
                userFullName = "Ahmet Yılmaz",
                userPhone = "5551234567",
                date = futureDate,
                startHour = 20,
                endHour = 21,
                totalPrice = 700.0,
                depositAmount = 140.0,
                remainingAmount = 400.0,
                currency = "TRY",
                status = BookingStatus.CONFIRMED,
                paymentStatus = PaymentStatus.DEPOSIT_PAID,
                ticketNumber = Booking.generateTicketNumber()
            )
        )

        _userBookings.value = mockBookings
        return mockBookings
    }
}

// MARK: - Enums & Data Classes

enum class PaymentMethod(val rawValue: String, val icon: String) {
    CREDIT_CARD("Kredi Kartı", "credit_card"),
    DEBIT_CARD("Banka Kartı", "credit_card"),
    WALLET("Cüzdan", "account_balance_wallet")
}

data class PaymentResult(
    val success: Boolean,
    val transactionId: String?,
    val message: String
)

sealed class BookingError(message: String) : Exception(message) {
    object NotAuthenticated : BookingError("Bu işlem için giriş yapmanız gerekiyor.")
    object NotFound : BookingError("Rezervasyon bulunamadı.")
    object SlotNotAvailable : BookingError("Seçtiğiniz saat dilimi artık müsait değil.")
    object CannotCancel : BookingError("Bu rezervasyon iptal edilemez.")
    object PermissionDenied : BookingError("Bu işlem için yetkiniz yok.")
    class FetchFailed(message: String) : BookingError("Veriler yüklenemedi: $message")
    class Unknown(message: String) : BookingError(message)
}