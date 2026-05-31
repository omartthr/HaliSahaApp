//
//  ChatDetailView.swift
//  HaliSahaApp
//
//  Tek bir maç grubunun mesajlaşma ekranı.
//  - Tepe: maç context kartı (saha, saat, üye sayısı)
//  - Orta: gerçek-zamanlı mesaj akışı (iMessage tarzı baloncuklar)
//  - Alt: composer (metin alanı + gönder butonu)
//

import SwiftUI

// MARK: - Chat Detail View
struct ChatDetailView: View {

    @StateObject private var viewModel: ChatDetailViewModel
    @FocusState private var isInputFocused: Bool

    init(groupId: String) {
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(groupId: groupId))
    }

    var body: some View {
        VStack(spacing: 0) {
            matchContextCard

            Divider().opacity(0.4)

            messagesScroll

            composer
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Maç Sohbeti")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .alert(
            "Hata",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("Tamam") { viewModel.errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    // MARK: - Match Context Card
    private var matchContextCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "2E7D32").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "2E7D32"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.group?.name ?? "")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(contextDetailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appCardBackground)
    }

    /// "Saha 1 • 22:00 - 23:00 • 2/14 üye" — context card alt satırı.
    private var contextDetailLine: String {
        var parts: [String] = []
        let subtitle = viewModel.matchSubtitle
        if !subtitle.isEmpty {
            parts.append(subtitle)
        }
        let members = viewModel.memberSummary
        if !members.isEmpty {
            parts.append(members)
        }
        return parts.joined(separator: " • ")
    }

    // MARK: - Messages
    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .center, spacing: 6) {
                    Color.clear.frame(height: 8)
                    ForEach(viewModel.sectionedMessages()) { row in
                        switch row {
                        case .dateSeparator(let label, _):
                            DateSeparatorPill(label: label)
                                .padding(.vertical, 6)
                                .id(row.id)
                        case .message(let message):
                            ChatMessageRow(
                                message: message,
                                isMine: isMine(message),
                                showSenderName: shouldShowSenderName(for: message)
                            )
                            .id(row.id)
                            .contextMenu {
                                if isMine(message) && !message.isDeleted {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteMyMessage(message) }
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    Color.clear.frame(height: 4)
                        .id("bottom-anchor")
                }
                .padding(.horizontal, 10)
            }
            .background(Color.appBackground)
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onAppear {
                // İlk yüklemede en alta kaydır
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    scrollToBottom(proxy: proxy, animated: false)
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom-anchor", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
    }

    // MARK: - Composer
    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Mesaj yaz", text: $viewModel.draftText, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 12)
                    .font(.body)
            }
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )

            sendButton
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(
            Color.appBackground
                .overlay(
                    Rectangle()
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    private var sendButton: some View {
        Button {
            Task { await viewModel.send() }
        } label: {
            ZStack {
                Circle()
                    .fill(canSend ? Color(hex: "2E7D32") : Color.gray.opacity(0.35))
                    .frame(width: 38, height: 38)

                if viewModel.isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(!canSend || viewModel.isSending)
        .animation(.easeOut(duration: 0.15), value: canSend)
    }

    private var canSend: Bool {
        !viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Helpers
    private func isMine(_ m: Message) -> Bool {
        AuthService.shared.currentUser?.id == m.senderId && m.messageType != .system
    }

    /// Aynı kişiden art arda mesajlarda yalnız ilkinde gönderen adını göster.
    private func shouldShowSenderName(for message: Message) -> Bool {
        guard message.messageType != .system else { return false }
        if isMine(message) { return false }
        guard let idx = viewModel.messages.firstIndex(where: { $0.id == message.id }) else {
            return true
        }
        if idx == 0 { return true }
        let prev = viewModel.messages[idx - 1]
        return prev.senderId != message.senderId || prev.messageType == .system
    }
}

// MARK: - Date Separator
private struct DateSeparatorPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(Color.primary.opacity(0.06))
            )
    }
}

// MARK: - Single Message Row (bubble OR system pill)
private struct ChatMessageRow: View {
    let message: Message
    let isMine: Bool
    let showSenderName: Bool

    var body: some View {
        if message.messageType == .system {
            HStack {
                Spacer(minLength: 0)
                Text(message.content)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.primary.opacity(0.06))
                    )
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        } else {
            HStack(alignment: .bottom, spacing: 6) {
                if isMine { Spacer(minLength: 40) }

                if !isMine {
                    avatar
                        .frame(width: 28, height: 28)
                        .opacity(showSenderName ? 1 : 0)
                }

                VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                    if showSenderName && !isMine {
                        Text(message.senderName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 6)
                    }

                    bubble
                }

                if !isMine { Spacer(minLength: 40) }
            }
            .padding(.vertical, 1)
        }
    }

    private var bubble: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
            Text(message.isDeleted ? "Mesaj silindi" : message.content)
                .italic(message.isDeleted)
                .font(.body)
                .foregroundStyle(isMine ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(bubbleBackground)
                .clipShape(BubbleShape(isMine: isMine))

            Text(message.formattedTime)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
        }
    }

    private var bubbleBackground: some View {
        SwiftUI.Group {
            if isMine {
                LinearGradient(
                    colors: [Color(hex: "2E7D32"), Color(hex: "1B5E20")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color.appCardBackground
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "2E7D32").opacity(0.18))
            Text(initials(of: message.senderName))
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color(hex: "2E7D32"))
        }
    }

    private func initials(of name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first.map(String.init) ?? ""
        let last = parts.dropFirst().first.map(String.init) ?? ""
        let f = first.first.map(String.init) ?? "?"
        let l = last.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }
}

// MARK: - Bubble Shape (rounded with "tail" corner)
private struct BubbleShape: Shape {
    let isMine: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailRadius: CGFloat = 4
        let tl = isMine ? radius : radius
        let tr = isMine ? radius : radius
        let bl = isMine ? radius : tailRadius
        let br = isMine ? tailRadius : radius
        return Path(roundedCornerPath(
            in: rect, topLeft: tl, topRight: tr, bottomLeft: bl, bottomRight: br
        ).cgPath)
    }

    private func roundedCornerPath(
        in rect: CGRect,
        topLeft: CGFloat,
        topRight: CGFloat,
        bottomLeft: CGFloat,
        bottomRight: CGFloat
    ) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
            radius: topRight, startAngle: -.pi / 2, endAngle: 0, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
            radius: bottomRight, startAngle: 0, endAngle: .pi / 2, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
            radius: bottomLeft, startAngle: .pi / 2, endAngle: .pi, clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
            radius: topLeft, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true
        )
        path.close()
        return path
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ChatDetailView(groupId: "preview")
    }
}
