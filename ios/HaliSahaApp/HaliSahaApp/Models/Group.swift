//
//  Group.swift
//  HaliSahaApp
//
//  Takım/Grup veri modeli (Sosyal özellikler için)
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import Foundation
import FirebaseFirestore

// MARK: - Group Model
struct Group: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String                     // Grup adı
    var description: String?
    var imageURL: String?                // Grup fotoğrafı
    var creatorId: String                // Grup kurucusu
    var adminIds: [String]               // Grup yöneticileri
    var memberIds: [String]              // Tüm üyeler (adminler dahil)
    var maxMembers: Int                  // Maksimum üye sayısı
    var isPublic: Bool                   // Herkese açık mı?
    var groupType: GroupType
    var linkedBookingId: String?         // İlişkili rezervasyon (maç grubu ise)
    var lastMessage: LastMessagePreview? // Son mesaj önizlemesi
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    
    // MARK: - Computed Properties
    var memberCount: Int {
        memberIds.count
    }
    
    var isFull: Bool {
        memberCount >= maxMembers
    }
    
    var availableSlots: Int {
        max(0, maxMembers - memberCount)
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        name: String,
        description: String? = nil,
        imageURL: String? = nil,
        creatorId: String,
        adminIds: [String]? = nil,
        memberIds: [String]? = nil,
        maxMembers: Int = 20,
        isPublic: Bool = false,
        groupType: GroupType = .team,
        linkedBookingId: String? = nil,
        lastMessage: LastMessagePreview? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.creatorId = creatorId
        self.adminIds = adminIds ?? [creatorId]
        self.memberIds = memberIds ?? [creatorId]
        self.maxMembers = maxMembers
        self.isPublic = isPublic
        self.groupType = groupType
        self.linkedBookingId = linkedBookingId
        self.lastMessage = lastMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
    
    // MARK: - Helper Methods
    func isAdmin(_ userId: String) -> Bool {
        adminIds.contains(userId)
    }
    
    func isCreator(_ userId: String) -> Bool {
        creatorId == userId
    }
    
    func isMember(_ userId: String) -> Bool {
        memberIds.contains(userId)
    }
    
    func canJoin(_ userId: String) -> Bool {
        !isMember(userId) && !isFull && isActive
    }
}

// MARK: - Group Type
enum GroupType: String, Codable, CaseIterable {
    case team = "team"           // Kalıcı takım grubu
    case matchGroup = "match"    // Tek maçlık grup
    case private_ = "private"    // Özel sohbet grubu
    
    var displayName: String {
        switch self {
        case .team: return "Takım"
        case .matchGroup: return "Maç Grubu"
        case .private_: return "Özel Grup"
        }
    }
    
    var icon: String {
        switch self {
        case .team: return "person.3.fill"
        case .matchGroup: return "sportscourt.fill"
        case .private_: return "lock.fill"
        }
    }
}

// MARK: - Last Message Preview (Sohbet listesi için)
struct LastMessagePreview: Codable, Hashable {
    var senderId: String
    var senderName: String
    var content: String
    var timestamp: Date
    var messageType: MessageType
    
    var previewText: String {
        switch messageType {
        case .text:
            return content.count > 50 ? String(content.prefix(50)) + "..." : content
        case .image:
            return "📷 Fotoğraf"
        case .matchInvite:
            return "⚽ Maç Daveti"
        case .joinRequest:
            return "🙋 Katılma İsteği"
        case .system:
            return content
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Group Member (Detaylı üye bilgisi için)
struct GroupMember: Identifiable, Codable, Hashable {
    var id: String { oderId }
    var oderId: String
    var userId: String
    var userName: String
    var userProfileImage: String?
    var role: GroupMemberRole
    var joinedAt: Date
    var invitedBy: String?
    
    init(
        oderId: String = UUID().uuidString,
        userId: String,
        userName: String,
        userProfileImage: String? = nil,
        role: GroupMemberRole = .member,
        joinedAt: Date = Date(),
        invitedBy: String? = nil
    ) {
        self.oderId = oderId
        self.userId = userId
        self.userName = userName
        self.userProfileImage = userProfileImage
        self.role = role
        self.joinedAt = joinedAt
        self.invitedBy = invitedBy
    }
}

// MARK: - Group Member Role
enum GroupMemberRole: String, Codable, CaseIterable {
    case creator = "creator"     // Grup kurucusu
    case admin = "admin"         // Yönetici
    case member = "member"       // Normal üye
    
    var displayName: String {
        switch self {
        case .creator: return "Kurucu"
        case .admin: return "Yönetici"
        case .member: return "Üye"
        }
    }
    
    var canInvite: Bool {
        self == .creator || self == .admin
    }
    
    var canRemoveMember: Bool {
        self == .creator || self == .admin
    }
    
    var canEditGroup: Bool {
        self == .creator || self == .admin
    }
}

// MARK: - Mock Data
extension Group {
    static let mockGroup = Group(
        id: "group123",
        name: "Perşembe Akşamı Futbol",
        description: "Her perşembe akşamı düzenli maç yapan arkadaş grubu",
        creatorId: "user123",
        memberIds: ["user123", "user456", "user789"],
        maxMembers: 14,
        isPublic: false,
        groupType: .team,
        lastMessage: LastMessagePreview(
            senderId: "user456",
            senderName: "Mehmet",
            content: "Bu hafta gelecek misiniz?",
            timestamp: Date().addingTimeInterval(-3600),
            messageType: .text
        )
    )
    
    static let mockMatchGroup = Group(
        id: "group456",
        name: "Cumartesi Maçı - Yıldız Spor",
        description: "28 Aralık Cumartesi 20:00 maçı",
        creatorId: "user123",
        memberIds: ["user123", "user456"],
        maxMembers: 14,
        isPublic: true,
        groupType: .matchGroup,
        linkedBookingId: "booking123"
    )
}
