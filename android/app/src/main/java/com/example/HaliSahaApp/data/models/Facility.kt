package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import java.util.Date
import java.util.Locale

// MARK: - Facility Model
data class Facility(
    @DocumentId
    val id: String? = null,
    val ownerId: String = "",              // Admin (saha sahibi) user ID
    val name: String = "",                 // İşletme adı
    val description: String = "",
    val taxNumber: String = "",            // Vergi numarası
    val phone: String = "",
    val email: String? = null,
    val address: String = "",
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val images: List<String> = emptyList(),             // Fotoğraf URL'leri
    val amenities: FacilityAmenities = FacilityAmenities(), // Özellikler
    val operatingHours: OperatingHours = OperatingHours(),
    val status: FacilityStatus = FacilityStatus.PENDING,
    val averageRating: Double = 0.0,
    val totalReviews: Int = 0,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date(),
    val isActive: Boolean = true
) {
    // MARK: - Computed Properties
    // Not: LatLng sınıfı için Google Maps bağımlılığı gerekir.
    // UI katmanında ihtiyaç duyduğunda MapView için dönüştürebilirsin.

    val mainImage: String?
        get() = images.firstOrNull()

    val formattedRating: String
        get() = String.format(Locale.US, "%.1f", averageRating)

    // MARK: - Mock Data
    companion object {
        val mockFacility = Facility(
            id = "facility123",
            ownerId = "admin123",
            name = "Yıldız Spor Tesisleri",
            description = "İstanbul'un en modern halı saha kompleksi. 4 adet profesyonel saha ile hizmetinizdeyiz.",
            taxNumber = "1234567890",
            phone = "+902121234567",
            email = "info@yildizsport.com",
            address = "Ataşehir, İstanbul",
            latitude = 40.9923,
            longitude = 29.1244,
            images = listOf("facility1.jpg", "facility2.jpg"),
            amenities = FacilityAmenities(
                hasParking = true,
                hasShower = true,
                hasLockerRoom = true,
                hasCafe = true,
                hasLighting = true
            ),
            status = FacilityStatus.APPROVED,
            averageRating = 4.5,
            totalReviews = 128
        )
    }
}

// MARK: - Facility Status
enum class FacilityStatus(val rawValue: String, val displayName: String, val color: String) {
    PENDING("pending", "Onay Bekliyor", "orange"),
    APPROVED("approved", "Aktif", "green"),
    REJECTED("rejected", "Reddedildi", "red"),
    SUSPENDED("suspended", "Askıya Alındı", "gray");
}

// MARK: - Facility Amenities (Özellikler)
data class FacilityAmenities(
    val hasParking: Boolean = false,
    val hasShuttleService: Boolean = false,
    val hasShower: Boolean = false,
    val hasLockerRoom: Boolean = false,
    val hasEquipmentRental: Boolean = false,
    val hasCafe: Boolean = false,
    val hasVideoRecording: Boolean = false,
    val isIndoor: Boolean = false,
    val hasLighting: Boolean = true,
    val hasHeating: Boolean = false,
    val hasFirstAid: Boolean = false,
    val hasWifi: Boolean = false
) {
    // Aktif özelliklerin listesi (Icon ve İsim olarak)
    fun getActiveAmenities(): List<Pair<String, String>> {
        val list = mutableListOf<Pair<String, String>>()
        if (hasParking) list.add("🅿️" to "Otopark")
        if (hasShuttleService) list.add("🚐" to "Servis")
        if (hasShower) list.add("🚿" to "Duş")
        if (hasLockerRoom) list.add("🚪" to "Soyunma Odası")
        if (hasEquipmentRental) list.add("👟" to "Ekipman Kiralama")
        if (hasCafe) list.add("☕" to "Kafe")
        if (hasVideoRecording) list.add("📹" to "Video Kaydı")
        if (isIndoor) list.add("🏠" to "Kapalı Alan")
        if (hasLighting) list.add("💡" to "Aydınlatma")
        if (hasHeating) list.add("🔥" to "Isıtma")
        if (hasFirstAid) list.add("🩹" to "İlk Yardım")
        if (hasWifi) list.add("📶" to "Wi-Fi")
        return list
    }
}

// MARK: - Operating Hours (Çalışma Saatleri)
data class OperatingHours(
    val mondayOpen: String = "09:00", val mondayClose: String = "23:00",
    val tuesdayOpen: String = "09:00", val tuesdayClose: String = "23:00",
    val wednesdayOpen: String = "09:00", val wednesdayClose: String = "23:00",
    val thursdayOpen: String = "09:00", val thursdayClose: String = "23:00",
    val fridayOpen: String = "09:00", val fridayClose: String = "23:00",
    val saturdayOpen: String = "09:00", val saturdayClose: String = "23:00",
    val sundayOpen: String = "09:00", val sundayClose: String = "23:00"
) {
    // Swift'teki day logic (1: Sunday, 2: Monday...) uyumluluğu için
    fun hoursForDay(day: Int): Pair<String, String> {
        return when (day) {
            1 -> sundayOpen to sundayClose
            2 -> mondayOpen to mondayClose
            3 -> tuesdayOpen to tuesdayClose
            4 -> wednesdayOpen to wednesdayClose
            5 -> thursdayOpen to thursdayClose
            6 -> fridayOpen to fridayClose
            7 -> saturdayOpen to saturdayClose
            else -> mondayOpen to mondayClose
        }
    }
}