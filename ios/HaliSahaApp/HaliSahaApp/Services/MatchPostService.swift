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

        // İlana bağlı sohbet grubunu (matchGroup) önce oluşturuyoruz; başarısız
        // olursa ilan da oluşmasın ki "sohbeti olmayan ilan" durumu yaşanmasın.
        // Idempotent: ChatService aynı booking için varsa mevcut grubu döndürür.
        let group = try await ChatService.shared.createMatchGroup(
            for: booking,
            creator: user,
            maxPlayers: maxPlayers
        )

        var post = MatchPost(
            creatorId: creatorId,
            creatorName: user.fullName,
            creatorProfileImage: user.profileImageURL,
            groupId: group.id,
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

    // MARK: - Observe Single Post (real-time)
    /// Tek bir ilanı gerçek-zamanlı dinler. Detay ekranında / başvuranlar
    /// ekranında host accept/reject yaptıkça anlık güncellenmek için.
    @discardableResult
    func observePost(id: String, onUpdate: @escaping (MatchPost?) -> Void) -> ListenerRegistration {
        firebaseService.matchPostsCollection.document(id)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ observePost error: \(error.localizedDescription)")
                    onUpdate(nil)
                    return
                }
                onUpdate(try? snapshot?.data(as: MatchPost.self))
            }
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

    // MARK: - Apply / Withdraw (Oyuncu)

    /// Oyuncu ilana başvurur. `applicantIds`'e KENDİSİNİ ekler ve ilan sahibine
    /// (host) bildirim gönderir. Firestore kuralı self-apply'a izin verir.
    @MainActor
    func applyToPost(_ post: MatchPost, applicant: User) async throws {
        guard let postId = post.id else { throw MatchPostServiceError.missingBookingId }
        guard let applicantId = firebaseService.currentUserId else {
            throw MatchPostServiceError.notAuthenticated
        }
        guard post.canApply(applicantId) else {
            throw MatchPostServiceError.cannotApply
        }

        try await firebaseService.matchPostsCollection.document(postId).updateData([
            "applicantIds": FieldValue.arrayUnion([applicantId]),
            FirestoreField.updatedAt: Timestamp(date: Date())
        ])

        // Host'a bildirim
        await AppNotificationService.shared.notify(
            AppNotification.joinRequestReceived(
                userId: post.creatorId,
                applicantName: applicant.fullName,
                postId: postId
            )
        )
    }

    /// Oyuncu başvurusunu geri çeker. Firestore kuralı self-withdraw'a izin verir.
    /// Zaten kabul edilmişse iptal değil; bu fonksiyon yalnız `applicantIds` durumu için.
    @MainActor
    func withdrawApplication(from post: MatchPost) async throws {
        guard let postId = post.id else { throw MatchPostServiceError.missingBookingId }
        guard let userId = firebaseService.currentUserId else {
            throw MatchPostServiceError.notAuthenticated
        }
        guard post.applicantIds.contains(userId) else {
            throw MatchPostServiceError.notApplicant
        }

        try await firebaseService.matchPostsCollection.document(postId).updateData([
            "applicantIds": FieldValue.arrayRemove([userId]),
            FirestoreField.updatedAt: Timestamp(date: Date())
        ])
    }

    // MARK: - Accept / Reject (Host)

    /// Host bir başvuruyu kabul eder. Tek batch'te:
    ///   1) MatchPost: applicantIds -= applicant, acceptedIds += applicant, currentPlayers += 1
    ///   2) Group: memberIds += applicant
    ///   3) Sistem mesajı: "X gruba katıldı"
    /// Sonrasında batch dışında oyuncuya bildirim gönderilir.
    @MainActor
    func acceptApplication(post: MatchPost, applicant: User) async throws {
        guard let postId = post.id else { throw MatchPostServiceError.missingBookingId }
        guard let groupId = post.groupId else { throw MatchPostServiceError.missingGroupId }
        guard let applicantId = applicant.id else { throw MatchPostServiceError.invalidApplicant }
        guard let hostId = firebaseService.currentUserId else {
            throw MatchPostServiceError.notAuthenticated
        }
        guard hostId == post.creatorId else { throw MatchPostServiceError.permissionDenied }
        guard post.applicantIds.contains(applicantId) else {
            throw MatchPostServiceError.notApplicant
        }
        guard !post.isFull else { throw MatchPostServiceError.postFull }

        let postRef = firebaseService.matchPostsCollection.document(postId)
        let groupRef = firebaseService.groupsCollection.document(groupId)
        let messagesRef = firebaseService.messagesCollection(for: groupId)

        let batch = firebaseService.db.batch()
        let now = Date()
        let timestamp = Timestamp(date: now)

        // 1) Post
        batch.updateData([
            "applicantIds": FieldValue.arrayRemove([applicantId]),
            "acceptedIds": FieldValue.arrayUnion([applicantId]),
            "currentPlayers": FieldValue.increment(Int64(1)),
            FirestoreField.updatedAt: timestamp
        ], forDocument: postRef)

        // 2) Group
        batch.updateData([
            FirestoreField.memberIds: FieldValue.arrayUnion([applicantId]),
            FirestoreField.updatedAt: timestamp
        ], forDocument: groupRef)

        // 3) Sistem mesajı (host'un kimliğiyle — Firestore kuralı senderId == auth.uid bekler)
        let sysMessage = Message(
            groupId: groupId,
            senderId: hostId,
            senderName: "Sistem",
            content: "\(applicant.fullName) gruba katıldı",
            messageType: .system,
            readBy: [hostId],
            createdAt: now,
            updatedAt: now
        )
        let encoded = try Firestore.Encoder().encode(sysMessage)
        batch.setData(encoded, forDocument: messagesRef.document())

        try await batch.commit()

        // 4) Oyuncuya bildirim
        await AppNotificationService.shared.notify(
            AppNotification.joinRequestAccepted(
                userId: applicantId,
                facilityName: post.facilityName,
                groupId: groupId
            )
        )
    }

    /// Host başvuruyu reddeder. Post: applicantIds -= applicant, rejectedIds += applicant.
    /// Grup üyeliği etkilenmez; oyuncuya bildirim gönderilir.
    @MainActor
    func rejectApplication(post: MatchPost, applicant: User, reason: String? = nil) async throws {
        guard let postId = post.id else { throw MatchPostServiceError.missingBookingId }
        guard let applicantId = applicant.id else { throw MatchPostServiceError.invalidApplicant }
        guard let hostId = firebaseService.currentUserId else {
            throw MatchPostServiceError.notAuthenticated
        }
        guard hostId == post.creatorId else { throw MatchPostServiceError.permissionDenied }
        guard post.applicantIds.contains(applicantId) else {
            throw MatchPostServiceError.notApplicant
        }

        try await firebaseService.matchPostsCollection.document(postId).updateData([
            "applicantIds": FieldValue.arrayRemove([applicantId]),
            "rejectedIds": FieldValue.arrayUnion([applicantId]),
            FirestoreField.updatedAt: Timestamp(date: Date())
        ])

        await AppNotificationService.shared.notify(
            AppNotification.joinRequestRejected(
                userId: applicantId,
                facilityName: post.facilityName,
                postId: postId,
                reason: reason
            )
        )
    }
}

// MARK: - Match Post Service Error
enum MatchPostServiceError: LocalizedError {
    case notAuthenticated
    case missingBookingId
    case missingGroupId
    case invalidBooking
    case duplicatePost
    case cannotApply
    case notApplicant
    case invalidApplicant
    case permissionDenied
    case postFull

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "İlan oluşturmak için giriş yapmalısınız."
        case .missingBookingId:
            return "Randevu bilgisi bulunamadı."
        case .missingGroupId:
            return "Bu ilana bağlı bir sohbet grubu bulunamadı."
        case .invalidBooking:
            return "Sadece yaklaşan ve onaylanmış randevular için ilan oluşturabilirsiniz."
        case .duplicatePost:
            return "Bu randevu için zaten aktif bir maç ilanı var."
        case .cannotApply:
            return "Bu ilana başvurma koşulları sağlanmıyor."
        case .notApplicant:
            return "Bu oyuncu ilana başvurmuş görünmüyor."
        case .invalidApplicant:
            return "Geçersiz başvuran bilgisi."
        case .permissionDenied:
            return "Bu işlem için yetkiniz yok."
        case .postFull:
            return "Kontenjan dolu, yeni oyuncu eklenemez."
        }
    }
}
