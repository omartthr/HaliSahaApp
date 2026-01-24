//
//  MainTabView.swift
//  HaliSahaApp
//
//  Ana Tab Bar Navigasyonu - 5 sekme
//
//  Created by Mehmet Mert Mazıcı on 26.12.2025.
//

import SwiftUI

// MARK: - Tab Item Enum
enum TabItem: Int, CaseIterable {
    case home = 0
    case map = 1
    case bookings = 2
    case chat = 3
    case profile = 4
    
    var title: String {
        switch self {
        case .home: return "Keşfet"
        case .map: return "Harita"
        case .bookings: return "Randevularım"
        case .chat: return "Sohbet"
        case .profile: return "Profil"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .map: return "map.fill"
        case .bookings: return "ticket.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }
    
    var unselectedIcon: String {
        switch self {
        case .home: return "house"
        case .map: return "map"
        case .bookings: return "ticket"
        case .chat: return "bubble.left.and.bubble.right"
        case .profile: return "person"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    
    // MARK: - Properties
    @State private var selectedTab: TabItem = .home
    @State private var showGuestAlert = false
    @StateObject private var authService = AuthService.shared
    
    // Badge counts
    @State private var unreadBookings: Int = 0
    @State private var unreadMessages: Int = 3 // Test için
    @State private var unreadNotifications: Int = 2 // Test için
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1: Keşfet (Home)
            NavigationStack {
                HomeView()
            }
            .tag(TabItem.home)
            .tabItem {
                Label(TabItem.home.title, systemImage: selectedTab == .home ? TabItem.home.icon : TabItem.home.unselectedIcon)
            }
            
            // 2: Harita
            NavigationStack {
                MapView()
            }
            .tag(TabItem.map)
            .tabItem {
                Label(TabItem.map.title, systemImage: selectedTab == .map ? TabItem.map.icon : TabItem.map.unselectedIcon)
            }
            
            // 3: Randevularım
            NavigationStack {
                BookingsView()  
            }
            .tag(TabItem.bookings)
            .tabItem {
                Label(TabItem.bookings.title, systemImage: selectedTab == .bookings ? TabItem.bookings.icon : TabItem.bookings.unselectedIcon)
            }
            .badge(unreadBookings > 0 ? unreadBookings : 0)
            
            // 4: Sohbet
            NavigationStack {
                ChatListViewPlaceholder()
            }
            .tag(TabItem.chat)
            .tabItem {
                Label(TabItem.chat.title, systemImage: selectedTab == .chat ? TabItem.chat.icon : TabItem.chat.unselectedIcon)
            }
            .badge(unreadMessages > 0 ? unreadMessages : 0)
            
            // 5: Profil
            NavigationStack {
                ProfileViewPlaceholder()
            }
            .tag(TabItem.profile)
            .tabItem {
                Label(TabItem.profile.title, systemImage: selectedTab == .profile ? TabItem.profile.icon : TabItem.profile.unselectedIcon)
            }
        }
        .tint(Color(hex: "2E7D32"))
        .onChange(of: selectedTab) { _, newTab in
            handleTabChange(newTab)
        }
        .sheet(isPresented: $showGuestAlert) {
            GuestRestrictionSheet(
                onLogin: {
                    showGuestAlert = false
                    try? authService.signOut()
                },
                onDismiss: {
                    showGuestAlert = false
                    selectedTab = .home
                }
            )
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Handle Tab Change
    private func handleTabChange(_ tab: TabItem) {
        // Misafir kullanıcılar için kısıtlama getiriyoz burda
        guard let user = authService.currentUser else { return }
        
        if user.userType == .guest {
            switch tab {
            case .bookings, .chat, .profile:
                showGuestAlert = true
            default:
                break
            }
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - Guest Restriction Sheet
struct GuestRestrictionSheet: View {
    
    var onLogin: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "2E7D32").opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            // Text
            VStack(spacing: 8) {
                Text("Üye Girişi Gerekli")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Bu özelliği kullanmak için üye girişi yapmanız veya kayıt olmanız gerekiyor.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Buttons
            VStack(spacing: 12) {
                PrimaryButton(title: "Giriş Yap / Kayıt Ol", icon: "person.fill") {
                    onLogin()
                }
                
                Button("Vazgeç") {
                    onDismiss()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - (Sonraki adımlarda güncellicez bunları)

// Chat List View Placeholder
struct ChatListViewPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
            
            Text("Sohbet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("ADIM 7'de eklenecek")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sohbet")
    }
}

// Profile View Placeholder
struct ProfileViewPlaceholder: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color(hex: "2E7D32").opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "2E7D32"))
            }
            
            // User Info
            if let user = authService.currentUser {
                VStack(spacing: 4) {
                    Text(user.fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("@\(user.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(user.preferredPosition.icon)
                        Text(user.preferredPosition.displayName)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
            }
            
            Text("ADIM 8'de eklenecek")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 20)
            
            Spacer()
            
            // Logout Button
            PrimaryButton(
                title: "Çıkış Yap",
                icon: "rectangle.portrait.and.arrow.right",
                style: .outline
            ) {
                try? authService.signOut()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profil")
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
