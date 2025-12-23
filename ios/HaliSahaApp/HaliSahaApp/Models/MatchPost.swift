//
//  MatchPost.swift
//  HaliSahaApp
//
//  Oyuncu Bulma İlanı veri modeli
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//

import Foundation
import FirebaseFirestore

// MARK: - MatchPost Model (Oyuncu Aranıyor İlanı)
struct MatchPost: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var creatorId: String            // İlanı oluşturan kullanıcı
    var creatorName: String          // Oluşturan adı (denormalize)
    var creatorProfileImage: String?
    var groupId: String?             // İlişkili grup (opsiyonel)
    var bookingId: String            // İlişkili rezervasyon
    
    // Maç bilgileri (denormalize)
    var facilityId: String
    var facilityName: String
    var facilityAddress: String
    var pitchName: String
    var matchDate: Date
    var startHour: Int
    var endHour: Int
    
    // İlan detayları
    var title: String                // İlan başlığı
    var description: String?         // Açıklama
    var neededPlayers: Int           // Aranan oyuncu sayısı
    var currentPlayers: Int          // Mevcut oyuncu sayısı
    var maxPlayers: Int              // Maksimum oyuncu sayısı
    var preferredPositions: [PlayerPosition] // Tercih edilen mevkiler
    var skillLevel: SkillLevel       // Seviye beklentisi
    var ageRange: AgeRange?          // Yaş aralığı tercihi
    var costPerPlayer: Double?       // Kişi başı ücret
    
    // Başvurular
    var applicantIds: [String]       // Başvuran kullanıcı ID'leri
    var acceptedIds: [String]        // Kabul edilen kullanıcı ID'leri
    var rejectedIds: [String]        // Reddedilen kullanıcı ID'leri
    
    // Durum
    var status: MatchPostStatus
    var createdAt: Date
    var updatedAt: Date
    var expiresAt: Date              // Maç saatinde otomatik expire olur
    
    // MARK: - Computed Properties
    var availableSlots: Int {
        neededPlayers - acceptedIds.count
    }
    
    var isFull: Bool {
        availableSlots <= 0
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: matchDate)
    }
    
    var timeSlot: String {
        String(format: "%02d:00 - %02d:00", startHour, endHour)
    }
    
    var formattedCostPerPlayer: String? {
        guard let cost = costPerPlayer else { return nil }
        return "\(Int(cost)) ₺/kişi"
    }
    
    var pendingApplicationsCount: Int {
        applicantIds.filter { !acceptedIds.contains($0) && !rejectedIds.contains($0) }.count
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        creatorId: String,
        creatorName: String,
        creatorProfileImage: String? = nil,
        groupId: String? = nil,
        bookingId: String,
        facilityId: String,
        facilityName: String,
        facilityAddress: String,
        pitchName: String,
        matchDate: Date,
        startHour: Int,
        endHour: Int,
        title: String,
        description: String? = nil,
        neededPlayers: Int,
        currentPlayers: Int,
        maxPlayers: Int,
        preferredPositions: [PlayerPosition] = [],
        skillLevel: SkillLevel = .any,
        ageRange: AgeRange? = nil,
        costPerPlayer: Double? = nil,
        applicantIds: [String] = [],
        acceptedIds: [String] = [],
        rejectedIds: [String] = [],
        status: MatchPostStatus = .active,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.creatorProfileImage = creatorProfileImage
        self.groupId = groupId
        self.bookingId = bookingId
        self.facilityId = facilityId
        self.facilityName = facilityName
        self.facilityAddress = facilityAddress
        self.pitchName = pitchName
        self.matchDate = matchDate
        self.startHour = startHour
        self.endHour = endHour
        self.title = title
        self.description = description
        self.neededPlayers = neededPlayers
        self.currentPlayers = currentPlayers
        self.maxPlayers = maxPlayers
        self.preferredPositions = preferredPositions
        self.skillLevel = skillLevel
        self.ageRange = ageRange
        self.costPerPlayer = costPerPlayer
        self.applicantIds = applicantIds
        self.acceptedIds = acceptedIds
        self.rejectedIds = rejectedIds
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Varsayılan expire tarihi: maç başlangıç saati
        if let expDate = expiresAt {
            self.expiresAt = expDate
        } else {
            let calendar = Calendar.current
            self.expiresAt = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: matchDate) ?? matchDate
        }
    }
    
    // MARK: - Helper Methods
    func canApply(_ userId: String) -> Bool {
        guard status == .active && !isExpired && !isFull else { return false }
        return !applicantIds.contains(userId) &&
               !acceptedIds.contains(userId) &&
               userId != creatorId
    }
    
    func hasApplied(_ userId: String) -> Bool {
        applicantIds.contains(userId)
    }
    
    func isAccepted(_ userId: String) -> Bool {
        acceptedIds.contains(userId)
    }
    
    func isRejected(_ userId: String) -> Bool {
        rejectedIds.contains(userId)
    }
}

