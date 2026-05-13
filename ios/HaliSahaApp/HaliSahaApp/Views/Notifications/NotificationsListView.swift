//
//  NotificationsListView.swift
//  HaliSahaApp
//
//  Uygulama içi bildirim listesi (real-time, AppNotificationService listener'ına bağlı)
//

import SwiftUI

// MARK: - Notifications List View
struct NotificationsListView: View {

    // MARK: - Dependencies
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = AppNotificationService.shared

    // MARK: - Body
    var body: some View {
        NavigationStack {
            SwiftUI.Group {
                if service.isLoading && service.notifications.isEmpty {
                    LoadingView()
                } else if service.notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "Henüz Bildirim Yok",
                        message:
                            "Rezervasyonların ve maç hatırlatmaların burada görünür."
                    )
                } else {
                    listContent
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if service.unreadCount > 0 {
                        Button {
                            Task { await service.markAllAsRead() }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                Text("Tümünü Okundu Yap")
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }

    // MARK: - List
    private var listContent: some View {
        List {
            ForEach(service.notifications) { notification in
                NotificationRow(notification: notification)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.appCardBackground)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let id = notification.id {
                                Task { await service.delete(id) }
                            }
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }

                        if !notification.isRead, let id = notification.id {
                            Button {
                                Task { await service.markAsRead(id) }
                            } label: {
                                Label("Okundu", systemImage: "envelope.open")
                            }
                            .tint(Color(hex: "2E7D32"))
                        }
                    }
                    .onTapGesture {
                        if !notification.isRead, let id = notification.id {
                            Task { await service.markAsRead(id) }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // İkon
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: notification.icon)
                    .font(.system(size: 18))
                    .foregroundColor(typeColor)
            }

            // İçerik
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .medium : .semibold)
                        .foregroundColor(.primary)

                    Spacer(minLength: 4)

                    if !notification.isRead {
                        Circle()
                            .fill(Color(hex: "2E7D32"))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                    }
                }

                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                Text(notification.relativeTime)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }

    private var typeColor: Color {
        switch notification.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "gray": return .gray
        default: return Color(hex: "2E7D32")
        }
    }
}

// MARK: - Preview
#Preview {
    NotificationsListView()
}
