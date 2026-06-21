package com.example.HaliSahaApp.data.services

import com.example.HaliSahaApp.data.models.*
import com.example.HaliSahaApp.data.remote.FirebaseService
import com.example.HaliSahaApp.data.remote.FirestoreField
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.Query
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Calendar
import java.util.Date
import java.util.UUID

// MARK: - Admin Service
object AdminService {

    private val firebaseService = FirebaseService
    private val authService = com.example.HaliSahaApp.data.remote.AuthService

    // MARK: - UI State
    private val _myFacilities = MutableStateFlow<List<Facility>>(emptyList())
    val myFacilities: StateFlow<List<Facility>> = _myFacilities.asStateFlow()

    private val _pendingBookings = MutableStateFlow<List<Booking>>(emptyList())
    val pendingBookings: StateFlow<List<Booking>> = _pendingBookings.asStateFlow()

    private val _todayBookings = MutableStateFlow<List<Booking>>(emptyList())
    val todayBookings: StateFlow<List<Booking>> = _todayBookings.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _myAdminProfile = MutableStateFlow<AdminProfile?>(null)
    val myAdminProfile: StateFlow<AdminProfile?> = _myAdminProfile.asStateFlow()

    // MARK: - Dashboard Stats Data Class
    data class DashboardStats(
        var totalFacilities: Int = 0,
        var totalPitches: Int = 0,
        var todayBookings: Int = 0,
        var pendingBookings: Int = 0,
        var monthlyRevenue: Double = 0.0,
        var monthlyBookings: Int = 0,
        var averageRating: Double = 0.0,
        var totalReviews: Int = 0
    )

    // MARK: - Revenue Report Data Class
    data class RevenueReport(
        val month: Date,
        val totalRevenue: Double,
        val totalDeposits: Double,
        val totalBookings: Int,
        val dailyRevenue: Map<Date, Double>
    ) {
        val averagePerBooking: Double
            get() = if (totalBookings > 0) totalRevenue / totalBookings else 0.0
    }

    // MARK: - Fetch Dashboard Stats
    suspend fun fetchDashboardStats(): DashboardStats {
        val userId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        var stats = DashboardStats()

        try {
            // 1. Tesislerimi al
            val facilities = fetchMyFacilities()
            stats.totalFacilities = facilities.size

            // 2. Toplam saha ve puan hesapla
            var totalPitches = 0
            var totalRating = 0.0
            var totalReviews = 0

            val facilityIds = facilities.mapNotNull { it.id }

            // Her tesis için sahaları çek (Gerçek senaryoda bu optimize edilmeli)
            for (facility in facilities) {
                // Burada fetchPitches fonksiyonunu kullanıyoruz ama facilityId lazım
                facility.id?.let { id ->
                    val pitches = fetchPitches(id)
                    totalPitches += pitches.size
                }

                totalRating += facility.averageRating * facility.totalReviews
                totalReviews += facility.totalReviews
            }

            stats.totalPitches = totalPitches
            stats.averageRating = if (totalReviews > 0) totalRating / totalReviews else 0.0
            stats.totalReviews = totalReviews

            // 3. Bugünkü rezervasyonlar
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val today = calendar.time

            calendar.add(Calendar.DAY_OF_YEAR, 1)
            val tomorrow = calendar.time

            // Not: Firestore'da "IN" sorgusu 10 elemanla sınırlıdır.
            // Eğer çok tesis varsa bu sorguyu bölmek gerekir. Şimdilik client-side filtreleme yapıyoruz.
            // Gerçek projede "ownerId" alanı Booking'de de tutulursa tek sorguda çekilebilir.

            // Şimdilik Mock veri veya genel sorgu yapıp filtreleyelim
            // (Performans uyarısı: Bu yöntem production için ideal değil)
            val allBookingsQuery = firebaseService.bookingsCollection
                .whereGreaterThanOrEqualTo(FirestoreField.DATE, Timestamp(today))
                .whereLessThan(FirestoreField.DATE, Timestamp(tomorrow))

            val allTodayBookings: List<Booking> = firebaseService.fetchDocuments(allBookingsQuery)

            // Benim tesislerime ait olanları filtrele
            val myTodayBookings = allTodayBookings.filter { facilityIds.contains(it.facilityId) }

            stats.todayBookings = myTodayBookings.size
            _todayBookings.value = myTodayBookings

            // 4. Aylık Gelir
            calendar.time = Date()
            calendar.set(Calendar.DAY_OF_MONTH, 1) // Ayın başı
            val startOfMonth = calendar.time

            val monthlyBookings = myTodayBookings.filter { it.createdAt >= startOfMonth }

            stats.monthlyBookings = monthlyBookings.size
            stats.monthlyRevenue = monthlyBookings.sumOf { it.depositAmount }

            return stats

        } catch (e: Exception) {
            throw AdminError.OperationFailed(e.localizedMessage ?: "İstatistikler alınamadı")
        }
    }

