//
//  AppNotification.swift
//  HaliSahaApp
//
//  Uygulama içi bildirim veri modeli
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import Foundation
import FirebaseFirestore

// MARK: - AppNotification Model
struct AppNotification: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var userId: String               // Bildirimin gönderildiği kullanıcı
    var title: String
    var body: String
    var type: NotificationType
    var data: NotificationData?      // Ek veriler (navigasyon için)
    var isRead: Bool
    var createdAt: Date
    
    // MARK: - Computed Properties
    var icon: String {
        type.icon
    }
    
    var color: String {
        type.color
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        if Calendar.current.isDateInToday(createdAt) {
            formatter.dateFormat = "'Bugün' HH:mm"
        } else if Calendar.current.isDateInYesterday(createdAt) {
            formatter.dateFormat = "'Dün' HH:mm"
        } else {
            formatter.dateFormat = "d MMM, HH:mm"
        }
        return formatter.string(from: createdAt)
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        userId: String,
        title: String,
        body: String,
        type: NotificationType,
        data: NotificationData? = nil,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.type = type
        self.data = data
        self.isRead = isRead
        self.createdAt = createdAt
    }
    
    // MARK: - Factory Methods
    static func bookingConfirmed(userId: String, booking: Booking) -> AppNotification {
        AppNotification(
            userId: userId,
            title: "Rezervasyon Onaylandı ✅",
            body: "\(booking.facilityName) - \(booking.pitchName) için \(booking.formattedDate) tarihli rezervasyonunuz onaylandı.",
            type: .bookingConfirmed,
            data: NotificationData(bookingId: booking.id, facilityId: booking.facilityId)
        )
    }
    
    static func bookingReminder(userId: String, booking: Booking, hoursLeft: Int) -> AppNotification {
        AppNotification(
            userId: userId,
            title: "Maç Hatırlatması ⚽",
            body: "\(booking.facilityName) - \(booking.pitchName)'da maçınıza \(hoursLeft) saat kaldı!",
            type: .bookingReminder,
            data: NotificationData(bookingId: booking.id, facilityId: booking.facilityId)
        )
    }

    static func bookingCancelled(userId: String, booking: Booking, reason: String? = nil) -> AppNotification {
        let body: String
        if let reason, !reason.isEmpty {
            body = "\(booking.facilityName) – \(booking.formattedDate) tarihli rezervasyonunuz iptal edildi. Sebep: \(reason)"
        } else {
            body = "\(booking.facilityName) – \(booking.formattedDate) tarihli rezervasyonunuz iptal edildi."
        }
        return AppNotification(
            userId: userId,
            title: "Rezervasyon İptali ❌",
            body: body,
            type: .bookingCancelled,
            data: NotificationData(bookingId: booking.id, facilityId: booking.facilityId)
        )
    }

    /// Admin'e: yeni rezervasyon (kullanıcı oluşturduğunda)
    static func newBookingForAdmin(adminId: String, booking: Booking) -> AppNotification {
        let actionText =
            booking.status == .pending
            ? "için ödeme yaptı ve onayınızı bekliyor."
            : "için ayırdı."

        return AppNotification(
            userId: adminId,
            title: "Yeni Rezervasyon 🎫",
            body: "\(booking.userFullName) – \(booking.pitchName) sahasını \(booking.formattedDate) (\(booking.timeSlotString)) \(actionText)",
            type: .bookingConfirmed,
            data: NotificationData(bookingId: booking.id, facilityId: booking.facilityId, pitchId: booking.pitchId)
        )
    }

    /// Admin'e: kullanıcı rezervasyonunu iptal etti
    static func bookingCancelledByUser(adminId: String, booking: Booking) -> AppNotification {
        AppNotification(
            userId: adminId,
            title: "Rezervasyon İptal Edildi ❌",
            body: "\(booking.userFullName) – \(booking.pitchName) için \(booking.formattedDate) tarihli rezervasyonunu iptal etti.",
            type: .bookingCancelled,
            data: NotificationData(bookingId: booking.id, facilityId: booking.facilityId, pitchId: booking.pitchId)
        )
    }

    /// Admin'e: yeni değerlendirme alındı
    static func reviewReceived(
        adminId: String,
        facilityName: String,
        review: Review
    ) -> AppNotification {
        let stars = String(format: "%.1f", review.overallRating)
        let snippet: String = {
            guard let comment = review.comment, !comment.isEmpty else {
                return "\(review.userName) tesisini \(stars) yıldızla değerlendirdi."
            }
            let truncated = comment.count > 100
                ? String(comment.prefix(100)) + "…"
                : comment
            return "\(review.userName) (\(stars)★): \"\(truncated)\""
        }()

        return AppNotification(
            userId: adminId,
            title: "Yeni Değerlendirme ⭐️",
            body: snippet,
            type: .reviewReceived,
            data: NotificationData(
                facilityId: review.facilityId,
                pitchId: review.pitchId,
                reviewId: review.id
            )
        )
    }
    
    static func matchInvite(userId: String, senderName: String, groupId: String, bookingId: String) -> AppNotification {
        AppNotification(
            userId: userId,
            title: "Maç Daveti 🎯",
            body: "\(senderName) sizi bir maça davet etti.",
            type: .matchInvite,
            data: NotificationData(bookingId: bookingId, groupId: groupId)
        )
    }
    
    static func joinRequestReceived(userId: String, applicantName: String, postId: String) -> AppNotification {
        AppNotification(
            userId: userId,
            title: "Katılma İsteği 🙋",
            body: "\(applicantName) maçınıza katılmak istiyor.",
            type: .joinRequest,
            data: NotificationData(matchPostId: postId)
        )
    }
    
    static func joinRequestAccepted(userId: String, facilityName: String, groupId: String) -> AppNotification {
        AppNotification(
            userId: userId,
            title: "İstek Kabul Edildi 🎉",
            body: "\(facilityName)'daki maça katılma isteğiniz kabul edildi!",
            type: .joinRequestAccepted,
            data: NotificationData(groupId: groupId)
        )
    }
    
    static func newMessage(userId: String, senderName: String, groupId: String, groupName: String) -> AppNotification {
        AppNotification(
            userId: userId,
            title: groupName,
            body: "\(senderName) bir mesaj gönderdi.",
            type: .newMessage,
            data: NotificationData(groupId: groupId)
        )
    }
    
    static func newFollower(userId: String, followerName: String, followerId: String) -> AppNotification {
        AppNotification(
            userId: userId,
            title: "Yeni Takipçi 👤",
            body: "\(followerName) sizi takip etmeye başladı.",
            type: .newFollower,
            data: NotificationData(userId: followerId)
        )
    }
}

