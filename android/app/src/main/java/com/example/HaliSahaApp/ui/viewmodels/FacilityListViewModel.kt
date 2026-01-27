package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.models.UserLocation
import com.example.HaliSahaApp.data.services.FacilityFilters
import com.example.HaliSahaApp.data.services.FacilityService
import com.example.HaliSahaApp.data.services.LocationService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// MARK: - Sort Option Enum
enum class SortOption(val displayName: String) {
    DISTANCE("Mesafe"),
    RATING("Puan"),
    NAME("İsim")
}

// MARK: - Facility List UI State
data class FacilityListUiState(
    val facilities: List<Facility> = emptyList(),
    val filteredFacilities: List<Facility> = emptyList(),
    val searchText: String = "",
    val filters: FacilityFilters = FacilityFilters(),
    val sortOption: SortOption = SortOption.DISTANCE,
    val isLoading: Boolean = false,
    val userLocation: UserLocation? = null
) {
    val hasActiveFilters: Boolean
        get() = searchText.isNotEmpty() || filters.hasActiveFilters
}

// MARK: - Facility List ViewModel
class FacilityListViewModel : ViewModel() {

    private val facilityService = FacilityService
    private val locationService = LocationService

    private val _uiState = MutableStateFlow(FacilityListUiState())
    val uiState: StateFlow<FacilityListUiState> = _uiState.asStateFlow()

    init {
        // Konum bilgisini al
        viewModelScope.launch {
            locationService.userLocation.collect { location ->
                _uiState.update { it.copy(userLocation = location) }
                // Konum değişirse mesafeleri tekrar hesaplayabiliriz
                if (_uiState.value.sortOption == SortOption.DISTANCE) {
                    applyFiltersAndSort()
                }
            }
        }

        loadFacilities()
    }

    // MARK: - Load Data
    fun loadFacilities() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            // Mock Data veya Service
            val facilities = facilityService.loadMockFacilities()
            // Gerçek implementation: facilityService.fetchAllFacilities()

            _uiState.update {
                it.copy(
                    facilities = facilities,
                    isLoading = false
                )
            }
            applyFiltersAndSort()
        }
    }

    // MARK: - Filtering & Sorting Logic
    private fun applyFiltersAndSort() {
        val currentState = _uiState.value
        var result = currentState.facilities

        // 1. Arama Filtresi
        if (currentState.searchText.isNotEmpty()) {
            val query = currentState.searchText.lowercase()
            result = result.filter { facility ->
                facility.name.lowercase().contains(query) ||
                        facility.address.lowercase().contains(query)
            }
        }

        // 2. Özellik Filtreleri
        val filters = currentState.filters
        if (filters.hasActiveFilters) {
            filters.isIndoor?.let { isIndoor ->
                result = result.filter { it.amenities.isIndoor == isIndoor }
            }
            filters.minRating?.let { minRating ->
                result = result.filter { it.averageRating >= minRating }
            }
            if (filters.hasParking) result = result.filter { it.amenities.hasParking }
            if (filters.hasShower) result = result.filter { it.amenities.hasShower }
            if (filters.hasCafe) result = result.filter { it.amenities.hasCafe }
            if (filters.hasEquipmentRental) result = result.filter { it.amenities.hasEquipmentRental }
        }

        // 3. Sıralama
        result = when (currentState.sortOption) {
            SortOption.DISTANCE -> {
                val userLoc = currentState.userLocation ?: LocationService.defaultLocation
                result.sortedBy { facility ->
                    val facLoc = UserLocation(facility.latitude, facility.longitude)
                    userLoc.distanceTo(facLoc)
                }
            }
            SortOption.RATING -> result.sortedByDescending { it.averageRating }
            SortOption.NAME -> result.sortedBy { it.name }
        }

        _uiState.update { it.copy(filteredFacilities = result) }
    }

    // MARK: - Actions
    fun onSearchTextChange(text: String) {
        _uiState.update { it.copy(searchText = text) }
        applyFiltersAndSort()
    }

    fun onSortOptionChange(option: SortOption) {
        _uiState.update { it.copy(sortOption = option) }
        applyFiltersAndSort()
    }

    fun clearFilters() {
        _uiState.update { it.copy(searchText = "", filters = FacilityFilters()) }
        applyFiltersAndSort()
    }

    // Filtre ekranından dönen yeni filtreler
    fun updateFilters(newFilters: FacilityFilters) {
        _uiState.update { it.copy(filters = newFilters) }
        applyFiltersAndSort()
    }

    // MARK: - Helpers
    fun getDistance(facility: Facility): Double? {
        val userLoc = _uiState.value.userLocation ?: return null
        val facLoc = UserLocation(facility.latitude, facility.longitude)
        return userLoc.distanceTo(facLoc)
    }
}