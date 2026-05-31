//
//  ChatListViewModel.swift
//  HaliSahaApp
//
//  Kullanıcının üye olduğu sohbet gruplarının gerçek-zamanlı listesini yönetir.
//

import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
final class ChatListViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var groups: [Group] = []
    @Published private(set) var isLoading: Bool = true
    @Published var errorMessage: String?

    // MARK: - Private
    private let chatService = ChatService.shared
    private var listener: ListenerRegistration?

    // MARK: - Lifecycle
    func start() {
        guard listener == nil else { return }
        isLoading = true

        listener = chatService.observeMyGroups { [weak self] groups in
            Task { @MainActor in
                guard let self else { return }
                self.groups = groups
                self.isLoading = false
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Derived
    /// Toplam okunmamış sohbet sayısı (badge için).
    /// MVP: lastMessage.timestamp > kullanıcı son okuma zamanı yerine basitçe
    /// "lastMessage var ve gönderen biz değiliz" kabaca yaklaşımı; gerçek
    /// okunmamış sayısı per-message `readBy` üzerinden hesaplanır (sonra).
    var totalUnread: Int {
        guard let myId = AuthService.shared.currentUser?.id else { return 0 }
        return groups.filter { group in
            guard let last = group.lastMessage else { return false }
            return last.senderId != myId
        }.count
    }
}
