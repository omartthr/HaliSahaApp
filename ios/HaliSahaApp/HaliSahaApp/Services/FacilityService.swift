//
//  FacilityService.swift
//  HaliSahaApp
//
//  Tesis (Halı Saha) CRUD işlemleri servisi
//
//  Created by Mehmet Mert Mazıcı on 1.01.2026.
//

import Foundation
import FirebaseFirestore
import CoreLocation

// MARK: - Facility Service
final class FacilityService: ObservableObject {
    
    static let shared = FacilityService()
    
    // MARK: - Published Properties
    @Published var facilities: [Facility] = []
    @Published var isLoading = false
    @Published var error: FacilityError?
    
    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private let locationManager = LocationManager.shared
    
    // Cache
    private var facilitiesCache: [String: Facility] = [:]
    private var pitchesCache: [String: [Pitch]] = [:]
    private var lastFetchTime: Date?
    private let cacheExpiration: TimeInterval = 300 // 5 dakika
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - Tüm facilityleri getir
    @MainActor
    func fetchAllFacilities(forceRefresh: Bool = false) async throws -> [Facility] {
        // Cache kontrolü
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpiration,
           !facilities.isEmpty {
            return facilities
        }
        
        isLoading = true
        error = nil
        
        do {
            let query = firebaseService.facilitiesCollection
                .whereField(FirestoreField.status, isEqualTo: FacilityStatus.approved.rawValue)
                .whereField(FirestoreField.isActive, isEqualTo: true)
            
            let fetchedFacilities: [Facility] = try await firebaseService.fetchDocuments(query: query)
            
            // Cache güncelle
            self.facilities = fetchedFacilities
            self.lastFetchTime = Date()
            
            for facility in fetchedFacilities {
                if let id = facility.id {
                    facilitiesCache[id] = facility
                }
            }
            
            isLoading = false
            return fetchedFacilities
            
        } catch {
            isLoading = false
            self.error = .fetchFailed(error.localizedDescription)
            throw FacilityError.fetchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Tek facilityi getir pampa
    @MainActor
    func fetchFacility(id: String) async throws -> Facility {
        // Cache kontrolü
        if let cached = facilitiesCache[id] {
            return cached
        }
        
        do {
            let facility: Facility = try await firebaseService.fetchDocument(
                from: firebaseService.facilitiesCollection,
                documentId: id
            )
            
            facilitiesCache[id] = facility
            return facility
            
        } catch {
            throw FacilityError.notFound
        }
    }
    
    // MARK: - Fetch Nearby Facilities
    @MainActor
    func fetchNearbyFacilities(
        location: CLLocationCoordinate2D? = nil,
        radiusKm: Double = AppConstants.nearbyRadiusKm
    ) async throws -> [Facility] {
        let targetLocation = location ?? locationManager.currentOrDefaultLocation
        
        // Tüm tesisleri al ve mesafeye göre filtrele
        let allFacilities = try await fetchAllFacilities()
        
        let nearbyFacilities = allFacilities
            .map { facility -> (Facility, Double) in
                let facilityLocation = CLLocationCoordinate2D(
                    latitude: facility.latitude,
                    longitude: facility.longitude
                )
                let distance = targetLocation.distance(to: facilityLocation)
                return (facility, distance)
            }
            .filter { $0.1 <= radiusKm }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
        
        return nearbyFacilities
    }
    
    // MARK: - mesafeyle facilityleri getir
    @MainActor
    func fetchFacilitiesWithDistance(
        from location: CLLocationCoordinate2D? = nil
    ) async throws -> [(facility: Facility, distance: Double)] {
        let targetLocation = location ?? locationManager.currentOrDefaultLocation
        let allFacilities = try await fetchAllFacilities()
        
        return allFacilities
            .map { facility -> (Facility, Double) in
                let facilityLocation = CLLocationCoordinate2D(
                    latitude: facility.latitude,
                    longitude: facility.longitude
                )
                let distance = targetLocation.distance(to: facilityLocation)
                return (facility, distance)
            }
            .sorted { $0.1 < $1.1 }
    }
    
    // MARK: - facility ara
    @MainActor
    func searchFacilities(
        query: String,
        filters: FacilityFilters? = nil
    ) async throws -> [Facility] {
        var allFacilities = try await fetchAllFacilities()
        
        // Metin araması
        if !query.isEmpty {
            let lowercasedQuery = query.lowercased()
            allFacilities = allFacilities.filter { facility in
                facility.name.lowercased().contains(lowercasedQuery) ||
                facility.address.lowercased().contains(lowercasedQuery) ||
                facility.description.lowercased().contains(lowercasedQuery)
            }
        }
        
        // Filtreler
        if let filters = filters {
            allFacilities = applyFilters(facilities: allFacilities, filters: filters)
        }
        
        return allFacilities
    }
    
    // MARK: - Apply Filters
    private func applyFilters(facilities: [Facility], filters: FacilityFilters) -> [Facility] {
        var filtered = facilities
        
        // Kapalı/Açık alan filtresi
        if let isIndoor = filters.isIndoor {
            filtered = filtered.filter { $0.amenities.isIndoor == isIndoor }
        }
        
        // Minimum puan filtresi
        if let minRating = filters.minRating {
            filtered = filtered.filter { $0.averageRating >= minRating }
        }
        
        // Özellik filtreleri
        if filters.hasParking {
            filtered = filtered.filter { $0.amenities.hasParking }
        }
        
        if filters.hasShower {
            filtered = filtered.filter { $0.amenities.hasShower }
        }
        
        if filters.hasCafe {
            filtered = filtered.filter { $0.amenities.hasCafe }
        }
        
        if filters.hasEquipmentRental {
            filtered = filtered.filter { $0.amenities.hasEquipmentRental }
        }
        
        return filtered
    }
    
    // MARK: - facility için pitchleri getir
    @MainActor
    func fetchPitches(for facilityId: String) async throws -> [Pitch] {
        // Cache kontrolü
        if let cached = pitchesCache[facilityId] {
            return cached
        }
        
        do {
            let query = firebaseService.pitchesCollection(for: facilityId)
                .whereField(FirestoreField.isActive, isEqualTo: true)
            
            let pitches: [Pitch] = try await firebaseService.fetchDocuments(query: query)
            
            pitchesCache[facilityId] = pitches
            return pitches
            
        } catch {
            throw FacilityError.fetchFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Fvzorilere ekle
    func addToFavorites(facilityId: String) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw FacilityError.notAuthenticated
        }
        
        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: [
                "favoriteFields": FieldValue.arrayUnion([facilityId])
            ]
        )
    }
    
    // MARK: - Favlardan sil
    func removeFromFavorites(facilityId: String) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw FacilityError.notAuthenticated
        }
        
