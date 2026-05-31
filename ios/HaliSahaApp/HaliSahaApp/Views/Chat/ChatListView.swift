//
//  ChatListView.swift
//  HaliSahaApp
//
//  Kullanıcının üye olduğu sohbet gruplarının listesi (real-time).
//

import SwiftUI

// MARK: - Chat List View
struct ChatListView: View {

    @StateObject private var viewModel = ChatListViewModel()

    var body: some View {
        SwiftUI.Group {
            if viewModel.isLoading && viewModel.groups.isEmpty {
                LoadingView()
            } else if viewModel.groups.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "Henüz Sohbet Yok",
                    message: "Bir maç ilanı açtığında veya bir ilana katıldığında sohbet burada görünür."
                )
            } else {
                listContent
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Sohbet")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - List
    private var listContent: some View {
        List {
            ForEach(viewModel.groups) { group in
                ZStack {
                    // Hidden NavigationLink to remove disclosure chevron
                    NavigationLink(
                        destination: ChatDetailView(groupId: group.id ?? "")
                    ) {
                        EmptyView()
                    }
                    .opacity(0)

                    ChatListRow(group: group)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - Chat List Row
struct ChatListRow: View {

    let group: Group

    private var isMine: Bool {
        AuthService.shared.currentUser?.id == group.lastMessage?.senderId
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar (group icon or photo)
            avatar

            // Title + last message
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(group.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    if let last = group.lastMessage {
                        Text(last.timeAgo)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    if let last = group.lastMessage {
                        if last.messageType == .system {
                            Text(last.previewText)
                                .italic()
                                .foregroundStyle(.secondary)
                        } else {
                            if !isMine {
                                Text("\(last.senderName.firstName):")
                                    .foregroundStyle(.secondary)
                            }
                            Text(last.previewText)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(group.description ?? "Henüz mesaj yok")
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    Spacer(minLength: 0)
                }
                .font(.footnote)
                .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(hex: "2E7D32"),
                        Color(hex: "1B5E20")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 48, height: 48)

            Image(systemName: group.groupType.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Helpers
private extension String {
    /// "Mehmet Yılmaz" → "Mehmet"
    var firstName: String {
        components(separatedBy: " ").first ?? self
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ChatListView()
    }
}
