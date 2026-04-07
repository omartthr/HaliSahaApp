//
//  User.swift
//  HaliSaha
//
//  Kullanıcı veri modeli
//

import Foundation
import FirebaseFirestore

// MARK: - User Model
struct User: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var email: String
    var firstName: String
    var lastName: String
    var username: String
    var phone: String
    var profileImageURL: String?
    var preferredPosition: PlayerPosition
    var userType: UserType
    var fcmToken: String?
    var followers: [String]          // Takipçi user ID'leri
    var following: [String]          // Takip edilen user ID'leri
    var favoriteFields: [String]     // Favori saha ID'leri
    var reliabilityScore: Double     // Güvenilirlik puanı (0-5)
    var totalMatches: Int            // Toplam maç sayısı
    var attendedMatches: Int         // Katıldığı maç sayısı
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    
    // MARK: - Computed Properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var attendanceRate: Double {
        guard totalMatches > 0 else { return 100.0 }
        return (Double(attendedMatches) / Double(totalMatches)) * 100
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        phone: String,
        profileImageURL: String? = nil,
        preferredPosition: PlayerPosition = .unspecified,
        userType: UserType = .player,
        fcmToken: String? = nil,
        followers: [String] = [],
        following: [String] = [],
        favoriteFields: [String] = [],
        reliabilityScore: Double = 5.0,
        totalMatches: Int = 0,
        attendedMatches: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.phone = phone
        self.profileImageURL = profileImageURL
        self.preferredPosition = preferredPosition
        self.userType = userType
        self.fcmToken = fcmToken
        self.followers = followers
        self.following = following
        self.favoriteFields = favoriteFields
        self.reliabilityScore = reliabilityScore
        self.totalMatches = totalMatches
        self.attendedMatches = attendedMatches
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
}

// MARK: - User Type Enum
enum UserType: String, Codable, CaseIterable {
    case player = "player"           // Normal kullanıcı
    case admin = "admin"             // Saha sahibi
    case superAdmin = "superAdmin"   // Süper admin
    case guest = "guest"             // Misafir (kayıtsız)
    
    var displayName: String {
        switch self {
        case .player: return "Oyuncu"
        case .admin: return "Saha Sahibi"
        case .superAdmin: return "Yönetici"
        case .guest: return "Misafir"
        }
    }
}

// MARK: - Player Position Enum
enum PlayerPosition: String, Codable, CaseIterable {
    case goalkeeper = "goalkeeper"   // Kaleci
    case defender = "defender"       // Defans
    case midfielder = "midfielder"   // Orta saha
    case forward = "forward"         // Forvet
    case unspecified = "unspecified" // Belirtilmemiş
    
    var displayName: String {
        switch self {
        case .goalkeeper: return "Kaleci"
        case .defender: return "Defans"
        case .midfielder: return "Orta Saha"
        case .forward: return "Forvet"
        case .unspecified: return "Belirtilmemiş"
        }
    }
    
    var icon: String {
        switch self {
        case .goalkeeper: return "🧤"
        case .defender: return "🛡️"
        case .midfielder: return "⚙️"
        case .forward: return "⚽"
        case .unspecified: return "👤"
        }
    }
}

// MARK: - Mock Data for Preview
extension User {
    static let mockUser = User(
        id: "user123",
        email: "ahmet@example.com",
        firstName: "Ahmet",
        lastName: "Yılmaz",
        username: "ahmet_10",
        phone: "+905551234567",
        profileImageURL: nil,
        preferredPosition: .midfielder,
        userType: .player,
        reliabilityScore: 4.8,
        totalMatches: 25,
        attendedMatches: 24
    )
    
    static let mockAdmin = User(
        id: "admin123",
        email: "admin@sahaspor.com",
        firstName: "Mehmet",
        lastName: "Demir",
        username: "sahaspor_admin",
        phone: "+905559876543",
        userType: .admin
    )
}
