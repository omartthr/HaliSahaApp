//
//  FacilityDetailViewModel.swift
//  HaliSahaApp
//
//  Saha Detay ViewModel
//
//  Created by Mehmet Mert Mazıcı on 13.01.2026.
//

import Foundation
import SwiftUI

// MARK: - Facility Detail ViewModel
@MainActor
final class FacilityDetailViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var facility: Facility
    @Published var pitches: [Pitch] = []
    @Published var selectedPitch: Pitch?
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var isFavorite = false
    @Published var error: String?

    // Booking Flow
    @Published var selectedDate: Date = Date()
    @Published var availableTimeSlots: [TimeSlot] = []
    @Published var selectedStartHour: Int?
    @Published var selectedEndHour: Int?
    @Published var showBookingFlow = false

    // MARK: - Private Properties
    private let facilityService = FacilityService.shared
    private let bookingService = BookingService.shared
    private let authService = AuthService.shared

    // MARK: - Computed Properties
    var selectedDuration: Int {
        guard let start = selectedStartHour, let end = selectedEndHour else { return 0 }
        return end - start
    }

    var totalPrice: Double {
        guard let pitch = selectedPitch,
            let start = selectedStartHour
        else { return 0 }

        return pitch.pricing.calculatePrice(
            startHour: start,
            duration: selectedDuration,
            isWeekend: selectedDate.isWeekend
        )
    }

    var depositAmount: Double {
        guard let pitch = selectedPitch else { return 0 }
        return pitch.pricing.calculateDeposit(totalPrice: totalPrice)
    }

    var canProceedToBooking: Bool {
        selectedPitch != nil && selectedStartHour != nil && selectedEndHour != nil
            && selectedDuration > 0
    }

    var isGuestUser: Bool {
        authService.currentUser?.userType == .guest
    }

    var hasPitches: Bool {
        !pitches.isEmpty
    }

    // MARK: - Init
    init(facility: Facility) {
        self.facility = facility
    }

    // MARK: - Load Data
    func loadData() async {
        isLoading = true

        await loadPitches()
        await loadTimeSlots()
        checkFavoriteStatus()

        isLoading = false
    }

    // MARK: - Load Pitches
    private func loadPitches() async {
        guard let facilityId = facility.id else { return }

        do {
            pitches = try await facilityService.fetchPitches(for: facilityId)
            if selectedPitch == nil, let firstPitch = pitches.first {
                selectedPitch = firstPitch
            }
        } catch {
            // Hata durumunda pitches boş kalır, empty state gösterilir
            pitches = []
            self.error = "Saha bilgileri yüklenemedi"
        }
    }

    // MARK: - Load Time Slots
    func loadTimeSlots() async {
        guard let pitch = selectedPitch else {
            availableTimeSlots = []
            return
        }

        do {
            let slots = try await bookingService.getAvailableTimeSlots(
                facility: facility,
                pitch: pitch,
                date: selectedDate
            )

            // Eğer boş dönerse fallback kullan
            if slots.isEmpty {
                availableTimeSlots = generateTimeSlotsFromOperatingHours(pitch: pitch)
            } else {
                availableTimeSlots = slots
            }
        } catch {
            // Hata durumunda tesisin çalışma saatlerinden üret
            availableTimeSlots = generateTimeSlotsFromOperatingHours(pitch: pitch)
        }
    }

    // MARK: - Generate Time Slots from Operating Hours
    private func generateTimeSlotsFromOperatingHours(pitch: Pitch) -> [TimeSlot] {
        var slots: [TimeSlot] = []

        // Günün çalışma saatlerini al
        let dayOfWeek = Calendar.current.component(.weekday, from: selectedDate)
        let hours = facility.operatingHours.hours(for: dayOfWeek)

        // Saat string'lerinden integer'a çevir (örn: "09:00" -> 9)
        let openHourInt = Int(hours.open.prefix(2)) ?? 9
        // "00:00" kapanış saati gece yarısı demek, 24 olarak ele al
        var closeHourInt = Int(hours.close.prefix(2)) ?? 23
        if closeHourInt == 0 {
            closeHourInt = 24  // Gece yarısı = 24
        }

        let isWeekend = selectedDate.isWeekend
        let now = Date()

        // Guard: Geçersiz saat aralığı kontrolü
        guard openHourInt < closeHourInt else {
            print("⚠️ Invalid hour range: open=\(openHourInt), close=\(closeHourInt)")
            return []
        }

        for hour in openHourInt..<closeHourInt {
            // Geçmiş saatleri kontrol et
            let slotDate =
                Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate)
                ?? selectedDate
            let isPast = slotDate < now

            let price = pitch.pricing.calculatePrice(
                startHour: hour,
                duration: 1,
                isWeekend: isWeekend
            )

            slots.append(
                TimeSlot(
                    date: selectedDate,
                    hour: hour,
                    isAvailable: !isPast,
                    price: price
                ))
        }

        return slots
    }

    // MARK: - Select Date
    func selectDate(_ date: Date) {
        selectedDate = date
        selectedStartHour = nil
        selectedEndHour = nil

        Task {
            await loadTimeSlots()
        }
    }

    // MARK: - Select Pitch
    func selectPitch(_ pitch: Pitch) {
        selectedPitch = pitch
        selectedStartHour = nil
        selectedEndHour = nil

        Task {
            await loadTimeSlots()
        }
    }

    // MARK: - Select Time Slot
    func selectTimeSlot(_ slot: TimeSlot) {
        guard slot.isAvailable else { return }

        // Tek saat seçimi - aynı saate tıklanırsa seçimi kaldır
        if selectedStartHour == slot.hour {
            selectedStartHour = nil
            selectedEndHour = nil
        } else {
            // Yeni saat seç
            selectedStartHour = slot.hour
            selectedEndHour = slot.hour + 1
        }
    }

    // MARK: - Is Slot Selected
    func isSlotSelected(_ slot: TimeSlot) -> Bool {
        guard let start = selectedStartHour, let end = selectedEndHour else { return false }
        return slot.hour >= start && slot.hour < end
    }

    // MARK: - Toggle Favorite
    func toggleFavorite() async {
        guard let facilityId = facility.id else { return }

        do {
            if isFavorite {
                try await facilityService.removeFromFavorites(facilityId: facilityId)
            } else {
                try await facilityService.addToFavorites(facilityId: facilityId)
            }
            isFavorite.toggle()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Check Favorite Status
    private func checkFavoriteStatus() {
        guard let facilityId = facility.id,
            let favorites = authService.currentUser?.favoriteFields
        else {
            isFavorite = false
            return
        }

        isFavorite = favorites.contains(facilityId)
    }

    // MARK: - Proceed to Booking
    func proceedToBooking() {
        guard !isGuestUser else { return }
        showBookingFlow = true
    }

}
