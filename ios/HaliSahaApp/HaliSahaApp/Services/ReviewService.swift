//
//  ReviewService.swift
//  HaliSahaApp
//
//  Saha değerlendirme (Review) CRUD + Facility rating'in atomik güncellenmesi.
//

import FirebaseFirestore
import Foundation

// MARK: - Review Service
@MainActor
final class ReviewService {

    // MARK: - Singleton
    static let shared = ReviewService()

    // MARK: - Dependencies
    private let firebaseService = FirebaseService.shared

    private init() {}

    // MARK: - Fetch

    /// Bir tesisin tüm görünür yorumlarını getirir (en yeniden eskiye).
    func fetchReviews(forFacility facilityId: String) async throws -> [Review] {
        let query = firebaseService.reviewsCollection
            .whereField("facilityId", isEqualTo: facilityId)
            .whereField("isHidden", isEqualTo: false)
            .order(by: FirestoreField.createdAt, descending: true)
            .limit(to: 100)

        return try await firebaseService.fetchDocuments(query: query)
    }

    /// Mevcut kullanıcının yazdığı tüm yorumları getirir.
    /// "Hangi rezervasyonu zaten değerlendirdim?" sorusu için kullanılır.
    func fetchReviewsByCurrentUser() async throws -> [Review] {
        guard let userId = firebaseService.currentUserId else { return [] }

        let query = firebaseService.reviewsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: FirestoreField.createdAt, descending: true)

        return try await firebaseService.fetchDocuments(query: query)
    }

    /// Belirli bir rezervasyon için zaten yorum yapılmış mı?
    func hasReviewed(bookingId: String) async throws -> Bool {
        guard let userId = firebaseService.currentUserId else { return false }

        let query = firebaseService.reviewsCollection
            .whereField("userId", isEqualTo: userId)
            .whereField("bookingId", isEqualTo: bookingId)
            .limit(to: 1)

        let reviews: [Review] = try await firebaseService.fetchDocuments(query: query)
        return !reviews.isEmpty
    }

    // MARK: - Create

    /// Yeni yorum ekler ve tesisin ortalamasını/sayacını atomik olarak günceller.
    /// - Yan etki: tesis sahibine `reviewReceived` bildirimi yazar.
    @discardableResult
    func createReview(
        booking: Booking,
        rating: Double,
        comment: String?,
        userFullName: String,
        userProfileImage: String?
    ) async throws -> Review {
        guard let userId = firebaseService.currentUserId else {
            throw ReviewError.notAuthenticated
        }
        guard userId == booking.userId else {
            throw ReviewError.permissionDenied
        }

        // Aynı booking için ikinci yorum yazılamaz
        if try await hasReviewed(bookingId: booking.id ?? "") {
            throw ReviewError.alreadyReviewed
        }

        let trimmedComment = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalComment = (trimmedComment?.isEmpty == false) ? trimmedComment : nil

        // Review yaratma — MVP'de tek genel puan, diğer 5 boyutu da aynı puanla doldur
        let review = Review(
            facilityId: booking.facilityId,
            pitchId: booking.pitchId,
            bookingId: booking.id ?? "",
            userId: userId,
            userName: userFullName,
            userProfileImage: userProfileImage,
            overallRating: rating,
            cleanlinessRating: rating,
            surfaceRating: rating,
            serviceRating: rating,
            facilitiesRating: rating,
            valueForMoneyRating: rating,
            comment: finalComment,
            isVerified: true
        )

        // Firestore'a yaz
        let documentId = try await firebaseService.createDocument(
            in: firebaseService.reviewsCollection,
            data: review
        )
        var saved = review
        saved.id = documentId

        // Tesis ortalamasını/sayısını atomik güncelle
        try await updateFacilityRating(
            facilityId: booking.facilityId,
            delta: .add(rating: rating)
        )

        // Tesis sahibine bildirim
        await notifyFacilityOwner(
            facilityId: booking.facilityId,
            review: saved
        )

        return saved
    }

    // MARK: - Delete

    /// Kullanıcı kendi yorumunu siler. Tesis ortalaması yeniden hesaplanır.
    func deleteReview(_ review: Review) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw ReviewError.notAuthenticated
        }
        guard review.userId == userId else {
            throw ReviewError.permissionDenied
        }
        guard let id = review.id else {
            throw ReviewError.notFound
        }

        try await firebaseService.deleteDocument(
            from: firebaseService.reviewsCollection,
            documentId: id
        )

        try await updateFacilityRating(
            facilityId: review.facilityId,
            delta: .remove(rating: review.overallRating)
        )
    }

    // MARK: - Helpers

    private enum RatingDelta {
        case add(rating: Double)
        case remove(rating: Double)
    }

    /// `facilities/{id}.averageRating` ve `totalReviews` alanlarını
    /// Firestore transaction ile güncelle (race-safe).
    private func updateFacilityRating(facilityId: String, delta: RatingDelta) async throws {
        let facilityRef = firebaseService.facilitiesCollection.document(facilityId)
        let db = firebaseService.db

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(facilityRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            let data = snapshot.data() ?? [:]
            let currentAvg = (data["averageRating"] as? Double) ?? 0.0
            let currentCount = (data["totalReviews"] as? Int) ?? 0

            let newAvg: Double
            let newCount: Int

            switch delta {
            case .add(let rating):
                newCount = currentCount + 1
                newAvg = ((currentAvg * Double(currentCount)) + rating) / Double(newCount)

            case .remove(let rating):
                newCount = max(0, currentCount - 1)
                if newCount == 0 {
                    newAvg = 0
                } else {
                    let total = (currentAvg * Double(currentCount)) - rating
                    newAvg = max(0, total / Double(newCount))
                }
            }

            // Yuvarlama: 1 ondalık (4.78 → 4.8)
            let roundedAvg = (newAvg * 10).rounded() / 10

            transaction.updateData(
                [
                    "averageRating": roundedAvg,
                    "totalReviews": newCount,
                    FirestoreField.updatedAt: Timestamp(date: Date()),
                ],
                forDocument: facilityRef
            )
            return nil
        }
    }

    /// Yorum yazıldığında tesis sahibine in-app bildirim gönder.
    private func notifyFacilityOwner(facilityId: String, review: Review) async {
        do {
            let facility = try await FacilityService.shared.fetchFacility(id: facilityId)
            await AppNotificationService.shared.notify(
                AppNotification.reviewReceived(
                    adminId: facility.ownerId,
                    facilityName: facility.name,
                    review: review
                )
            )
        } catch {
            // Bildirim aksaklığı yorum yazma akışını bozmaz
        }
    }
}

