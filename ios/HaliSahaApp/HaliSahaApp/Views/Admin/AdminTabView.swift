//
//  AdminTabView.swift
//  HaliSahaApp
//
//  Admin için özel Tab Bar navigasyonu
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import SwiftUI

// MARK: - Admin Tab Item
enum AdminTabItem: Int, CaseIterable {
    case dashboard = 0
    case bookings = 1
    case facilities = 2
    case reports = 3
    case settings = 4
    
    var title: String {
        switch self {
        case .dashboard: return "Panel"
        case .bookings: return "Rezervasyonlar"
        case .facilities: return "Tesisler"
        case .reports: return "Raporlar"
        case .settings: return "Ayarlar"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .bookings: return "calendar.badge.clock"
        case .facilities: return "sportscourt.fill"
        case .reports: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    var unselectedIcon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .bookings: return "calendar.badge.clock"
        case .facilities: return "sportscourt"
        case .reports: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Admin Tab View
struct AdminTabView: View {
    
    // MARK: - Properties
    @State private var selectedTab: AdminTabItem = .dashboard
    @StateObject private var adminService = AdminService.shared
    
    // Badge counts
    @State private var pendingBookings: Int = 3
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Tab 1: Dashboard
            NavigationStack {
                // AdminDashboardView()
            }
            .tag(AdminTabItem.dashboard)
            .tabItem {
                Label(
                    AdminTabItem.dashboard.title,
                    systemImage: selectedTab == .dashboard ? AdminTabItem.dashboard.icon : AdminTabItem.dashboard.unselectedIcon
                )
            }
            
            // MARK: - Tab 2: Bookings
            NavigationStack {
                // AdminBookingsView()
            }
            .tag(AdminTabItem.bookings)
            .tabItem {
                Label(
                    AdminTabItem.bookings.title,
                    systemImage: selectedTab == .bookings ? AdminTabItem.bookings.icon : AdminTabItem.bookings.unselectedIcon
                )
            }
            .badge(pendingBookings > 0 ? pendingBookings : 0)
            
            // MARK: - Tab 3: Facilities
            NavigationStack {
                // AdminFacilitiesView()
            }
            .tag(AdminTabItem.facilities)
            .tabItem {
                Label(
                    AdminTabItem.facilities.title,
                    systemImage: selectedTab == .facilities ? AdminTabItem.facilities.icon : AdminTabItem.facilities.unselectedIcon
                )
            }
            
            // MARK: - Tab 4: Reports
            NavigationStack {
                // AdminReportsView()
            }
            .tag(AdminTabItem.reports)
            .tabItem {
                Label(
                    AdminTabItem.reports.title,
                    systemImage: selectedTab == .reports ? AdminTabItem.reports.icon : AdminTabItem.reports.unselectedIcon
                )
            }
            
            // MARK: - Tab 5: Settings
            NavigationStack {
                // AdminSettingsView()
            }
            .tag(AdminTabItem.settings)
            .tabItem {
                Label(
                    AdminTabItem.settings.title,
                    systemImage: selectedTab == .settings ? AdminTabItem.settings.icon : AdminTabItem.settings.unselectedIcon
                )
            }
        }
        .tint(Color(hex: "2E7D32"))
        .onChange(of: selectedTab) { _, _ in
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        .task {
            await loadPendingCount()
        }
    }
    
    // MARK: - Load Pending Count
    private func loadPendingCount() async {
        // Mock data için
        pendingBookings = 3
    }
}

// MARK: - Preview
#Preview {
    AdminTabView()
}
