package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.services.AdminService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class AdminFacilitiesUiState(
    val facilities: List<Facility> = emptyList(),
    val isLoading: Boolean = false
)

class AdminFacilitiesViewModel : ViewModel() {

    private val adminService = AdminService
    private val _uiState = MutableStateFlow(AdminFacilitiesUiState())
    val uiState: StateFlow<AdminFacilitiesUiState> = _uiState.asStateFlow()

    init {
        loadFacilities()
    }

    fun loadFacilities() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val facilities = adminService.loadMockAdminFacilities()
            _uiState.update {
                it.copy(facilities = facilities, isLoading = false)
            }
        }
    }
}