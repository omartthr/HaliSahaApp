package com.example.HaliSahaApp.data.models

import android.text.format.DateUtils
import com.google.firebase.firestore.DocumentId
import java.text.SimpleDateFormat
import java.util.*

// MARK: - Message Model
data class Message(
    @DocumentId
    val id: String? = null,
    val groupId: String = "",              // Üst grup ID
    val senderId: String = "",             // Gönderen kullanıcı ID
    val senderName: String = "",           // Gönderen adı (denormalize)
    val senderProfileImage: String? = null,  // Profil fotoğrafı URL
    val content: String = "",              // Mesaj içeriği
    val messageType: MessageType = MessageType.TEXT,
    val imageURL: String? = null,            // Fotoğraf mesajı için
    val matchInviteData: MatchInviteData? = null, // Maç daveti için
    val replyToMessageId: String? = null,    // Yanıtlanan mesaj ID
    val readBy: List<String> = emptyList(),             // Okuyan kullanıcı ID'leri
    val isEdited: Boolean = false,
    val isDeleted: Boolean = false,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
) {
    // MARK: - Computed Properties
    val isRead: Boolean get() = readBy.isNotEmpty()

    val formattedTime: String
        get() = SimpleDateFormat("HH:mm", Locale("tr", "TR")).format(createdAt)

    val formattedDate: String
        get() {
            return when {
                DateUtils.isToday(createdAt.time) -> "Bugün"
                isYesterday(createdAt) -> "Dün"
                else -> SimpleDateFormat("d MMMM", Locale("tr", "TR")).format(createdAt)
            }
        }

    // MARK: - Helper Methods
    private fun isYesterday(date: Date): Boolean {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        val yesterday = calendar.time

        val fmt = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
        return fmt.format(date) == fmt.format(yesterday)
    }

    // MARK: - Factory Methods
    companion object {
        fun textMessage(groupId: String, senderId: String, senderName: String, content: String) =
            Message(
                groupId = groupId,
                senderId = senderId,
                senderName = senderName,
                content = content,
                messageType = MessageType.TEXT
            )

        fun systemMessage(groupId: String, content: String) =
            Message(
                groupId = groupId,
                senderId = "system",
                senderName = "Sistem",
                content = content,
                messageType = MessageType.SYSTEM
            )

        fun matchInvite(groupId: String, senderId: String, senderName: String, inviteData: MatchInviteData) =
            Message(
                groupId = groupId,
                senderId = senderId,
                senderName = senderName,
                content = "Maç daveti gönderdi",
                messageType = MessageType.MATCH_INVITE,
                matchInviteData = inviteData
            )

        // Mock Data
        val mockMessages = listOf(
            Message(
                id = "msg1",
                groupId = "group123",
                senderId = "user123",
                senderName = "Ahmet",
                content = "Merhaba arkadaşlar, bu hafta maç var mı?",
                createdAt = Date(System.currentTimeMillis() - 7200000)
            ),
            Message(
                id = "msg3",
                groupId = "group123",
                senderId = "user456",
                senderName = "Mehmet",
                messageType = MessageType.MATCH_INVITE,
                matchInviteData = MatchInviteData(
                    bookingId = "booking123",
                    facilityName = "Yıldız Spor",
                    pitchName = "Saha A",
                    matchDate = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 3) }.time,
                    startHour = 20,
                    endHour = 21,
                    currentPlayers = 8,
                    maxPlayers = 14,
                    status = MatchInviteStatus.PENDING
                )
            )
        )
    }
}

// MARK: - Match Invite Data
data class MatchInviteData(
    val bookingId: String = "",
    val facilityName: String = "",
    val pitchName: String = "",
    val matchDate: Date = Date(),
    val startHour: Int = 0,
    val endHour: Int = 0,
    val currentPlayers: Int = 0,
    val maxPlayers: Int = 0,
    val status: MatchInviteStatus = MatchInviteStatus.PENDING
) {
    val formattedDate: String
        get() = SimpleDateFormat("d MMMM, EEEE", Locale("tr", "TR")).format(matchDate)

    val timeSlot: String
        get() = String.format(Locale.getDefault(), "%02d:00 - %02d:00", startHour, endHour)

    val availableSlots: Int get() = (maxPlayers - currentPlayers).coerceAtLeast(0)
    val isFull: Boolean get() = currentPlayers >= maxPlayers
}

// MARK: - Match Invite Status Enum
enum class MatchInviteStatus(val rawValue: String, val displayName: String, val color: String) {
    PENDING("pending", "Bekliyor", "orange"),
    ACCEPTED("accepted", "Kabul Edildi", "green"),
    DECLINED("declined", "Reddedildi", "red"),
    EXPIRED("expired", "Süresi Doldu", "gray"),
    CANCELLED("cancelled", "İptal Edildi", "gray");
}