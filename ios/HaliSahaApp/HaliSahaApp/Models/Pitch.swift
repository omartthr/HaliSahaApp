//
//  Pitch.swift
//  HaliSahaApp
//
//  Alt Saha veri modeli (Tesis içindeki bireysel sahalar - Sub-collection)
//
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//

import Foundation
import FirebaseFirestore

// MARK: - Pitch Model (Alt Saha)
struct Pitch: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var facilityId: String           // Üst tesis ID
    var name: String                 // Saha adı (Örn: "Saha A", "1 No'lu Saha")
    var description: String?
    var pitchType: PitchType         // Saha türü
    var surfaceType: SurfaceType     // Zemin türü
    var size: PitchSize              // Saha boyutu (5x5, 6x6, 7x7)
    var capacity: Int                // Maksimum oyuncu sayısı
    var images: [String]             // Sahaya özel fotoğraflar
    var pricing: PitchPricing        // Fiyatlandırma
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializer
    init(
        id: String? = nil,
        facilityId: String,
        name: String,
        description: String? = nil,
        pitchType: PitchType = .outdoor,
        surfaceType: SurfaceType = .syntheticGrass,
        size: PitchSize = .fiveASide,
        capacity: Int = 14,
        images: [String] = [],
        pricing: PitchPricing = PitchPricing(),
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.facilityId = facilityId
        self.name = name
        self.description = description
        self.pitchType = pitchType
        self.surfaceType = surfaceType
        self.size = size
        self.capacity = capacity
        self.images = images
        self.pricing = pricing
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Pitch Type
enum PitchType: String, Codable, CaseIterable {
    case indoor = "indoor"     // Kapalı
    case outdoor = "outdoor"   // Açık
    case covered = "covered"   // Üstü kapalı (yanlar açık)
    
    var displayName: String {
        switch self {
        case .indoor: return "Kapalı"
        case .outdoor: return "Açık"
        case .covered: return "Yarı Kapalı"
        }
    }
    
    var icon: String {
        switch self {
        case .indoor: return "house.fill"
        case .outdoor: return "sun.max.fill"
        case .covered: return "umbrella.fill"
        }
    }
}

// MARK: - Surface Type (Zemin Türü)
enum SurfaceType: String, Codable, CaseIterable {
    case syntheticGrass = "syntheticGrass"   // Sentetik çim
    case naturalGrass = "naturalGrass"       // Doğal çim
    case hybrid = "hybrid"                   // Hibrit
    case artificial = "artificial"           // Yapay zemin
    
    var displayName: String {
        switch self {
        case .syntheticGrass: return "Sentetik Çim"
        case .naturalGrass: return "Doğal Çim"
        case .hybrid: return "Hibrit"
        case .artificial: return "Yapay Zemin"
        }
    }
}

// MARK: - Pitch Size
enum PitchSize: String, Codable, CaseIterable {
    case fiveASide = "5v5"     // 5'e 5
    case sixASide = "6v6"      // 6'ya 6
    case sevenASide = "7v7"    // 7'ye 7
    case eightASide = "8v8"    // 8'e 8
    
    var displayName: String {
        switch self {
        case .fiveASide: return "5v5 (10 Kişilik)"
        case .sixASide: return "6v6 (12 Kişilik)"
        case .sevenASide: return "7v7 (14 Kişilik)"
        case .eightASide: return "8v8 (16 Kişilik)"
        }
    }
    
    var playerCount: Int {
        switch self {
        case .fiveASide: return 10
        case .sixASide: return 12
        case .sevenASide: return 14
        case .eightASide: return 16
        }
    }
    
    // Yaklaşık boyutlar (metre)
    var dimensions: String {
        switch self {
        case .fiveASide: return "25x15m"
        case .sixASide: return "35x20m"
        case .sevenASide: return "50x30m"
        case .eightASide: return "60x40m"
        }
    }
}

// MARK: - Pitch Pricing (Fiyatlandırma)
struct PitchPricing: Codable, Hashable {
    var daytimePrice: Double         // Gündüz saatlik ücreti (08:00-18:00)
    var eveningPrice: Double         // Akşam saatlik ücreti (18:00-00:00)
    var weekendMultiplier: Double    // Hafta sonu çarpanı (Örn: 1.2 = %20 fazla)
    var depositPercentage: Double    // Kapora yüzdesi (Örn: 0.2 = %20)
    var currency: String             // Para birimi
    
    init(
        daytimePrice: Double = 500.0,
        eveningPrice: Double = 700.0,
        weekendMultiplier: Double = 1.0,
        depositPercentage: Double = 0.2,
        currency: String = "TRY"
    ) {
        self.daytimePrice = daytimePrice
        self.eveningPrice = eveningPrice
        self.weekendMultiplier = weekendMultiplier
        self.depositPercentage = depositPercentage
        self.currency = currency
    }
    
    // MARK: - Price Calculation
    func calculatePrice(startHour: Int, duration: Int, isWeekend: Bool) -> Double {
        // 18:00 ve sonrası akşam tarifesi, öncesi gündüz tarifesi
        let basePrice = startHour >= 18 ? eveningPrice : daytimePrice
        
        // Hafta sonu çarpanını uygula
        let hourlyPrice = isWeekend ? basePrice * weekendMultiplier : basePrice
        
        // Toplam süreyi çarp (saatlik ücret * süre)
        return hourlyPrice * Double(duration)
    }
    
    func calculateDeposit(totalPrice: Double) -> Double {
        return totalPrice * depositPercentage
    }
    
    var formattedDaytimePrice: String {
        return "\(Int(daytimePrice)) ₺/saat"
    }
    
    var formattedEveningPrice: String {
        return "\(Int(eveningPrice)) ₺/saat"
    }
}

// MARK: - Time Slot (Müsaitlik Takvimi için)
struct TimeSlot: Identifiable, Codable, Hashable {
    var id: String { "\(date.timeIntervalSince1970)-\(hour)" }
    var date: Date
    var hour: Int                    // 0-23 arası saat
    var isAvailable: Bool
    var bookingId: String?           // Eğer dolu ise, rezervasyon ID
    var isManuallyBlocked: Bool      // Admin tarafından manuel olarak kapatıldı mı?
    var price: Double
    
    var timeString: String {
        String(format: "%02d:00 - %02d:00", hour, hour + 1)
    }
    
    init(
        date: Date,
        hour: Int,
        isAvailable: Bool = true,
        bookingId: String? = nil,
        isManuallyBlocked: Bool = false,
        price: Double = 0
    ) {
        self.date = date
        self.hour = hour
        self.isAvailable = isAvailable
        self.bookingId = bookingId
        self.isManuallyBlocked = isManuallyBlocked
        self.price = price
    }
}

// MARK: - Mock Data
extension Pitch {
    static let mockPitch = Pitch(
        id: "pitch123",
        facilityId: "facility123",
        name: "Saha A",
        description: "Profesyonel aydınlatma sistemli ana saha",
        pitchType: .outdoor,
        surfaceType: .syntheticGrass,
        size: .sevenASide,
        capacity: 14,
        pricing: PitchPricing(
            daytimePrice: 600,
            eveningPrice: 800,
            weekendMultiplier: 1.2
        )
    )
    
    static let mockPitches: [Pitch] = [
        mockPitch,
        Pitch(
            id: "pitch456",
            facilityId: "facility123",
            name: "Saha B",
            pitchType: .indoor,
            surfaceType: .syntheticGrass,
            size: .fiveASide,
            capacity: 10,
            pricing: PitchPricing(
                daytimePrice: 500,
                eveningPrice: 700
            )
        )
    ]
}
