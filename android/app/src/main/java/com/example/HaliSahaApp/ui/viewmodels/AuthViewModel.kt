package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.PlayerPosition
import com.example.HaliSahaApp.data.remote.AuthError
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.utils.FormValidator
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// UI State
data class AuthUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val successMessage: String? = null,
    val isSuccess: Boolean = false
)

enum class PasswordStrength(val score: Int, val label: String, val color: Long) {
    WEAK(1, "Zayıf", 0xFFF44336),   // Red
    MEDIUM(2, "Orta", 0xFFFF9800),  // Orange
    STRONG(3, "Güçlü", 0xFF4CAF50); // Green

    companion object {
        fun evaluate(password: String): PasswordStrength {
            var score = 0
            if (password.length >= 6) score++
            if (password.length >= 10) score++
            if (password.any { it.isUpperCase() }) score++
            if (password.any { it.isLowerCase() }) score++
            if (password.any { it.isDigit() }) score++
            if (password.any { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains(it) }) score++

            return when (score) {
                in 0..2 -> WEAK
                in 3..4 -> MEDIUM
                else -> STRONG
            }
        }
    }
}

class AuthViewModel : ViewModel() {

    private val authService = AuthService

    // UI State
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    // Form Fields
    var email = MutableStateFlow("")
    var password = MutableStateFlow("")
    var confirmPassword = MutableStateFlow("")
    var firstName = MutableStateFlow("")
    var lastName = MutableStateFlow("")
    var username = MutableStateFlow("")
    var phone = MutableStateFlow("")
    var preferredPosition = MutableStateFlow(PlayerPosition.UNSPECIFIED)

    // Admin Fields
    var businessName = MutableStateFlow("")
    var taxNumber = MutableStateFlow("")

    // Computed Properties (Devam edilebilir mi?)
    fun isStep1Valid(): Boolean {
        return FormValidator.validateEmail(email.value).isValid &&
                password.value.length >= 6 &&
                password.value == confirmPassword.value
    }

    fun isStep2Valid(): Boolean {
        return firstName.value.isNotEmpty() &&
                lastName.value.isNotEmpty() &&
                username.value.isNotEmpty()
    }

    fun getPasswordStrength(): PasswordStrength {
        return PasswordStrength.evaluate(password.value)
    }

    // MARK: - Login
    fun login() {
        if (email.value.isBlank() || password.value.isBlank()) {
            _uiState.value = AuthUiState(error = "Lütfen tüm alanları doldurun.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.signIn(email.value, password.value)
                _uiState.value = AuthUiState(isSuccess = true)
            } catch (e: Exception) {
                val msg = (e as? AuthError)?.message ?: "Giriş başarısız."
                _uiState.value = AuthUiState(error = msg)
            }
        }
    }

    // MARK: - Register
    fun register() {
        if (!isStep1Valid() || !isStep2Valid()) {
            _uiState.value = AuthUiState(error = "Lütfen bilgileri kontrol edin.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.signUp(
                    email = email.value,
                    password = password.value,
                    firstName = firstName.value,
                    lastName = lastName.value,
                    username = username.value,
                    phone = phone.value,
                    preferredPosition = preferredPosition.value
                )
                _uiState.value = AuthUiState(isSuccess = true)
            } catch (e: Exception) {
                val msg = (e as? AuthError)?.message ?: "Kayıt başarısız."
                _uiState.value = AuthUiState(error = msg)
            }
        }
    }

    // MARK: - Admin Register
    fun registerAsAdmin() {
        if (!isStep1Valid() || !isStep2Valid() || businessName.value.isBlank()) {
            _uiState.value = AuthUiState(error = "Lütfen tüm alanları doldurun.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.registerAsAdmin(
                    email = email.value,
                    password = password.value,
                    firstName = firstName.value,
                    lastName = lastName.value,
                    phone = phone.value,
                    businessName = businessName.value,
                    taxNumber = taxNumber.value
                )
                _uiState.value = AuthUiState(isSuccess = true, successMessage = "Kayıt başarılı! İşletmeniz onay sürecindedir.")
            } catch (e: Exception) {
                val msg = (e as? AuthError)?.message ?: "Kayıt başarısız."
                _uiState.value = AuthUiState(error = msg)
            }
        }
    }

    // MARK: - Password Reset
    fun resetPassword() {
        if (email.value.isBlank()) {
            _uiState.value = AuthUiState(error = "Lütfen e-posta adresinizi girin.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.sendPasswordReset(email.value)
                _uiState.value = AuthUiState(successMessage = "Şifre sıfırlama bağlantısı gönderildi.")
            } catch (e: Exception) {
                _uiState.value = AuthUiState(error = e.localizedMessage)
            }
        }
    }

    // MARK: - Guest Mode
    fun continueAsGuest() {
        authService.continueAsGuest()
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null, successMessage = null)
    }
}