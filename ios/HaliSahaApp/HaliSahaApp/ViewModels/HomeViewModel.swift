//
//  HomeViewModel.swift
//  HaliSahaApp
//
//  Ana Sayfa (Keşfet) ViewModel
//
//  Created by Mehmet Mert Mazıcı on 26.12.2025.
//

import CoreLocation
import Foundation
import SwiftUI

// MARK: - Home ViewModel
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    // Data
    @Published var featuredFacilities: [Facility] = []
    @Published var nearbyFacilities: [Facility] = []
    @Published var recentlyViewedFacilities: [Facility] = []
    @Published var upcomingMatches: [MatchPost] = []

    // Location
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationPermissionDenied = false

    // Filters
    @Published var selectedFilter: HomeFilter = .all

    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private let facilityService = FacilityService.shared
    private let locationManager = CLLocationManager()

    // MARK: - Computed Properties
    var filteredFacilities: [Facility] {
        var facilities = nearbyFacilities

        // Arama filtresi
        if !searchText.isEmpty {
            facilities = facilities.filter { facility in
                facility.name.localizedCaseInsensitiveContains(searchText)
                    || facility.address.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Kategori filtresi
        switch selectedFilter {
        case .all:
            break
        case .indoor:
            facilities = facilities.filter { $0.amenities.isIndoor }
        case .outdoor:
            facilities = facilities.filter { !$0.amenities.isIndoor }
        case .highRated:
            facilities = facilities.filter { $0.averageRating >= 4.0 }
        case .hasParking:
            facilities = facilities.filter { $0.amenities.hasParking }
        }

        return facilities
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedFilter != .all
    }

    // MARK: - Init
    init() {
        // Data will be loaded when view appears via loadData()
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all approved, active facilities from Firestore
            let allFacilities = try await facilityService.fetchAllFacilities()

            // Featured facilities: top 3 by rating
            featuredFacilities = Array(
                allFacilities.sorted { $0.averageRating > $1.averageRating }.prefix(3)
            )

            // Nearby facilities: all approved facilities
            nearbyFacilities = allFacilities

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh Data
    func refreshData() async {
        isRefreshing = true
        errorMessage = nil

        do {
            let allFacilities = try await facilityService.fetchAllFacilities(forceRefresh: true)

            featuredFacilities = Array(
                allFacilities.sorted { $0.averageRating > $1.averageRating }.prefix(3)
            )
            nearbyFacilities = allFacilities

            isRefreshing = false
        } catch {
            isRefreshing = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load Mock Data
    private func loadMockData() {
        // Featured Facilities
        featuredFacilities = [
            createMockFacility(
                id: "f1",
                name: "Yıldız Spor Tesisleri",
                address: "Gölbaşı, Ankara",
                rating: 4.8,
                reviewCount: 256,
                isIndoor: false,
                hasParking: true,
                priceRange: "500-800 ₺"
            ),
            createMockFacility(
                id: "f2",
                name: "Elit Arena",
                address: "Keçiören, Ankara",
                rating: 4.9,
                reviewCount: 189,
                isIndoor: true,
                hasParking: true,
                priceRange: "600-900 ₺"
            ),
            createMockFacility(
                id: "f3",
                name: "Green Field",
                address: "Çankaya, Ankara",
                rating: 4.6,
                reviewCount: 142,
                isIndoor: false,
                hasParking: false,
                priceRange: "450-700 ₺"
            ),
        ]

        // Nearby Facilities
        nearbyFacilities = [
            createMockFacility(
                id: "f4",
                name: "Spor Vadisi",
                address: "Mamak, Ankara",
                rating: 4.5,
                reviewCount: 98,
                isIndoor: false,
                hasParking: true,
                priceRange: "400-600 ₺",
                distance: 1.2
            ),
            createMockFacility(
                id: "f5",
                name: "Gol Park",
                address: "Altındağ, Ankara",
                rating: 4.3,
                reviewCount: 76,
                isIndoor: true,
                hasParking: true,
                priceRange: "500-750 ₺",
                distance: 2.5
            ),
            createMockFacility(
                id: "f6",
                name: "Sahil Arena",
                address: "Gölbaşı, Ankara",
                rating: 4.7,
                reviewCount: 134,
                isIndoor: false,
                hasParking: false,
                priceRange: "350-550 ₺",
                distance: 3.8
            ),
            createMockFacility(
                id: "f7",
                name: "Merkez Spor",
                address: "Gölbaşı, Ankara",
                rating: 4.2,
                reviewCount: 54,
                isIndoor: true,
                hasParking: true,
                priceRange: "400-650 ₺",
                distance: 5.1
            ),
        ]

        // Upcoming Match Posts
        upcomingMatches = [
            MatchPost.mockPost,
            createMockMatchPost(
                id: "mp2",
                title: "Pazar Sabahı Dostluk Maçı",
                facilityName: "Elit Arena",
                neededPlayers: 3,
                currentPlayers: 11,
                maxPlayers: 14,
                daysFromNow: 4
            ),
        ]
    }

    // MARK: - Helper: Create Mock Facility
    private func createMockFacility(
        id: String,
        name: String,
        address: String,
        rating: Double,
        reviewCount: Int,
        isIndoor: Bool,
        hasParking: Bool,
        priceRange: String,
        distance: Double? = nil
    ) -> Facility {
        var facility = Facility(
            id: id,
            ownerId: "owner_\(id)",
            name: name,
            description: "Modern tesisimizde profesyonel sahalarımızla hizmetinizdeyiz.",
            taxNumber: "123456789",
            phone: "+902121234567",
            address: address,
            latitude: 41.0 + Double.random(in: -0.1...0.1),
            longitude: 29.0 + Double.random(in: -0.1...0.1),
            images: ["facility_placeholder"],
            amenities: FacilityAmenities(
                hasParking: hasParking,
                hasShower: true,
                hasLockerRoom: true,
                hasCafe: Bool.random(),
                isIndoor: isIndoor,
                hasLighting: true
            ),
            status: .approved,
            averageRating: rating,
            totalReviews: reviewCount
        )
        return facility
    }

    // MARK: - Helper: Create Mock Match Post
    private func createMockMatchPost(
        id: String,
        title: String,
        facilityName: String,
        neededPlayers: Int,
        currentPlayers: Int,
        maxPlayers: Int,
        daysFromNow: Int
    ) -> MatchPost {
        MatchPost(
            id: id,
            creatorId: "user123",
            creatorName: "Mehmet K.",
            bookingId: "booking_\(id)",
            facilityId: "facility_\(id)",
            facilityName: facilityName,
            facilityAddress: "Ankara",
            pitchName: "Saha 1",
            matchDate: Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())
                ?? Date(),
            startHour: 19,
            endHour: 20,
            title: title,
            neededPlayers: neededPlayers,
            currentPlayers: currentPlayers,
            maxPlayers: maxPlayers,
            skillLevel: .intermediate,
            costPerPlayer: 80
        )
    }

    // MARK: - Actions
    func clearFilters() {
        searchText = ""
        selectedFilter = .all
    }

    func selectFilter(_ filter: HomeFilter) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedFilter == filter {
                selectedFilter = .all
            } else {
                selectedFilter = filter
            }
        }
    }
}

// MARK: - Home Filter Enum
enum HomeFilter: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case indoor = "Kapalı"
    case outdoor = "Açık"
    case highRated = "Yüksek Puan"
    case hasParking = "Otoparkı Var"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .indoor: return "house.fill"
        case .outdoor: return "sun.max.fill"
        case .highRated: return "star.fill"
        case .hasParking: return "car.fill"
        }
    }
}
