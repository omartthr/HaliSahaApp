//
//  FacilityViewModel.swift
//  HaliSahaApp
//
//  Created by Mehmet Mert Mazıcı on 13.01.2026.
//

import SwiftUI

// MARK: - Facility List ViewModel
@MainActor
final class FacilityListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var facilities: [Facility] = []
    @Published var searchText = ""
    @Published var filters = FacilityFilters()
    @Published var sortOption: SortOption = .distance
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private let facilityService = FacilityService.shared
    private let locationManager = LocationManager.shared
    private var facilitiesWithDistance: [(facility: Facility, distance: Double)] = []
    
    // MARK: - Computed Properties
    var filteredFacilities: [Facility] {
        var result = facilities
        
        // Metin araması
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { facility in
                facility.name.lowercased().contains(query) ||
                facility.address.lowercased().contains(query)
            }
        }
        
        // Filtreler
        if let isIndoor = filters.isIndoor {
            result = result.filter { $0.amenities.isIndoor == isIndoor }
        }
        if let minRating = filters.minRating {
            result = result.filter { $0.averageRating >= minRating }
        }
        if filters.hasParking {
            result = result.filter { $0.amenities.hasParking }
        }
        if filters.hasShower {
            result = result.filter { $0.amenities.hasShower }
        }
        if filters.hasCafe {
            result = result.filter { $0.amenities.hasCafe }
        }
        
        // Sıralama
        switch sortOption {
        case .distance:
            result = sortByDistance(result)
        case .rating:
            result = result.sorted { $0.averageRating > $1.averageRating }
        case .name:
            result = result.sorted { $0.name < $1.name }
        }
        
        return result
    }
    
    // MARK: - Load Facilities
    func loadFacilities() async {
        isLoading = true
        
        // Mock data
        facilities = facilityService.loadMockFacilities()
        calculateDistances()
        
        isLoading = false
    }
    
    // MARK: - Refresh
    func refreshFacilities() async {
        await loadFacilities()
    }
    
    // MARK: - Calculate Distances
    private func calculateDistances() {
        let userLocation = locationManager.currentOrDefaultLocation
        
        facilitiesWithDistance = facilities.map { facility in
            let distance = userLocation.distance(to: facility.coordinate)
            return (facility, distance)
        }
    }
    
    // MARK: - Sort by Distance
    private func sortByDistance(_ facilities: [Facility]) -> [Facility] {
        facilities.sorted { f1, f2 in
            let d1 = facilitiesWithDistance.first { $0.facility.id == f1.id }?.distance ?? Double.infinity
            let d2 = facilitiesWithDistance.first { $0.facility.id == f2.id }?.distance ?? Double.infinity
            return d1 < d2
        }
    }
    
    // MARK: - Get Distance
    func getDistance(for facility: Facility) -> Double? {
        facilitiesWithDistance.first { $0.facility.id == facility.id }?.distance
    }
    
    // MARK: - Clear Filters
    func clearFilters() {
        searchText = ""
        filters.reset()
    }
}
