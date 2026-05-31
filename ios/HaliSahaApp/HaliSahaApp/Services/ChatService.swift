//
//  ChatService.swift
//  HaliSahaApp
//
//  Sohbet (grup + mesaj) servisleri.
//  Snapshot listener'lar ile gerçek-zamanlı liste/mesaj akışı sağlar.
//

import FirebaseFirestore
import Foundation

// MARK: - Chat Service
final class ChatService {

    static let shared = ChatService()

    private let firebaseService = FirebaseService.shared

    /// Tek bir mesaj baskı limiti (Firestore kuralı da aynı sayıyı zorluyor).
    static let maxMessageLength = 2000

    /// Liste sorgusunda tek sayfa boyutu.
    static let defaultMessagePageSize = 50

    private init() {}

    // MARK: - Group Observers

    /// Kullanıcının üye olduğu (aktif) sohbet gruplarını gerçek-zamanlı dinler.
    /// Dönen `ListenerRegistration`'ı caller, view kapanırken `.remove()` ile durdurur.
    ///
    /// NOT: Sorgu yalnız `memberIds arrayContains uid` filtresi kullanır; `isActive`
    /// kontrolü ve `updatedAt` sıralaması client-side yapılır. Böylece Firestore'da
    /// composite index gerekmez ve kullanıcının ilk açılışta indeks oluşturma
    /// hatası alma riski kalmaz.
    @discardableResult
    func observeMyGroups(onUpdate: @escaping ([Group]) -> Void) -> ListenerRegistration? {
        guard let uid = firebaseService.currentUserId else {
            onUpdate([])
            return nil
        }

        let query = firebaseService.groupsCollection
            .whereField(FirestoreField.memberIds, arrayContains: uid)

        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                let ns = error as NSError
                print("❌ observeMyGroups error: \(error.localizedDescription)")
                print("   uid: \(uid)")
                print("   query: groups where memberIds arrayContains \(uid)")
                print("   code: \(ns.code) domain: \(ns.domain)")
                onUpdate([])
                return
            }
            let groups = (snapshot?.documents ?? [])
                .compactMap { try? $0.data(as: Group.self) }
                .filter { $0.isActive }
                .sorted { $0.updatedAt > $1.updatedAt }
            onUpdate(groups)
        }
    }

    /// Tek bir grubu gerçek-zamanlı dinler (ChatDetailView başlığı / üye listesi için).
    @discardableResult
    func observeGroup(id: String, onUpdate: @escaping (Group?) -> Void) -> ListenerRegistration {
        firebaseService.groupsCollection.document(id)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ observeGroup error: \(error.localizedDescription)")
                    onUpdate(nil)
                    return
                }
                onUpdate(try? snapshot?.data(as: Group.self))
            }
    }

    // MARK: - Group Fetch / Create

    @MainActor
    func fetchGroup(id: String) async throws -> Group {
        try await firebaseService.fetchDocument(
            from: firebaseService.groupsCollection,
            documentId: id
        )
    }

    /// Belirli bir rezervasyon için zaten oluşturulmuş bir matchGroup var mı?
    /// Aynı booking için iki grup açılmasını önler.
    ///
    /// NOT: Firestore kuralı "yalnız üyeler grupları okuyabilir" diyor. Bu yüzden
    /// sorguya `memberIds arrayContains uid` filtresi şart — yoksa kural sorguyu
    /// "ihlal edebilir" diye reddeder. Booking sahibi (ilanı açan kişi) zaten
    /// gruba üye olduğu için bu filtre idempotency'yi bozmaz.
    ///
    /// `groupType` kontrolü composite index gerektirmemesi için client-side yapılır.
    func existingMatchGroupId(for bookingId: String) async throws -> String? {
        guard let uid = firebaseService.currentUserId else { return nil }
        let snapshot = try await firebaseService.groupsCollection
            .whereField("linkedBookingId", isEqualTo: bookingId)
            .whereField(FirestoreField.memberIds, arrayContains: uid)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Group.self) }
            .first(where: { $0.groupType == .matchGroup })?
            .id
    }

    /// Booking + (opsiyonel) ilan bilgisiyle matchGroup oluşturur.
    /// Kurucu otomatik tek üye olur; oyuncular sonradan `addMember` ile eklenir.
    @MainActor
    func createMatchGroup(
        for booking: Booking,
        creator: User,
        maxPlayers: Int
    ) async throws -> Group {
        guard let creatorId = firebaseService.currentUserId else {
            throw ChatServiceError.notAuthenticated
        }
        guard let bookingId = booking.id else {
            throw ChatServiceError.missingBookingId
        }

        // Idempotency: aynı booking için varsa onu döndür.
        if let existingId = try await existingMatchGroupId(for: bookingId) {
            return try await fetchGroup(id: existingId)
        }

        let name = "\(booking.facilityName) • \(booking.shortDate)"
        let description = "\(booking.pitchName) • \(booking.timeSlotString)"

        var group = Group(
            name: name,
            description: description,
            imageURL: nil,
            creatorId: creatorId,
            adminIds: [creatorId],
            memberIds: [creatorId],
            maxMembers: maxPlayers,
            isPublic: false,
            groupType: .matchGroup,
            linkedBookingId: bookingId
        )

        let docId = try await firebaseService.createDocument(
            in: firebaseService.groupsCollection,
            data: group
        )
        group.id = docId

        // Açılış sistem mesajı.
        try? await sendSystemMessage(
            groupId: docId,
            content: "\(creator.fullName) maç sohbetini başlattı"
        )

        return group
    }

    // MARK: - Membership

    /// Bir kullanıcıyı gruba ekler ve "X gruba katıldı" sistem mesajı atar.
    /// Yalnız kurucu/admin çağırmalı (Firestore kuralı doğrular).
    @MainActor
    func addMember(groupId: String, userId: String, userName: String) async throws {
        let groupRef = firebaseService.groupsCollection.document(groupId)
        let messagesRef = firebaseService.messagesCollection(for: groupId)

        let batch = firebaseService.db.batch()

        batch.updateData([
            FirestoreField.memberIds: FieldValue.arrayUnion([userId]),
            FirestoreField.updatedAt: Timestamp(date: Date())
        ], forDocument: groupRef)

        let sysMsg = makeSystemMessage(
            groupId: groupId,
            content: "\(userName) gruba katıldı"
        )
        let encoded = try Firestore.Encoder().encode(sysMsg)
        batch.setData(encoded, forDocument: messagesRef.document())

        try await batch.commit()
    }

    /// Bir kullanıcıyı gruptan çıkarır (yalnız kurucu/admin).
    @MainActor
    func removeMember(groupId: String, userId: String, userName: String) async throws {
        let groupRef = firebaseService.groupsCollection.document(groupId)
        let messagesRef = firebaseService.messagesCollection(for: groupId)

        let batch = firebaseService.db.batch()

        batch.updateData([
            FirestoreField.memberIds: FieldValue.arrayRemove([userId]),
            FirestoreField.updatedAt: Timestamp(date: Date())
        ], forDocument: groupRef)

        let sysMsg = makeSystemMessage(
            groupId: groupId,
            content: "\(userName) gruptan çıkarıldı"
        )
        let encoded = try Firestore.Encoder().encode(sysMsg)
        batch.setData(encoded, forDocument: messagesRef.document())

        try await batch.commit()
    }

    /// Kullanıcı gruptan KENDİSİNİ çıkarır (Firestore kuralı: rule c).
    @MainActor
    func leaveGroup(groupId: String, userName: String) async throws {
        guard let uid = firebaseService.currentUserId else {
            throw ChatServiceError.notAuthenticated
        }

        try await firebaseService.groupsCollection.document(groupId).updateData([
            FirestoreField.memberIds: FieldValue.arrayRemove([uid]),
            FirestoreField.updatedAt: Timestamp(date: Date())
        ])

        // Sistem mesajı: artık üye olmadığımız için yazamayız; bilerek atlanıyor.
        _ = userName
    }

    // MARK: - Messages

    /// Bir grubun mesajlarını gerçek-zamanlı dinler (eski → yeni sıralı).
    /// `limit` ile son N mesajı çeker; pagination ileride `loadMore` ile yapılır.
    @discardableResult
    func observeMessages(
        groupId: String,
        limit: Int = ChatService.defaultMessagePageSize,
        onUpdate: @escaping ([Message]) -> Void
    ) -> ListenerRegistration {
        firebaseService.messagesCollection(for: groupId)
            .order(by: FirestoreField.createdAt, descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ observeMessages error: \(error.localizedDescription)")
                    onUpdate([])
                    return
                }
                let messages = (snapshot?.documents ?? [])
                    .compactMap { try? $0.data(as: Message.self) }
                    .reversed()
                onUpdate(Array(messages))
            }
    }

    /// Metin mesajı gönderir. Aynı batch'te grup `lastMessage` önizlemesini günceller.
    @MainActor
    func sendTextMessage(
        groupId: String,
        sender: User,
        content: String
    ) async throws {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ChatServiceError.emptyMessage }
        guard trimmed.count <= ChatService.maxMessageLength else {
            throw ChatServiceError.messageTooLong
        }
        guard let senderId = firebaseService.currentUserId else {
            throw ChatServiceError.notAuthenticated
        }

        let now = Date()
        let message = Message(
            groupId: groupId,
            senderId: senderId,
            senderName: sender.fullName,
            senderProfileImage: sender.profileImageURL,
            content: trimmed,
            messageType: .text,
            readBy: [senderId],
            createdAt: now,
            updatedAt: now
        )

        let preview = LastMessagePreview(
            senderId: senderId,
            senderName: sender.fullName,
            content: trimmed,
            timestamp: now,
            messageType: .text
        )

        try await commitMessage(message, preview: preview, groupId: groupId)
    }

    /// "X gruba katıldı / ayrıldı" gibi sistem mesajları için.
    /// NOT: Firestore kuralı `senderId == auth.uid` zorluyor; bu yüzden sistem mesajını
    /// işlemi tetikleyen kullanıcının (örn. host'un) kimliğiyle gönderiyoruz.
    /// `messageType: .system` ile UI'da ortalanmış pill olarak render edilir.
    @MainActor
    func sendSystemMessage(groupId: String, content: String) async throws {
        guard let senderId = firebaseService.currentUserId else {
            throw ChatServiceError.notAuthenticated
        }

        let now = Date()
        let message = Message(
            groupId: groupId,
            senderId: senderId,
            senderName: "Sistem",
            senderProfileImage: nil,
            content: content,
            messageType: .system,
            readBy: [senderId],
            createdAt: now,
            updatedAt: now
        )

        let preview = LastMessagePreview(
            senderId: senderId,
            senderName: "Sistem",
            content: content,
            timestamp: now,
            messageType: .system
        )

        try await commitMessage(message, preview: preview, groupId: groupId)
    }

    /// Verilen mesajları kullanıcı için "okundu" olarak işaretler.
    /// Tek tek arrayUnion yerine tek batch ile gönderilir.
    @MainActor
    func markMessagesRead(groupId: String, messageIds: [String]) async throws {
        guard let uid = firebaseService.currentUserId else { return }
        guard !messageIds.isEmpty else { return }

        let messagesRef = firebaseService.messagesCollection(for: groupId)
        let batch = firebaseService.db.batch()

        for id in messageIds {
            batch.updateData(
                [
                    "readBy": FieldValue.arrayUnion([uid]),
                    FirestoreField.updatedAt: Timestamp(date: Date())
                ],
                forDocument: messagesRef.document(id)
            )
        }

        try await batch.commit()
    }

    /// Kendi mesajını soft-delete eder (15 dakika içinde; Firestore kuralı doğrular).
    @MainActor
    func deleteMyMessage(groupId: String, messageId: String) async throws {
        try await firebaseService.messagesCollection(for: groupId)
            .document(messageId)
            .updateData([
                "isDeleted": true,
                "content": "",
                FirestoreField.updatedAt: Timestamp(date: Date())
            ])
    }

    // MARK: - Private Helpers

    /// Mesajı yazarken aynı batch'te grup önizlemesini de günceller.
    private func commitMessage(
        _ message: Message,
        preview: LastMessagePreview,
        groupId: String
    ) async throws {
        let messagesRef = firebaseService.messagesCollection(for: groupId)
        let groupRef = firebaseService.groupsCollection.document(groupId)

        let batch = firebaseService.db.batch()

        let messageEncoded: [String: Any]
        let previewEncoded: [String: Any]
        do {
            messageEncoded = try Firestore.Encoder().encode(message)
            previewEncoded = try Firestore.Encoder().encode(preview)
        } catch {
            throw ChatServiceError.encodingFailed
        }

        batch.setData(messageEncoded, forDocument: messagesRef.document())
        batch.updateData([
            "lastMessage": previewEncoded,
            FirestoreField.updatedAt: Timestamp(date: Date())
        ], forDocument: groupRef)

        try await batch.commit()
    }

    private func makeSystemMessage(groupId: String, content: String) -> Message {
        guard let senderId = firebaseService.currentUserId else {
            return Message(
                groupId: groupId,
                senderId: "system",
                senderName: "Sistem",
                content: content,
                messageType: .system
            )
        }
        let now = Date()
        return Message(
            groupId: groupId,
            senderId: senderId,
            senderName: "Sistem",
            senderProfileImage: nil,
            content: content,
            messageType: .system,
            readBy: [senderId],
            createdAt: now,
            updatedAt: now
        )
    }
}

// MARK: - Chat Service Error
enum ChatServiceError: LocalizedError {
    case notAuthenticated
    case missingBookingId
    case emptyMessage
    case messageTooLong
    case encodingFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Sohbet için giriş yapmalısınız."
        case .missingBookingId:
            return "Rezervasyon bilgisi bulunamadı."
        case .emptyMessage:
            return "Boş mesaj gönderilemez."
        case .messageTooLong:
            return "Mesaj 2000 karakteri aşamaz."
        case .encodingFailed:
            return "Mesaj kodlanamadı."
        case .permissionDenied:
            return "Bu işlem için yetkiniz yok."
        }
    }
}
