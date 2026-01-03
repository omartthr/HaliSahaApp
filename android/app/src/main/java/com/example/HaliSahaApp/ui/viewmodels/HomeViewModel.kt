package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.*
import com.example.HaliSahaApp.utils.AppIcons
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date

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
    // Filtrelenmiş tesisleri hesaplayan Computed Property
    val filteredFacilities: List<Facility>
        get() {
            var facilities = nearbyFacilities

            // Arama Filtresi
            if (searchText.isNotEmpty()) {
                facilities = facilities.filter { facility ->
                    facility.name.contains(searchText, ignoreCase = true) ||
                            facility.address.contains(searchText, ignoreCase = true)
                }
            }

            // Kategori Filtresi
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

    // UI State
    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    init {
        // Mock data yükle
        viewModelScope.launch {
            loadData()
        }
    }

    // MARK: - Actions

    fun onSearchTextChange(text: String) {
        _uiState.value = _uiState.value.copy(searchText = text)
    }

    fun onFilterSelect(filter: HomeFilter) {
        val currentFilter = _uiState.value.selectedFilter
        _uiState.value = _uiState.value.copy(
            selectedFilter = if (currentFilter == filter) HomeFilter.ALL else filter
        )
    }

    fun clearFilters() {
        _uiState.value = _uiState.value.copy(
            searchText = "",
            selectedFilter = HomeFilter.ALL
        )
    }

    suspend fun refreshData() {
        _uiState.value = _uiState.value.copy(isRefreshing = true)
        delay(1000) // Simüle edilmiş gecikme
        loadMockData()
        _uiState.value = _uiState.value.copy(isRefreshing = false)
    }

    private suspend fun loadData() {
        _uiState.value = _uiState.value.copy(isLoading = true)
        delay(500)
        loadMockData()
        _uiState.value = _uiState.value.copy(isLoading = false)
    }

    // MARK: - Mock Data Logic
    private fun loadMockData() {
        val featured = listOf(
            createMockFacility(
                id = "f1", name = "Yıldız Spor Tesisleri", address = "Gölbaşı, Ankara",
                rating = 4.8, reviewCount = 256, isIndoor = false, hasParking = true
            ),
            createMockFacility(
                id = "f2", name = "Elit Arena", address = "Keçiören, Ankara",
                rating = 4.9, reviewCount = 189, isIndoor = true, hasParking = true
            ),
            createMockFacility(
                id = "f3", name = "Green Field", address = "Çankaya, Ankara",
                rating = 4.6, reviewCount = 142, isIndoor = false, hasParking = false
            )
        )

        val nearby = listOf(
            createMockFacility(
                id = "f4", name = "Spor Vadisi", address = "Mamak, Ankara",
                rating = 4.5, reviewCount = 98, isIndoor = false, hasParking = true
            ),
            createMockFacility(
                id = "f5", name = "Gol Park", address = "Altındağ, Ankara",
                rating = 4.3, reviewCount = 76, isIndoor = true, hasParking = true
            ),
            createMockFacility(
                id = "f6", name = "Sahil Arena", address = "Gölbaşı, Ankara",
                rating = 4.7, reviewCount = 134, isIndoor = false, hasParking = false
            ),
            createMockFacility(
                id = "f7", name = "Merkez Spor", address = "Gölbaşı, Ankara",
                rating = 4.2, reviewCount = 54, isIndoor = true, hasParking = true
            )
        )

        val upcoming = listOf(
            MatchPost.mockPost,
            createMockMatchPost(
                id = "mp2", title = "Pazar Sabahı Dostluk Maçı", facilityName = "Elit Arena",
                neededPlayers = 3, currentPlayers = 11, maxPlayers = 14, daysFromNow = 4
            )
        )

        _uiState.value = _uiState.value.copy(
            featuredFacilities = featured,
            nearbyFacilities = nearby,
            upcomingMatches = upcoming
        )
    }

    // MARK: - Helper: Create Mock Facility
    private fun createMockFacility(
        id: String, name: String, address: String, rating: Double,
        reviewCount: Int, isIndoor: Boolean, hasParking: Boolean
    ): Facility {
        return Facility(
            id = id,
            ownerId = "owner_$id",
            name = name,
            description = "Modern tesisimizde profesyonel sahalarımızla hizmetinizdeyiz.",
            taxNumber = "123456789",
            phone = "+902121234567",
            address = address,
            latitude = 41.0 + Math.random() * 0.2 - 0.1,
            longitude = 29.0 + Math.random() * 0.2 - 0.1,
            images = listOf("facility_placeholder"), // Resim URL veya placeholder
            amenities = FacilityAmenities(
                hasParking = hasParking,
                hasShower = true,
                hasLockerRoom = true,
                hasCafe = Math.random() > 0.5,
                isIndoor = isIndoor,
                hasLighting = true
            ),
            status = FacilityStatus.APPROVED,
            averageRating = rating,
            totalReviews = reviewCount
        )
    }

    // MARK: - Helper: Create Mock Match Post
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
            skillLevel = SkillLevel.INTERMEDIATE,
            costPerPlayer = 80.0
        )
    }
}

// MARK: - Home Filter Enum
enum class HomeFilter(val displayName: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    ALL("Tümü", AppIcons.Filter), // square.grid.2x2 yerine Filter kullandık
    INDOOR("Kapalı", AppIcons.Indoor),
    OUTDOOR("Açık", AppIcons.Outdoor),
    HIGH_RATED("Yüksek Puan", AppIcons.Star),
    HAS_PARKING("Otoparkı Var", AppIcons.Parking)
}