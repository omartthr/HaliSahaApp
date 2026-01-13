//
//  FacilityListView.swift
//  HaliSahaApp
//
//  Sahalar Liste Görünümü
//
//  Created by Mehmet Mert Mazıcı on 13.01.2026.
//


import SwiftUI

// MARK: - Facility List View
struct FacilityListView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = FacilityListViewModel()
    @State private var showFilters = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Search & Filter Bar
            searchBar
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredFacilities.isEmpty {
                emptyView
            } else {
                listView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Tüm Sahalar")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showFilters) {
            FilterSheet(filters: $viewModel.filters)
                .presentationDetents([.medium])
        }
        .task {
            await viewModel.loadFacilities()
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Saha, konum ara...", text: $viewModel.searchText)
                    .textInputAutocapitalization(.never)
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            
            // Filter Button
            Button {
                showFilters = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    
                    if viewModel.filters.hasActiveFilters {
                        Circle()
                            .fill(Color(hex: "2E7D32"))
                            .frame(width: 8, height: 8)
                            .offset(x: -2, y: 2)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    CardSkeletonView()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack {
            Spacer()
            
            EmptyStateView(
                icon: "sportscourt",
                title: "Saha Bulunamadı",
                message: viewModel.filters.hasActiveFilters
                    ? "Arama kriterlerinize uygun saha bulunamadı."
                    : "Henüz kayıtlı saha bulunmuyor.",
                buttonTitle: viewModel.filters.hasActiveFilters ? "Filtreleri Temizle" : nil
            ) {
                viewModel.clearFilters()
            }
            
            Spacer()
        }
    }
    
    // MARK: - List View
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Sonuç sayısı
                HStack {
                    Text("\(viewModel.filteredFacilities.count) saha")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Sıralama menüsü
                    Menu {
                        Button {
                            viewModel.sortOption = .distance
                        } label: {
                            Label("Mesafe", systemImage: viewModel.sortOption == .distance ? "checkmark" : "")
                        }
                        
                        Button {
                            viewModel.sortOption = .rating
                        } label: {
                            Label("Puan", systemImage: viewModel.sortOption == .rating ? "checkmark" : "")
                        }
                        
                        Button {
                            viewModel.sortOption = .name
                        } label: {
                            Label("İsim", systemImage: viewModel.sortOption == .name ? "checkmark" : "")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.sortOption.rawValue)
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(Color(hex: "2E7D32"))
                    }
                }
                .padding(.horizontal)
                
                // Facility Cards
                ForEach(viewModel.filteredFacilities) { facility in
                    NavigationLink {
                        FacilityDetailPlaceholder(facility: facility)
                    } label: {
                        FacilityCard(
                            facility: facility,
                            showDistance: true,
                            distance: viewModel.getDistance(for: facility)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshFacilities()
        }
    }
}



// MARK: - Sort Option
enum SortOption: String, CaseIterable {
    case distance = "Mesafe"
    case rating = "Puan"
    case name = "İsim"
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FacilityListView()
    }
}
