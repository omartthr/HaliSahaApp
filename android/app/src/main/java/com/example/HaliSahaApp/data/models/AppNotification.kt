package com.example.HaliSahaApp.data.models

import android.text.format.DateUtils
import com.google.firebase.firestore.DocumentId
import java.text.SimpleDateFormat
import java.util.*

// MARK: - AppNotification Model
data class AppNotification(
    @DocumentId
    val id: String? = null,
    val userId: String = "",               // Bildirimin gönderildiği kullanıcı
    val title: String = "",
    val body: String = "",
    val type: NotificationType = NotificationType.SYSTEM,
    val data: NotificationData? = null,      // Ek veriler (navigasyon için)
    val isRead: Boolean = false,
    val createdAt: Date = Date()
) {
    // MARK: - Computed Properties
    val icon: String get() = type.icon
    val color: String get() = type.color

    val relativeTime: String
        get() = DateUtils.getRelativeTimeSpanString(
            createdAt.time,
            System.currentTimeMillis(),
            DateUtils.MINUTE_IN_MILLIS,
            DateUtils.FORMAT_ABBREV_RELATIVE
        ).toString()

    val formattedDate: String
        get() {
            return when {
                DateUtils.isToday(createdAt.time) -> {
                    SimpleDateFormat("'Bugün' HH:mm", Locale("tr", "TR")).format(createdAt)
                }
                isYesterday(createdAt) -> {
                    SimpleDateFormat("'Dün' HH:mm", Locale("tr", "TR")).format(createdAt)
                }
                else -> {
                    SimpleDateFormat("d MMM, HH:mm", Locale("tr", "TR")).format(createdAt)
                }
            }
        }

    private fun isYesterday(date: Date): Boolean {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        val yesterday = calendar.time
        val fmt = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
        return fmt.format(date) == fmt.format(yesterday)
    }

    // MARK: - Factory Methods
    companion object {
        fun bookingConfirmed(userId: String, booking: Booking) = AppNotification(
            userId = userId,
            title = "Rezervasyon Onaylandı ✅",
            body = "${booking.facilityName} - ${booking.pitchName} için ${booking.formattedDate} tarihli rezervasyonunuz onaylandı.",
            type = NotificationType.BOOKING_CONFIRMED,
            data = NotificationData(bookingId = booking.id, facilityId = booking.facilityId)
        )

        fun bookingReminder(userId: String, booking: Booking, hoursLeft: Int) = AppNotification(
            userId = userId,
            title = "Maç Hatırlatması ⚽",
            body = "${booking.facilityName} - ${booking.pitchName}'da maçınıza $hoursLeft saat kaldı!",
            type = NotificationType.BOOKING_REMINDER,
            data = NotificationData(bookingId = booking.id, facilityId = booking.facilityId)
        )

        fun matchInvite(userId: String, senderName: String, groupId: String, bookingId: String) = AppNotification(
            userId = userId,
            title = "Maç Daveti 🎯",
            body = "$senderName sizi bir maça davet etti.",
            type = NotificationType.MATCH_INVITE,
            data = NotificationData(groupId = groupId, bookingId = bookingId)
        )

        fun joinRequestReceived(userId: String, applicantName: String, postId: String) = AppNotification(
            userId = userId,
            title = "Katılma İsteği 🙋",
            body = "$applicantName maçınıza katılmak istiyor.",
            type = NotificationType.JOIN_REQUEST,
            data = NotificationData(matchPostId = postId)
        )

        fun joinRequestAccepted(userId: String, facilityName: String, groupId: String) = AppNotification(
            userId = userId,
            title = "İstek Kabul Edildi 🎉",
            body = "$facilityName'daki maça katılma isteğiniz kabul edildi!",
            type = NotificationType.JOIN_REQUEST_ACCEPTED,
            data = NotificationData(groupId = groupId)
        )

        fun newMessage(userId: String, senderName: String, groupId: String, groupName: String) = AppNotification(
            userId = userId,
            title = groupName,
            body = "$senderName bir mesaj gönderdi.",
            type = NotificationType.NEW_MESSAGE,
            data = NotificationData(groupId = groupId)
        )

        fun newFollower(userId: String, followerName: String, followerId: String) = AppNotification(
            userId = userId,
            title = "Yeni Takipçi 👤",
            body = "$followerName sizi takip etmeye başladı.",
            type = NotificationType.NEW_FOLLOWER,
            data = NotificationData(userId = followerId)
        )
    }
}

// MARK: - Notification Type Enum
enum class NotificationType(val rawValue: String, val icon: String, val color: String) {
    BOOKING_CONFIRMED("bookingConfirmed", "check_circle", "green"),
    BOOKING_CANCELLED("bookingCancelled", "cancel", "red"),
    BOOKING_REMINDER("bookingReminder", "notifications_active", "orange"),
    MATCH_INVITE("matchInvite", "sports_soccer", "blue"),
    JOIN_REQUEST("joinRequest", "person_add", "blue"),
    JOIN_REQUEST_ACCEPTED("joinRequestAccepted", "verified", "green"),
    JOIN_REQUEST_REJECTED("joinRequestRejected", "block", "red"),
    NEW_MESSAGE("newMessage", "chat", "purple"),
    NEW_FOLLOWER("newFollower", "person_add_alt", "pink"),
    FACILITY_APPROVED("facilityApproved", "business", "green"),
    FACILITY_REJECTED("facilityRejected", "domain_disabled", "red"),
    REVIEW_RECEIVED("reviewReceived", "grade", "yellow"),
    PROMOTIONAL("promotional", "redeem", "indigo"),
    SYSTEM("system", "notifications", "gray");

    val category: NotificationCategory
        get() = when (this) {
            BOOKING_CONFIRMED, BOOKING_CANCELLED, BOOKING_REMINDER -> NotificationCategory.BOOKING
            MATCH_INVITE, JOIN_REQUEST, JOIN_REQUEST_ACCEPTED, JOIN_REQUEST_REJECTED, NEW_MESSAGE, NEW_FOLLOWER -> NotificationCategory.SOCIAL
            else -> NotificationCategory.SYSTEM
        }
}

// MARK: - Notification Category Enum
enum class NotificationCategory(val rawValue: String, val displayName: String) {
    BOOKING("booking", "Rezervasyonlar"),
    SOCIAL("social", "Sosyal"),
    SYSTEM("system", "Sistem");
}

// MARK: - Notification Data
data class NotificationData(
    val bookingId: String? = null,
    val facilityId: String? = null,
    val pitchId: String? = null,
    val groupId: String? = null,
    val matchPostId: String? = null,
    val userId: String? = null,
    val reviewId: String? = null
)