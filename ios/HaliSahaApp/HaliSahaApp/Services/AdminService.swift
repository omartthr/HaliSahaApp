//
//  AdminService.swift
//  HaliSahaApp
//
//  Admin işlemleri servisi - Tesis ve rezervasyon yönetimi
//
//  Created by Mehmet Mert Mazıcı on 24.01.2026.
//

import FirebaseFirestore
import Foundation

// MARK: - Admin Service
final class AdminService: ObservableObject {

    // MARK: - Singleton
    static let shared = AdminService()

    // MARK: - Published Properties
    @Published var myFacilities: [Facility] = []
    @Published var pendingBookings: [Booking] = []
    @Published var todayBookings: [Booking] = []
    @Published var isLoading = false

    /// Mevcut admin'in profili — onay durumu / belgeler için anlık güncellenir.
    /// AdminTabView'in routing'i bunu dinler.
    @Published var myAdminProfile: AdminProfile?

    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private let authService = AuthService.shared
    private var adminProfileListener: ListenerRegistration?

    // MARK: - Private Init
    private init() {}

    deinit {
        adminProfileListener?.remove()
    }

    // MARK: - Admin Profile Listener (canlı durum)
    /// Mevcut admin için Firestore snapshot dinleyicisi başlatır.
    /// approvalStatus, documents, rejectionReason değişimlerinde anında UI güncellenir.
    @MainActor
    func startMyAdminProfileListener() {
        guard let userId = firebaseService.currentUserId else { return }

        // Aynı listener tekrar tekrar başlatılmasın
        adminProfileListener?.remove()

        adminProfileListener = firebaseService.adminsCollection
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("⚠️ Admin profile listener error: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot, snapshot.exists else {
                    self.myAdminProfile = nil
                    return
                }
                do {
                    self.myAdminProfile = try snapshot.data(as: AdminProfile.self)
                } catch {
                    print("⚠️ Admin profile decode error: \(error.localizedDescription)")
                }
            }
    }

    @MainActor
    func stopMyAdminProfileListener() {
        adminProfileListener?.remove()
        adminProfileListener = nil
        myAdminProfile = nil
    }

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
        let allTodayBookings: [Booking] = try await firebaseService.fetchDocuments(
            query: todayQuery)
        let facilityIds = Set(facilities.compactMap { $0.id })
        let myTodayBookings = allTodayBookings.filter { facilityIds.contains($0.facilityId) }

        stats.todayBookings = myTodayBookings.count
        self.todayBookings = myTodayBookings

        // Bekleyen rezervasyonlar
        let pendingQuery = firebaseService.bookingsCollection
            .whereField(FirestoreField.status, isEqualTo: BookingStatus.pending.rawValue)

        let allPendingBookings: [Booking] = try await firebaseService.fetchDocuments(
            query: pendingQuery)
        let myPendingBookings = allPendingBookings.filter { facilityIds.contains($0.facilityId) }

        stats.pendingBookings = myPendingBookings.count
        self.pendingBookings = myPendingBookings

        // Aylık gelir ve rezervasyon
        let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let startOfNextMonth = Calendar.current.date(
            byAdding: .month, value: 1, to: startOfMonth)!

        let monthlyQuery = firebaseService.bookingsCollection
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
            .whereField(FirestoreField.date, isLessThan: Timestamp(date: startOfNextMonth))

        let allMonthlyBookings: [Booking] = try await firebaseService.fetchDocuments(
            query: monthlyQuery)
        let monthlyBookings = allMonthlyBookings.filter {
            facilityIds.contains($0.facilityId)
                && ($0.status == .confirmed || $0.status == .completed)
        }

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
            throw AdminError.operationFailed(
                "Tesisler yüklenirken hata: \(error.localizedDescription)")
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
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        var newFacility = facility
        newFacility.ownerId = userId
        newFacility.status = .pending  // Onay bekliyor

        // autoConfirmBookings kullanıcı tercihinin facility üzerine kopyalanması:
        // müşteri ödeme akışında bu alanı facility'den okuyacak (admins/{uid}'i
        // okuyamaz). Tercih daha önce override edilmediyse admin profilinden gelsin.
        if newFacility.autoConfirmBookings == nil {
            let adminDoc = try? await firebaseService.adminsCollection
                .document(userId)
                .getDocument()
            newFacility.autoConfirmBookings =
                adminDoc?.data()?["autoConfirmBookings"] as? Bool ?? true
        }

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

        // Server-side timestamp ile güncelleme
        try await firebaseService.updateDocument(
            in: firebaseService.facilitiesCollection,
            documentId: facilityId,
            fields: [
                "name": facility.name,
                "description": facility.description,
                "taxNumber": facility.taxNumber,
                "phone": facility.phone,
                "email": facility.email as Any,
                "address": facility.address,
                "latitude": facility.latitude,
                "longitude": facility.longitude,
                "images": facility.images,
                "amenities": try Firestore.Encoder().encode(facility.amenities),
                "operatingHours": try Firestore.Encoder().encode(facility.operatingHours),
                "isActive": facility.isActive,
                FirestoreField.updatedAt: Timestamp(date: Date()),  // Server timestamp
            ]
        )
    }

    // MARK: - Update Denormalized Facility Data
    @MainActor
    func updateDenormalizedFacilityData(
        facilityId: String,
        newName: String? = nil,
        newPhone: String? = nil,
        newAddress: String? = nil
    ) async throws {
        // Mevcut rezervasyonları bul
        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.facilityId, isEqualTo: facilityId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: Date()))  // Gelecek rezervasyonlar

        let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)

        // Batch update
        let batch = firebaseService.db.batch()

        for booking in bookings {
            guard let bookingId = booking.id else { continue }

            var updates: [String: Any] = [:]
            if let name = newName { updates["facilityName"] = name }
            if let phone = newPhone { updates["facilityPhone"] = phone }
            if let address = newAddress { updates["facilityAddress"] = address }

            if !updates.isEmpty {
                let ref = firebaseService.bookingsCollection.document(bookingId)
                batch.updateData(updates, forDocument: ref)
            }
        }

        try await batch.commit()
    }

    // MARK: - Create Pitch
    @MainActor
    func createPitch(_ pitch: Pitch, facilityId: String) async throws -> String {
        guard !facilityId.isEmpty else {
            throw AdminError.invalidData
        }

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

        // Server-side timestamp ile güncelleme
        try await firebaseService.updateDocument(
            in: firebaseService.pitchesCollection(for: facilityId),
            documentId: pitchId,
            fields: [
                "name": pitch.name,
                "description": pitch.description as Any,
                "pitchType": pitch.pitchType.rawValue,
                "surfaceType": pitch.surfaceType.rawValue,
                "size": pitch.size.rawValue,
                "capacity": pitch.capacity,
                "isActive": pitch.isActive,
                "images": pitch.images,
                "pricing": try Firestore.Encoder().encode(pitch.pricing),
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )

        // Pitch adı değiştiyse denormalized data'yı güncelle
        let nameChanged = true  // Önceki adı karşılaştırmak için ViewModel'den parametre gerekli
        if nameChanged {
            try await updateDenormalizedPitchData(pitchId: pitchId, newName: pitch.name)
        }
    }

    // MARK: - Update Denormalized Pitch Data
    @MainActor
    func updateDenormalizedPitchData(
        pitchId: String,
        newName: String
    ) async throws {
        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.pitchId, isEqualTo: pitchId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: Date()))

        let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)

        let batch = firebaseService.db.batch()

        for booking in bookings {
            guard let bookingId = booking.id else { continue }
            let ref = firebaseService.bookingsCollection.document(bookingId)
            batch.updateData(["pitchName": newName], forDocument: ref)
        }

        try await batch.commit()
    }

    // MARK: - Delete Pitch
    @MainActor
    func deletePitch(pitchId: String, facilityId: String) async throws {
        let todayStart = Calendar.current.startOfDay(for: Date())

        let futureBookingsQuery = firebaseService.bookingsCollection
            .whereField(FirestoreField.pitchId, isEqualTo: pitchId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: todayStart))

        let futureBookings: [Booking] = try await firebaseService.fetchDocuments(
            query: futureBookingsQuery)
        let activeBookings = futureBookings.filter {
            $0.status == .pending || $0.status == .confirmed
        }

        if !activeBookings.isEmpty {
            throw AdminError.operationFailed(
                "Bu sahada \(activeBookings.count) aktif rezervasyon bulunuyor. Önce rezervasyonları iptal edin."
            )
        }

        try await firebaseService.deleteDocument(
            from: firebaseService.pitchesCollection(for: facilityId),
            documentId: pitchId
        )
    }

    // MARK: - Delete Facility
    @MainActor
    func deleteFacility(facilityId: String) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        // 1. Tesisin bu kullanıcıya ait olduğunu doğrula
        let facility: Facility = try await firebaseService.fetchDocument(
            from: firebaseService.facilitiesCollection,
            documentId: facilityId
        )

        guard facility.ownerId == userId else {
            throw AdminError.notAuthorized
        }

        // 2. Aktif rezervasyon kontrolü (gelecek rezervasyonları al, status'u client-side filtrele)
        let todayStart = Calendar.current.startOfDay(for: Date())
        let futureBookingsQuery = firebaseService.bookingsCollection
            .whereField(FirestoreField.facilityId, isEqualTo: facilityId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: todayStart))

        let futureBookings: [Booking] = try await firebaseService.fetchDocuments(
            query: futureBookingsQuery)

        // Client-side status filtresi (index sorunu olmadan)
        let activeBookings = futureBookings.filter { booking in
            booking.status == .pending || booking.status == .confirmed
        }

        if !activeBookings.isEmpty {
            throw AdminError.operationFailed(
                "Bu tesiste \(activeBookings.count) aktif rezervasyon bulunuyor. Önce rezervasyonları iptal edin."
            )
        }

        // 3. Alt sahaları (pitches) sil
        let pitches = try await fetchPitches(for: facilityId)
        for pitch in pitches {
            guard let pitchId = pitch.id else { continue }
            try await deletePitch(pitchId: pitchId, facilityId: facilityId)
        }

        // 4. Geçmiş rezervasyonları sil veya anonim yap (opsiyonel)
        let allBookingsQuery = firebaseService.bookingsCollection
            .whereField(FirestoreField.facilityId, isEqualTo: facilityId)

        let allBookings: [Booking] = try await firebaseService.fetchDocuments(
            query: allBookingsQuery)
        let batch = firebaseService.db.batch()

        for booking in allBookings {
            guard let bookingId = booking.id else { continue }
            let ref = firebaseService.bookingsCollection.document(bookingId)
            // Rezervasyonları silmek yerine tesisi "Silinmiş Tesis" olarak işaretleyebilirsiniz
            batch.updateData(
                [
                    "facilityName": "[Silinmiş Tesis]",
                    FirestoreField.updatedAt: Timestamp(date: Date()),
                ], forDocument: ref)
        }

        try await batch.commit()

        // 5. Tesisi sil
        try await firebaseService.deleteDocument(
            from: firebaseService.facilitiesCollection,
            documentId: facilityId
        )

        // 6. Lokal listeyi güncelle
        myFacilities.removeAll { $0.id == facilityId }
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
            query = query.whereField(
                FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: start))
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
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )

        // Kullanıcıya bildirim
        if let updated = try? await fetchBooking(id: bookingId) {
            await AppNotificationService.shared.notify(
                AppNotification.bookingConfirmed(userId: updated.userId, booking: updated)
            )
        }
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
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )

        // Kullanıcıya bildirim
        if let updated = try? await fetchBooking(id: bookingId) {
            await AppNotificationService.shared.notify(
                AppNotification.bookingCancelled(
                    userId: updated.userId,
                    booking: updated,
                    reason: reason
                )
            )
        }
    }

    // MARK: - Helper: Booking by ID
    @MainActor
    private func fetchBooking(id: String) async throws -> Booking {
        try await firebaseService.fetchDocument(
            from: firebaseService.bookingsCollection,
            documentId: id
        )
    }

    // MARK: - Complete Booking
    @MainActor
    func completeBooking(bookingId: String) async throws {
        try await firebaseService.updateDocument(
            in: firebaseService.bookingsCollection,
            documentId: bookingId,
            fields: [
                FirestoreField.status: BookingStatus.completed.rawValue,
                FirestoreField.updatedAt: Timestamp(date: Date()),
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
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )
    }

    // MARK: - Get Revenue Report
    @MainActor
    func getRevenueReport(facilityId: String, month: Date) async throws -> RevenueReport {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: month))!
        let endOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

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

    // MARK: - Fetch Facility Revenue (Toplam Gelir)
    @MainActor
    func fetchFacilityRevenue(for facilityId: String) async throws -> Double {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: Date()))!

        // Bu ayki tamamlanmış ve onaylanmış rezervasyonları çek
        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.facilityId, isEqualTo: facilityId)
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))

        let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)

        // Client-side filtrele: sadece tamamlanmış, onaylanmış veya completed olanları say
        let validBookings = bookings.filter { booking in
            booking.status == .confirmed || booking.status == .completed
        }

        // Toplam geliri hesapla (deposit tutarından veya totalPrice'dan)
        let totalRevenue = validBookings.reduce(0.0) { $0 + $1.depositAmount }

        return totalRevenue
    }

    // MARK: - Update Facility Images
    @MainActor
    func updateFacilityImages(facilityId: String, images: [String]) async throws {
        try await firebaseService.updateDocument(
            in: firebaseService.facilitiesCollection,
            documentId: facilityId,
            fields: [
                "images": images,
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )
    }

    // MARK: - Update Pitch Images
    @MainActor
    func updatePitchImages(pitchId: String, facilityId: String, images: [String]) async throws {
        try await firebaseService.updateDocument(
            in: firebaseService.pitchesCollection(for: facilityId),
            documentId: pitchId,
            fields: [
                "images": images,
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
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
            ),
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

// MARK: - Admin Reports Data Types
struct AdminReportData {
    var totalRevenue: Double = 0
    var totalBookings: Int = 0
    var averageRevenue: Double = 0
    var occupancyRate: Int = 0
    var cancellationRate: Int = 0
    var revenueData: [RevenueDataPoint] = []
    var distribution: BookingDistribution = BookingDistribution()
    var topHours: [PopularHour] = []
    var revenueChangePercent: Int = 0
    var comparisonLabel: String = "Geçen aya göre"
}

struct BookingDistribution: Hashable {
    var completedPercent: Int = 0
    var pendingPercent: Int = 0
    var cancelledPercent: Int = 0
    var emptyPercent: Int = 0
}

struct PopularHour: Identifiable, Hashable {
    let hour: Int
    let percentage: Int

    var id: Int { hour }

    var hourString: String {
        String(format: "%02d:00 - %02d:00", hour, hour + 1)
    }
}

// MARK: - Admin Settings Data
struct AdminSettingsData {
    var businessName: String = "İşletme Hesabı"
    var taxNumber: String = "-"
    var approvalStatus: AdminApprovalStatus = .pending
    var pushNotificationsEnabled: Bool = true
    var emailNotificationsEnabled: Bool = true
    var autoConfirmBookings: Bool = true
    var createdAt: Date?
    var approvedAt: Date?
}

// MARK: - Admin Reports
extension AdminService {

    @MainActor
    func fetchAdminSettings() async throws -> AdminSettingsData {
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        let document = try await firebaseService.adminsCollection.document(userId).getDocument()
        guard document.exists, let data = document.data() else {
            return AdminSettingsData()
        }

        let statusRaw = data[FirestoreField.approvalStatus] as? String
        let status = statusRaw.flatMap(AdminApprovalStatus.init(rawValue:)) ?? .pending

        let autoConfirm = data["autoConfirmBookings"] as? Bool ?? true

        // Bir defalık migration: admin profilindeki autoConfirmBookings,
        // alanı eksik olan facility'lere yazılır. Müşteri ödeme akışı bu alanı
        // facility'den okuduğu için eski tesislerin senkronize olması gerekir.
        Task { [weak self] in
            await self?.backfillAutoConfirmIfNeeded(ownerId: userId, value: autoConfirm)
        }

        return AdminSettingsData(
            businessName: data[FirestoreField.businessName] as? String ?? "İşletme Hesabı",
            taxNumber: data[FirestoreField.taxNumber] as? String ?? "-",
            approvalStatus: status,
            pushNotificationsEnabled: data["pushNotificationsEnabled"] as? Bool ?? true,
            emailNotificationsEnabled: data["emailNotificationsEnabled"] as? Bool ?? true,
            autoConfirmBookings: autoConfirm,
            createdAt: (data[FirestoreField.createdAt] as? Timestamp)?.dateValue(),
            approvedAt: (data["approvedAt"] as? Timestamp)?.dateValue()
        )
    }

    @MainActor
    private func backfillAutoConfirmIfNeeded(ownerId: String, value: Bool) async {
        do {
            let query = firebaseService.facilitiesCollection
                .whereField(FirestoreField.ownerId, isEqualTo: ownerId)
            let snapshot = try await query.getDocuments()

            let missing = snapshot.documents.filter { $0.data()["autoConfirmBookings"] == nil }
            guard !missing.isEmpty else { return }

            let batch = firebaseService.db.batch()
            for doc in missing {
                batch.updateData(["autoConfirmBookings": value], forDocument: doc.reference)
            }
            try await batch.commit()
        } catch {
            // Sessiz geç: migration başarısız olsa da ayar admin profilinde mevcut.
        }
    }

    @MainActor
    func updateAdminPreferences(
        pushNotificationsEnabled: Bool? = nil,
        emailNotificationsEnabled: Bool? = nil,
        autoConfirmBookings: Bool? = nil
    ) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        var fields: [String: Any] = [:]
        if let pushNotificationsEnabled {
            fields["pushNotificationsEnabled"] = pushNotificationsEnabled
        }
        if let emailNotificationsEnabled {
            fields["emailNotificationsEnabled"] = emailNotificationsEnabled
        }
        if let autoConfirmBookings {
            fields["autoConfirmBookings"] = autoConfirmBookings
        }

        guard !fields.isEmpty else { return }

        try await firebaseService.updateDocument(
            in: firebaseService.adminsCollection,
            documentId: userId,
            fields: fields
        )

        // autoConfirmBookings facility üzerine de mirror'lanır; çünkü
        // müşteri ödeme akışında admins/{uid}'i okuyamaz, facility'den okur.
        if let autoConfirmBookings {
            try? await mirrorAutoConfirmToFacilities(
                ownerId: userId,
                value: autoConfirmBookings
            )
        }
    }

    /// Admin'in tüm facility'lerinin autoConfirmBookings alanını günceller.
    /// Hata durumunda sessizce geçer (tercih ana admin profilinde zaten yazılmış olur).
    @MainActor
    private func mirrorAutoConfirmToFacilities(ownerId: String, value: Bool) async throws {
        let query = firebaseService.facilitiesCollection
            .whereField(FirestoreField.ownerId, isEqualTo: ownerId)
        let snapshot = try await query.getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        let batch = firebaseService.db.batch()
        for doc in snapshot.documents {
            batch.updateData(
                [
                    "autoConfirmBookings": value,
                    FirestoreField.updatedAt: FieldValue.serverTimestamp(),
                ],
                forDocument: doc.reference
            )
        }
        try await batch.commit()
    }

    @MainActor
    func fetchReportData(period: ReportPeriod) async throws -> AdminReportData {
        guard firebaseService.currentUserId != nil else {
            throw AdminError.notAuthenticated
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "tr_TR")
        calendar.firstWeekday = 2

        let facilities = try await fetchMyFacilities()
        let facilityIds = Set(facilities.compactMap { $0.id })

        guard !facilityIds.isEmpty else {
            return AdminReportData(comparisonLabel: comparisonLabel(for: period))
        }

        let range = computeDateRange(for: period, now: Date(), calendar: calendar)

        let currentBookings = try await fetchBookings(
            facilityIds: facilityIds,
            start: range.start,
            end: range.end
        )

        let previousBookings = try await fetchBookings(
            facilityIds: facilityIds,
            start: range.previousStart,
            end: range.previousEnd
        )

        var report = AdminReportData()
        report.comparisonLabel = range.comparisonLabel

        let revenueBookings = currentBookings.filter {
            $0.status == .confirmed || $0.status == .completed
        }
        report.totalRevenue = revenueBookings.reduce(0) { $0 + $1.depositAmount }
        report.totalBookings = currentBookings.count
        report.averageRevenue =
            report.totalBookings > 0 ? report.totalRevenue / Double(report.totalBookings) : 0

        let cancelledCount = currentBookings.filter { $0.status == .cancelled }.count
        report.cancellationRate =
            report.totalBookings > 0
            ? Int(
                (Double(cancelledCount) / Double(report.totalBookings) * 100).rounded()
            )
            : 0

        var totalAvailableHours = 0
        var totalActivePitches = 0

        for facility in facilities {
            guard let fid = facility.id else { continue }
            let pitches = try await fetchPitches(for: fid)
            let activePitches = pitches.filter { $0.isActive }
            totalActivePitches += activePitches.count

            var day = calendar.startOfDay(for: range.start)
            let endDay = calendar.startOfDay(for: range.end)
            while day < endDay {
                let weekday = calendar.component(.weekday, from: day)
                let (openStr, closeStr) = facility.operatingHours.hours(for: weekday)
                let openHour = parseHour(openStr) ?? 9
                var closeHour = parseHour(closeStr) ?? 23
                if closeHour <= openHour {
                    closeHour = openHour
                }
                let hoursOpen = max(closeHour - openHour, 0)
                totalAvailableHours += hoursOpen * activePitches.count
                day = calendar.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86400)
            }
        }

        let activeHours = revenueBookings.reduce(0) { $0 + max($1.endHour - $1.startHour, 0) }
        report.occupancyRate =
            totalAvailableHours > 0
            ? min(Int((Double(activeHours) / Double(totalAvailableHours) * 100).rounded()), 100)
            : 0

        var distribution = BookingDistribution()
        if totalAvailableHours > 0 {
            let pendingHours = currentBookings
                .filter { $0.status == .pending }
                .reduce(0) { $0 + max($1.endHour - $1.startHour, 0) }
            let cancelledHours = currentBookings
                .filter { $0.status == .cancelled }
                .reduce(0) { $0 + max($1.endHour - $1.startHour, 0) }

            distribution.completedPercent = min(
                Int((Double(activeHours) / Double(totalAvailableHours) * 100).rounded()),
                100
            )
            distribution.pendingPercent = min(
                Int((Double(pendingHours) / Double(totalAvailableHours) * 100).rounded()),
                100
            )
            distribution.cancelledPercent = min(
                Int((Double(cancelledHours) / Double(totalAvailableHours) * 100).rounded()),
                100
            )
            let usedSum =
                distribution.completedPercent + distribution.pendingPercent
                + distribution.cancelledPercent
            distribution.emptyPercent = max(100 - usedSum, 0)
        }
        report.distribution = distribution

        report.topHours = computeTopHours(
            bookings: revenueBookings,
            totalActivePitches: totalActivePitches,
            start: range.start,
            end: range.end,
            calendar: calendar
        )

        report.revenueData = aggregateRevenue(
            period: period,
            bookings: revenueBookings,
            start: range.start,
            end: range.end,
            calendar: calendar
        )

        let previousRevenue =
            previousBookings
            .filter { $0.status == .confirmed || $0.status == .completed }
            .reduce(0.0) { $0 + $1.depositAmount }

        if previousRevenue > 0 {
            let change = (report.totalRevenue - previousRevenue) / previousRevenue * 100
            report.revenueChangePercent = Int(change.rounded())
        } else if report.totalRevenue > 0 {
            report.revenueChangePercent = 100
        } else {
            report.revenueChangePercent = 0
        }

        return report
    }

    // MARK: - Reports Helpers
    fileprivate struct ReportDateRange {
        let start: Date
        let end: Date
        let previousStart: Date
        let previousEnd: Date
        let comparisonLabel: String
    }

    fileprivate func comparisonLabel(for period: ReportPeriod) -> String {
        switch period {
        case .thisWeek: return "Geçen haftaya göre"
        case .thisMonth: return "Geçen aya göre"
        case .lastMonth: return "Önceki aya göre"
        case .custom: return "Önceki 30 güne göre"
        }
    }

    fileprivate func computeDateRange(
        for period: ReportPeriod, now: Date, calendar: Calendar
    ) -> ReportDateRange {
        switch period {
        case .thisWeek:
            let today = calendar.startOfDay(for: now)
            let weekday = calendar.component(.weekday, from: today)
            let mondayOffset = (weekday - calendar.firstWeekday + 7) % 7
            let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today
            let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday) ?? today
            let prevMonday = calendar.date(byAdding: .day, value: -7, to: monday) ?? today
            return ReportDateRange(
                start: monday,
                end: nextMonday,
                previousStart: prevMonday,
                previousEnd: monday,
                comparisonLabel: "Geçen haftaya göre"
            )

        case .thisMonth:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: comps) ?? now
            let nextMonth =
                calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
            let prevMonth =
                calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? now
            return ReportDateRange(
                start: startOfMonth,
                end: nextMonth,
                previousStart: prevMonth,
                previousEnd: startOfMonth,
                comparisonLabel: "Geçen aya göre"
            )

        case .lastMonth:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: comps) ?? now
            let lastMonthStart =
                calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? now
            let monthBefore =
                calendar.date(byAdding: .month, value: -2, to: startOfMonth) ?? now
            return ReportDateRange(
                start: lastMonthStart,
                end: startOfMonth,
                previousStart: monthBefore,
                previousEnd: lastMonthStart,
                comparisonLabel: "Önceki aya göre"
            )

        case .custom:
            let endOfDay =
                calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
                ?? now
            let start30 =
                calendar.date(byAdding: .day, value: -30, to: endOfDay) ?? now
            let prev30Start =
                calendar.date(byAdding: .day, value: -60, to: endOfDay) ?? now
            return ReportDateRange(
                start: start30,
                end: endOfDay,
                previousStart: prev30Start,
                previousEnd: start30,
                comparisonLabel: "Önceki 30 güne göre"
            )
        }
    }

    fileprivate func fetchBookings(
        facilityIds: Set<String>, start: Date, end: Date
    ) async throws -> [Booking] {
        let query = firebaseService.bookingsCollection
            .whereField(FirestoreField.date, isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField(FirestoreField.date, isLessThan: Timestamp(date: end))

        let bookings: [Booking] = try await firebaseService.fetchDocuments(query: query)
        return bookings.filter { facilityIds.contains($0.facilityId) }
    }

    fileprivate func parseHour(_ str: String) -> Int? {
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        let firstSegment = trimmed.split(separator: ":").first.map(String.init) ?? trimmed
        return Int(firstSegment)
    }

    fileprivate func computeTopHours(
        bookings: [Booking], totalActivePitches: Int, start: Date, end: Date, calendar: Calendar
    ) -> [PopularHour] {
        var hourCounts: [Int: Int] = [:]
        for booking in bookings {
            let upper = max(booking.endHour, booking.startHour)
            for h in booking.startHour..<upper {
                hourCounts[h, default: 0] += 1
            }
        }

        guard !hourCounts.isEmpty else { return [] }

        let dayCount = max(
            calendar.dateComponents(
                [.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)
            ).day ?? 1,
            1
        )
        let maxPerHour = max(totalActivePitches * dayCount, 1)

        return hourCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { (hour, count) in
                let pct = min(
                    Int((Double(count) / Double(maxPerHour) * 100).rounded()), 100
                )
                return PopularHour(hour: hour, percentage: pct)
            }
    }

    fileprivate func aggregateRevenue(
        period: ReportPeriod, bookings: [Booking], start: Date, end: Date, calendar: Calendar
    ) -> [RevenueDataPoint] {
        switch period {
        case .thisWeek:
            let dayLabels = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
            var dailyRevenue: [Int: Double] = [:]
            for booking in bookings {
                let weekday = calendar.component(.weekday, from: booking.date)
                let mondayIndex = (weekday - 2 + 7) % 7
                dailyRevenue[mondayIndex, default: 0] += booking.depositAmount
            }
            return (0..<7).map { idx in
                RevenueDataPoint(day: dayLabels[idx], revenue: dailyRevenue[idx] ?? 0)
            }

        case .thisMonth, .lastMonth:
            let totalDays =
                calendar.dateComponents(
                    [.day], from: calendar.startOfDay(for: start),
                    to: calendar.startOfDay(for: end)
                ).day ?? 30
            let weekCount = max(Int(ceil(Double(totalDays) / 7.0)), 1)
            var weeklyRevenue: [Int: Double] = [:]
            for booking in bookings {
                let daysSinceStart =
                    calendar.dateComponents(
                        [.day], from: calendar.startOfDay(for: start),
                        to: calendar.startOfDay(for: booking.date)
                    ).day ?? 0
                let weekIdx = min(max(daysSinceStart / 7, 0), weekCount - 1)
                weeklyRevenue[weekIdx, default: 0] += booking.depositAmount
            }
            return (0..<weekCount).map { idx in
                RevenueDataPoint(day: "\(idx + 1). H", revenue: weeklyRevenue[idx] ?? 0)
            }

        case .custom:
            let weekCount = 5
            var weeklyRevenue: [Int: Double] = [:]
            for booking in bookings {
                let daysSinceStart =
                    calendar.dateComponents(
                        [.day], from: calendar.startOfDay(for: start),
                        to: calendar.startOfDay(for: booking.date)
                    ).day ?? 0
                let weekIdx = min(max(daysSinceStart / 7, 0), weekCount - 1)
                weeklyRevenue[weekIdx, default: 0] += booking.depositAmount
            }
            return (0..<weekCount).map { idx in
                RevenueDataPoint(day: "H\(idx + 1)", revenue: weeklyRevenue[idx] ?? 0)
            }
        }
    }
}

