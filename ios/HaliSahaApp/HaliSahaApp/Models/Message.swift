//
//  Message.swift
//  HaliSahaApp
//
//  Mesaj veri modeli (Grup sohbeti için - Sub-collection)
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//

import Foundation
import FirebaseFirestore

// MARK: - Message Model
struct Message: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var groupId: String              // Üst grup ID
    var senderId: String             // Gönderen kullanıcı ID
    var senderName: String           // Gönderen adı (denormalize)
    var senderProfileImage: String?  // Profil fotoğrafı URL
    var content: String              // Mesaj içeriği
    var messageType: MessageType
    var imageURL: String?            // Fotoğraf mesajı için
    var matchInviteData: MatchInviteData? // Maç daveti için
    var replyToMessageId: String?    // Yanıtlanan mesaj ID
    var readBy: [String]             // Okuyan kullanıcı ID'leri
    var isEdited: Bool
    var isDeleted: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    var isRead: Bool {
        !readBy.isEmpty
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        
        if Calendar.current.isDateInToday(createdAt) {
            return "Bugün"
        } else if Calendar.current.isDateInYesterday(createdAt) {
            return "Dün"
        } else {
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: createdAt)
        }
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        groupId: String,
        senderId: String,
        senderName: String,
        senderProfileImage: String? = nil,
        content: String,
        messageType: MessageType = .text,
        imageURL: String? = nil,
        matchInviteData: MatchInviteData? = nil,
        replyToMessageId: String? = nil,
        readBy: [String] = [],
        isEdited: Bool = false,
        isDeleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.senderId = senderId
        self.senderName = senderName
        self.senderProfileImage = senderProfileImage
        self.content = content
        self.messageType = messageType
        self.imageURL = imageURL
        self.matchInviteData = matchInviteData
        self.replyToMessageId = replyToMessageId
        self.readBy = readBy
        self.isEdited = isEdited
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Factory Methods
    static func textMessage(groupId: String, senderId: String, senderName: String, content: String) -> Message {
        Message(
            groupId: groupId,
            senderId: senderId,
            senderName: senderName,
            content: content,
            messageType: .text
        )
    }
    
    static func systemMessage(groupId: String, content: String) -> Message {
        Message(
            groupId: groupId,
            senderId: "system",
            senderName: "Sistem",
            content: content,
            messageType: .system
        )
    }
    
    static func matchInvite(groupId: String, senderId: String, senderName: String, inviteData: MatchInviteData) -> Message {
        Message(
            groupId: groupId,
            senderId: senderId,
            senderName: senderName,
            content: "Maç daveti gönderdi",
            messageType: .matchInvite,
            matchInviteData: inviteData
        )
    }
}

// MARK: - Message Type
enum MessageType: String, Codable, CaseIterable {
    case text = "text"               // Normal metin mesajı
    case image = "image"             // Fotoğraf
    case matchInvite = "matchInvite" // Maç daveti
    case joinRequest = "joinRequest" // Gruba katılma isteği
    case system = "system"           // Sistem mesajı (X gruba katıldı vb.)
    
    var icon: String {
        switch self {
        case .text: return "text.bubble"
        case .image: return "photo"
        case .matchInvite: return "sportscourt"
        case .joinRequest: return "person.badge.plus"
        case .system: return "info.circle"
        }
    }
}

// MARK: - Match Invite Data (Maç daveti içeriği)
struct MatchInviteData: Codable, Hashable {
    var bookingId: String
    var facilityName: String
    var pitchName: String
    var matchDate: Date
    var startHour: Int
    var endHour: Int
    var currentPlayers: Int
    var maxPlayers: Int
    var status: MatchInviteStatus
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: matchDate)
    }
    
    var timeSlot: String {
        String(format: "%02d:00 - %02d:00", startHour, endHour)
    }
    
    var availableSlots: Int {
        maxPlayers - currentPlayers
    }
    
    var isFull: Bool {
        currentPlayers >= maxPlayers
    }
}

// MARK: - Match Invite Status
enum MatchInviteStatus: String, Codable {
    case pending = "pending"       // Bekliyor
    case accepted = "accepted"     // Kabul edildi
    case declined = "declined"     // Reddedildi
    case expired = "expired"       // Süresi doldu
    case cancelled = "cancelled"   // İptal edildi
    
    var displayName: String {
        switch self {
        case .pending: return "Bekliyor"
        case .accepted: return "Kabul Edildi"
        case .declined: return "Reddedildi"
        case .expired: return "Süresi Doldu"
        case .cancelled: return "İptal Edildi"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .accepted: return "green"
        case .declined: return "red"
        case .expired: return "gray"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Mock Data
extension Message {
    static let mockMessages: [Message] = [
        Message(
            id: "msg1",
            groupId: "group123",
            senderId: "user123",
            senderName: "Ahmet",
            content: "Merhaba arkadaşlar, bu hafta maç var mı?",
            messageType: .text,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        Message(
            id: "msg2",
            groupId: "group123",
            senderId: "user456",
            senderName: "Mehmet",
            content: "Evet, cumartesi akşam 8'de rezervasyon yaptım",
            messageType: .text,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Message(
            id: "msg3",
            groupId: "group123",
            senderId: "user456",
            senderName: "Mehmet",
            content: "Maç daveti gönderdi",
            messageType: .matchInvite,
            matchInviteData: MatchInviteData(
                bookingId: "booking123",
                facilityName: "Yıldız Spor",
                pitchName: "Saha A",
                matchDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                startHour: 20,
                endHour: 21,
                currentPlayers: 8,
                maxPlayers: 14,
                status: .pending
            ),
            createdAt: Date().addingTimeInterval(-1800)
        ),
        Message(
            id: "msg4",
            groupId: "group123",
            senderId: "system",
            senderName: "Sistem",
            content: "Ali gruba katıldı",
            messageType: .system,
            createdAt: Date().addingTimeInterval(-900)
        )
    ]
}