// MARK: - Review Error
enum ReviewError: LocalizedError {
    case notAuthenticated
    case alreadyReviewed
    case permissionDenied
    case notFound
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Bu işlem için giriş yapmanız gerekiyor."
        case .alreadyReviewed:
            return "Bu rezervasyon için zaten değerlendirme yaptınız."
        case .permissionDenied:
            return "Bu işlem için yetkiniz yok."
        case .notFound:
            return "Yorum bulunamadı."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Review Distribution Helper

/// Bir yorum dizisinden 1-5 yıldız bazlı sayım döndürür.
/// Saha detay sayfasındaki "Rating Breakdown" çubukları için kullanılır.
struct ReviewDistribution {
    /// star: 1...5, value: o yıldıza yuvarlanmış yorum sayısı
    let counts: [Int: Int]
    let total: Int

    init(reviews: [Review]) {
        var counts: [Int: Int] = [:]
        for star in 1...5 { counts[star] = 0 }

        for review in reviews {
            // 1...5 aralığına clamp + yuvarla
            let raw = Int(review.overallRating.rounded())
            let star = min(5, max(1, raw))
            counts[star, default: 0] += 1
        }

        self.counts = counts
        self.total = reviews.count
    }

    /// Belirli bir yıldız için yüzde [0...1]. Toplam 0 ise 0 döner.
    func percentage(for star: Int) -> Double {
        guard total > 0 else { return 0 }
        let count = counts[star] ?? 0
        return Double(count) / Double(total)
    }

    func count(for star: Int) -> Int {
        counts[star] ?? 0
    }
}
