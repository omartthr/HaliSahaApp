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
              let start = selectedStartHour else { return 0 }
        
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
        selectedPitch != nil &&
        selectedStartHour != nil &&
        selectedEndHour != nil &&
        selectedDuration > 0
    }
    
    var isGuestUser: Bool {
        authService.currentUser?.userType == .guest
    }
    
    // MARK: - Init
    init(facility: Facility) {
        self.facility = facility
        loadMockData()
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
            // Mock data kullan
            loadMockData()
        }
    }
    
    // MARK: - Load Time Slots
    func loadTimeSlots() async {
        guard let pitch = selectedPitch else { return }
        
        do {
            availableTimeSlots = try await bookingService.getAvailableTimeSlots(
                facility: facility,
                pitch: pitch,
                date: selectedDate
            )
        } catch {
            // Mock time slots
            availableTimeSlots = generateMockTimeSlots()
        }
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
        
        if selectedStartHour == nil {
            // İlk seçim: başlangıç saati
            selectedStartHour = slot.hour
            selectedEndHour = slot.hour + 1
        } else if let start = selectedStartHour {
            if slot.hour < start {
                // Yeni başlangıç saati
                selectedStartHour = slot.hour
                selectedEndHour = slot.hour + 1
            } else if slot.hour >= start {
                // Bitiş saatini güncelle (ardışık saat kontrolü)
                let newEnd = slot.hour + 1
                
                // Aradaki saatler müsait mi kontrol et
                var allAvailable = true
                for hour in start..<newEnd {
                    if let slotForHour = availableTimeSlots.first(where: { $0.hour == hour }),
                       !slotForHour.isAvailable {
                        allAvailable = false
                        break
                    }
                }
                
                if allAvailable {
                    selectedEndHour = newEnd
                } else {
                    // Yeni seçim başlat
                    selectedStartHour = slot.hour
                    selectedEndHour = slot.hour + 1
                }
            }
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
              let favorites = authService.currentUser?.favoriteFields else {
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
    
    // MARK: - Mock Data
    private func loadMockData() {
        pitches = [
            Pitch(
                id: "pitch1",
                facilityId: facility.id ?? "",
                name: "Saha 1",
                description: "Ana saha - Profesyonel zemin",
                pitchType: .outdoor,
                surfaceType: .syntheticGrass,
                size: .fiveASide,
                capacity: 10,
                images: [],
                pricing: PitchPricing(
                    daytimePrice: 500,
                    eveningPrice: 650,
                    weekendMultiplier: 1.2,
                    depositPercentage: 0.20
                )
            ),
            Pitch(
                id: "pitch2",
                facilityId: facility.id ?? "",
                name: "Saha 2",
                description: "Kapalı saha - Klimali",
                pitchType: .indoor,
                surfaceType: .syntheticGrass,
                size: .sixASide,
                capacity: 10,
                images: [],
                pricing: PitchPricing(
                    daytimePrice: 600,
                    eveningPrice: 750,
                    weekendMultiplier: 1.2,
                    depositPercentage: 0.20
                )
            )
        ]
        
        selectedPitch = pitches.first
        availableTimeSlots = generateMockTimeSlots()
    }
    
    private func generateMockTimeSlots() -> [TimeSlot] {
        var slots: [TimeSlot] = []
        let basePrice: Double = selectedPitch?.pricing.daytimePrice ?? 500
        let eveningPrice: Double = selectedPitch?.pricing.eveningPrice ?? 650
        
        for hour in 9..<23 {
            let isEvening = hour >= 18
            let price = isEvening ? eveningPrice : basePrice
            
            // Rastgele bazı slotları dolu yap
            let isBooked = [10, 14, 19, 20].contains(hour)
            
            // Geçmiş saatleri kontrol et
            let now = Date()
            let slotDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate)!
            let isPast = slotDate < now
            
            slots.append(TimeSlot(
                date: selectedDate,
                hour: hour,
                isAvailable: !isBooked && !isPast,
                price: price
            ))
        }
        
        return slots
    }
}