    // MARK: - Admin Profile Listener
    fun startMyAdminProfileListener() {
        val userId = firebaseService.currentUserId ?: return
        
        firebaseService.adminsCollection.document(userId).addSnapshotListener { snapshot, error ->
            if (error != null) return@addSnapshotListener
            
            if (snapshot != null && snapshot.exists()) {
                val profile = snapshot.toObject(AdminProfile::class.java)
                _myAdminProfile.value = profile
            } else {
                _myAdminProfile.value = null
            }
        }
    }

    // MARK: - Admin Verification (Belge Yükleme & Onay Akışı)
    
    suspend fun fetchMyAdminProfile(): AdminProfile {
        val userId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        return try {
            firebaseService.fetchDocument(firebaseService.adminsCollection, userId)
        } catch (e: Exception) {
            throw AdminError.OperationFailed("Profil yüklenemedi")
        }
    }
    
    suspend fun fetchAdminProfile(adminId: String): AdminProfile {
        return firebaseService.fetchDocument(firebaseService.adminsCollection, adminId)
    }
    
    suspend fun submitVerificationDocuments(documents: VerificationDocuments) {
        val userId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        if (!documents.isComplete) throw AdminError.InvalidData
        
        val updates = mapOf(
            "documents" to documents,
            "documentsSubmittedAt" to FieldValue.serverTimestamp(),
            "approvalStatus" to AdminApprovalStatus.PENDING,
            "rejectionReason" to FieldValue.delete(),
            FirestoreField.UPDATED_AT to FieldValue.serverTimestamp()
        )
        
        firebaseService.updateDocument(firebaseService.adminsCollection, userId, updates)
    }
    
    // MARK: - Super Admin Actions
    
    suspend fun fetchPendingAdmins(): List<AdminProfile> {
        val query = firebaseService.adminsCollection
            .whereEqualTo("approvalStatus", AdminApprovalStatus.PENDING)
            
        val admins: List<AdminProfile> = firebaseService.fetchDocuments(query)
        return admins.filter { it.documentsSubmittedAt != null }
            .sortedBy { it.documentsSubmittedAt }
    }
    
    suspend fun fetchAllAdmins(status: AdminApprovalStatus? = null): List<AdminProfile> {
        val query = if (status != null) {
            firebaseService.adminsCollection.whereEqualTo("approvalStatus", status)
        } else {
            firebaseService.adminsCollection
        }
        
        val admins: List<AdminProfile> = firebaseService.fetchDocuments(query)
        return admins.sortedByDescending { it.createdAt }
    }
    
    suspend fun approveAdmin(adminId: String) {
        val reviewerId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        val now = FieldValue.serverTimestamp()
        
        val updates = mapOf(
            "approvalStatus" to AdminApprovalStatus.APPROVED,
            "approvedAt" to now,
            "reviewedAt" to now,
            "reviewedBy" to reviewerId,
            "rejectionReason" to FieldValue.delete(),
            FirestoreField.UPDATED_AT to now
        )
        firebaseService.updateDocument(firebaseService.adminsCollection, adminId, updates)
    }
    
    suspend fun rejectAdmin(adminId: String, reason: String) {
        val reviewerId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        val trimmed = reason.trim()
        if (trimmed.isEmpty()) throw AdminError.InvalidData
        
        val now = FieldValue.serverTimestamp()
        val updates = mapOf(
            "approvalStatus" to AdminApprovalStatus.REJECTED,
            "rejectionReason" to trimmed,
            "reviewedAt" to now,
            "reviewedBy" to reviewerId,
            FirestoreField.UPDATED_AT to now
        )
        firebaseService.updateDocument(firebaseService.adminsCollection, adminId, updates)
    }
    