        try await firebaseService.updateDocument(
            in: firebaseService.usersCollection,
            documentId: userId,
            fields: [
                "favoriteFields": FieldValue.arrayRemove([facilityId])
            ]
        )
    }
    
    // MARK: - Fav mı kontrol et
    func isFavorite(facilityId: String, userFavorites: [String]) -> Bool {
        userFavorites.contains(facilityId)
    }
    
    // MARK: - Clear Cache
    func clearCache() {
        facilitiesCache.removeAll()
        pitchesCache.removeAll()
        lastFetchTime = nil
    }
    
    // MARK: - Mock Data (Development için)
    @MainActor
    func loadMockFacilities() -> [Facility] {
        let mockFacilities = [
            Facility(
                id: "mock1",
                ownerId: "owner1",
                name: "Yıldız Spor Tesisleri",
                description: "İstanbul'un en modern halı saha kompleksi",
                taxNumber: "1234567890",
                phone: "+902121234567",
                address: "Ataşehir, İstanbul",
                latitude: 40.9923,
                longitude: 29.1244,
                images: [],
                amenities: FacilityAmenities(hasParking: true, hasShower: true, hasLockerRoom: true, hasCafe: true, isIndoor: false, hasLighting: true),
                status: .approved,
                averageRating: 4.8,
                totalReviews: 256
            ),
            Facility(
                id: "mock2",
                ownerId: "owner2",
                name: "Elit Arena",
                description: "Kapalı alan profesyonel saha",
                taxNumber: "0987654321",
                phone: "+902161234567",
                address: "Kadıköy, İstanbul",
                latitude: 40.9823,
                longitude: 29.0544,
                images: [],
                amenities: FacilityAmenities(hasParking: true, hasShower: true, hasLockerRoom: true, hasCafe: false, isIndoor: true, hasLighting: true, hasHeating: true),
                status: .approved,
                averageRating: 4.9,
                totalReviews: 189
            ),
            Facility(
                id: "mock3",
                ownerId: "owner3",
                name: "Green Field",
                description: "Doğa ile iç içe futbol deneyimi",
                taxNumber: "1122334455",
                phone: "+902127654321",
                address: "Beşiktaş, İstanbul",
                latitude: 41.0423,
                longitude: 29.0044,
                images: [],
                amenities: FacilityAmenities(hasParking: false, hasShower: true, hasLockerRoom: true, hasCafe: true, isIndoor: false, hasLighting: true),
                status: .approved,
                averageRating: 4.6,
                totalReviews: 142
            ),
            Facility(
                id: "mock4",
                ownerId: "owner4",
                name: "Spor Vadisi",
                description: "Geniş otopark ve modern tesisler",
                taxNumber: "5566778899",
                phone: "+902163334455",
                address: "Üsküdar, İstanbul",
                latitude: 41.0223,
                longitude: 29.0344,
                images: [],
                amenities: FacilityAmenities(hasParking: true, hasShower: true, hasLockerRoom: true, hasEquipmentRental: true, isIndoor: false, hasLighting: true),
                status: .approved,
                averageRating: 4.5,
                totalReviews: 98
            ),
            Facility(
                id: "mock5",
                ownerId: "owner5",
                name: "Gol Park",
                description: "7/24 açık kapalı saha",
                taxNumber: "9988776655",
                phone: "+902164445566",
                address: "Maltepe, İstanbul",
                latitude: 40.9323,
                longitude: 29.1544,
                images: [],
                amenities: FacilityAmenities(hasParking: true, hasShower: true, hasLockerRoom: true, hasCafe: true, isIndoor: true, hasLighting: true, hasHeating: true, hasWifi: true),
                status: .approved,
                averageRating: 4.3,
                totalReviews: 76
            )
        ]
        
        self.facilities = mockFacilities
        for facility in mockFacilities {
            if let id = facility.id {
                facilitiesCache[id] = facility
            }
        }
        
        return mockFacilities
    }
}

