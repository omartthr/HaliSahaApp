package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.BookingStatus
import com.example.HaliSahaApp.data.services.AdminService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date

// MARK: - Filter Enum
enum class AdminBookingFilter(val displayName: String) {
    ALL("Tümü"),
    TODAY("Bugün"),
    PENDING("Bekleyen"),
    CONFIRMED("Onaylı"),
    COMPLETED("Tamamlanan"),
    CANCELLED("İptal")
}

// MARK: - UI State
data class AdminBookingsUiState(
    val allBookings: List<Booking> = emptyList(),
    val filteredBookings: List<Booking> = emptyList(),
    val selectedDate: Date = Date(),
    val isLoading: Boolean = false,
    val selectedFilter: AdminBookingFilter = AdminBookingFilter.ALL
) {
    val confirmedCount: Int get() = filteredBookings.count { it.status == BookingStatus.confirmed }
    val pendingCount: Int get() = filteredBookings.count { it.status == BookingStatus.pending }
    val totalRevenue: Double get() = filteredBookings.sumOf { it.depositAmount }
}

// MARK: - ViewModel
class AdminBookingsViewModel : ViewModel() {
    val adminService = AdminService
    private val _uiState = MutableStateFlow(AdminBookingsUiState())
    val uiState: StateFlow<AdminBookingsUiState> = _uiState.asStateFlow()

    init {
        loadBookings()
    }

    fun loadBookings() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val bookings = adminService.fetchAllBookings() // Gerçek data
            _uiState.update {
                it.copy(
                    allBookings = bookings,
                    isLoading = false
                )
            }
            applyFilter(_uiState.value.selectedFilter)
        }
    }

    fun applyFilter(filter: AdminBookingFilter) {
        val currentState = _uiState.value
        val all = currentState.allBookings
        val date = currentState.selectedDate

        val filtered = when (filter) {
            AdminBookingFilter.ALL -> all
            AdminBookingFilter.TODAY -> all.filter { isSameDay(it.date, Date()) }
            AdminBookingFilter.PENDING -> all.filter { it.status == BookingStatus.pending }
            AdminBookingFilter.CONFIRMED -> all.filter { it.status == BookingStatus.confirmed }
            AdminBookingFilter.COMPLETED -> all.filter { it.status == BookingStatus.completed }
            AdminBookingFilter.CANCELLED -> all.filter { it.status == BookingStatus.cancelled }
        }

        // Tarih filtresi (Sadece ALL seçili değilse tarihe göre de filtrele)
        // Not: Swift kodunda date picker değişince loadBookings çağrılıyor.
        // Biz burada basitlik için client-side filtreleme yapabiliriz.

        _uiState.update { it.copy(filteredBookings = filtered, selectedFilter = filter) }
    }

    fun countForFilter(filter: AdminBookingFilter): Int {
        val all = _uiState.value.allBookings
        return when (filter) {
            AdminBookingFilter.ALL -> all.size
            AdminBookingFilter.TODAY -> all.count { isSameDay(it.date, Date()) }
            AdminBookingFilter.PENDING -> all.count { it.status == BookingStatus.pending }
            AdminBookingFilter.CONFIRMED -> all.count { it.status == BookingStatus.confirmed }
            AdminBookingFilter.COMPLETED -> all.count { it.status == BookingStatus.completed }
            AdminBookingFilter.CANCELLED -> all.count { it.status == BookingStatus.cancelled }
        }
    }

    fun changeDate(offset: Int) {
        val calendar = Calendar.getInstance()
        calendar.time = _uiState.value.selectedDate
        calendar.add(Calendar.DAY_OF_YEAR, offset)
        _uiState.update { it.copy(selectedDate = calendar.time) }
        // loadBookings() // Gerçek senaryoda API çağrısı
    }

    // Actions
    fun confirmBooking(booking: Booking) = viewModelScope.launch {
        booking.id?.let { adminService.confirmBooking(it) }
        loadBookings()
    }

    fun rejectBooking(booking: Booking) = viewModelScope.launch {
        booking.id?.let { adminService.rejectBooking(it, "Admin reddetti") }
        loadBookings()
    }

    fun completeBooking(booking: Booking) = viewModelScope.launch {
        booking.id?.let {
            // AdminService'e completeBooking eklenmeli (aşağıda ekledim)
            // adminService.completeBooking(it)
        }
        loadBookings()
    }

    fun markAsNoShow(booking: Booking) = viewModelScope.launch {
        booking.id?.let {
            // adminService.markAsNoShow(it)
        }
        loadBookings()
    }

    // Helper
    private fun isSameDay(date1: Date, date2: Date): Boolean {
        val cal1 = Calendar.getInstance().apply { time = date1 }
        val cal2 = Calendar.getInstance().apply { time = date2 }
        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
                cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
    }
}
