package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import java.text.SimpleDateFormat
import java.util.*

// MARK: - MatchPost Model
data class MatchPost(
    @DocumentId
    val id: String? = null,
    val creatorId: String = "",
    val creatorName: String = "",
    val creatorProfileImage: String? = null,
    val groupId: String? = null,
    val bookingId: String = "",

    // Maç bilgileri (denormalize)
    val facilityId: String = "",
    val facilityName: String = "",
    val facilityAddress: String = "",
    val pitchName: String = "",
    val matchDate: Date = Date(),
    val startHour: Int = 0,
    val endHour: Int = 0,

    // İlan detayları
    val title: String = "",
    val description: String? = null,
    val neededPlayers: Int = 0,
    val currentPlayers: Int = 0,
    val maxPlayers: Int = 0,
    val preferredPositions: List<PlayerPosition> = emptyList(),
    val skillLevel: SkillLevel = SkillLevel.ANY,
    val ageRange: AgeRange? = null,
    val costPerPlayer: Double? = null,

    // Başvurular
    val applicantIds: List<String> = emptyList(),
    val acceptedIds: List<String> = emptyList(),
    val rejectedIds: List<String> = emptyList(),

    // Durum
    val status: MatchPostStatus = MatchPostStatus.ACTIVE,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date(),
    val expiresAt: Date = Date()
) {
    // MARK: - Computed Properties
    val availableSlots: Int get() = neededPlayers - acceptedIds.size
    val isFull: Boolean get() = availableSlots <= 0
    val isExpired: Boolean get() = Date().after(expiresAt)

    val formattedDate: String
        get() = SimpleDateFormat("d MMMM, EEEE", Locale("tr", "TR")).format(matchDate)

    val timeSlot: String
        get() = String.format(Locale.getDefault(), "%02d:00 - %02d:00", startHour, endHour)

    val formattedCostPerPlayer: String?
        get() = costPerPlayer?.let { "${it.toInt()} ₺/kişi" }

    val pendingApplicationsCount: Int
        get() = applicantIds.count { it !in acceptedIds && it !in rejectedIds }

    // MARK: - Helper Methods
    fun canApply(userId: String): Boolean {
        if (status != MatchPostStatus.ACTIVE || isExpired || isFull) return false
        return userId !in applicantIds && userId !in acceptedIds && userId != creatorId
    }

    fun hasApplied(userId: String): Boolean = userId in applicantIds
    fun isAccepted(userId: String): Boolean = userId in acceptedIds
    fun isRejected(userId: String): Boolean = userId in rejectedIds

    companion object {
        // Swift'teki custom init mantığını factory method olarak kuruyoruz
        fun create(
            creatorId: String, creatorName: String, bookingId: String,
            facilityId: String, facilityName: String, facilityAddress: String,
            pitchName: String, matchDate: Date, startHour: Int, endHour: Int,
            title: String, neededPlayers: Int, currentPlayers: Int, maxPlayers: Int
        ): MatchPost {
            val calendar = Calendar.getInstance()
            calendar.time = matchDate
            calendar.set(Calendar.HOUR_OF_DAY, startHour)
            calendar.set(Calendar.MINUTE, 0)

            return MatchPost(
                creatorId = creatorId, creatorName = creatorName, bookingId = bookingId,
                facilityId = facilityId, facilityName = facilityName, facilityAddress = facilityAddress,
                pitchName = pitchName, matchDate = matchDate, startHour = startHour, endHour = endHour,
                title = title, neededPlayers = neededPlayers, currentPlayers = currentPlayers,
                maxPlayers = maxPlayers, expiresAt = calendar.time
            )
        }

        val mockPost = MatchPost(
            id = "post123",
            creatorId = "user123",
            creatorName = "Ahmet Yılmaz",
            bookingId = "booking123",
            facilityId = "facility123",
            facilityName = "Yıldız Spor Tesisleri",
            facilityAddress = "Ataşehir, İstanbul",
            pitchName = "Saha A",
            matchDate = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 3) }.time,
            startHour = 20,
            endHour = 21,
            title = "Cumartesi Akşamı Maça 4 Kişi Aranıyor",
            description = "Dostluk maçı yapıyoruz, eğlenceli bir ortam.",
            neededPlayers = 4,
            currentPlayers = 10,
            maxPlayers = 14,
            preferredPositions = listOf(PlayerPosition.DEFENDER, PlayerPosition.MIDFIELDER),
            skillLevel = SkillLevel.INTERMEDIATE,
            costPerPlayer = 100.0
        )
    }
}

// MARK: - Enums & Secondary Models

enum class MatchPostStatus(val rawValue: String, val displayName: String, val color: String) {
    ACTIVE("active", "Aktif", "green"),
    FULL("full", "Kadro Tamamlandı", "blue"),
    COMPLETED("completed", "Tamamlandı", "gray"),
    CANCELLED("cancelled", "İptal Edildi", "red"),
    EXPIRED("expired", "Süresi Doldu", "gray");
}

enum class SkillLevel(val rawValue: String, val displayName: String, val icon: String) {
    BEGINNER("beginner", "Başlangıç", "⭐"),
    INTERMEDIATE("intermediate", "Orta Seviye", "⭐⭐"),
    ADVANCED("advanced", "İleri Seviye", "⭐⭐⭐"),
    PROFESSIONAL("professional", "Profesyonel", "🏆"),
    ANY("any", "Farketmez", "🎯");
}

data class AgeRange(
    val minAge: Int = 18,
    val maxAge: Int = 65
) {
    val displayName: String get() = "$minAge - $maxAge yaş"

    companion object {
        val young = AgeRange(18, 25)
        val adult = AgeRange(25, 35)
        val senior = AgeRange(35, 50)
        val any = AgeRange(18, 65)
    }
}

data class MatchPostApplication(
    @DocumentId
    val id: String? = null,
    val postId: String = "",
    val userId: String = "",
    val userName: String = "",
    val userProfileImage: String? = null,
    val userPosition: PlayerPosition = PlayerPosition.UNSPECIFIED,
    val userReliabilityScore: Double = 5.0,
    val message: String? = null,
    val status: ApplicationStatus = ApplicationStatus.PENDING,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
)

enum class ApplicationStatus(val rawValue: String, val displayName: String) {
    PENDING("pending", "Bekliyor"),
    ACCEPTED("accepted", "Kabul Edildi"),
    REJECTED("rejected", "Reddedildi"),
    WITHDRAWN("withdrawn", "Geri Çekildi");
}