    suspend fun suspendAdmin(adminId: String, reason: String) {
        val reviewerId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        val trimmed = reason.trim()
        if (trimmed.isEmpty()) throw AdminError.InvalidData
        
        val now = FieldValue.serverTimestamp()
        val updates = mapOf(
            "approvalStatus" to AdminApprovalStatus.SUSPENDED,
            "rejectionReason" to trimmed,
            "reviewedAt" to now,
            "reviewedBy" to reviewerId,
            FirestoreField.UPDATED_AT to now
        )
        firebaseService.updateDocument(firebaseService.adminsCollection, adminId, updates)
    }

    // MARK: - Fetch My Facilities
    suspend fun fetchMyFacilities(): List<Facility> {
        val userId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated

        _isLoading.value = true
        return try {
            val query = firebaseService.facilitiesCollection
                .whereEqualTo(FirestoreField.OWNER_ID, userId)

            val facilities: List<Facility> = firebaseService.fetchDocuments(query)
            _myFacilities.value = facilities
            _isLoading.value = false
            facilities
        } catch (e: Exception) {
            _isLoading.value = false
            // Hata durumunda mock data dön (Geliştirme için)
            val mocks = loadMockAdminFacilities()
            _myFacilities.value = mocks
            mocks
        }
    }

    // MARK: - Fetch Pitches
    suspend fun fetchPitches(facilityId: String): List<Pitch> {
        return try {
            val query = firebaseService.pitchesCollection(facilityId)
            firebaseService.fetchDocuments(query)
        } catch (e: Exception) {
            emptyList()
        }
    }

    // MARK: - Fetch All Bookings
    suspend fun fetchAllBookings(): List<Booking> {
        val userId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        return try {
            // Gerçek senaryoda ownerı olduğu facility'leri alır ve onlara ait bookingleri çeker
            val myFacilities = fetchMyFacilities()
            val facilityIds = myFacilities.mapNotNull { it.id }
            
            if (facilityIds.isEmpty()) return emptyList()

            // NOT: Firebase'te '.whereIn' 10 id ile sınırlıdır.
            val query = firebaseService.bookingsCollection
                .whereIn("facilityId", facilityIds.take(10)) 
            
            firebaseService.fetchDocuments(query)
        } catch (e: Exception) {
            emptyList()
        }
    }

    // MARK: - Create/Update Facility
    suspend fun createFacility(facility: Facility): String {
        val userId = firebaseService.currentUserId ?: throw AdminError.NotAuthenticated
        val newFacility = facility.copy(ownerId = userId, status = FacilityStatus.pending)

        return try {
            firebaseService.createDocument(firebaseService.facilitiesCollection, newFacility)
        } catch (e: Exception) {
            throw AdminError.OperationFailed("Tesis oluşturulamadı")
        }
    }

    suspend fun updateFacility(facility: Facility) {
        val facilityId = facility.id ?: throw AdminError.InvalidData
        // Firestore update işlemi generic yapılmalı veya elle map oluşturulmalı
        // Şimdilik basitleştirilmiş:
        try {
            firebaseService.facilitiesCollection.document(facilityId).set(facility)
        } catch (e: Exception) {
            throw AdminError.OperationFailed("Güncelleme başarısız")
        }
    }

    // MARK: - Booking Actions
    suspend fun confirmBooking(bookingId: String) {
        updateBookingStatus(bookingId, BookingStatus.confirmed)
    }

    suspend fun rejectBooking(bookingId: String, reason: String) {
        // NOT: paymentStatus client-side güncellemelere kapalı (Firestore rules)
        val updates = mapOf(
            FirestoreField.STATUS to BookingStatus.cancelled.rawValue,
            "cancellationReason" to reason,
            FirestoreField.UPDATED_AT to FieldValue.serverTimestamp()
        )
        try {
            firebaseService.updateDocument(firebaseService.bookingsCollection, bookingId, updates)
        } catch (e: Exception) {
            throw AdminError.OperationFailed("İşlem başarısız")
        }
    }

