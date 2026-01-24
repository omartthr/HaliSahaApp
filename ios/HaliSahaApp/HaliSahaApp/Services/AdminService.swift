//
//  AdminService.swift
//  HaliSahaApp
//
//  Admin işlemleri servisi - Tesis ve rezervasyon yönetimi
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//


import Foundation
import FirebaseFirestore

// MARK: - Admin Service
final class AdminService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AdminService()
    
    // MARK: - Published Properties
    @Published var myFacilities: [Facility] = []
    @Published var pendingBookings: [Booking] = []
    @Published var todayBookings: [Booking] = []
    @Published var isLoading = false
    
    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private let authService = AuthService.shared
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - Dashboard Stats
    struct DashboardStats {
        var totalFacilities: Int = 0
        var totalPitches: Int = 0
        var todayBookings: Int = 0
        var pendingBookings: Int = 0
        var monthlyRevenue: Double = 0
        var monthlyBookings: Int = 0
        var averageRating: Double = 0
        var totalReviews: Int = 0
    }
    
    // MARK: - Fetch Dashboard Stats
    @MainActor
    func fetchDashboardStats() async throws -> DashboardStats {
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }
        
        var stats = DashboardStats()
        
        // Tesislerimi al
        let facilities = try await fetchMyFacilities()
        stats.totalFacilities = facilities.count
        
        // Toplam saha ve ortalama puan
        var totalPitches = 0
        var totalRating = 0.0
        var totalReviews = 0
        
        for facility in facilities {
            let pitches = try await fetchPitches(for: facility.id ?? "")
            totalPitches += pitches.count
            totalRating += facility.averageRating * Double(facility.totalReviews)
            totalReviews += facility.totalReviews
        }
        
        stats.totalPitches = totalPitches
        stats.averageRating = totalReviews > 0 ? totalRating / Double(totalReviews) : 0
        stats.totalReviews = totalReviews
        
        // Bugünkü rezervasyonlar
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todayQuery = firebaseService.bookingsCollection
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField(FirestoreField.date, isLessThan: Timestamp(date: tomorrow))
        
        // Facility ID'lere göre filtrele (mock için basitleştirildi)
        let allTodayBookings: [Booking] = try await firebaseService.fetchDocuments(query: todayQuery)
        let facilityIds = Set(facilities.compactMap { $0.id })
        let myTodayBookings = allTodayBookings.filter { facilityIds.contains($0.facilityId) }
        
        stats.todayBookings = myTodayBookings.count
        self.todayBookings = myTodayBookings
        
        // Bekleyen rezervasyonlar
        stats.pendingBookings = pendingBookings.count
        
        // Aylık gelir ve rezervasyon
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let monthlyBookings = myTodayBookings.filter { $0.createdAt >= startOfMonth }
        
        stats.monthlyBookings = monthlyBookings.count
        stats.monthlyRevenue = monthlyBookings.reduce(0) { $0 + $1.depositAmount }
        
        return stats
    }
    
    // MARK: - Fetch My Facilities
    @MainActor
    func fetchMyFacilities() async throws -> [Facility] {
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }
        
        isLoading = true
        
        do {
            let query = firebaseService.facilitiesCollection
                .whereField(FirestoreField.ownerId, isEqualTo: userId)
            
            let facilities: [Facility] = try await firebaseService.fetchDocuments(query: query)
            self.myFacilities = facilities
            isLoading = false
            return facilities
            
        } catch {
            isLoading = false
            // Mock data dön
            let mockFacilities = loadMockAdminFacilities()
            self.myFacilities = mockFacilities
            return mockFacilities
        }
    }
    
    // MARK: - Fetch Pitches for Facility
    @MainActor
    func fetchPitches(for facilityId: String) async throws -> [Pitch] {
        let query = firebaseService.pitchesCollection(for: facilityId)
        let pitches: [Pitch] = try await firebaseService.fetchDocuments(query: query)
        return pitches
    }
    
    // MARK: - Create Facility
    @MainActor
    func createFacility(_ facility: Facility) async throws -> String {
        guard firebaseService.currentUserId != nil else {
            throw AdminError.notAuthenticated
        }
        
        var newFacility = facility
        newFacility.status = .pending // Onay bekliyor
        
        let documentId = try await firebaseService.createDocument(
            in: firebaseService.facilitiesCollection,
            data: newFacility
        )
        
        return documentId
    }
    
    // MARK: - Update Facility
    @MainActor
    func updateFacility(_ facility: Facility) async throws {
        guard let facilityId = facility.id else {
            throw AdminError.invalidData
        }
        
        try firebaseService.facilitiesCollection
            .document(facilityId)
            .setData(from: facility, merge: true)
    }
    
    // MARK: - Create Pitch
    @MainActor
    func createPitch(_ pitch: Pitch, facilityId: String) async throws -> String {
        var newPitch = pitch
        newPitch.facilityId = facilityId
        
        let documentId = try await firebaseService.createDocument(
            in: firebaseService.pitchesCollection(for: facilityId),
            data: newPitch
        )
        
        return documentId
    }
    
    // MARK: - Update Pitch
    @MainActor
    func updatePitch(_ pitch: Pitch, facilityId: String) async throws {
        guard let pitchId = pitch.id else {
            throw AdminError.invalidData
        }
        

        try firebaseService.pitchesCollection(for: facilityId)
            .document(pitchId)
            .setData(from: pitch, merge: true)
    }
    
    // MARK: - Delete Pitch
    @MainActor
    func deletePitch(pitchId: String, facilityId: String) async throws {
        try await firebaseService.deleteDocument(
            from: firebaseService.pitchesCollection(for: facilityId),
            documentId: pitchId
        )
    }
    
    // MARK: - Fetch Facility Bookings
    @MainActor
    func fetchFacilityBookings(
        facilityId: String,
        status: BookingStatus? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [Booking] {
        var query: Query = firebaseService.bookingsCollection
            .whereField(FirestoreField.facilityId, isEqualTo: facilityId)
        
        if let status = status {
            query = query.whereField(FirestoreField.status, isEqualTo: status.rawValue)
        }
        
        if let start = startDate {
            query = query.whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: start))
        }
        
        if let end = endDate {
            query = query.whereField(FirestoreField.date, isLessThanOrEqualTo: Timestamp(date: end))
        }
        
        let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)
        return bookings.sorted { $0.date > $1.date }
    }
    
    // MARK: - Confirm Booking
    @MainActor
    func confirmBooking(bookingId: String) async throws {
        try await firebaseService.updateDocument(
            in: firebaseService.bookingsCollection,
            documentId: bookingId,
            fields: [
                FirestoreField.status: BookingStatus.confirmed.rawValue,
                FirestoreField.updatedAt: Timestamp(date: Date())
            ]
        )
    }
    
    // MARK: - Reject Booking
    @MainActor
    func rejectBooking(bookingId: String, reason: String) async throws {
        try await firebaseService.updateDocument(
            in: firebaseService.bookingsCollection,
            documentId: bookingId,
            fields: [
                FirestoreField.status: BookingStatus.cancelled.rawValue,
                "cancellationReason": reason,
                "paymentStatus": PaymentStatus.refunded.rawValue,
                FirestoreField.updatedAt: Timestamp(date: Date())
            ]
        )
    }
    
    // MARK: - Mark Booking as Completed
    @MainActor
    func completeBooking(bookingId: String) async throws {
        try await firebaseService.updateDocument(
            in: firebaseService.bookingsCollection,
            documentId: bookingId,
            fields: [
                FirestoreField.status: BookingStatus.completed.rawValue,
                "paymentStatus": PaymentStatus.fullyPaid.rawValue,
                FirestoreField.updatedAt: Timestamp(date: Date())
            ]
        )
    }
    
    // MARK: - Mark as No Show
    @MainActor
    func markAsNoShow(bookingId: String) async throws {
        try await firebaseService.updateDocument(
            in: firebaseService.bookingsCollection,
            documentId: bookingId,
            fields: [
                FirestoreField.status: BookingStatus.noShow.rawValue,
                FirestoreField.updatedAt: Timestamp(date: Date())
            ]
        )
    }
    
    // MARK: - Get Revenue Report
    @MainActor
    func getRevenueReport(facilityId: String, month: Date) async throws -> RevenueReport {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        let bookings = try await fetchFacilityBookings(
            facilityId: facilityId,
            status: .completed,
            startDate: startOfMonth,
            endDate: endOfMonth
        )
        
        let totalRevenue = bookings.reduce(0) { $0 + $1.totalPrice }
        let totalDeposits = bookings.reduce(0) { $0 + $1.depositAmount }
        let totalBookings = bookings.count
        
        // Günlük dağılım
        var dailyRevenue: [Date: Double] = [:]
        for booking in bookings {
            let day = calendar.startOfDay(for: booking.date)
            dailyRevenue[day, default: 0] += booking.totalPrice
        }
        
        return RevenueReport(
            month: month,
            totalRevenue: totalRevenue,
            totalDeposits: totalDeposits,
            totalBookings: totalBookings,
            dailyRevenue: dailyRevenue
        )
    }
    
    // MARK: - Mock Data
    func loadMockAdminFacilities() -> [Facility] {
        return [
            Facility(
                id: "admin_facility_1",
                ownerId: firebaseService.currentUserId ?? "admin",
                name: "Yıldız Spor Tesisleri",
                description: "Modern tesislerimizde profesyonel sahalarımızla hizmetinizdeyiz.",
                taxNumber: "1234567890",
                phone: "+902121234567",
                address: "Ataşehir, İstanbul",
                latitude: 40.9923,
                longitude: 29.1244,
                images: [],
                amenities: FacilityAmenities(
                    hasParking: true,
                    hasShower: true,
                    hasLockerRoom: true,
                    hasCafe: true,
                    isIndoor: false,
                    hasLighting: true
                ),
                status: .approved,
                averageRating: 4.8,
                totalReviews: 256
            )
        ]
    }
    
    func loadMockAdminBookings() -> [Booking] {
        return [
            Booking(
                id: "admin_booking_1",
                userId: "user1",
                facilityId: "admin_facility_1",
                pitchId: "pitch1",
                facilityName: "Yıldız Spor Tesisleri",
                pitchName: "Saha 1",
                facilityAddress: "Ataşehir, İstanbul",
                facilityPhone: "+902121234567",
                userFullName: "Ahmet Yılmaz",
                userPhone: "5551234567",
                date: Date(),
                startHour: 19,
                endHour: 20,
                totalPrice: 650,
                depositAmount: 130,
                remainingAmount: 520,
                currency: "TRY",
                status: .confirmed,
                paymentStatus: .depositPaid,
                ticketNumber: "HS-2024-001"
            ),
            Booking(
                id: "admin_booking_2",
                userId: "user2",
                facilityId: "admin_facility_1",
                pitchId: "pitch1",
                facilityName: "Yıldız Spor Tesisleri",
                pitchName: "Saha 1",
                facilityAddress: "Ataşehir, İstanbul",
                facilityPhone: "+902121234567",
                userFullName: "Mehmet Kaya",
                userPhone: "5559876543",
                date: Date(),
                startHour: 20,
                endHour: 21,
                totalPrice: 650,
                depositAmount: 130,
                remainingAmount: 520, currency: "TRY",
                status: .confirmed,
                paymentStatus: .depositPaid,
                ticketNumber: "HS-2024-002"
            ),
            Booking(
                id: "admin_booking_3",
                userId: "user3",
                facilityId: "admin_facility_1",
                pitchId: "pitch2",
                facilityName: "Yıldız Spor Tesisleri",
                pitchName: "Saha 2",
                facilityAddress: "Ataşehir, İstanbul",
                facilityPhone: "+902121234567",
                userFullName: "Ali Demir",
                userPhone: "5554567890",
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                startHour: 18,
                endHour: 19,
                totalPrice: 700,
                depositAmount: 140,
                remainingAmount: 560, currency: "TRY",
                status: .pending,
                paymentStatus: .depositPaid,
                ticketNumber: "HS-2024-003"
            )
        ]
    }
}

// MARK: - Revenue Report
struct RevenueReport {
    let month: Date
    let totalRevenue: Double
    let totalDeposits: Double
    let totalBookings: Int
    let dailyRevenue: [Date: Double]
    
    var averagePerBooking: Double {
        totalBookings > 0 ? totalRevenue / Double(totalBookings) : 0
    }
}

// MARK: - Admin Error
enum AdminError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case invalidData
    case facilityNotFound
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Bu işlem için giriş yapmanız gerekiyor."
        case .notAuthorized:
            return "Bu işlem için yetkiniz yok."
        case .invalidData:
            return "Geçersiz veri."
        case .facilityNotFound:
            return "Tesis bulunamadı."
        case .operationFailed(let message):
            return message
        }
    }
}
