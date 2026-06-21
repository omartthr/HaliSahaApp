package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.User
import com.example.HaliSahaApp.data.remote.AuthService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Locale

// MARK: - Profile Booking Stats
data class ProfileBookingStats(
    val total: Int = 0,
    val upcoming: Int = 0,
    val completed: Int = 0,
    val cancelled: Int = 0
) {
    companion object {
        val empty = ProfileBookingStats()
    }
}

// MARK: - Profile View Model
class ProfileViewModel : ViewModel() {

    // Dependencies
    private val authService = AuthService

    // State
    private val _bookingStats = MutableStateFlow(ProfileBookingStats.empty)
    val bookingStats: StateFlow<ProfileBookingStats> = _bookingStats.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    // Computed
    val currentUser: StateFlow<User?> = authService.currentUser

    val memberSinceText: String
        get() {
            val user = authService.currentUser.value ?: return "-"
            return try {
                val formatter = SimpleDateFormat("MMMM yyyy", Locale("tr", "TR"))
                val result = formatter.format(user.createdAt)
                result.replaceFirstChar { it.uppercase() }
            } catch (e: Exception) {
                "-"
            }
        }

    val favoritesCount: Int
        get() = authService.currentUser.value?.favoriteFields?.size ?: 0

    // MARK: - Load All
    fun loadAll() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // İstatistikleri yükle (şimdilik mock — BookingService entegre olunca gerçek veri çekilecek)
                loadStats()
            } catch (e: Exception) {
                _errorMessage.value = e.localizedMessage
            }
            _isLoading.value = false
        }
    }

    private fun loadStats() {
        // TODO: BookingService entegre olunca gerçek veriler çekilecek
        // Şimdilik User modelindeki totalMatches ve attendedMatches kullanılıyor
        val user = authService.currentUser.value
        val total = user?.totalMatches ?: 0
        val attended = user?.attendedMatches ?: 0
        val cancelled = if (total > attended) total - attended else 0

        _bookingStats.value = ProfileBookingStats(
            total = total,
            upcoming = 0,
            completed = attended,
            cancelled = cancelled
        )
    }

    // MARK: - Actions
    fun signOut() {
        AuthService.signOut()
    }

    fun clearError() {
        _errorMessage.value = null
    }
}
