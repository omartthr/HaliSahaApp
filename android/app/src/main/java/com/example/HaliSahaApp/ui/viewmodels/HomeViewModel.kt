package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.*
import com.example.HaliSahaApp.data.services.FacilityService
import com.example.HaliSahaApp.utils.AppIcons
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.Calendar

// MARK: - Home UI State
data class HomeUiState(
    val searchText: String = "",
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val errorMessage: String? = null,
    val featuredFacilities: List<Facility> = emptyList(),
    val nearbyFacilities: List<Facility> = emptyList(),
    val upcomingMatches: List<MatchPost> = emptyList(),
    val selectedFilter: HomeFilter = HomeFilter.ALL
) {
    val filteredFacilities: List<Facility>
        get() {
            var facilities = nearbyFacilities

            if (searchText.isNotEmpty()) {
                facilities = facilities.filter { facility ->
                    facility.name.contains(searchText, ignoreCase = true) ||
                            facility.address.contains(searchText, ignoreCase = true)
                }
            }

            facilities = when (selectedFilter) {
                HomeFilter.ALL -> facilities
                HomeFilter.INDOOR -> facilities.filter { it.amenities.isIndoor }
                HomeFilter.OUTDOOR -> facilities.filter { !it.amenities.isIndoor }
                HomeFilter.HIGH_RATED -> facilities.filter { it.averageRating >= 4.0 }
                HomeFilter.HAS_PARKING -> facilities.filter { it.amenities.hasParking }
            }

            return facilities
        }

    val hasActiveFilters: Boolean
        get() = searchText.isNotEmpty() || selectedFilter != HomeFilter.ALL
}

// MARK: - Home ViewModel
class HomeViewModel : ViewModel() {

    private val facilityService = FacilityService // Servis bağlantısı

    // UI State
    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            loadData()
        }
    }

    // MARK: - Actions

    fun onSearchTextChange(text: String) {
        _uiState.update { it.copy(searchText = text) }
    }

    fun onFilterSelect(filter: HomeFilter) {
        _uiState.update { currentState ->
            val newFilter = if (currentState.selectedFilter == filter) HomeFilter.ALL else filter
            currentState.copy(selectedFilter = newFilter)
        }
    }

    fun clearFilters() {
        _uiState.update { it.copy(searchText = "", selectedFilter = HomeFilter.ALL) }
    }

    suspend fun refreshData() {
        _uiState.update { it.copy(isRefreshing = true) }
        loadData() // Verileri tekrar çek
        _uiState.update { it.copy(isRefreshing = false) }
    }

    // MARK: - Data Loading
    private suspend fun loadData() {
        _uiState.update { it.copy(isLoading = true) }

        try {
            // 1. Tesisleri Servisten Çek
            val allFacilities = facilityService.fetchAllFacilities()

            // 2. Maç İlanlarını Oluştur (Şimdilik Local Mock)
            // FacilityService'e MatchPost servisi eklediğimizde oradan çekeceğiz
            val matches = listOf(
                MatchPost.mockPost,
                createMockMatchPost(
                    id = "mp2", title = "Pazar Sabahı Dostluk Maçı", facilityName = "Elit Arena",
                    neededPlayers = 3, currentPlayers = 11, maxPlayers = 14, daysFromNow = 4
                )
            )

            delay(500) // Yüklenme efekti için küçük gecikme

            _uiState.update {
                it.copy(
                    isLoading = false,
                    // İlk 3 tanesini öne çıkan yapalım
                    featuredFacilities = allFacilities.take(3),
                    // Hepsini yakındakiler olarak gösterelim
                    nearbyFacilities = allFacilities,
                    upcomingMatches = matches
                )
            }
        } catch (e: Exception) {
            _uiState.update {
                it.copy(isLoading = false, errorMessage = e.localizedMessage)
            }
        }
    }

    // MARK: - Helper: Create Mock Match Post
    // (Facility createMock fonksiyonunu sildik çünkü artık Service yapıyor)
    private fun createMockMatchPost(
        id: String, title: String, facilityName: String,
        neededPlayers: Int, currentPlayers: Int, maxPlayers: Int, daysFromNow: Int
    ): MatchPost {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, daysFromNow)

        return MatchPost(
            id = id,
            creatorId = "user123",
            creatorName = "Mehmet K.",
            bookingId = "booking_$id",
            facilityId = "facility_$id",
            facilityName = facilityName,
            facilityAddress = "Ankara",
            pitchName = "Saha 1",
            matchDate = calendar.time,
            startHour = 19,
            endHour = 20,
            title = title,
            neededPlayers = neededPlayers,
            currentPlayers = currentPlayers,
            maxPlayers = maxPlayers,
            skillLevel = SkillLevel.intermediate,
            costPerPlayer = 80.0
        )
    }
}

// MARK: - Home Filter Enum
enum class HomeFilter(val displayName: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    ALL("Tümü", AppIcons.Filter),
    INDOOR("Kapalı", AppIcons.Indoor),
    OUTDOOR("Açık", AppIcons.Outdoor),
    HIGH_RATED("Yüksek Puan", AppIcons.Star),
    HAS_PARKING("Otoparkı Var", AppIcons.Parking)
}