    private suspend fun updateBookingStatus(bookingId: String, status: BookingStatus) {
        val updates = mapOf(
            FirestoreField.STATUS to status.rawValue,
            FirestoreField.UPDATED_AT to FieldValue.serverTimestamp()
        )
        try {
            firebaseService.updateDocument(firebaseService.bookingsCollection, bookingId, updates)
        } catch (e: Exception) {
            throw AdminError.OperationFailed("Durum güncellenemedi")
        }
    }

    // MARK: - Mock Data
    fun loadMockAdminBookings(): List<Booking> {
        val calendar = Calendar.getInstance()

        return listOf(
            Booking(
                id = "admin_booking_1",
                userId = "user1",
                facilityId = "admin_facility_1",
                pitchId = "pitch1",
                facilityName = "Yıldız Spor Tesisleri",
                pitchName = "Saha 1",
                facilityAddress = "Ataşehir, İstanbul",
                facilityPhone = "+902121234567",
                userFullName = "Ahmet Yılmaz",
                userPhone = "5551234567",
                date = Date(), // Bugün
                startHour = 19,
                endHour = 20,
                totalPrice = 650.0,
                depositAmount = 130.0,
                remainingAmount = 520.0,
                currency = "TRY",
                statusRaw = BookingStatus.confirmed.rawValue,
                paymentStatusRaw = PaymentStatus.depositPaid.rawValue,
                ticketNumber = "HS-2024-001"
            ),
            Booking(
                id = "admin_booking_2",
                userId = "user2",
                facilityId = "admin_facility_1",
                pitchId = "pitch1",
                facilityName = "Yıldız Spor Tesisleri",
                pitchName = "Saha 1",
                facilityAddress = "Ataşehir, İstanbul",
                facilityPhone = "+902121234567",
                userFullName = "Mehmet Kaya",
                userPhone = "5559876543",
                date = Date(), // Bugün
                startHour = 20,
                endHour = 21,
                totalPrice = 650.0,
                depositAmount = 130.0,
                remainingAmount = 520.0,
                currency = "TRY",
                statusRaw = BookingStatus.pending.rawValue, // Bekleyen örnek
                paymentStatusRaw = PaymentStatus.depositPaid.rawValue,
                ticketNumber = "HS-2024-002"
            ),
            Booking(
                id = "admin_booking_3",
                userId = "user3",
                facilityId = "admin_facility_1",
                pitchId = "pitch2",
                facilityName = "Yıldız Spor Tesisleri",
                pitchName = "Saha 2",
                facilityAddress = "Ataşehir, İstanbul",
                facilityPhone = "+902121234567",
                userFullName = "Ali Demir",
                userPhone = "5554567890",
                date = calendar.apply { add(Calendar.DAY_OF_YEAR, 1) }.time, // Yarın
                startHour = 18,
                endHour = 19,
                totalPrice = 700.0,
                depositAmount = 140.0,
                remainingAmount = 560.0,
                currency = "TRY",
                statusRaw = BookingStatus.confirmed.rawValue,
                paymentStatusRaw = PaymentStatus.depositPaid.rawValue,
                ticketNumber = "HS-2024-003"
            )
        )
    }
    fun loadMockAdminFacilities(): List<Facility> {
        return listOf(
            Facility(
                id = "admin_facility_1",
                ownerId = firebaseService.currentUserId ?: "admin",
                name = "Yıldız Spor Tesisleri",
                description = "Modern tesislerimizde profesyonel sahalarımızla hizmetinizdeyiz.",
                taxNumber = "1234567890",
                phone = "+902121234567",
                address = "Ataşehir, İstanbul",
                latitude = 40.9923,
                longitude = 29.1244,
                images = emptyList(),
                amenities = FacilityAmenities(
                    hasParking = true,
                    hasShower = true,
                    hasLockerRoom = true,
                    hasCafe = true,
                    isIndoor = false,
                    hasLighting = true
                ),
                status = FacilityStatus.approved,
                averageRating = 4.8,
                totalReviews = 256
            )
        )
    }
}

// MARK: - Admin Errors
sealed class AdminError(message: String) : Exception(message) {
    object NotAuthenticated : AdminError("Bu işlem için giriş yapmanız gerekiyor.")
    object NotAuthorized : AdminError("Bu işlem için yetkiniz yok.")
    object InvalidData : AdminError("Geçersiz veri.")
    object FacilityNotFound : AdminError("Tesis bulunamadı.")
    class OperationFailed(message: String) : AdminError(message)
}
