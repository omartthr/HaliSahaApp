//
//  Facility.swift
//  HaliSahaApp
//
// Tesis (Halı Saha İşletmesi) veri modeli
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import Foundation
import FirebaseFirestore
import CoreLocation

// MARK: - Facility Model
struct Facility: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var ownerId: String              // Admin (saha sahibi) user ID
    var name: String                 // İşletme adı
    var description: String
    var taxNumber: String            // Vergi numarası
    var phone: String
    var email: String?
    var address: String
    var latitude: Double
    var longitude: Double
    var images: [String]             // Fotoğraf URL'leri
    var amenities: FacilityAmenities // Özellikler
    var operatingHours: OperatingHours
    var status: FacilityStatus
    var averageRating: Double
    var totalReviews: Int
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    
    // MARK: - Computed Properties
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var mainImage: String? {
        images.first
    }
    
    var formattedRating: String {
        String(format: "%.1f", averageRating)
    }
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        ownerId: String,
        name: String,
        description: String = "",
        taxNumber: String,
        phone: String,
        email: String? = nil,
        address: String,
        latitude: Double,
        longitude: Double,
        images: [String] = [],
        amenities: FacilityAmenities = FacilityAmenities(),
        operatingHours: OperatingHours = OperatingHours(),
        status: FacilityStatus = .pending,
        averageRating: Double = 0.0,
        totalReviews: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.description = description
        self.taxNumber = taxNumber
        self.phone = phone
        self.email = email
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.images = images
        self.amenities = amenities
        self.operatingHours = operatingHours
        self.status = status
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
}

// MARK: - Facility Status
enum FacilityStatus: String, Codable, CaseIterable {
    case pending = "pending"       // Onay bekliyor
    case approved = "approved"     // Onaylandı
    case rejected = "rejected"     // Reddedildi
    case suspended = "suspended"   // Askıya alındı
    
    var displayName: String {
        switch self {
        case .pending: return "Onay Bekliyor"
        case .approved: return "Aktif"
        case .rejected: return "Reddedildi"
        case .suspended: return "Askıya Alındı"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .suspended: return "gray"
        }
    }
}

// MARK: - Facility Amenities (Özellikler)
struct FacilityAmenities: Codable, Hashable {
    var hasParking: Bool           // Otopark
    var hasShuttleService: Bool    // Servis
    var hasShower: Bool            // Duş
    var hasLockerRoom: Bool        // Soyunma odası
    var hasEquipmentRental: Bool   // Krampon/Top kiralama
    var hasCafe: Bool              // Kafe/Büfe
    var hasVideoRecording: Bool    // Video kaydı
    var isIndoor: Bool             // Kapalı alan
    var hasLighting: Bool          // Aydınlatma
    var hasHeating: Bool           // Isıtma
    var hasFirstAid: Bool          // İlk yardım
    var hasWifi: Bool              // Wi-Fi
    
    init(
        hasParking: Bool = false,
        hasShuttleService: Bool = false,
        hasShower: Bool = false,
        hasLockerRoom: Bool = false,
        hasEquipmentRental: Bool = false,
        hasCafe: Bool = false,
        hasVideoRecording: Bool = false,
        isIndoor: Bool = false,
        hasLighting: Bool = true,
        hasHeating: Bool = false,
        hasFirstAid: Bool = false,
        hasWifi: Bool = false
    ) {
        self.hasParking = hasParking
        self.hasShuttleService = hasShuttleService
        self.hasShower = hasShower
        self.hasLockerRoom = hasLockerRoom
        self.hasEquipmentRental = hasEquipmentRental
        self.hasCafe = hasCafe
        self.hasVideoRecording = hasVideoRecording
        self.isIndoor = isIndoor
        self.hasLighting = hasLighting
        self.hasHeating = hasHeating
        self.hasFirstAid = hasFirstAid
        self.hasWifi = hasWifi
    }
    
