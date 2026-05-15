//
//  SuperAdminTabView.swift
//  HaliSahaApp
//
//  Süper admin (geliştirici) paneli ana tab bar.
//  Routing ContentView'da: userType == .superAdmin → bu view.
//  Süper admin hesapları sadece manuel olarak Firestore Console'da
//  users/{uid}.userType = "superAdmin" yapılarak oluşturulur.
//

import SwiftUI

// MARK: - Super Admin Tab Item
enum SuperAdminTabItem: Int, CaseIterable {
    case pending = 0
    case admins = 1
    case stats = 2

    var title: String {
        switch self {
        case .pending: return "Onay Bekleyenler"
        case .admins:  return "İşletmeciler"
        case .stats:   return "İstatistik"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "tray.full.fill"
        case .admins:  return "person.2.fill"
        case .stats:   return "chart.bar.xaxis"
        }
    }

    var unselectedIcon: String {
        switch self {
        case .pending: return "tray.full"
        case .admins:  return "person.2"
        case .stats:   return "chart.bar"
        }
    }
}

// MARK: - Super Admin Tab View
struct SuperAdminTabView: View {

    @State private var selectedTab: SuperAdminTabItem = .pending
    @State private var pendingCount: Int = 0
    @StateObject private var authService = AuthService.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Tab 1: Pending Approvals
            NavigationStack {
                PendingApprovalsListView(onCountChange: { count in
                    pendingCount = count
                })
            }
            .tag(SuperAdminTabItem.pending)
            .tabItem {
                Label(
                    SuperAdminTabItem.pending.title,
                    systemImage: selectedTab == .pending
                        ? SuperAdminTabItem.pending.icon
                        : SuperAdminTabItem.pending.unselectedIcon
                )
            }
            .badge(pendingCount > 0 ? pendingCount : 0)

            // MARK: - Tab 2: All Admins
            NavigationStack {
                AllAdminsListView()
            }
            .tag(SuperAdminTabItem.admins)
            .tabItem {
                Label(
                    SuperAdminTabItem.admins.title,
                    systemImage: selectedTab == .admins
                        ? SuperAdminTabItem.admins.icon
                        : SuperAdminTabItem.admins.unselectedIcon
                )
            }

            // MARK: - Tab 3: Stats
            NavigationStack {
                SuperAdminStatsView()
            }
            .tag(SuperAdminTabItem.stats)
            .tabItem {
                Label(
                    SuperAdminTabItem.stats.title,
                    systemImage: selectedTab == .stats
                        ? SuperAdminTabItem.stats.icon
                        : SuperAdminTabItem.stats.unselectedIcon
                )
            }
        }
        .tint(Color(hex: "2E7D32"))
        .onChange(of: selectedTab) { _, _ in
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}

// MARK: - Preview
#Preview {
    SuperAdminTabView()
}