// MARK: - Admin Verification (Belge Yükleme & Onay Akışı)
extension AdminService {

    // MARK: - Mevcut admin'in profilini al
    @MainActor
    func fetchMyAdminProfile() async throws -> AdminProfile {
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        let profile: AdminProfile = try await firebaseService.fetchDocument(
            from: firebaseService.adminsCollection,
            documentId: userId
        )
        return profile
    }

    // MARK: - Belirli bir admin profilini al (super admin için)
    @MainActor
    func fetchAdminProfile(adminId: String) async throws -> AdminProfile {
        try await firebaseService.fetchDocument(
            from: firebaseService.adminsCollection,
            documentId: adminId
        )
    }

    // MARK: - Belgeleri Gönder (saha sahibi tarafı)
    /// Yüklenen belge URL'lerini admin profiline yazar ve durumu inceleme'ye alır.
    @MainActor
    func submitVerificationDocuments(_ documents: VerificationDocuments) async throws {
        guard let userId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        guard documents.isComplete else {
            throw AdminError.invalidData
        }

        let encoded = try Firestore.Encoder().encode(documents)

        try await firebaseService.updateDocument(
            in: firebaseService.adminsCollection,
            documentId: userId,
            fields: [
                FirestoreField.documents: encoded,
                FirestoreField.documentsSubmittedAt: Timestamp(date: Date()),
                FirestoreField.approvalStatus: AdminApprovalStatus.pending.rawValue,
                FirestoreField.rejectionReason: FieldValue.delete(),
                FirestoreField.updatedAt: Timestamp(date: Date()),
            ]
        )
    }