// MARK: - Notification Type
enum NotificationType: String, Codable, CaseIterable {
    // Rezervasyon bildirimleri
    case bookingConfirmed = "bookingConfirmed"
    case bookingCancelled = "bookingCancelled"
    case bookingReminder = "bookingReminder"
    
    // Sosyal bildirimler
    case matchInvite = "matchInvite"
    case joinRequest = "joinRequest"
    case joinRequestAccepted = "joinRequestAccepted"
    case joinRequestRejected = "joinRequestRejected"
    case newMessage = "newMessage"
    case newFollower = "newFollower"
    
    // Sistem bildirimleri
    case facilityApproved = "facilityApproved"
    case facilityRejected = "facilityRejected"
    case reviewReceived = "reviewReceived"
    case promotional = "promotional"
    case system = "system"
    
    var icon: String {
        switch self {
        case .bookingConfirmed: return "checkmark.circle.fill"
        case .bookingCancelled: return "xmark.circle.fill"
        case .bookingReminder: return "alarm.fill"
        case .matchInvite: return "sportscourt.fill"
        case .joinRequest: return "person.badge.plus"
        case .joinRequestAccepted: return "checkmark.seal.fill"
        case .joinRequestRejected: return "xmark.seal.fill"
        case .newMessage: return "message.fill"
        case .newFollower: return "person.fill.badge.plus"
        case .facilityApproved: return "building.2.fill"
        case .facilityRejected: return "building.2"
        case .reviewReceived: return "star.fill"
        case .promotional: return "gift.fill"
        case .system: return "bell.fill"
        }
    }
    
