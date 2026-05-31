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
    var billingAddress: BillingAddress?  // iyzico ödemesi için fatura adresi

    // MARK: - Onboarding Fields
    // Hepsi optional — eski Firestore dökümanlarıyla geri uyumlu olsun diye.
    var playFrequency: PlayFrequency?
    var skillLevel: SkillLevel?
    var preferredDays: [Weekday]?
    var preferredTimeSlots: [PlayTimeSlot]?
    var motivations: [Motivation]?
    var onboardingCompletedAt: Date?

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

    var hasCompletedOnboarding: Bool {
        onboardingCompletedAt != nil
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
        billingAddress: BillingAddress? = nil,
        playFrequency: PlayFrequency? = nil,
        skillLevel: SkillLevel? = nil,
        preferredDays: [Weekday]? = nil,
        preferredTimeSlots: [PlayTimeSlot]? = nil,
        motivations: [Motivation]? = nil,
        onboardingCompletedAt: Date? = nil,
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
        self.billingAddress = billingAddress
        self.playFrequency = playFrequency
        self.skillLevel = skillLevel
        self.preferredDays = preferredDays
        self.preferredTimeSlots = preferredTimeSlots
        self.motivations = motivations
        self.onboardingCompletedAt = onboardingCompletedAt
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

// MARK: - Play Frequency Enum
enum PlayFrequency: String, Codable, CaseIterable, Identifiable {
    case firstTime = "firstTime"
    case monthly = "monthly"             // Ayda 1-2
    case weekly = "weekly"               // Haftada 1
    case multipleTimesWeek = "multiple"  // Haftada 2+

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firstTime: return "İlk kez"
        case .monthly: return "Ayda 1-2"
        case .weekly: return "Haftada 1"
        case .multipleTimesWeek: return "Haftada 2+"
        }
    }

    var subtitle: String {
        switch self {
        case .firstTime: return "Yeni başlıyorum"
        case .monthly: return "Ara sıra oynuyorum"
        case .weekly: return "Düzenli olarak oynarım"
        case .multipleTimesWeek: return "Düzenli, sık oynayan biriyim"
        }
    }

    var icon: String {
        switch self {
        case .firstTime: return "sparkles"
        case .monthly: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .multipleTimesWeek: return "flame.fill"
        }
    }
}

// MARK: - SkillLevel onboarding extension
// `SkillLevel` MatchPost.swift'te tanımlı; onboarding için sade görünüm sağlıyoruz.
extension SkillLevel {
    var onboardingSubtitle: String {
        switch self {
        case .beginner: return "Eğlence için oynuyorum"
        case .intermediate: return "Düzenli oynuyorum, formdayım"
        case .advanced: return "Takım tecrübem var, iddialıyım"
        case .professional: return "Profesyonel seviyedeyim"
        case .any: return "Her seviyede oynarım"
        }
    }

    var onboardingEmoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "⚡"
        case .advanced: return "🔥"
        case .professional: return "🏆"
        case .any: return "🎯"
        }
    }

    /// Onboarding'de gösterilecek seviyeler — sade tutuluyor.
    static var onboardingCases: [SkillLevel] {
        [.beginner, .intermediate, .advanced]
    }
}

// MARK: - Weekday Enum
enum Weekday: String, Codable, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .monday: return "Pzt"
        case .tuesday: return "Sal"
        case .wednesday: return "Çar"
        case .thursday: return "Per"
        case .friday: return "Cum"
        case .saturday: return "Cmt"
        case .sunday: return "Paz"
        }
    }

    var displayName: String {
        switch self {
        case .monday: return "Pazartesi"
        case .tuesday: return "Salı"
        case .wednesday: return "Çarşamba"
        case .thursday: return "Perşembe"
        case .friday: return "Cuma"
        case .saturday: return "Cumartesi"
        case .sunday: return "Pazar"
        }
    }
}

// MARK: - Play Time Slot Enum (onboarding tercihi)
/// Not: `TimeSlot` (Pitch.swift) saha rezervasyon slot'unu temsil eder.
/// `PlayTimeSlot` ise kullanıcının onboarding sırasında belirttiği günün hangi diliminde oynamayı tercih ettiğidir.
enum PlayTimeSlot: String, Codable, CaseIterable, Identifiable {
    case morning = "morning"     // 09 - 17
    case evening = "evening"     // 18 - 21
    case night = "night"         // 21+

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: return "Sabah / Öğlen"
        case .evening: return "Akşam"
        case .night: return "Gece"
        }
    }

    var subtitle: String {
        switch self {
        case .morning: return "09:00 - 17:00"
        case .evening: return "18:00 - 21:00"
        case .night: return "21:00 sonrası"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "sun.horizon.fill"
        case .night: return "moon.stars.fill"
        }
    }
}

// MARK: - Motivation Enum
enum Motivation: String, Codable, CaseIterable, Identifiable {
    case competition = "competition"
    case friends = "friends"
    case fitness = "fitness"
    case socialize = "socialize"
    case loveOfGame = "loveOfGame"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .competition: return "Rekabet"
        case .friends: return "Arkadaşlarımla vakit"
        case .fitness: return "Form tutmak"
        case .socialize: return "Yeni insanlar"
        case .loveOfGame: return "Futbol aşkı"
        }
    }

    var emoji: String {
        switch self {
        case .competition: return "🏆"
        case .friends: return "🤝"
        case .fitness: return "💪"
        case .socialize: return "🆕"
        case .loveOfGame: return "⚽"
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
        attendedMatches: 24,
        onboardingCompletedAt: Date()
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
