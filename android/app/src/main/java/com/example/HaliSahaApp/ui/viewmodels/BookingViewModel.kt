package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.BookingStatus
import com.example.HaliSahaApp.data.services.BookingService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// MARK: - Filter Enum
enum class BookingFilter(val displayName: String) {
    UPCOMING("Yaklaşan"),
    PAST("Geçmiş"),
    CANCELLED("İptal")
}

// MARK: - UI State
data class BookingsUiState(
    val bookings: List<Booking> = emptyList(),
    val filteredBookings: List<Booking> = emptyList(),
    val selectedFilter: BookingFilter = BookingFilter.UPCOMING,
    val isLoading: Boolean = false,
    val error: String? = null
)

// MARK: - ViewModel
class BookingsViewModel : ViewModel() {

    private val bookingService = BookingService
    private val _uiState = MutableStateFlow(BookingsUiState())
    val uiState: StateFlow<BookingsUiState> = _uiState.asStateFlow()

    init {
        loadBookings()
    }

    fun loadBookings() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            try {
                // Şimdilik Mock Data (Gerçek data için: bookingService.fetchUserBookings())
                val bookings = bookingService.loadMockBookings()

                _uiState.update {
                    it.copy(bookings = bookings, isLoading = false)
                }
                applyFilter()
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false, error = e.localizedMessage) }
            }
        }
    }

    fun setFilter(filter: BookingFilter) {
        _uiState.update { it.copy(selectedFilter = filter) }
        applyFilter()
    }

    private fun applyFilter() {
        val currentState = _uiState.value
        val result = when (currentState.selectedFilter) {
            BookingFilter.UPCOMING -> currentState.bookings.filter { !it.isPast && it.status == BookingStatus.CONFIRMED }
            BookingFilter.PAST -> currentState.bookings.filter { it.isPast || it.status == BookingStatus.COMPLETED }
            BookingFilter.CANCELLED -> currentState.bookings.filter { it.status == BookingStatus.CANCELLED }
        }
        _uiState.update { it.copy(filteredBookings = result) }
    }

    suspend fun refresh() {
        // Gerçek senaryoda servisten tekrar çekilir
        loadBookings()
    }
}