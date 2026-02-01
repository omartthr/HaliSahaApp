package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.models.Pitch
import com.example.HaliSahaApp.data.models.TimeSlot
import com.example.HaliSahaApp.data.models.UserType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.data.services.BookingService
import com.example.HaliSahaApp.data.services.FacilityService
import com.example.HaliSahaApp.utils.formattedTurkish
import com.example.HaliSahaApp.utils.isWeekend
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Date

// MARK: - UI State
data class FacilityDetailUiState(
    val facility: Facility? = null,
    val pitches: List<Pitch> = emptyList(),
    val selectedPitch: Pitch? = null,
    val isLoading: Boolean = false,
    val isFavorite: Boolean = false,
    val error: String? = null,

    // Booking Flow
    val selectedDate: Date = Date(),
    val availableTimeSlots: List<TimeSlot> = emptyList(),
    val selectedStartHour: Int? = null,
    val selectedEndHour: Int? = null,
    val showBookingFlow: Boolean = false,
    val showGuestAlert: Boolean = false
) {
    val selectedDuration: Int
        get() {
            return if (selectedStartHour != null && selectedEndHour != null) {
                selectedEndHour - selectedStartHour
            } else 0
        }

    val totalPrice: Double
        get() {
            if (selectedPitch == null || selectedStartHour == null) return 0.0
            return selectedPitch.pricing.calculatePrice(
                startHour = selectedStartHour,
                duration = selectedDuration,
                isWeekend = selectedDate.isWeekend()
            )
        }

    val canProceedToBooking: Boolean
        get() = selectedPitch != null &&
                selectedStartHour != null &&
                selectedEndHour != null &&
                selectedDuration > 0
}

// MARK: - ViewModel
class FacilityDetailViewModel(
    private val facilityId: String // ID ile başlatıyoruz
) : ViewModel() {

    private val facilityService = FacilityService
    private val bookingService = BookingService
    private val authService = AuthService

    private val _uiState = MutableStateFlow(FacilityDetailUiState())
    val uiState: StateFlow<FacilityDetailUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    // MARK: - Load Data
    private fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                // Facility'yi cache'den veya networkten çek
                val facility = facilityService.fetchFacility(facilityId)
                _uiState.update { it.copy(facility = facility) }

                checkFavoriteStatus()
                loadPitches()
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.localizedMessage, isLoading = false) }
            }
        }
    }

    // MARK: - Load Pitches
    private suspend fun loadPitches() {
        try {
            val pitches = facilityService.fetchPitches(facilityId)
            _uiState.update {
                it.copy(
                    pitches = pitches,
                    selectedPitch = pitches.firstOrNull(),
                    isLoading = false
                )
            }
            loadTimeSlots()
        } catch (e: Exception) {
            // Hata olursa veya veri yoksa mock yükle (Geliştirme aşaması için)
            // loadMockData() // İstersen buraya mock fallback ekleyebilirsin
            _uiState.update { it.copy(isLoading = false) }
        }
    }

    // MARK: - Load Time Slots
    private fun loadTimeSlots() {
        val currentState = _uiState.value
        val pitch = currentState.selectedPitch ?: return
        val facility = currentState.facility ?: return

        viewModelScope.launch {
            try {
                val slots = bookingService.getAvailableTimeSlots(
                    facility = facility,
                    pitch = pitch,
                    date = currentState.selectedDate
                )
                _uiState.update { it.copy(availableTimeSlots = slots) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Saatler yüklenemedi") }
            }
        }
    }

    // MARK: - Actions

    fun selectDate(date: Date) {
        _uiState.update {
            it.copy(
                selectedDate = date,
                selectedStartHour = null,
                selectedEndHour = null
            )
        }
        loadTimeSlots()
    }

    fun selectPitch(pitch: Pitch) {
        _uiState.update {
            it.copy(
                selectedPitch = pitch,
                selectedStartHour = null,
                selectedEndHour = null
            )
        }
        loadTimeSlots()
    }

    fun selectTimeSlot(slot: TimeSlot) {
        if (!slot.isAvailable) return

        _uiState.update { current ->
            var start = current.selectedStartHour
            var end = current.selectedEndHour

            if (start == null) {
                // İlk seçim
                start = slot.hour
                end = slot.hour + 1
            } else {
                if (slot.hour < start) {
                    // Geriye doğru seçim: Yeni başlangıç
                    start = slot.hour
                    end = slot.hour + 1
                } else if (slot.hour >= start) {
                    // İleriye doğru seçim: Bitişi güncelle
                    val newEnd = slot.hour + 1

                    // Aradaki saatlerin müsaitliğini kontrol et
                    var allAvailable = true
                    for (h in start until newEnd) {
                        val s = current.availableTimeSlots.find { it.hour == h }
                        if (s == null || !s.isAvailable) {
                            allAvailable = false
                            break
                        }
                    }

                    if (allAvailable) {
                        end = newEnd
                    } else {
                        // Arada dolu varsa seçimi sıfırla, yeni başlangıç yap
                        start = slot.hour
                        end = slot.hour + 1
                    }
                }
            }
            current.copy(selectedStartHour = start, selectedEndHour = end)
        }
    }

    fun isSlotSelected(slot: TimeSlot): Boolean {
        val start = _uiState.value.selectedStartHour ?: return false
        val end = _uiState.value.selectedEndHour ?: return false
        return slot.hour >= start && slot.hour < end
    }

    fun toggleFavorite() {
        viewModelScope.launch {
            val isFav = _uiState.value.isFavorite
            try {
                if (isFav) {
                    facilityService.removeFromFavorites(facilityId)
                } else {
                    facilityService.addToFavorites(facilityId)
                }
                _uiState.update { it.copy(isFavorite = !isFav) }
            } catch (e: Exception) {
                // Hata yönetimi
            }
        }
    }

    private fun checkFavoriteStatus() {
        val currentUser = authService.currentUser.value
        val favorites = currentUser?.favoriteFields ?: emptyList()
        _uiState.update { it.copy(isFavorite = favorites.contains(facilityId)) }
    }

    fun proceedToBooking() {
        val isGuest = authService.currentUser.value?.userType == UserType.GUEST
        if (isGuest) {
            _uiState.update { it.copy(showGuestAlert = true) }
        } else {
            _uiState.update { it.copy(showBookingFlow = true) }
        }
    }

    fun dismissGuestAlert() {
        _uiState.update { it.copy(showGuestAlert = false) }
    }
}