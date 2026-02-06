package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.models.Pitch
import com.example.HaliSahaApp.data.models.TimeSlot
import com.example.HaliSahaApp.data.models.UserType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.data.services.BookingService
import com.example.HaliSahaApp.data.services.FacilityService
import com.example.HaliSahaApp.data.services.PaymentMethod
import com.example.HaliSahaApp.utils.isWeekend
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Calendar
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

    val depositAmount: Double
        get() {
            return selectedPitch?.pricing?.calculateDeposit(totalPrice) ?: 0.0
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

    fun closeBookingFlow() {
        _uiState.update { it.copy(showBookingFlow = false) }
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
                // Eğer facility bulunamazsa mock datadan çekmeye çalışabiliriz (Geliştirme için)
                // Şimdilik hata gösteriyoruz
                _uiState.update { it.copy(error = e.localizedMessage, isLoading = false) }
            }
        }
    }

    // MARK: - Load Pitches
    private suspend fun loadPitches() {
        try {
            val pitches = facilityService.fetchPitches(facilityId)

            // Eğer veritabanında pitch yoksa, UI boş kalmasın diye mock pitch ekleyelim
            val finalPitches = if (pitches.isEmpty()) {
                val mockPitch = Pitch.mockPitch.copy(facilityId = facilityId, name = "Saha 1 (Mock)")
                listOf(mockPitch)
            } else {
                pitches
            }

            _uiState.update {
                it.copy(
                    pitches = finalPitches,
                    selectedPitch = finalPitches.firstOrNull(),
                    isLoading = false
                )
            }
            loadTimeSlots()
        } catch (e: Exception) {
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
                // Servisten saatleri çekmeye çalış
                val slots = bookingService.getAvailableTimeSlots(
                    facility = facility,
                    pitch = pitch,
                    date = currentState.selectedDate
                )

                // Eğer servis boş dönerse (henüz rezervasyon yoksa veya hata varsa)
                // Geliştirme aşamasında ekran boş kalmasın diye Mock saatler üret
                if (slots.isEmpty()) {
                    val mockSlots = generateMockTimeSlots(pitch, currentState.selectedDate)
                    _uiState.update { it.copy(availableTimeSlots = mockSlots) }
                } else {
                    _uiState.update { it.copy(availableTimeSlots = slots) }
                }

            } catch (e: Exception) {
                // Hata durumunda da mock gösterelim ki test edebilelim
                val mockSlots = generateMockTimeSlots(pitch, currentState.selectedDate)
                _uiState.update { it.copy(availableTimeSlots = mockSlots) }
            }
        }
    }

    // MARK: - Generate Mock Time Slots (Fallback)
    private fun generateMockTimeSlots(pitch: Pitch, date: Date): List<TimeSlot> {
        val slots = mutableListOf<TimeSlot>()
        val calendar = Calendar.getInstance()
        calendar.time = date
        val isWeekend = date.isWeekend()

        // 09:00 - 24:00 arası
        for (hour in 9..23) {
            // Rastgele doluluk (Sadece bugünden sonraki günler için rastgelelik yapalım)
            // Bugün ise geçmiş saatleri kapat
            val isToday = Date().isToday()
            val currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

            var isAvailable = true

            if (isToday && hour <= currentHour) {
                isAvailable = false // Geçmiş saat
            } else {
                // %20 ihtimalle dolu olsun (görsellik için)
                isAvailable = Math.random() > 0.2
            }

            val price = pitch.pricing.calculatePrice(hour, 1, isWeekend)

            slots.add(TimeSlot(
                date = date,
                hour = hour,
                isAvailable = isAvailable,
                price = price
            ))
        }
        return slots
    }

    // Yardımcı: Date.isToday() extension'ı yoksa diye basit kontrol
    private fun Date.isToday(): Boolean {
        val cal1 = Calendar.getInstance()
        val cal2 = Calendar.getInstance()
        cal2.time = this
        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
                cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
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
        // Eğer slot doluysa veya geçmişse işlem yapma
        if (!slot.isAvailable) return

        _uiState.update { current ->
            // Eğer kullanıcı zaten seçili olan slota tekrar tıklarsa seçimi kaldır (Opsiyonel, kullanışlıdır)
            if (current.selectedStartHour == slot.hour) {
                current.copy(
                    selectedStartHour = null,
                    selectedEndHour = null
                )
            } else {
                // Yeni bir slota tıklandıysa, eski seçimi unut ve sadece bu saati seç (1 saatlik)
                current.copy(
                    selectedStartHour = slot.hour,
                    selectedEndHour = slot.hour + 1
                )
            }
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

    // MARK: - Booking Creation
    fun createBooking(
        paymentMethod: PaymentMethod,
        onSuccess: (Booking) -> Unit,
        onError: (String) -> Unit
    ) {
        val currentUser = authService.currentUser.value
        val pitch = _uiState.value.selectedPitch
        val startHour = _uiState.value.selectedStartHour
        val endHour = _uiState.value.selectedEndHour
        val date = _uiState.value.selectedDate
        val facility = _uiState.value.facility

        if (currentUser == null || pitch == null || startHour == null || endHour == null || facility == null) {
            onError("Eksik bilgi. Lütfen tekrar deneyin.")
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                // 1. Rezervasyon Oluştur
                val booking = bookingService.createBooking(
                    facility = facility,
                    pitch = pitch,
                    date = date,
                    startHour = startHour,
                    endHour = endHour,
                    user = currentUser
                )

                // 2. Ödeme Yap
                val paymentResult = bookingService.processPayment(booking, paymentMethod)

                if (paymentResult.success) {
                    // DÜZELTME: showBookingFlow = false SATIRINI KALDIRDIK.
                    // Sadece loading'i durduruyoruz.
                    _uiState.update { it.copy(isLoading = false) }

                    onSuccess(booking)
                } else {
                    _uiState.update { it.copy(isLoading = false) }
                    onError(paymentResult.message)
                }

            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false) }
                onError(e.localizedMessage ?: "Rezervasyon oluşturulamadı")
            }
        }
    }
}