    // Aktif özelliklerin listesi
    var activeAmenities: [(icon: String, name: String)] {
        var list: [(String, String)] = []
        if hasParking { list.append(("🅿️", "Otopark")) }
        if hasShuttleService { list.append(("🚐", "Servis")) }
        if hasShower { list.append(("🚿", "Duş")) }
        if hasLockerRoom { list.append(("🚪", "Soyunma Odası")) }
        if hasEquipmentRental { list.append(("👟", "Ekipman Kiralama")) }
        if hasCafe { list.append(("☕", "Kafe")) }
        if hasVideoRecording { list.append(("📹", "Video Kaydı")) }
        if isIndoor { list.append(("🏠", "Kapalı Alan")) }
        if hasLighting { list.append(("💡", "Aydınlatma")) }
        if hasHeating { list.append(("🔥", "Isıtma")) }
        if hasFirstAid { list.append(("🩹", "İlk Yardım")) }
        if hasWifi { list.append(("📶", "Wi-Fi")) }
        return list
    }
}

// MARK: - Operating Hours (Çalışma Saatleri)
struct OperatingHours: Codable, Hashable {
    var mondayOpen: String
    var mondayClose: String
    var tuesdayOpen: String
    var tuesdayClose: String
    var wednesdayOpen: String
    var wednesdayClose: String
    var thursdayOpen: String
    var thursdayClose: String
    var fridayOpen: String
    var fridayClose: String
    var saturdayOpen: String
    var saturdayClose: String
    var sundayOpen: String
    var sundayClose: String
    
    init(
        mondayOpen: String = "09:00",
        mondayClose: String = "23:00",
        tuesdayOpen: String = "09:00",
        tuesdayClose: String = "23:00",
        wednesdayOpen: String = "09:00",
        wednesdayClose: String = "23:00",
        thursdayOpen: String = "09:00",
        thursdayClose: String = "23:00",
        fridayOpen: String = "09:00",
        fridayClose: String = "23:00",
        saturdayOpen: String = "09:00",
        saturdayClose: String = "23:00",
        sundayOpen: String = "09:00",
        sundayClose: String = "23:00"
    ) {
        self.mondayOpen = mondayOpen
        self.mondayClose = mondayClose
        self.tuesdayOpen = tuesdayOpen
        self.tuesdayClose = tuesdayClose
        self.wednesdayOpen = wednesdayOpen
        self.wednesdayClose = wednesdayClose
        self.thursdayOpen = thursdayOpen
        self.thursdayClose = thursdayClose
        self.fridayOpen = fridayOpen
        self.fridayClose = fridayClose
        self.saturdayOpen = saturdayOpen
        self.saturdayClose = saturdayClose
        self.sundayOpen = sundayOpen
        self.sundayClose = sundayClose
    }
    
    func hours(for day: Int) -> (open: String, close: String) {
        switch day {
        case 1: return (sundayOpen, sundayClose)
        case 2: return (mondayOpen, mondayClose)
        case 3: return (tuesdayOpen, tuesdayClose)
        case 4: return (wednesdayOpen, wednesdayClose)
        case 5: return (thursdayOpen, thursdayClose)
        case 6: return (fridayOpen, fridayClose)
        case 7: return (saturdayOpen, saturdayClose)
        default: return (mondayOpen, mondayClose)
        }
    }
}

// MARK: - Mock Data
extension Facility {
    static let mockFacility = Facility(
        id: "facility123",
        ownerId: "admin123",
        name: "Yıldız Spor Tesisleri",
        description: "Ankara'nın en modern halı saha kompleksi. 4 adet profesyonel saha ile hizmetinizdeyiz.",
        taxNumber: "1234567890",
        phone: "+902121234567",
        email: "info@yildizsport.com",
        address: "Keçiören, Ankara",
        latitude: 40.9923,
        longitude: 29.1244,
        images: ["facility1.jpg", "facility2.jpg"],
        amenities: FacilityAmenities(
            hasParking: true,
            hasShower: true,
            hasLockerRoom: true,
            hasCafe: true,
            hasLighting: true
        ),
        status: .approved,
        averageRating: 4.5,
        totalReviews: 128
    )
}
