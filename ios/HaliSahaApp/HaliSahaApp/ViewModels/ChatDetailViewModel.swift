//
//  ChatDetailViewModel.swift
//  HaliSahaApp
//
//  Tek bir grubun mesaj akışını ve mesaj gönderme operasyonlarını yönetir.
//

import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
final class ChatDetailViewModel: ObservableObject {

    // MARK: - Inputs
    let groupId: String

    // MARK: - Published State
    @Published private(set) var group: Group?
    @Published private(set) var messages: [Message] = []
    @Published private(set) var isSending: Bool = false
    @Published var draftText: String = ""
    @Published var errorMessage: String?

    // MARK: - Private
    private let chatService = ChatService.shared
    private var groupListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    // MARK: - Init
    init(groupId: String) {
        self.groupId = groupId
    }

    // MARK: - Lifecycle
    func start() {
        if groupListener == nil {
            groupListener = chatService.observeGroup(id: groupId) { [weak self] g in
                Task { @MainActor in
                    self?.group = g
                }
            }
        }
        if messagesListener == nil {
            messagesListener = chatService.observeMessages(groupId: groupId) { [weak self] msgs in
                Task { @MainActor in
                    guard let self else { return }
                    self.messages = msgs
                    await self.markVisibleAsRead(msgs)
                }
            }
        }
    }

    func stop() {
        groupListener?.remove()
        messagesListener?.remove()
        groupListener = nil
        messagesListener = nil
    }

    deinit {
        groupListener?.remove()
        messagesListener?.remove()
    }

    // MARK: - Send
    func send() async {
        let content = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard !isSending else { return }
        guard let user = AuthService.shared.currentUser else {
            errorMessage = "Mesaj göndermek için giriş yapmalısınız."
            return
        }

        isSending = true
        defer { isSending = false }

        // Önce input'u temizle ki kullanıcı bekleme algılamasın; başarısızlıkta geri koyacağız.
        let snapshot = draftText
        draftText = ""

        do {
            try await chatService.sendTextMessage(
                groupId: groupId,
                sender: user,
                content: content
            )
        } catch {
            draftText = snapshot
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete (own message, 15 dk içinde)
    func deleteMyMessage(_ message: Message) async {
        guard let id = message.id else { return }
        guard let myId = AuthService.shared.currentUser?.id,
              message.senderId == myId else { return }
        do {
            try await chatService.deleteMyMessage(groupId: groupId, messageId: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Read receipts
    /// Görüntülenen mesajlardan henüz okunmamış olanları toplu işaretler.
    private func markVisibleAsRead(_ msgs: [Message]) async {
        guard let myId = AuthService.shared.currentUser?.id else { return }
        let unreadIds = msgs
            .filter { $0.senderId != myId && !$0.readBy.contains(myId) }
            .compactMap { $0.id }
        guard !unreadIds.isEmpty else { return }
        try? await chatService.markMessagesRead(groupId: groupId, messageIds: unreadIds)
    }

    // MARK: - UI Helpers

    /// Maç başlangıcına kalan süre (matchGroup için).
    /// `linkedBookingId` üzerinden saati çıkarmak için ayrı fetch yerine
    /// MVP'de `group.description` zaten "Saha • HH:00 - HH:00" formatında.
    var matchSubtitle: String {
        group?.description ?? ""
    }

    /// Gruptaki üye sayısı / max gösterimi.
    var memberSummary: String {
        guard let g = group else { return "" }
        return "\(g.memberCount)/\(g.maxMembers) üye"
    }

    /// Mesajları gün ayraçlarıyla birlikte hazır liste hâline getirir.
    /// `nil` sender = gün ayracı.
    func sectionedMessages() -> [ChatRow] {
        var rows: [ChatRow] = []
        var lastDayKey: String?

        for message in messages {
            let dayKey = Self.dayKey(for: message.createdAt)
            if dayKey != lastDayKey {
                rows.append(.dateSeparator(label: message.formattedDate, id: dayKey))
                lastDayKey = dayKey
            }
            rows.append(.message(message))
        }
        return rows
    }

    private static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Chat Row
enum ChatRow: Identifiable, Hashable {
    case dateSeparator(label: String, id: String)
    case message(Message)

    var id: String {
        switch self {
        case .dateSeparator(_, let id): return "sep-\(id)"
        case .message(let m): return "msg-\(m.id ?? UUID().uuidString)"
        }
    }
}
