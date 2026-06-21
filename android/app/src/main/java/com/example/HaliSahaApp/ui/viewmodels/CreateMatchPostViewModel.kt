package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import com.example.HaliSahaApp.data.models.PlayerPosition
import com.example.HaliSahaApp.data.models.SkillLevel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

// MARK: - Create Match Post UI State
data class CreateMatchPostUiState(
    val title: String = "",
    val description: String = "",
    val neededPlayers: Int = 4,
    val currentPlayers: Int = 10,
    val maxPlayers: Int = 14,
    val preferredPositions: List<PlayerPosition> = emptyList(),
    val skillLevel: SkillLevel = SkillLevel.any,
    val hasCostPerPlayer: Boolean = false,
    val costPerPlayerText: String = "",
    val isSaving: Boolean = false,
    val showSuccess: Boolean = false,
    val showError: Boolean = false,
    val errorMessage: String = "",

    // Booking bilgileri (mock olarak doldurulacak)
    val facilityName: String = "Etimesgut Pro Halı Saha",
    val pitchName: String = "Saha A",
    val facilityAddress: String = "71 Evler Mah. Necatibey Cad.",
    val matchDate: String = "31 Mayıs, Pazar",
    val timeSlot: String = "22:00 - 23:00",
    val ticketNumber: String = "TK-1234"
) {
    val isRosterValid: Boolean
        get() = currentPlayers < maxPlayers && neededPlayers <= maxPlayers - currentPlayers

    val rosterHint: String
        get() {
            if (currentPlayers >= maxPlayers) {
                return "Mevcut oyuncu sayısı maksimum kadrodan düşük olmalı."
            }
            val emptySlots = maxPlayers - currentPlayers
            if (neededPlayers > emptySlots) {
                return "Aranan oyuncu sayısı kalan $emptySlots kişilik kapasiteyi aşamaz."
            }
            return "$emptySlots kişilik boşluk var, $neededPlayers kişi aranacak."
        }

    val canSubmit: Boolean
        get() {
            val titleValid = title.trim().isNotEmpty()
            val rosterValid = isRosterValid
            val costValid = !hasCostPerPlayer || parsedCostPerPlayer != null
            return titleValid && rosterValid && costValid
        }

    val parsedCostPerPlayer: Double?
        get() {
            val normalized = costPerPlayerText.replace(",", ".")
            return normalized.toDoubleOrNull()?.takeIf { it >= 0 }
        }
}

// MARK: - Create Match Post ViewModel
class CreateMatchPostViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(CreateMatchPostUiState())
    val uiState: StateFlow<CreateMatchPostUiState> = _uiState.asStateFlow()

    fun initWithBookingId(bookingId: String) {
        // TODO: BookingService'ten gerçek booking bilgilerini çek
        // Şimdilik mock veri ile başlatıyoruz
        _uiState.update {
            it.copy(
                title = "${it.timeSlot} maçına oyuncu aranıyor"
            )
        }
    }

    fun onTitleChange(title: String) {
        _uiState.update { it.copy(title = title) }
    }

    fun onDescriptionChange(description: String) {
        _uiState.update { it.copy(description = description) }
    }

    fun onNeededPlayersChange(value: Int) {
        _uiState.update { it.copy(neededPlayers = value.coerceIn(1, 10)) }
    }

    fun onCurrentPlayersChange(value: Int) {
        _uiState.update { it.copy(currentPlayers = value.coerceIn(1, 30)) }
    }

    fun onMaxPlayersChange(value: Int) {
        _uiState.update { it.copy(maxPlayers = value.coerceIn(2, 30)) }
    }

    fun onSkillLevelChange(level: SkillLevel) {
        _uiState.update { it.copy(skillLevel = level) }
    }

    fun togglePosition(position: PlayerPosition) {
        _uiState.update { state ->
            val newPositions = if (position in state.preferredPositions) {
                state.preferredPositions - position
            } else {
                state.preferredPositions + position
            }
            state.copy(preferredPositions = newPositions)
        }
    }

    fun onHasCostPerPlayerChange(enabled: Boolean) {
        _uiState.update { it.copy(hasCostPerPlayer = enabled) }
    }

    fun onCostPerPlayerTextChange(text: String) {
        _uiState.update { it.copy(costPerPlayerText = text) }
    }

    fun createPost() {
        val state = _uiState.value
        if (!state.canSubmit) return

        _uiState.update { it.copy(isSaving = true) }

        // TODO: MatchPostService entegre olunca gerçek kayıt yapılacak
        // Şimdilik success göster
        _uiState.update { it.copy(isSaving = false, showSuccess = true) }
    }

    fun clearSuccess() {
        _uiState.update { it.copy(showSuccess = false) }
    }

    fun clearError() {
        _uiState.update { it.copy(showError = false, errorMessage = "") }
    }
}
