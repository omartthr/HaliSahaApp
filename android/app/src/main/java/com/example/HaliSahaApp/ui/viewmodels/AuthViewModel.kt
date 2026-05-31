package com.example.HaliSahaApp.ui.viewmodels

import androidx.compose.ui.graphics.Color
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.PlayerPosition
import com.example.HaliSahaApp.data.remote.AuthError
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppConstants
import com.example.HaliSahaApp.utils.FormValidator
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// MARK: - UI State
data class AuthUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val successMessage: String? = null,
    val isSuccess: Boolean = false
)

// MARK: - Password Strength Enum
enum class PasswordStrength(val score: Int, val label: String, val color: Color) { // <-- Değişiklik burada
    WEAK(1, "Zayıf", AppColors.Error),
    MEDIUM(2, "Orta", AppColors.Warning),
    STRONG(3, "Güçlü", AppColors.Success);

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

// MARK: - Auth ViewModel
class AuthViewModel : ViewModel() {

    private val authService = AuthService

    // MARK: - UI State
    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    // MARK: - Form Properties (MutableStateFlow)
    val email = MutableStateFlow("")
    val password = MutableStateFlow("")
    val confirmPassword = MutableStateFlow("")
    val firstName = MutableStateFlow("")
    val lastName = MutableStateFlow("")
    val username = MutableStateFlow("")
    val phone = MutableStateFlow("")
    val preferredPosition = MutableStateFlow(PlayerPosition.UNSPECIFIED)

    // Admin Properties
    val businessName = MutableStateFlow("")
    val taxNumber = MutableStateFlow("")

    // MARK: - Auth State Observer
    // (Android'de NavController ve MainActivity bu durumu zaten AuthService üzerinden dinliyor,
    // ancak ViewModel içinde de lokal bir state tutmak istersek:)
    val isAuthenticated = authService.isAuthenticated

    // MARK: - Computed Properties (Validations)

    val isAdminStep1Valid: Boolean
        get() = firstName.value.isNotEmpty() &&
                lastName.value.isNotEmpty() &&
                FormValidator.validateEmail(email.value).isValid &&
                password.value.length >= AppConstants.MIN_PASSWORD_LENGTH &&
                passwordsMatch

    // Admin Kayıt Adım 2 Kontrolü (İşletme)
    val isAdminStep2Valid: Boolean
        get() = businessName.value.isNotEmpty() &&
                FormValidator.taxNumber.validate(taxNumber.value).isValid &&
                FormValidator.validatePhone(phone.value).isValid

    // Swift'teki computed property'ler gibi anlık değerleri kontrol eder
    val isLoginFormValid: Boolean
        get() = FormValidator.validateEmail(email.value).isValid &&
                password.value.isNotEmpty()

    val isRegisterFormValid: Boolean
        get() = FormValidator.validateEmail(email.value).isValid &&
                FormValidator.validatePassword(password.value).isValid &&
                passwordsMatch &&
                password.value.length >= AppConstants.MIN_PASSWORD_LENGTH &&
                firstName.value.trim().isNotEmpty() &&
                lastName.value.trim().isNotEmpty() &&
                FormValidator.validateUsername(username.value).isValid &&
                FormValidator.validatePhone(phone.value).isValid

    val isAdminRegisterFormValid: Boolean
        get() = isRegisterFormValid &&
                businessName.value.trim().isNotEmpty() &&
                FormValidator.taxNumber.validate(taxNumber.value).isValid

    val passwordsMatch: Boolean
        get() = confirmPassword.value.isNotEmpty() && password.value == confirmPassword.value

    fun getPasswordStrength(): PasswordStrength {
        return PasswordStrength.evaluate(password.value)
    }

    // MARK: - Actions

    // 1. Email/Password Login
    fun login() {
        if (!isLoginFormValid) {
            _uiState.value = AuthUiState(error = "Lütfen tüm alanları doğru şekilde doldurun.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.signIn(email.value.trim(), password.value)
                // signIn başarılı - AuthService.fetchUserProfile() currentUser'ı set edecek
                // clearForm() burada ÇAĞRILMAMALI: currentUser henüz null olabilir
                // ve LaunchedEffect'te currentUser != null kontrolü başarısız olur
                _uiState.value = AuthUiState(isSuccess = true)
            } catch (e: Exception) {
                val errorMsg = (e as? AuthError)?.message ?: "Giriş başarısız."
                _uiState.value = AuthUiState(error = errorMsg)
            }
        }
    }

    // 2. Email/Password Register
    fun register() {
        if (!isRegisterFormValid) {
            _uiState.value = AuthUiState(error = "Lütfen tüm alanları doğru şekilde doldurun.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.signUp(
                    email = email.value.trim(),
                    password = password.value,
                    firstName = firstName.value.trim(),
                    lastName = lastName.value.trim(),
                    username = username.value.trim().lowercase(),
                    phone = phone.value.trim(),
                    preferredPosition = preferredPosition.value
                )
                _uiState.value = AuthUiState(isSuccess = true)
                clearForm()
            } catch (e: Exception) {
                val errorMsg = (e as? AuthError)?.message ?: "Kayıt başarısız."
                _uiState.value = AuthUiState(error = errorMsg)
            }
        }
    }

    // 3. Admin Register
    fun registerAsAdmin() {
        if (!isAdminRegisterFormValid) {
            _uiState.value = AuthUiState(error = "Lütfen tüm alanları doğru şekilde doldurun.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.registerAsAdmin(
                    email = email.value.trim(),
                    password = password.value,
                    firstName = firstName.value.trim(),
                    lastName = lastName.value.trim(),
                    phone = phone.value.trim(),
                    businessName = businessName.value.trim(),
                    taxNumber = taxNumber.value.trim()
                )
                _uiState.value = AuthUiState(
                    isSuccess = true,
                    successMessage = "Kayıt başarılı! İşletmeniz onay sürecindedir."
                )
                clearForm()
            } catch (e: Exception) {
                val errorMsg = (e as? AuthError)?.message ?: "Kayıt başarısız."
                _uiState.value = AuthUiState(error = errorMsg)
            }
        }
    }

    // 4. Forgot Password
    fun resetPassword() {
        if (email.value.trim().isEmpty() || !FormValidator.validateEmail(email.value).isValid) {
            _uiState.value = AuthUiState(error = "Geçerli bir e-posta adresi girin.")
            return
        }

        viewModelScope.launch {
            _uiState.value = AuthUiState(isLoading = true)
            try {
                authService.sendPasswordReset(email.value.trim())
                _uiState.value = AuthUiState(successMessage = "Şifre sıfırlama bağlantısı gönderildi.")
            } catch (e: Exception) {
                val errorMsg = (e as? AuthError)?.message ?: "İşlem başarısız."
                _uiState.value = AuthUiState(error = errorMsg)
            }
        }
    }

    // 5. Google Sign In
    fun signInWithGoogle() {
        // Google Sign In implementasyonu eklendiğinde burası dolacak
        _uiState.value = AuthUiState(error = "Google ile giriş yakında aktif olacak.")
    }

    // 6. Guest Mode
    fun continueAsGuest() {
        authService.continueAsGuest()
    }

    // 7. Sign Out
    fun signOut() {
        authService.signOut()
        clearForm()
    }

    // MARK: - Helpers
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null, successMessage = null)
    }

    private fun clearForm() {
        email.value = ""
        password.value = ""
        confirmPassword.value = ""
        firstName.value = ""
        lastName.value = ""
        username.value = ""
        phone.value = ""
        businessName.value = ""
        taxNumber.value = ""
        preferredPosition.value = PlayerPosition.UNSPECIFIED
    }
}