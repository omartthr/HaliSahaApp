package com.example.HaliSahaApp.data.services

import com.example.HaliSahaApp.data.models.*
import com.example.HaliSahaApp.data.remote.*
import com.example.HaliSahaApp.utils.AppConstants
import com.google.firebase.firestore.FieldValue
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date

// MARK: - Facility Service
object FacilityService {

    private val firebaseService = FirebaseService
    private val locationService = LocationService

    // MARK: - UI State (Swift'teki @Published karşılığı)
    private val _facilities = MutableStateFlow<List<Facility>>(emptyList())
    val facilities: StateFlow<List<Facility>> = _facilities.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<FacilityError?>(null)
    val error: StateFlow<FacilityError?> = _error.asStateFlow()

    // Cache
    private val facilitiesCache = mutableMapOf<String, Facility>()
    private val pitchesCache = mutableMapOf<String, List<Pitch>>()
    private var lastFetchTime: Long = 0
    private const val CACHE_EXPIRATION = 5 * 60 * 1000L // 5 dakika (milisaniye)

    // MARK: - Fetch All Facilities
    suspend fun fetchAllFacilities(forceRefresh: Boolean = false): List<Facility> {
        // Cache kontrolü
        if (!forceRefresh &&
            System.currentTimeMillis() - lastFetchTime < CACHE_EXPIRATION &&
            _facilities.value.isNotEmpty()
        ) {
            return _facilities.value
        }

        _isLoading.value = true
        _error.value = null

        return try {
            val query = firebaseService.facilitiesCollection
                .whereEqualTo(FirestoreField.STATUS, FacilityStatus.APPROVED.rawValue)
                .whereEqualTo(FirestoreField.IS_ACTIVE, true)

            val fetchedFacilities: List<Facility> = firebaseService.fetchDocuments(query)

            // Cache güncelle
            _facilities.value = fetchedFacilities
            lastFetchTime = System.currentTimeMillis()

            fetchedFacilities.forEach { facility ->
                facility.id?.let { facilitiesCache[it] = facility }
            }

            _isLoading.value = false
            fetchedFacilities

        } catch (e: Exception) {
            _isLoading.value = false
            val err = FacilityError.FetchFailed(e.localizedMessage ?: "Hata")
            _error.value = err
            throw err
        }
    }

    // MARK: - Fetch Single Facility
    suspend fun fetchFacility(id: String): Facility {
        // Cache kontrolü
        facilitiesCache[id]?.let { return it }

        return try {
            val facility: Facility = firebaseService.fetchDocument(
                collection = firebaseService.facilitiesCollection,
                documentId = id
            )
            facilitiesCache[id] = facility
            facility
        } catch (e: Exception) {
            throw FacilityError.NotFound
        }
    }

    // MARK: - Fetch Nearby Facilities
    suspend fun fetchNearbyFacilities(
        location: UserLocation? = null,
        radiusKm: Double = AppConstants.NEARBY_RADIUS_KM
    ): List<Facility> {
        val targetLocation = location ?: locationService.userLocation.value ?: locationService.defaultLocation

        // Tüm tesisleri al (daha sonra GeoFire gibi bir kütüphane ile optimize edilebilir)
        val allFacilities = fetchAllFacilities()

        return allFacilities
            .map { facility ->
                val facilityLocation = UserLocation(facility.latitude, facility.longitude)
                val distance = targetLocation.distanceTo(facilityLocation)
                Pair(facility, distance)
            }
            .filter { it.second <= radiusKm }
            .sortedBy { it.second }
            .map { it.first }
    }

    // MARK: - Search Facilities
    suspend fun searchFacilities(
        query: String,
        filters: FacilityFilters? = null
    ): List<Facility> {
        var allFacilities = fetchAllFacilities()

        // Metin araması
        if (query.isNotEmpty()) {
            val lowerQuery = query.lowercase()
            allFacilities = allFacilities.filter { facility ->
                facility.name.lowercase().contains(lowerQuery) ||
                        facility.address.lowercase().contains(lowerQuery) ||
                        facility.description.lowercase().contains(lowerQuery)
            }
        }

        // Filtreler
        if (filters != null) {
            allFacilities = applyFilters(allFacilities, filters)
        }

        return allFacilities
    }

    // MARK: - Apply Filters
    private fun applyFilters(facilities: List<Facility>, filters: FacilityFilters): List<Facility> {
        var filtered = facilities

        // Kapalı/Açık alan
        filters.isIndoor?.let { isIndoor ->
            filtered = filtered.filter { it.amenities.isIndoor == isIndoor }
        }

        // Puan
        filters.minRating?.let { minRating ->
            filtered = filtered.filter { it.averageRating >= minRating }
        }

        // Özellikler
        if (filters.hasParking) filtered = filtered.filter { it.amenities.hasParking }
        if (filters.hasShower) filtered = filtered.filter { it.amenities.hasShower }
        if (filters.hasCafe) filtered = filtered.filter { it.amenities.hasCafe }
        if (filters.hasEquipmentRental) filtered = filtered.filter { it.amenities.hasEquipmentRental }

        return filtered
    }

