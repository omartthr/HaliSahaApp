package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import java.util.Date

// MARK: - User Model
data class User(
    @DocumentId
    val id: String? = null,
    val email: String = "",
    val firstName: String = "",
    val lastName: String = "",
    val username: String = "",
    val phone: String = "",
    val profileImageURL: String? = null,
    val preferredPosition: PlayerPosition = PlayerPosition.UNSPECIFIED,
    val userType: UserType = UserType.PLAYER,
    val fcmToken: String? = null,
    val followers: List<String> = emptyList(),          // Takipçi user ID'leri
    val following: List<String> = emptyList(),          // Takip edilen user ID'leri
    val favoriteFields: List<String> = emptyList(),     // Favori saha ID'leri
    val reliabilityScore: Double = 5.0,                 // Güvenilirlik puanı (0-5)
    val totalMatches: Int = 0,                          // Toplam maç sayısı
    val attendedMatches: Int = 0,                       // Katıldığı maç sayısı
    val createdAt: Date = Date(),
    val updatedAt: Date = Date(),
    val isActive: Boolean = true
) {
    // MARK: - Computed Properties (Kotlin Custom Getters)
    val fullName: String
        get() = "$firstName $lastName"

    val attendanceRate: Double
        get() {
            if (totalMatches <= 0) return 100.0
            return (attendedMatches.toDouble() / totalMatches.toDouble()) * 100.0
        }

    // MARK: - Mock Data for Preview
    companion object {
        val mockUser = User(
            id = "user123",
            email = "ahmet@example.com",
            firstName = "Ahmet",
            lastName = "Yılmaz",
            username = "ahmet_10",
            phone = "+905551234567",
            profileImageURL = null,
            preferredPosition = PlayerPosition.MIDFIELDER,
            userType = UserType.PLAYER,
            reliabilityScore = 4.8,
            totalMatches = 25,
            attendedMatches = 24
        )

        val mockAdmin = User(
            id = "admin123",
            email = "admin@sahaspor.com",
            firstName = "Mehmet",
            lastName = "Demir",
            username = "sahaspor_admin",
            phone = "+905559876543",
            userType = UserType.ADMIN
        )
    }
}

// MARK: - User Type Enum
enum class UserType(val rawValue: String, val displayName: String) {
    PLAYER("player", "Oyuncu"),
    ADMIN("admin", "Saha Sahibi"),
    SUPER_ADMIN("superAdmin", "Yönetici"),
    GUEST("guest", "Misafir");

    companion object {
        fun fromString(value: String) = values().find { it.rawValue == value } ?: PLAYER
    }
}

// MARK: - Player Position Enum
enum class PlayerPosition(val rawValue: String, val displayName: String, val icon: String) {
    GOALKEEPER("goalkeeper", "Kaleci", "🧤"),
    DEFENDER("defender", "Defans", "🛡️"),
    MIDFIELDER("midfielder", "Orta Saha", "⚙️"),
    FORWARD("forward", "Forvet", "⚽"),
    UNSPECIFIED("unspecified", "Belirtilmemiş", "👤");

    companion object {
        fun fromString(value: String) = values().find { it.rawValue == value } ?: UNSPECIFIED
    }
}