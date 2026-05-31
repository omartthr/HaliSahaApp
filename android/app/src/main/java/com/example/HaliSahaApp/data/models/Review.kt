package com.example.HaliSahaApp.data.models
import android.text.format.DateUtils
import com.google.firebase.firestore.DocumentId
import java.text.SimpleDateFormat
import java.util.*

// MARK: - Review Model
data class Review(
    @DocumentId
    val id: String? = null,
    val facilityId: String = "",           // Değerlendirilen tesis
    val pitchId: String? = null,             // Değerlendirilen saha (opsiyonel)
    val bookingId: String = "",            // İlişkili rezervasyon
    val userId: String = "",               // Değerlendiren kullanıcı
    val userName: String = "",             // Kullanıcı adı (denormalize)
    val userProfileImage: String? = null,

    // Puanlar (1-5 arası)
    val overallRating: Double = 0.0,        // Genel puan
    val cleanlinessRating: Double = 0.0,    // Temizlik
    val surfaceRating: Double = 0.0,        // Zemin kalitesi
    val serviceRating: Double = 0.0,        // Hizmet kalitesi
    val facilitiesRating: Double = 0.0,     // Tesis olanakları
    val valueForMoneyRating: Double = 0.0,  // Fiyat/performans

    // Yorum
    val comment: String? = null,
    val images: List<String> = emptyList(),             // Yorum fotoğrafları

    // Admin yanıtı
    val adminReply: String? = null,
    val adminReplyDate: Date? = null,

    // Meta
    val isVerified: Boolean = true,             // Gerçek rezervasyon sonrası mı?
    val helpfulCount: Int = 0,            // Faydalı bulan sayısı
    val reportCount: Int = 0,            // Şikayet sayısı
    val isHidden: Boolean = false,               // Gizlendi mi?
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
) {
    // MARK: - Computed Properties
    val averageRating: Double
        get() {
            val ratings = listOf(cleanlinessRating, surfaceRating, serviceRating, facilitiesRating, valueForMoneyRating)
            return ratings.average()
        }

    val formattedDate: String
        get() = SimpleDateFormat("d MMMM yyyy", Locale("tr", "TR")).format(createdAt)

    val relativeDate: String
        get() = DateUtils.getRelativeTimeSpanString(
            createdAt.time,
            System.currentTimeMillis(),
            DateUtils.MINUTE_IN_MILLIS
        ).toString()

    // Yıldızları karakter olarak döndüren mantık
    val ratingStars: String
        get() {
            val fullStarsCount = overallRating.toInt()
            val hasHalfStar = (overallRating - fullStarsCount) >= 0.5
            var stars = "★".repeat(fullStarsCount)
            if (hasHalfStar) stars += "½"
            val emptyStarsCount = (5 - fullStarsCount - (if (hasHalfStar) 1 else 0)).coerceAtLeast(0)
            stars += "☆".repeat(emptyStarsCount)
            return stars
        }

    companion object {
        val mockReview = Review(
            id = "review123",
            facilityId = "facility123",
            pitchId = "pitch123",
            bookingId = "booking456",
            userId = "user123",
            userName = "Ahmet Yılmaz",
            overallRating = 4.5,
            cleanlinessRating = 5.0,
            surfaceRating = 4.0,
            serviceRating = 4.5,
            facilitiesRating = 4.5,
            valueForMoneyRating = 4.0,
            comment = "Harika bir tesis! Zemin kalitesi çok iyi, personel ilgili. Tek eksik otopark biraz küçük.",
            isVerified = true,
            helpfulCount = 12
        )
    }
}

// MARK: - User Reliability Review (Saha sahibinin oyuncuya verdiği puan)
data class UserReliabilityReview(
    @DocumentId
    val id: String? = null,
    val reviewedUserId: String = "",
    val reviewerId: String = "",
    val bookingId: String = "",
    val facilityId: String = "",
    val attended: Boolean = false,
    val wasOnTime: Boolean = true,
    val behaviorRating: Double = 5.0,
    val comment: String? = null,
    val createdAt: Date = Date()
)

// MARK: - Review Summary (İstatistikler)
data class ReviewSummary(
    val totalReviews: Int = 0,
    val averageOverall: Double = 0.0,
    val averageCleanliness: Double = 0.0,
    val averageSurface: Double = 0.0,
    val averageService: Double = 0.0,
    val averageFacilities: Double = 0.0,
    val averageValueForMoney: Double = 0.0,
    val fiveStarCount: Int = 0,
    val fourStarCount: Int = 0,
    val threeStarCount: Int = 0,
    val twoStarCount: Int = 0,
    val oneStarCount: Int = 0
) {
    val formattedAverage: String
        get() = String.format(Locale.US, "%.1f", averageOverall)

    fun getPercentage(stars: Int): Double {
        if (totalReviews == 0) return 0.0
        val count = when (stars) {
            5 -> fiveStarCount
            4 -> fourStarCount
            3 -> threeStarCount
            2 -> twoStarCount
            1 -> oneStarCount
            else -> 0
        }
        return (count.toDouble() / totalReviews.toDouble()) * 100.0
    }
}

// MARK: - Rating Category
enum class RatingCategory(val rawValue: String, val displayName: String, val icon: String) {
    CLEANLINESS("cleanliness", "Temizlik", "auto_awesome"), // sparkles
    SURFACE("surface", "Zemin Kalitesi", "grass"),          // leaf.fill
    SERVICE("service", "Hizmet", "person"),                // person.fill
    FACILITIES("facilities", "Tesisler", "apartment"),     // building.2.fill
    VALUE_FOR_MONEY("valueForMoney", "Fiyat/Performans", "payments"); // lirasign
}