    // MARK: - Fetch Pitches
    suspend fun fetchPitches(facilityId: String): List<Pitch> {
        // Cache kontrolü
        pitchesCache[facilityId]?.let { return it }

        return try {
            val query = firebaseService.pitchesCollection(facilityId)
                .whereEqualTo(FirestoreField.IS_ACTIVE, true)

            val pitches: List<Pitch> = firebaseService.fetchDocuments(query)
            pitchesCache[facilityId] = pitches
            pitches
        } catch (e: Exception) {
            throw FacilityError.FetchFailed(e.localizedMessage ?: "Hata")
        }
    }

    // MARK: - Favorites
    suspend fun addToFavorites(facilityId: String) {
        val userId = firebaseService.currentUserId ?: throw FacilityError.NotAuthenticated
        try {
            firebaseService.updateDocument(
                collection = firebaseService.usersCollection,
                documentId = userId,
                fields = mapOf("favoriteFields" to FieldValue.arrayUnion(facilityId))
            )
        } catch (e: Exception) {
            throw FacilityError.Unknown(e.localizedMessage ?: "Favoriye eklenemedi")
        }
    }

    suspend fun removeFromFavorites(facilityId: String) {
        val userId = firebaseService.currentUserId ?: throw FacilityError.NotAuthenticated
        try {
            firebaseService.updateDocument(
                collection = firebaseService.usersCollection,
                documentId = userId,
                fields = mapOf("favoriteFields" to FieldValue.arrayRemove(facilityId))
            )
        } catch (e: Exception) {
            throw FacilityError.Unknown(e.localizedMessage ?: "Favoriden silinemedi")
        }
    }

    fun isFavorite(facilityId: String, userFavorites: List<String>): Boolean {
        return userFavorites.contains(facilityId)
    }

    // MARK: - Clear Cache
    fun clearCache() {
        facilitiesCache.clear()
        pitchesCache.clear()
        lastFetchTime = 0
    }

    // MARK: - Mock Data
    fun loadMockFacilities(): List<Facility> {
        val mockFacilities = listOf(
            Facility(
                id = "mock1",
                ownerId = "owner1",
                name = "Yıldız Spor Tesisleri",
                description = "İstanbul'un en modern halı saha kompleksi",
                taxNumber = "1234567890",
                phone = "+902121234567",
                address = "Ataşehir, İstanbul",
                latitude = 40.9923,
                longitude = 29.1244,
                images = emptyList(),
                amenities = FacilityAmenities(hasParking = true, hasShower = true, hasLockerRoom = true, hasCafe = true, isIndoor = false, hasLighting = true),
                status = FacilityStatus.APPROVED,
                averageRating = 4.8,
                totalReviews = 256
            ),
            Facility(
                id = "mock2",
                ownerId = "owner2",
                name = "Elit Arena",
                description = "Kapalı alan profesyonel saha",
                taxNumber = "0987654321",
                phone = "+902161234567",
                address = "Kadıköy, İstanbul",
                latitude = 40.9823,
                longitude = 29.0544,
                images = emptyList(),
                amenities = FacilityAmenities(hasParking = true, hasShower = true, hasLockerRoom = true, hasCafe = false, isIndoor = true, hasLighting = true, hasHeating = true),
                status = FacilityStatus.APPROVED,
                averageRating = 4.9,
                totalReviews = 189
            )
            // Diğer mock veriler eklenebilir...
        )

        _facilities.value = mockFacilities
        mockFacilities.forEach { facility ->
            facility.id?.let { facilitiesCache[it] = facility }
        }
        return mockFacilities
    }
}

// MARK: - Facility Filters Data Class
data class FacilityFilters(
    var isIndoor: Boolean? = null,
    var minRating: Double? = null,
    var maxPrice: Double? = null,
    var hasParking: Boolean = false,
    var hasShower: Boolean = false,
    var hasCafe: Boolean = false,
    var hasEquipmentRental: Boolean = false,
    var date: Date? = null,
    var startHour: Int? = null,
    var endHour: Int? = null
) {
    val hasActiveFilters: Boolean
        get() = isIndoor != null ||
                minRating != null ||
                maxPrice != null ||
                hasParking ||
                hasShower ||
                hasCafe ||
                hasEquipmentRental ||
                date != null

    fun reset() {
        isIndoor = null
        minRating = null
        maxPrice = null
        hasParking = false
        hasShower = false
        hasCafe = false
        hasEquipmentRental = false
        date = null
        startHour = null
        endHour = null
    }
}

// MARK: - Facility Error Sealed Class
sealed class FacilityError(message: String) : Exception(message) {
    class FetchFailed(message: String) : FacilityError("Veriler yüklenemedi: $message")
    object NotFound : FacilityError("Tesis bulunamadı.")
    object NotAuthenticated : FacilityError("Bu işlem için giriş yapmanız gerekiyor.")
    object PermissionDenied : FacilityError("Bu işlem için yetkiniz yok.")
    class Unknown(message: String) : FacilityError(message)
}