// MARK: - Facility Filters
struct FacilityFilters {
    var isIndoor: Bool? = nil
    var minRating: Double? = nil
    var maxPrice: Double? = nil
    var hasParking: Bool = false
    var hasShower: Bool = false
    var hasCafe: Bool = false
    var hasEquipmentRental: Bool = false
    var date: Date? = nil
    var startHour: Int? = nil
    var endHour: Int? = nil
    
    var hasActiveFilters: Bool {
        isIndoor != nil ||
        minRating != nil ||
        maxPrice != nil ||
        hasParking ||
        hasShower ||
        hasCafe ||
        hasEquipmentRental ||
        date != nil
    }
    
    mutating func reset() {
        isIndoor = nil
        minRating = nil
        maxPrice = nil
        hasParking = false
        hasShower = false
        hasCafe = false
        hasEquipmentRental = false
        date = nil
        startHour = nil
        endHour = nil
    }
}

// MARK: - Facility Error
enum FacilityError: LocalizedError {
    case fetchFailed(String)
    case notFound
    case notAuthenticated
    case permissionDenied
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Veriler yüklenemedi: \(message)"
        case .notFound:
            return "Tesis bulunamadı."
        case .notAuthenticated:
            return "Bu işlem için giriş yapmanız gerekiyor."
        case .permissionDenied:
            return "Bu işlem için yetkiniz yok."
        case .unknown(let message):
            return message
        }
    }
}
