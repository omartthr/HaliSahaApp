package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.services.AdminService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date

// MARK: - UI State
data class AdminDashboardUiState(
    val stats: AdminService.DashboardStats = AdminService.DashboardStats(),
    val todayBookings: List<Booking> = emptyList(),
    val facilities: List<Facility> = emptyList(),
    val isLoading: Boolean = false
)

// MARK: - ViewModel
class AdminDashboardViewModel : ViewModel() {

    val adminService = AdminService
    private val _uiState = MutableStateFlow(AdminDashboardUiState())
    val uiState: StateFlow<AdminDashboardUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            // Mock Data
            val facilities = adminService.loadMockAdminFacilities()
            val allBookings = adminService.loadMockAdminBookings() // Buna erişim açılmalı (public yap)
            val todayBookings = allBookings.filter { isSameDay(it.date, Date()) }

            // Stats
            val stats = AdminService.DashboardStats(
                totalFacilities = facilities.size,
                todayBookings = todayBookings.size,
                pendingBookings = allBookings.count { it.status == com.example.HaliSahaApp.data.models.BookingStatus.PENDING },
                monthlyRevenue = 15750.0,
                averageRating = 4.8
            )

            _uiState.update {
                it.copy(
                    stats = stats,
                    todayBookings = todayBookings,
                    facilities = facilities,
                    isLoading = false
                )
            }
        }
    }

    private fun isSameDay(date1: Date, date2: Date): Boolean {
        val cal1 = Calendar.getInstance().apply { time = date1 }
        val cal2 = Calendar.getInstance().apply { time = date2 }
        return cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR) &&
                cal1.get(Calendar.DAY_OF_YEAR) == cal2.get(Calendar.DAY_OF_YEAR)
    }
}