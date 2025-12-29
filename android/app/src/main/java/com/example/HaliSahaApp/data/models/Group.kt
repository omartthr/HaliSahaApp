package com.example.HaliSahaApp.data.models

import android.text.format.DateUtils
import com.google.firebase.firestore.DocumentId
import java.util.*

// MARK: - Group Model
data class Group(
    @DocumentId
    val id: String? = null,
    val name: String = "",
    val description: String? = null,
    val imageURL: String? = null,
    val creatorId: String = "",
    val adminIds: List<String> = emptyList(),
    val memberIds: List<String> = emptyList(),
    val maxMembers: Int = 20,
    val isPublic: Boolean = false,
    val groupType: GroupType = GroupType.TEAM,
    val linkedBookingId: String? = null,
    val lastMessage: LastMessagePreview? = null,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date(),
    val isActive: Boolean = true
) {
    // MARK: - Computed Properties
    val memberCount: Int get() = memberIds.size
    val isFull: Boolean get() = memberCount >= maxMembers
    val availableSlots: Int get() = (maxMembers - memberCount).coerceAtLeast(0)

    // MARK: - Helper Methods
    fun isAdmin(userId: String): Boolean = adminIds.contains(userId)
    fun isCreator(userId: String): Boolean = creatorId == userId
    fun isMember(userId: String): Boolean = memberIds.contains(userId)
    fun canJoin(userId: String): Boolean = !isMember(userId) && !isFull && isActive

    companion object {
        val mockGroup = Group(
            id = "group123",
            name = "Perşembe Akşamı Futbol",
            description = "Her perşembe akşamı düzenli maç yapan arkadaş grubu",
            creatorId = "user123",
            adminIds = listOf("user123"),
            memberIds = listOf("user123", "user456", "user789"),
            maxMembers = 14,
            isPublic = false,
            groupType = GroupType.TEAM,
            lastMessage = LastMessagePreview(
                senderId = "user456",
                senderName = "Mehmet",
                content = "Bu hafta gelecek misiniz?",
                timestamp = Date(System.currentTimeMillis() - 3600000),
                messageType = MessageType.TEXT
            )
        )
    }
}

// MARK: - Group Type
enum class GroupType(val rawValue: String, val displayName: String, val icon: String) {
    TEAM("team", "Takım", "groups"),
    MATCH_GROUP("match", "Maç Grubu", "sports_soccer"),
    PRIVATE_CHAT("private", "Özel Grup", "lock");
}

// MARK: - Last Message Preview
data class LastMessagePreview(
    val senderId: String = "",
    val senderName: String = "",
    val content: String = "",
    val timestamp: Date = Date(),
    val messageType: MessageType = MessageType.TEXT
) {
    val previewText: String
        get() = when (messageType) {
            MessageType.TEXT -> if (content.length > 50) content.take(50) + "..." else content
            MessageType.IMAGE -> "📷 Fotoğraf"
            MessageType.MATCH_INVITE -> "⚽ Maç Daveti"
            MessageType.JOIN_REQUEST -> "🙋 Katılma İsteği"
            MessageType.SYSTEM -> content
        }

    // Swift'teki RelativeDateTimeFormatter karşılığı
    val timeAgo: String
        get() = DateUtils.getRelativeTimeSpanString(
            timestamp.time,
            System.currentTimeMillis(),
            DateUtils.MINUTE_IN_MILLIS
        ).toString()
}

// MARK: - Message Type (Swift kodunda implicit idi, burada tanımlıyoruz)
enum class MessageType(val rawValue: String) {
    TEXT("text"),
    IMAGE("image"),
    MATCH_INVITE("matchInvite"),
    JOIN_REQUEST("joinRequest"),
    SYSTEM("system");
}

// MARK: - Group Member
data class GroupMember(
    val oderId: String = UUID.randomUUID().toString(), // Swift'teki "oderId"
    val userId: String = "",
    val userName: String = "",
    val userProfileImage: String? = null,
    val role: GroupMemberRole = GroupMemberRole.MEMBER,
    val joinedAt: Date = Date(),
    val invitedBy: String? = null
) {
    val id: String get() = oderId
}

// MARK: - Group Member Role
enum class GroupMemberRole(val rawValue: String, val displayName: String) {
    CREATOR("creator", "Kurucu"),
    ADMIN("admin", "Yönetici"),
    MEMBER("member", "Üye");

    val canInvite: Boolean get() = this == CREATOR || this == ADMIN
    val canRemoveMember: Boolean get() = this == CREATOR || this == ADMIN
    val canEditGroup: Boolean get() = this == CREATOR || this == ADMIN
}