package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import com.example.HaliSahaApp.data.services.AdminService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID

enum class ReportPeriod(val displayName: String) {
    THIS_WEEK("Bu Hafta"),
    THIS_MONTH("Bu Ay"),
    LAST_MONTH("Geçen Ay"),
    CUSTOM("Özel")
}

data class RevenueDataPoint(val day: String, val revenue: Double)

data class AdminReportsUiState(
    val revenueData: List<RevenueDataPoint> = emptyList(),
    val totalRevenue: Double = 0.0,
    val totalBookings: Int = 0,
    val averageRevenue: Double = 0.0,
    val occupancyRate: Int = 0,
    val cancellationRate: Int = 0,
    val selectedPeriod: ReportPeriod = ReportPeriod.THIS_MONTH
)

class AdminReportsViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(AdminReportsUiState())
    val uiState: StateFlow<AdminReportsUiState> = _uiState.asStateFlow()

    init {
        loadMockData()
    }

    fun loadMockData() {
        val data = listOf(
            RevenueDataPoint("Pzt", 2100.0),
            RevenueDataPoint("Sal", 1800.0),
            RevenueDataPoint("Çar", 2400.0),
            RevenueDataPoint("Per", 1950.0),
            RevenueDataPoint("Cum", 2800.0),
            RevenueDataPoint("Cmt", 3200.0),
            RevenueDataPoint("Paz", 1500.0)
        )

        _uiState.value = AdminReportsUiState(
            revenueData = data,
            totalRevenue = 15750.0,
            totalBookings = 48,
            averageRevenue = 328.0,
            occupancyRate = 68,
            cancellationRate = 8
        )
    }
}