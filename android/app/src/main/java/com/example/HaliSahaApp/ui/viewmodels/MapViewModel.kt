package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.models.UserLocation
import com.example.HaliSahaApp.data.services.FacilityFilters
import com.example.HaliSahaApp.data.services.FacilityService
import com.example.HaliSahaApp.data.services.LocationService
import com.example.HaliSahaApp.utils.AppConstants
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// MARK: - Map UI State
data class MapUiState(
    val facilities: List<Facility> = emptyList(),
    val filteredFacilities: List<Facility> = emptyList(),
    val selectedFacility: Facility? = null,
    val isLoading: Boolean = false,
    val error: String? = null,

    // UI Controls
    val showListView: Boolean = false,
    val showFilters: Boolean = false, // BottomSheet kontrolü için
    val searchText: String = "",
    val filters: FacilityFilters = FacilityFilters(),

    // Map State
    val userLocation: UserLocation? = null,
    val cameraPosition: CameraPosition? = null // Harita kamerasını güncellemek için
) {
    val hasActiveFilters: Boolean
        get() = searchText.isNotEmpty() || filters.hasActiveFilters
}

// MARK: - Map ViewModel
class MapViewModel : ViewModel() {

    private val facilityService = FacilityService
    private val locationService = LocationService

    private val _uiState = MutableStateFlow(MapUiState())
    val uiState: StateFlow<MapUiState> = _uiState.asStateFlow()

    init {
        // Varsayılan kamera pozisyonu (İstanbul)
        val defaultLatLng = LatLng(AppConstants.DEFAULT_LATITUDE, AppConstants.DEFAULT_LONGITUDE)
        _uiState.update {
            it.copy(cameraPosition = CameraPosition.fromLatLngZoom(defaultLatLng, AppConstants.DEFAULT_MAP_ZOOM))
        }

        setupBindings()

        viewModelScope.launch {
            loadFacilities()
        }
    }

    // MARK: - Setup Bindings (Konum Dinleme)
    private fun setupBindings() {
        viewModelScope.launch {
            locationService.userLocation.collectLatest { location ->
                _uiState.update { it.copy(userLocation = location) }

                // Eğer ilk kez konum geldiyse oraya odaklan
                if (location != null && _uiState.value.facilities.isEmpty()) {
                    centerOnUserLocation()
                }

                // Mesafeleri yeniden hesapla veya listeyi güncelle (opsiyonel)
                applyFilters()
            }
        }
    }

    // MARK: - Load Facilities
    private suspend fun loadFacilities() {
        _uiState.update { it.copy(isLoading = true, error = null) }

        try {
            // Şimdilik Mock Data (Service'deki)
            val loadedFacilities = facilityService.loadMockFacilities()
            // İleride: facilityService.fetchAllFacilities()

            _uiState.update {
                it.copy(
                    facilities = loadedFacilities,
                    isLoading = false
                )
            }
            applyFilters() // İlk yüklemede filtreleri uygula

        } catch (e: Exception) {
            _uiState.update { it.copy(isLoading = false, error = e.localizedMessage) }
        }
    }

    // MARK: - Filtering Logic
    private fun applyFilters() {
        val currentState = _uiState.value
        var result = currentState.facilities

        // Metin Araması
        if (currentState.searchText.isNotEmpty()) {
            val query = currentState.searchText.lowercase()
            result = result.filter { facility ->
                facility.name.lowercase().contains(query) ||
                        facility.address.lowercase().contains(query)
            }
        }

        // Filtreler
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
        }

        // Sıralama (Opsiyonel: Yakına göre sırala)
        currentState.userLocation?.let { userLoc ->
            result = result.sortedBy { facility ->
                val facLoc = UserLocation(facility.latitude, facility.longitude)
                userLoc.distanceTo(facLoc)
            }
        }

        _uiState.update { it.copy(filteredFacilities = result) }
    }

    // MARK: - Actions

    fun onSearchTextChange(text: String) {
        _uiState.update { it.copy(searchText = text) }
        applyFilters()
    }

    fun toggleViewMode() {
        _uiState.update { it.copy(showListView = !it.showListView) }
    }

    fun toggleFilters() {
        _uiState.update { it.copy(showFilters = !it.showFilters) }
    }

    fun selectFacility(facility: Facility?) {
        _uiState.update { it.copy(selectedFacility = facility) }

        if (facility != null) {
            centerOnFacility(facility)
        }
    }

    fun clearFilters() {
        _uiState.update {
            it.copy(searchText = "", filters = FacilityFilters())
        }
        applyFilters()
    }

    // Filtre güncelleme (BottomSheet'ten gelecek)
    fun updateFilters(newFilters: FacilityFilters) {
        _uiState.update { it.copy(filters = newFilters) }
        applyFilters()
    }

    // MARK: - Map Actions

    fun centerOnUserLocation() {
        val location = _uiState.value.userLocation ?: return
        val target = LatLng(location.latitude, location.longitude)

        _uiState.update {
            it.copy(cameraPosition = CameraPosition.fromLatLngZoom(target, 14f))
        }
    }

    private fun centerOnFacility(facility: Facility) {
        val target = LatLng(facility.latitude, facility.longitude)
        _uiState.update {
            it.copy(cameraPosition = CameraPosition.fromLatLngZoom(target, 16f))
        }
    }

    fun requestLocationPermission(context: android.content.Context) {
        // İzin isteme mantığı UI (Screen) tarafında LaunchedEffect ile tetiklenmeli
        // veya Accompanist Permissions kütüphanesi kullanılmalı.
        // ViewModel sadece "izin istendi" state'ini tutabilir veya servise yönlendirebilir.
        locationService.startUpdatingLocation(context)
    }

    // MARK: - Helpers

    fun getDistanceString(facility: Facility): String {
        val userLoc = _uiState.value.userLocation ?: return ""
        val facLoc = UserLocation(facility.latitude, facility.longitude)
        val distance = userLoc.distanceTo(facLoc) // km döner

        return if (distance < 1.0) {
            String.format("%.0f m", distance * 1000)
        } else {
            String.format("%.1f km", distance)
        }
    }
}