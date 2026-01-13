//
//  MapViewModel.swift
//  HaliSahaApp
//
//  Harita ViewModel - MapKit iş mantığı
//
//  Created by Mehmet Mert Mazıcı on 1.01.2026.
//

import Foundation
import SwiftUI
import MapKit
import Combine

// MARK: - Map ViewModel
@MainActor
final class MapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var facilities: [Facility] = []
    @Published var facilitiesWithDistance: [(facility: Facility, distance: Double)] = []
    @Published var selectedFacility: Facility?
    @Published var isLoading = false
    @Published var error: String?
    
    // Map State
    @Published var region: MKCoordinateRegion
    @Published var mapCameraPosition: MapCameraPosition = .automatic
    
    // UI State
    @Published var showListView = false
    @Published var showFilters = false
    @Published var showFacilityDetail = false
    @Published var searchText = ""
    @Published var filters = FacilityFilters()
    
    // MARK: - Private Properties
    private let facilityService = FacilityService.shared
    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
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
        if filters.hasActiveFilters {
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
        }
        
        return result
    }
    
    var annotations: [FacilityAnnotation] {
        filteredFacilities.map { FacilityAnnotation(facility: $0) }
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty || filters.hasActiveFilters
    }
    
    // MARK: - Init
    init() {
        // Varsayılan bölge (Ankara)
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: AppConstants.defaultLatitude,
                longitude: AppConstants.defaultLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
        
        setupBindings()
    }
    
    // MARK: - Setup Bindings
    private func setupBindings() {
        // Konum değişikliklerini dinle
        locationManager.$userLocation
            .compactMap { $0 }
            .first() // Sadece ilk konumu al
            .sink { [weak self] location in
                self?.centerOnUserLocation(location)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Facilities
    func loadFacilities() async {
        isLoading = true
        error = nil
        
        do {
            // Mock data kullan (Firebase bağlantısı olmadığında)
            let loadedFacilities = facilityService.loadMockFacilities()
            
            // Gerçek implementasyon:
            // let loadedFacilities = try await facilityService.fetchAllFacilities()
            
            self.facilities = loadedFacilities
            
            // Mesafeleri hesapla
            calculateDistances()
            
            isLoading = false
        } catch {
            isLoading = false
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Calculate Distances
    private func calculateDistances() {
        let userLocation = locationManager.currentOrDefaultLocation
        
        facilitiesWithDistance = facilities.map { facility in
            let facilityLocation = CLLocationCoordinate2D(
                latitude: facility.latitude,
                longitude: facility.longitude
            )
            let distance = userLocation.distance(to: facilityLocation)
            return (facility, distance)
        }.sorted { $0.distance < $1.distance }
    }
    
    // MARK: - Request Location Permission
    func requestLocationPermission() {
        locationManager.requestPermission()
    }
    
    // MARK: - Center on User Location
    func centerOnUserLocation(_ location: CLLocationCoordinate2D? = nil) {
        let targetLocation = location ?? locationManager.userLocation ?? locationManager.defaultLocation
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: targetLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapCameraPosition = .region(region)
        }
        
        // Mesafeleri yeniden hesapla
        calculateDistances()
    }
    
    // MARK: - Center on Facility
    func centerOnFacility(_ facility: Facility) {
        withAnimation(.easeInOut(duration: 0.3)) {
            region = MKCoordinateRegion(
                center: facility.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            mapCameraPosition = .region(region)
        }
    }
    
    // MARK: - Select Facility
    func selectFacility(_ facility: Facility?) {
        selectedFacility = facility
        
        if let facility = facility {
            centerOnFacility(facility)
            showFacilityDetail = true
        } else {
            showFacilityDetail = false
        }
    }
    
    // MARK: - Toggle View Mode
    func toggleViewMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showListView.toggle()
        }
    }
    
    // MARK: - Clear Filters
    func clearFilters() {
        searchText = ""
        filters.reset()
    }
    
    // MARK: - Get Distance String
    func distanceString(for facility: Facility) -> String {
        if let match = facilitiesWithDistance.first(where: { $0.facility.id == facility.id }) {
            if match.distance < 1 {
                return String(format: "%.0f m", match.distance * 1000)
            } else {
                return String(format: "%.1f km", match.distance)
            }
        }
        return ""
    }
}

// MARK: - Facility Annotation
struct FacilityAnnotation: Identifiable {
    let id: String
    let facility: Facility
    var coordinate: CLLocationCoordinate2D
    
    init(facility: Facility) {
        self.id = facility.id ?? UUID().uuidString
        self.facility = facility
        self.coordinate = CLLocationCoordinate2D(
            latitude: facility.latitude,
            longitude: facility.longitude
        )
    }
}

// MARK: - Map Style
enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard = "Standart"
    case satellite = "Uydu"
    case hybrid = "Hibrit"
    
    var id: String { rawValue }
    
    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .satellite: return .imagery
        case .hybrid: return .hybrid
        }
    }
}
