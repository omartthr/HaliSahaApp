package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import java.util.Date
import java.util.Locale

// MARK: - Pitch Model
data class Pitch(
    @DocumentId
    val id: String? = null,
    val facilityId: String = "",           // Üst tesis ID
    val name: String = "",                 // Saha adı (Örn: "Saha A")
    val description: String? = null,
    val pitchType: PitchType = PitchType.OUTDOOR,
    val surfaceType: SurfaceType = SurfaceType.SYNTHETIC_GRASS,
    val size: PitchSize = PitchSize.FIVE_A_SIDE,
    val capacity: Int = 14,
    val images: List<String> = emptyList(),
    val pricing: PitchPricing = PitchPricing(),
    val isActive: Boolean = true,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
) {
    companion object {
        val mockPitch = Pitch(
            id = "pitch123",
            facilityId = "facility123",
            name = "Saha A",
            description = "Profesyonel aydınlatma sistemli ana saha",
            pitchType = PitchType.OUTDOOR,
            surfaceType = SurfaceType.SYNTHETIC_GRASS,
            size = PitchSize.SEVEN_A_SIDE,
            capacity = 14,
            pricing = PitchPricing(
                daytimePrice = 600.0,
                eveningPrice = 800.0,
                weekendMultiplier = 1.2
            )
        )

        val mockPitches = listOf(
            mockPitch,
            Pitch(
                id = "pitch456",
                facilityId = "facility123",
                name = "Saha B",
                pitchType = PitchType.INDOOR,
                surfaceType = SurfaceType.SYNTHETIC_GRASS,
                size = PitchSize.FIVE_A_SIDE,
                capacity = 10,
                pricing = PitchPricing(
                    daytimePrice = 500.0,
                    eveningPrice = 700.0
                )
            )
        )
    }
}

// MARK: - Pitch Type Enum
enum class PitchType(val rawValue: String, val displayName: String, val icon: String) {
    @com.google.firebase.firestore.PropertyName("indoor") INDOOR("indoor", "Kapalı", "home_work"),      // house.fill karşılığı
    @com.google.firebase.firestore.PropertyName("outdoor") OUTDOOR("outdoor", "Açık", "wb_sunny"),       // sun.max.fill karşılığı
    @com.google.firebase.firestore.PropertyName("covered") COVERED("covered", "Yarı Kapalı", "umbrella"); // umbrella.fill karşılığı
}

// MARK: - Surface Type Enum
enum class SurfaceType(val rawValue: String, val displayName: String) {
    @com.google.firebase.firestore.PropertyName("syntheticGrass") SYNTHETIC_GRASS("syntheticGrass", "Sentetik Çim"),
    @com.google.firebase.firestore.PropertyName("naturalGrass") NATURAL_GRASS("naturalGrass", "Doğal Çim"),
    @com.google.firebase.firestore.PropertyName("hybrid") HYBRID("hybrid", "Hibrit"),
    @com.google.firebase.firestore.PropertyName("artificial") ARTIFICIAL("artificial", "Yapay Zemin");
}

// MARK: - Pitch Size Enum
enum class PitchSize(val rawValue: String, val displayName: String, val playerCount: Int, val dimensions: String) {
    @com.google.firebase.firestore.PropertyName("5v5") FIVE_A_SIDE("5v5", "5v5 (10 Kişilik)", 10, "25x15m"),
    @com.google.firebase.firestore.PropertyName("6v6") SIX_A_SIDE("6v6", "6v6 (12 Kişilik)", 12, "35x20m"),
    @com.google.firebase.firestore.PropertyName("7v7") SEVEN_A_SIDE("7v7", "7v7 (14 Kişilik)", 14, "50x30m"),
    @com.google.firebase.firestore.PropertyName("8v8") EIGHT_A_SIDE("8v8", "8v8 (16 Kişilik)", 16, "60x40m");
}

// MARK: - Pitch Pricing
data class PitchPricing(
    val daytimePrice: Double = 500.0,
    val eveningPrice: Double = 700.0,
    val weekendMultiplier: Double = 1.0,
    val depositPercentage: Double = 0.2,
    val currency: String = "TRY"
) {
    fun calculatePrice(startHour: Int, duration: Int, isWeekend: Boolean): Double {
        // 18:00 ve sonrası akşam tarifesi, öncesi gündüz tarifesi
        val basePrice = if (startHour >= 18) eveningPrice else daytimePrice

        // Hafta sonu çarpanını uygula
        val hourlyPrice = if (isWeekend) basePrice * weekendMultiplier else basePrice

        // Toplam süreyi çarp
        return hourlyPrice * duration.toDouble()
    }

    fun calculateDeposit(totalPrice: Double): Double = totalPrice * depositPercentage

    // Swift'teki computed property'lerin karşılığı
    val formattedDaytimePrice: String
        get() = "${daytimePrice.toInt()} ₺/saat"

    val formattedEveningPrice: String
        get() = "${eveningPrice.toInt()} ₺/saat"
}

// MARK: - Time Slot
data class TimeSlot(
    val date: Date,
    val hour: Int,
    val isAvailable: Boolean = true,
    val bookingId: String? = null,
    val isManuallyBlocked: Boolean = false,
    val price: Double = 0.0
) {
    // Swift'teki 'id' computed property karşılığı
    val id: String
        get() = "${date.time}-$hour"

    val timeString: String
        get() = String.format(Locale.getDefault(), "%02d:00 - %02d:00", hour, hour + 1)
}