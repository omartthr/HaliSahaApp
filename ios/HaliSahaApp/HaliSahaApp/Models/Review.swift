//
//  Review.swift
//  HaliSahaApp
//
//  Değerlendirme veri modeli
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import Foundation
import FirebaseFirestore

// MARK: - Review Model (Saha Değerlendirmesi)
struct Review: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var facilityId: String           // Değerlendirilen tesis
    var pitchId: String?             // Değerlendirilen saha (opsiyonel)
    var bookingId: String            // İlişkili rezervasyon
    var userId: String               // Değerlendiren kullanıcı
    var userName: String             // Kullanıcı adı (denormalize)
    var userProfileImage: String?
    
    // Puanlar (1-5 arası)
    var overallRating: Double        // Genel puan
    var cleanlinessRating: Double    // Temizlik
    var surfaceRating: Double        // Zemin kalitesi
    var serviceRating: Double        // Hizmet kalitesi
    var facilitiesRating: Double     // Tesis olanakları
    var valueForMoneyRating: Double  // Fiyat/performans
    
    // Yorum
    var comment: String?
    var images: [String]             // Yorum fotoğrafları
    
    // Admin yanıtı
    var adminReply: String?
    var adminReplyDate: Date?
    
    // Meta
    var isVerified: Bool             // Gerçek rezervasyon sonrası mı?
    var helpfulCount: Int            // Faydalı bulan sayısı
    var reportCount: Int             // Şikayet sayısı
    var isHidden: Bool               // Gizlendi mi?
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed Properties
    var averageRating: Double {
        let ratings = [cleanlinessRating, surfaceRating, serviceRating, facilitiesRating, valueForMoneyRating]
        return ratings.reduce(0, +) / Double(ratings.count)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: createdAt)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var ratingStars: String {
        let fullStars = Int(overallRating)
        let hasHalfStar = overallRating - Double(fullStars) >= 0.5
        var stars = String(repeating: "★", count: fullStars)
        if hasHalfStar { stars += "½" }
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        stars += String(repeating: "☆", count: emptyStars)
        return stars
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        facilityId: String,
        pitchId: String? = nil,
        bookingId: String,
        userId: String,
        userName: String,
        userProfileImage: String? = nil,
        overallRating: Double,
        cleanlinessRating: Double,
        surfaceRating: Double,
        serviceRating: Double,
        facilitiesRating: Double,
        valueForMoneyRating: Double,
        comment: String? = nil,
        images: [String] = [],
        adminReply: String? = nil,
        adminReplyDate: Date? = nil,
        isVerified: Bool = true,
        helpfulCount: Int = 0,
        reportCount: Int = 0,
        isHidden: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.facilityId = facilityId
        self.pitchId = pitchId
        self.bookingId = bookingId
        self.userId = userId
        self.userName = userName
        self.userProfileImage = userProfileImage
        self.overallRating = overallRating
        self.cleanlinessRating = cleanlinessRating
        self.surfaceRating = surfaceRating
        self.serviceRating = serviceRating
        self.facilitiesRating = facilitiesRating
        self.valueForMoneyRating = valueForMoneyRating
        self.comment = comment
        self.images = images
        self.adminReply = adminReply
        self.adminReplyDate = adminReplyDate
        self.isVerified = isVerified
        self.helpfulCount = helpfulCount
        self.reportCount = reportCount
        self.isHidden = isHidden
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - User Reliability Review (Kullanıcı Güvenilirlik Değerlendirmesi)
struct UserReliabilityReview: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var reviewedUserId: String       // Değerlendirilen kullanıcı
    var reviewerId: String           // Değerlendiren (saha sahibi)
    var bookingId: String            // İlişkili rezervasyon
    var facilityId: String
    
    var attended: Bool               // Maça geldi mi?
    var wasOnTime: Bool              // Zamanında geldi mi?
    var behaviorRating: Double       // Davranış puanı (1-5)
    var comment: String?
    
    var createdAt: Date
    
    init(
        id: String? = nil,
        reviewedUserId: String,
        reviewerId: String,
        bookingId: String,
        facilityId: String,
        attended: Bool,
        wasOnTime: Bool = true,
        behaviorRating: Double = 5.0,
        comment: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reviewedUserId = reviewedUserId
        self.reviewerId = reviewerId
        self.bookingId = bookingId
        self.facilityId = facilityId
        self.attended = attended
        self.wasOnTime = wasOnTime
        self.behaviorRating = behaviorRating
        self.comment = comment
        self.createdAt = createdAt
    }
}

