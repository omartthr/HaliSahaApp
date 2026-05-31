package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.Exclude
import java.util.Date

// MARK: - User Model
// Firestore toObject() ile uyumlu: userType ve preferredPosition doğrudan String
// olarak tutulur (Firestore alan adlarıyla birebir eşleşir).
// Enum dönüşümleri @Exclude ile işaretlenmiş computed property'ler ile sağlanır.
data class User(
    @DocumentId
    val id: String? = null,
    val email: String = "",
    val firstName: String = "",
    val lastName: String = "",
    val username: String = "",
    val phone: String = "",
    val profileImageURL: String? = null,
    val preferredPosition: String = "unspecified",
    val userType: String = "player",
    val fcmToken: String? = null,
    val followers: List<String> = emptyList(),
    val following: List<String> = emptyList(),
    val favoriteFields: List<String> = emptyList(),
    val reliabilityScore: Double = 5.0,
    val totalMatches: Int = 0,
    val attendedMatches: Int = 0,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date(),
    val isActive: Boolean = true
) {
    // MARK: - Enum Computed Properties (Firestore tarafından yok sayılır)
    @get:Exclude
    val userTypeEnum: UserType
        get() = UserType.fromString(userType)

    @get:Exclude
    val preferredPositionEnum: PlayerPosition
        get() = PlayerPosition.fromString(preferredPosition)

    @get:Exclude
    val fullName: String
        get() = "$firstName $lastName"

    @get:Exclude
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
            preferredPosition = PlayerPosition.MIDFIELDER.rawValue,
            userType = UserType.PLAYER.rawValue,
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
            userType = UserType.ADMIN.rawValue
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
        fun fromString(value: String) = entries.find { it.rawValue == value } ?: PLAYER
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
        fun fromString(value: String) = entries.find { it.rawValue == value } ?: UNSPECIFIED
    }
}