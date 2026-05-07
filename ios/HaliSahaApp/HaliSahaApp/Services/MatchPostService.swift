//
//  MatchPostService.swift
//  HaliSahaApp
//
//  Maç ilanı oluşturma ve listeleme işlemleri
//

import FirebaseFirestore
import Foundation

// MARK: - Match Post Service
final class MatchPostService {

    static let shared = MatchPostService()

    private let firebaseService = FirebaseService.shared

    private init() {}

    // MARK: - Create Match Post
    @MainActor
    func createMatchPost(
        from booking: Booking,
        user: User,
        title: String,
        description: String?,
        neededPlayers: Int,
        currentPlayers: Int,
        maxPlayers: Int,
        preferredPositions: [PlayerPosition],
        skillLevel: SkillLevel,
        costPerPlayer: Double?
    ) async throws -> MatchPost {
        guard let bookingId = booking.id else {
            throw MatchPostServiceError.missingBookingId
        }

        guard let creatorId = firebaseService.currentUserId else {
            throw MatchPostServiceError.notAuthenticated
        }

        guard booking.status == .confirmed && !booking.isPast else {
            throw MatchPostServiceError.invalidBooking
        }

        if try await hasActivePost(for: bookingId) {
            throw MatchPostServiceError.duplicatePost
        }

        var post = MatchPost(
            creatorId: creatorId,
            creatorName: user.fullName,
            creatorProfileImage: user.profileImageURL,
            bookingId: bookingId,
            facilityId: booking.facilityId,
            facilityName: booking.facilityName,
            facilityAddress: booking.facilityAddress,
            pitchName: booking.pitchName,
            matchDate: booking.date,
            startHour: booking.startHour,
            endHour: booking.endHour,
            title: title,
            description: description,
            neededPlayers: neededPlayers,
            currentPlayers: currentPlayers,
            maxPlayers: maxPlayers,
            preferredPositions: preferredPositions,
            skillLevel: skillLevel,
            costPerPlayer: costPerPlayer
        )

        let documentId = try await firebaseService.createDocument(
            in: firebaseService.matchPostsCollection,
            data: post
        )
        post.id = documentId
        return post
    }

    // MARK: - Active Post Check
    func hasActivePost(for bookingId: String) async throws -> Bool {
        let snapshot = try await firebaseService.matchPostsCollection
            .whereField("bookingId", isEqualTo: bookingId)
            .whereField("status", isEqualTo: MatchPostStatus.active.rawValue)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: MatchPost.self) }
            .contains { !$0.isExpired }
    }
}

// MARK: - Match Post Service Error
enum MatchPostServiceError: LocalizedError {
    case notAuthenticated
    case missingBookingId
    case invalidBooking
    case duplicatePost

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "İlan oluşturmak için giriş yapmalısınız."
        case .missingBookingId:
            return "Randevu bilgisi bulunamadı."
        case .invalidBooking:
            return "Sadece yaklaşan ve onaylanmış randevular için ilan oluşturabilirsiniz."
        case .duplicatePost:
            return "Bu randevu için zaten aktif bir maç ilanı var."
        }
    }
}