// MARK: - Review Summary (Tesis için özet istatistikler)
struct ReviewSummary: Codable, Hashable {
    var totalReviews: Int
    var averageOverall: Double
    var averageCleanliness: Double
    var averageSurface: Double
    var averageService: Double
    var averageFacilities: Double
    var averageValueForMoney: Double
    
    // Puan dağılımı
    var fiveStarCount: Int
    var fourStarCount: Int
    var threeStarCount: Int
    var twoStarCount: Int
    var oneStarCount: Int
    
    var formattedAverage: String {
        String(format: "%.1f", averageOverall)
    }
    
    init(
        totalReviews: Int = 0,
        averageOverall: Double = 0,
        averageCleanliness: Double = 0,
        averageSurface: Double = 0,
        averageService: Double = 0,
        averageFacilities: Double = 0,
        averageValueForMoney: Double = 0,
        fiveStarCount: Int = 0,
        fourStarCount: Int = 0,
        threeStarCount: Int = 0,
        twoStarCount: Int = 0,
        oneStarCount: Int = 0
    ) {
        self.totalReviews = totalReviews
        self.averageOverall = averageOverall
        self.averageCleanliness = averageCleanliness
        self.averageSurface = averageSurface
        self.averageService = averageService
        self.averageFacilities = averageFacilities
        self.averageValueForMoney = averageValueForMoney
        self.fiveStarCount = fiveStarCount
        self.fourStarCount = fourStarCount
        self.threeStarCount = threeStarCount
        self.twoStarCount = twoStarCount
        self.oneStarCount = oneStarCount
    }
    
    // Puan yüzdelerini hesapla
    func percentage(for stars: Int) -> Double {
        guard totalReviews > 0 else { return 0 }
        let count: Int
        switch stars {
        case 5: count = fiveStarCount
        case 4: count = fourStarCount
        case 3: count = threeStarCount
        case 2: count = twoStarCount
        case 1: count = oneStarCount
        default: count = 0
        }
        return Double(count) / Double(totalReviews) * 100
    }
}

// MARK: - Rating Category
enum RatingCategory: String, CaseIterable {
    case cleanliness = "cleanliness"
    case surface = "surface"
    case service = "service"
    case facilities = "facilities"
    case valueForMoney = "valueForMoney"
    
    var displayName: String {
        switch self {
        case .cleanliness: return "Temizlik"
        case .surface: return "Zemin Kalitesi"
        case .service: return "Hizmet"
        case .facilities: return "Tesisler"
        case .valueForMoney: return "Fiyat/Performans"
        }
    }
    
    var icon: String {
        switch self {
        case .cleanliness: return "sparkles"
        case .surface: return "leaf.fill"
        case .service: return "person.fill"
        case .facilities: return "building.2.fill"
        case .valueForMoney: return "turkishlirasign.circle"
        }
    }
}

// MARK: - Mock Data
extension Review {
    static let mockReview = Review(
        id: "review123",
        facilityId: "facility123",
        pitchId: "pitch123",
        bookingId: "booking456",
        userId: "user123",
        userName: "Ahmet Yılmaz",
        overallRating: 4.5,
        cleanlinessRating: 5.0,
        surfaceRating: 4.0,
        serviceRating: 4.5,
        facilitiesRating: 4.5,
        valueForMoneyRating: 4.0,
        comment: "Harika bir tesis! Zemin kalitesi çok iyi, personel ilgili. Tek eksik otopark biraz küçük. Kesinlikle tekrar geliriz.",
        isVerified: true,
        helpfulCount: 12
    )
    
    static let mockReviews: [Review] = [
        mockReview,
        Review(
            id: "review456",
            facilityId: "facility123",
            bookingId: "booking789",
            userId: "user456",
            userName: "Mehmet Demir",
            overallRating: 5.0,
            cleanlinessRating: 5.0,
            surfaceRating: 5.0,
            serviceRating: 5.0,
            facilitiesRating: 5.0,
            valueForMoneyRating: 5.0,
            comment: "Mükemmel! En sevdiğim halı saha.",
            isVerified: true,
            helpfulCount: 8,
            createdAt: Date().addingTimeInterval(-86400 * 7)
        )
    ]
}
