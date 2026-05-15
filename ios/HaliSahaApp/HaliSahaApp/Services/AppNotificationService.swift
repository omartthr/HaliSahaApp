//
//  AppNotificationService.swift
//  HaliSahaApp
//
//  Uygulama içi bildirim (Firestore tabanlı) yönetimi:
//  - Snapshot listener ile real-time liste ve sayım
//  - Yazma, okundu işaretleme, silme
//

import FirebaseFirestore
import Foundation

// MARK: - App Notification Service
@MainActor
final class AppNotificationService: ObservableObject {

    // MARK: - Singleton
    static let shared = AppNotificationService()

    // MARK: - Published State
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    private let firebaseService = FirebaseService.shared

    // MARK: - Private
    private var listener: ListenerRegistration?
    private var listeningUserId: String?

    private init() {}

    // MARK: - Listener

    /// Verilen kullanıcının bildirimlerini real-time dinlemeye başlar.
    /// Aynı kullanıcı için tekrar çağırılırsa no-op.
    func startListening(for userId: String) {
        guard listeningUserId != userId else { return }
        stopListening()
        listeningUserId = userId
        isLoading = true

        let query = firebaseService.notificationsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: FirestoreField.createdAt, descending: true)
            .limit(to: 100)

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false

                if let error {
                    print("⚠️ Notifications listener error: \(error.localizedDescription)")
                    return
                }
                let docs = snapshot?.documents ?? []
                let items = docs.compactMap { try? $0.data(as: AppNotification.self) }
                self.notifications = items
                self.unreadCount = items.filter { !$0.isRead }.count
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        listeningUserId = nil
    }

    /// Çıkış sonrası state'i sıfırla.
    func clearAll() {
        stopListening()
        notifications = []
        unreadCount = 0
    }

    // MARK: - Write

    /// Verilen bildirimi Firestore'a yaz.
    /// Hata durumunda sessizce yutar — bildirim aksaklığı ana akışı bozmaz.
    func notify(_ notification: AppNotification) async {
        do {
            _ = try await firebaseService.createDocument(
                in: firebaseService.notificationsCollection,
                data: notification
            )
        } catch {
            print("⚠️ Notification write failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Read State

    func markAsRead(_ id: String) async {
        do {
            try await firebaseService.updateDocument(
                in: firebaseService.notificationsCollection,
                documentId: id,
                fields: ["isRead": true]
            )
        } catch {
            print("⚠️ markAsRead failed: \(error.localizedDescription)")
        }
    }

    /// Mevcut listede okunmamış olan tüm bildirimleri batch ile okundu yapar.
    func markAllAsRead() async {
        let unread = notifications.filter { !$0.isRead && $0.id != nil }
        guard !unread.isEmpty else { return }

        let batch = firebaseService.db.batch()
        for n in unread {
            guard let id = n.id else { continue }
            let ref = firebaseService.notificationsCollection.document(id)
            batch.updateData(["isRead": true], forDocument: ref)
        }

        do {
            try await batch.commit()
        } catch {
            print("⚠️ markAllAsRead failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    func delete(_ id: String) async {
        do {
            try await firebaseService.deleteDocument(
                from: firebaseService.notificationsCollection,
                documentId: id
            )
        } catch {
            print("⚠️ delete failed: \(error.localizedDescription)")
        }
    }
}