    // MARK: - Onay Bekleyen Admin'leri Listele (super admin için)
    /// Belgeleri yüklemiş ve henüz incelenmemiş başvurular.
    @MainActor
    func fetchPendingAdmins() async throws -> [AdminProfile] {
        let query = firebaseService.adminsCollection
            .whereField(FirestoreField.approvalStatus, isEqualTo: AdminApprovalStatus.pending.rawValue)

        let admins: [AdminProfile] = try await firebaseService.fetchDocuments(query: query)

        // Belgeleri henüz yüklememişler bu listede gözükmesin
        return admins
            .filter { $0.documentsSubmittedAt != nil }
            .sorted { ($0.documentsSubmittedAt ?? .distantPast) < ($1.documentsSubmittedAt ?? .distantPast) }
    }

    // MARK: - Tüm Admin'leri Listele (super admin için)
    @MainActor
    func fetchAllAdmins(status: AdminApprovalStatus? = nil) async throws -> [AdminProfile] {
        let query: Query
        if let status = status {
            query = firebaseService.adminsCollection
                .whereField(FirestoreField.approvalStatus, isEqualTo: status.rawValue)
        } else {
            query = firebaseService.adminsCollection
        }

        let admins: [AdminProfile] = try await firebaseService.fetchDocuments(query: query)
        return admins.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Admin'i Onayla (super admin için)
    @MainActor
    func approveAdmin(adminId: String) async throws {
        guard let reviewerId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        let now = Timestamp(date: Date())

        try await firebaseService.updateDocument(
            in: firebaseService.adminsCollection,
            documentId: adminId,
            fields: [
                FirestoreField.approvalStatus: AdminApprovalStatus.approved.rawValue,
                FirestoreField.approvedAt: now,
                FirestoreField.reviewedAt: now,
                FirestoreField.reviewedBy: reviewerId,
                FirestoreField.rejectionReason: FieldValue.delete(),
                FirestoreField.updatedAt: now,
            ]
        )
    }

    // MARK: - Admin'i Reddet (super admin için)
    @MainActor
    func rejectAdmin(adminId: String, reason: String) async throws {
        guard let reviewerId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AdminError.invalidData
        }

        let now = Timestamp(date: Date())

        try await firebaseService.updateDocument(
            in: firebaseService.adminsCollection,
            documentId: adminId,
            fields: [
                FirestoreField.approvalStatus: AdminApprovalStatus.rejected.rawValue,
                FirestoreField.rejectionReason: trimmed,
                FirestoreField.reviewedAt: now,
                FirestoreField.reviewedBy: reviewerId,
                FirestoreField.updatedAt: now,
            ]
        )
    }

    // MARK: - Admin'i Askıya Al (super admin için)
    @MainActor
    func suspendAdmin(adminId: String, reason: String) async throws {
        guard let reviewerId = firebaseService.currentUserId else {
            throw AdminError.notAuthenticated
        }

        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AdminError.invalidData
        }

        let now = Timestamp(date: Date())

        try await firebaseService.updateDocument(
            in: firebaseService.adminsCollection,
            documentId: adminId,
            fields: [
                FirestoreField.approvalStatus: AdminApprovalStatus.suspended.rawValue,
                FirestoreField.rejectionReason: trimmed,
                FirestoreField.reviewedAt: now,
                FirestoreField.reviewedBy: reviewerId,
                FirestoreField.updatedAt: now,
            ]
        )
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
