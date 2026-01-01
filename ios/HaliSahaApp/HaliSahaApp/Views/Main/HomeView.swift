//
//  HomeView.swift
//  HaliSahaApp
//
//  Keşfet Ana Sayfası
//
//  Created by Mehmet Mert Mazıcı on 26.12.2025.
//


import SwiftUI

// MARK: - Home View
struct HomeView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var showNotifications = false
    @State private var showFilters = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search Bar
                searchSection
                
                // Filter Pills
                filterSection
                
                // Content
                if viewModel.isLoading {
                    loadingSection
                } else {
                    contentSection
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                logoView
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                notificationButton
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheetView()
        }
    }
    
    // MARK: - Logo View
    private var logoView: some View {
        HStack(spacing: 6) {
            Image(systemName: "sportscourt.fill")
                .font(.title3)
                .foregroundColor(Color(hex: "2E7D32"))
            
            Text("HaliSaha")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Notification Button
    private var notificationButton: some View {
        Button {
            showNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.body)
                    .foregroundColor(.primary)
                
                // Badge
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authService.currentUser {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Merhaba, \(user.firstName) 👋")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Bugün maç yapmaya ne dersin?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // User avatar
                    ZStack {
                        Circle()
                            .fill(Color(hex: "2E7D32").opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Text(String(user.firstName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2E7D32"))
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundColor(.gray)
                
                TextField("Saha ara...", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            
            // Filter Button
            Button {
                showFilters.toggle()
            } label: {
                Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(viewModel.hasActiveFilters ? Color(hex: "2E7D32") : .gray)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeFilter.allCases) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectFilter(filter)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                CardSkeletonView()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: 24) {
            // Featured Section
            if !viewModel.featuredFacilities.isEmpty && viewModel.searchText.isEmpty {
                featuredSection
            }
            
            // Upcoming Matches Section
            if !viewModel.upcomingMatches.isEmpty && viewModel.searchText.isEmpty {
                upcomingMatchesSection
            }
            
            // Nearby/Filtered Facilities Section
            nearbySection
        }
        .padding(.bottom, 100) // Tab bar için boşluk
    }
    
    // MARK: - Featured Section
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Öne Çıkanlar", icon: "star.fill")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredFacilities) { facility in
                        NavigationLink {
                            FacilityDetailPlaceholder(facility: facility)
                        } label: {
                            FeaturedFacilityCard(facility: facility)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Upcoming Matches Section
    private var upcomingMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Oyuncu Aranan Maçlar",
                icon: "person.badge.plus",
                actionTitle: "Tümü"
            ) {
                // Tümünü gör
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.upcomingMatches) { matchPost in
                    NavigationLink {
                        MatchPostDetailPlaceholder(matchPost: matchPost)
                    } label: {
                        MatchPostCard(matchPost: matchPost)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Nearby Section
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: viewModel.hasActiveFilters ? "Sonuçlar" : "Yakındaki Sahalar",
                icon: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "location.fill",
                actionTitle: viewModel.hasActiveFilters ? "Temizle" : nil
            ) {
                viewModel.clearFilters()
            }
            
            if viewModel.filteredFacilities.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Saha Bulunamadı",
                    message: "Arama kriterlerinize uygun saha bulunamadı. Filtreleri değiştirmeyi deneyin.",
                    buttonTitle: "Filtreleri Temizle"
                ) {
                    viewModel.clearFilters()
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.filteredFacilities) { facility in
                        NavigationLink {
                            FacilityDetailPlaceholder(facility: facility)
                        } label: {
                            FacilityCard(
                                facility: facility,
                                showDistance: true,
                                distance: Double.random(in: 0.5...10.0)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    
    let title: String
    var icon: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2E7D32"))
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "2E7D32") : Color(.systemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Notifications Sheet View
struct NotificationsSheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // Notifications will be implemented in ADIM 8
                EmptyStateView(
                    icon: "bell.fill",
                    title: "Bildirimler",
                    message: "Henüz bildiriminiz yok."
                )
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Views (Sonraki adımlarda güncellenecek)

struct FacilityDetailPlaceholder: View {
    let facility: Facility
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
            
            Text(facility.name)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Detay sayfası ADIM 5'te eklenecek")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(facility.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MatchPostDetailPlaceholder: View {
    let matchPost: MatchPost
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "2E7D32").opacity(0.5))
            
            Text(matchPost.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Detay sayfası ADIM 7'de eklenecek")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Maç Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HomeView()
    }
}