    var color: String {
        switch self {
        case .bookingConfirmed, .joinRequestAccepted, .facilityApproved:
            return "green"
        case .bookingCancelled, .joinRequestRejected, .facilityRejected:
            return "red"
        case .bookingReminder:
            return "orange"
        case .matchInvite, .joinRequest:
            return "blue"
        case .newMessage:
            return "purple"
        case .newFollower:
            return "pink"
        case .reviewReceived:
            return "yellow"
        case .promotional:
            return "indigo"
        case .system:
            return "gray"
        }
    }
    
    var category: NotificationCategory {
        switch self {
        case .bookingConfirmed, .bookingCancelled, .bookingReminder:
            return .booking
        case .matchInvite, .joinRequest, .joinRequestAccepted, .joinRequestRejected, .newMessage, .newFollower:
            return .social
        case .facilityApproved, .facilityRejected, .reviewReceived, .promotional, .system:
            return .system
        }
    }
}

// MARK: - Notification Category
enum NotificationCategory: String, CaseIterable {
    case booking = "booking"
    case social = "social"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .booking: return "Rezervasyonlar"
        case .social: return "Sosyal"
        case .system: return "Sistem"
        }
    }
}

// MARK: - Notification Data (Navigasyon için ek veriler)
struct NotificationData: Codable, Hashable {
    var bookingId: String?
    var facilityId: String?
    var pitchId: String?
    var groupId: String?
    var matchPostId: String?
    var userId: String?
    var reviewId: String?
    
    init(
        bookingId: String? = nil,
        facilityId: String? = nil,
        pitchId: String? = nil,
        groupId: String? = nil,
        matchPostId: String? = nil,
        userId: String? = nil,
        reviewId: String? = nil
    ) {
        self.bookingId = bookingId
        self.facilityId = facilityId
        self.pitchId = pitchId
        self.groupId = groupId
        self.matchPostId = matchPostId
        self.userId = userId
        self.reviewId = reviewId
    }
}

// MARK: - Mock Data
extension AppNotification {
    static let mockNotifications: [AppNotification] = [
        AppNotification(
            id: "notif1",
            userId: "user123",
            title: "Rezervasyon Onaylandı ✅",
            body: "Yıldız Spor Tesisleri - Saha A için 28 Aralık tarihli rezervasyonunuz onaylandı.",
            type: .bookingConfirmed,
            data: NotificationData(bookingId: "booking123", facilityId: "facility123"),
            createdAt: Date().addingTimeInterval(-3600)
        ),
        AppNotification(
            id: "notif2",
            userId: "user123",
            title: "Maç Daveti 🎯",
            body: "Mehmet sizi bir maça davet etti.",
            type: .matchInvite,
            data: NotificationData(groupId: "group123"),
            createdAt: Date().addingTimeInterval(-7200)
        ),
        AppNotification(
            id: "notif3",
            userId: "user123",
            title: "Yeni Takipçi 👤",
            body: "Ali sizi takip etmeye başladı.",
            type: .newFollower,
            data: NotificationData(userId: "user789"),
            isRead: true,
            createdAt: Date().addingTimeInterval(-86400)
        ),
        AppNotification(
            id: "notif4",
            userId: "user123",
            title: "Maç Hatırlatması ⚽",
            body: "Yıldız Spor Tesisleri - Saha A'da maçınıza 2 saat kaldı!",
            type: .bookingReminder,
            data: NotificationData(bookingId: "booking123"),
            createdAt: Date().addingTimeInterval(-1800)
        )
    ]
}