// MARK: - Match Post Status
enum MatchPostStatus: String, Codable, CaseIterable {
    case active = "active"           // Aktif, başvuru alıyor
    case full = "full"               // Dolu, başvuru almıyor
    case completed = "completed"     // Maç oynandı
    case cancelled = "cancelled"     // İptal edildi
    case expired = "expired"         // Süresi doldu
    
    var displayName: String {
        switch self {
        case .active: return "Aktif"
        case .full: return "Kadro Tamamlandı"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal Edildi"
        case .expired: return "Süresi Doldu"
        }
    }
    
    var color: String {
        switch self {
        case .active: return "green"
        case .full: return "blue"
        case .completed: return "gray"
        case .cancelled: return "red"
        case .expired: return "gray"
        }
    }
}

// MARK: - Skill Level
enum SkillLevel: String, Codable, CaseIterable {
    case beginner = "beginner"       // Başlangıç
    case intermediate = "intermediate" // Orta
    case advanced = "advanced"       // İleri
    case professional = "professional" // Profesyonel
    case any = "any"                 // Farketmez
    
    var displayName: String {
        switch self {
        case .beginner: return "Başlangıç"
        case .intermediate: return "Orta Seviye"
        case .advanced: return "İleri Seviye"
        case .professional: return "Profesyonel"
        case .any: return "Farketmez"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "⭐"
        case .intermediate: return "⭐⭐"
        case .advanced: return "⭐⭐⭐"
        case .professional: return "🏆"
        case .any: return "🎯"
        }
    }
}

// MARK: - Age Range
struct AgeRange: Codable, Hashable {
    var minAge: Int
    var maxAge: Int
    
    var displayName: String {
        "\(minAge) - \(maxAge) yaş"
    }
    
    static let young = AgeRange(minAge: 18, maxAge: 25)
    static let adult = AgeRange(minAge: 25, maxAge: 35)
    static let senior = AgeRange(minAge: 35, maxAge: 50)
    static let any = AgeRange(minAge: 18, maxAge: 65)
}

// MARK: - Match Post Application (Başvuru)
struct MatchPostApplication: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var postId: String               // İlan ID
    var userId: String               // Başvuran kullanıcı
    var userName: String
    var userProfileImage: String?
    var userPosition: PlayerPosition
    var userReliabilityScore: Double
    var message: String?             // Başvuru mesajı
    var status: ApplicationStatus
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String? = nil,
        postId: String,
        userId: String,
        userName: String,
        userProfileImage: String? = nil,
        userPosition: PlayerPosition,
        userReliabilityScore: Double,
        message: String? = nil,
        status: ApplicationStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.userName = userName
        self.userProfileImage = userProfileImage
        self.userPosition = userPosition
        self.userReliabilityScore = userReliabilityScore
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Application Status
enum ApplicationStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case withdrawn = "withdrawn"     // Kullanıcı geri çekti
    
    var displayName: String {
        switch self {
        case .pending: return "Bekliyor"
        case .accepted: return "Kabul Edildi"
        case .rejected: return "Reddedildi"
        case .withdrawn: return "Geri Çekildi"
        }
    }
}

// MARK: - Mock Data
extension MatchPost {
    static let mockPost = MatchPost(
        id: "post123",
        creatorId: "user123",
        creatorName: "Ahmet Yılmaz",
        bookingId: "booking123",
        facilityId: "facility123",
        facilityName: "Yıldız Spor Tesisleri",
        facilityAddress: "Ataşehir, İstanbul",
        pitchName: "Saha A",
        matchDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        startHour: 20,
        endHour: 21,
        title: "Cumartesi Akşamı Maça 4 Kişi Aranıyor",
        description: "Dostluk maçı yapıyoruz, eğlenceli bir ortam. Tecrübe farketmez, önemli olan keyif almak!",
        neededPlayers: 4,
        currentPlayers: 10,
        maxPlayers: 14,
        preferredPositions: [.defender, .midfielder],
        skillLevel: .intermediate,
        costPerPlayer: 100
    )
}
