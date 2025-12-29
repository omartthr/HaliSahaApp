package com.example.HaliSahaApp.utils

// MARK: - Validation Result
data class ValidationResult(
    val isValid: Boolean,
    val errorMessage: String? = null
) {
    companion object {
        val Valid = ValidationResult(isValid = true, errorMessage = null)

        fun Invalid(message: String): ValidationResult {
            return ValidationResult(isValid = false, errorMessage = message)
        }
    }
}

// MARK: - Validator Interface
interface Validator<T> {
    fun validate(value: T): ValidationResult
}

// MARK: - Email Validator
class EmailValidator : Validator<String> {
    override fun validate(value: String): ValidationResult {
        val trimmed = value.trim()

        if (trimmed.isEmpty()) {
            return ValidationResult.Invalid("E-posta adresi gerekli")
        }

        // Android'in Patterns.EMAIL_ADDRESS'i yerine Swift ile aynı regex'i kullanıyoruz ki logic aynı olsun
        val emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}".toRegex(RegexOption.IGNORE_CASE)

        if (!emailRegex.matches(trimmed)) {
            return ValidationResult.Invalid("Geçerli bir e-posta adresi girin")
        }

        return ValidationResult.Valid
    }
}

// MARK: - Password Validator
class PasswordValidator(
    private val minLength: Int = 6,
    private val requireUppercase: Boolean = false,
    private val requireNumber: Boolean = false,
    private val requireSpecialChar: Boolean = false
) : Validator<String> {

    override fun validate(value: String): ValidationResult {
        if (value.isEmpty()) {
            return ValidationResult.Invalid("Şifre gerekli")
        }

        if (value.length < minLength) {
            return ValidationResult.Invalid("Şifre en az $minLength karakter olmalı")
        }

        if (requireUppercase && !value.any { it.isUpperCase() }) {
            return ValidationResult.Invalid("Şifre en az bir büyük harf içermeli")
        }

        if (requireNumber && !value.any { it.isDigit() }) {
            return ValidationResult.Invalid("Şifre en az bir rakam içermeli")
        }

        if (requireSpecialChar) {
            val specialChars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
            if (!value.any { specialChars.contains(it) }) {
                return ValidationResult.Invalid("Şifre en az bir özel karakter içermeli")
            }
        }

        return ValidationResult.Valid
    }
}

// MARK: - Phone Validator (Türkiye)
class PhoneValidator : Validator<String> {
    override fun validate(value: String): ValidationResult {
        val trimmed = value.trim()

        if (trimmed.isEmpty()) {
            return ValidationResult.Invalid("Telefon numarası gerekli")
        }

        // Sadece rakamları al
        val digitsOnly = trimmed.filter { it.isDigit() }

        val cleanNumber = when {
            digitsOnly.startsWith("90") && digitsOnly.length == 12 -> digitsOnly.substring(2)
            digitsOnly.startsWith("0") && digitsOnly.length == 11 -> digitsOnly.substring(1)
            digitsOnly.length == 10 -> digitsOnly
            else -> return ValidationResult.Invalid("Geçerli bir telefon numarası girin")
        }

        if (!cleanNumber.startsWith("5")) {
            return ValidationResult.Invalid("Telefon numarası 5 ile başlamalı")
        }

        return ValidationResult.Valid
    }
}

// MARK: - Username Validator
class UsernameValidator(
    private val minLength: Int = 3,
    private val maxLength: Int = 30
) : Validator<String> {

    override fun validate(value: String): ValidationResult {
        val trimmed = value.trim().lowercase()

        if (trimmed.isEmpty()) {
            return ValidationResult.Invalid("Kullanıcı adı gerekli")
        }

        if (trimmed.length < minLength) {
            return ValidationResult.Invalid("Kullanıcı adı en az $minLength karakter olmalı")
        }

        if (trimmed.length > maxLength) {
            return ValidationResult.Invalid("Kullanıcı adı en fazla $maxLength karakter olabilir")
        }

        // Sadece harf, rakam ve alt çizgi
        if (!trimmed.all { it.isLetterOrDigit() || it == '_' }) {
            return ValidationResult.Invalid("Kullanıcı adı sadece harf, rakam ve _ içerebilir")
        }

        // Rakam ile başlamamalı
        if (trimmed.first().isDigit()) {
            return ValidationResult.Invalid("Kullanıcı adı rakam ile başlayamaz")
        }

        return ValidationResult.Valid
    }
}

// MARK: - Required Field Validator
class RequiredValidator(private val fieldName: String) : Validator<String> {
    override fun validate(value: String): ValidationResult {
        if (value.trim().isEmpty()) {
            return ValidationResult.Invalid("$fieldName gerekli")
        }
        return ValidationResult.Valid
    }
}

// MARK: - Tax Number Validator
class TaxNumberValidator : Validator<String> {
    override fun validate(value: String): ValidationResult {
        val trimmed = value.trim()

        if (trimmed.isEmpty()) {
            return ValidationResult.Invalid("Vergi numarası gerekli")
        }

        val digitsOnly = trimmed.filter { it.isDigit() }

        if (digitsOnly.length != 10 && digitsOnly.length != 11) {
            return ValidationResult.Invalid("Vergi numarası 10 veya 11 hane olmalı")
        }

        return ValidationResult.Valid
    }
}

// MARK: - Form Validator Singleton
object FormValidator {

    val email = EmailValidator()
    val password = PasswordValidator()
    val strongPassword = PasswordValidator(
        minLength = 8,
        requireUppercase = true,
        requireNumber = true
    )
    val phone = PhoneValidator()
    val username = UsernameValidator()
    val taxNumber = TaxNumberValidator()

    fun required(fieldName: String) = RequiredValidator(fieldName)

    // MARK: - Convenience Methods

    fun validateEmail(email: String): ValidationResult = this.email.validate(email)

    fun validatePassword(password: String): ValidationResult = this.password.validate(password)

    fun validatePhone(phone: String): ValidationResult = this.phone.validate(phone)

    fun validateUsername(username: String): ValidationResult = this.username.validate(username)

    fun validatePasswordMatch(password: String, confirm: String): ValidationResult {
        return if (password == confirm) {
            ValidationResult.Valid
        } else {
            ValidationResult.Invalid("Şifreler eşleşmiyor")
        }
    }
}

// MARK: - String Extensions for Validation
val String.emailValidation: ValidationResult
    get() = FormValidator.validateEmail(this)

val String.passwordValidation: ValidationResult
    get() = FormValidator.validatePassword(this)

val String.phoneValidation: ValidationResult
    get() = FormValidator.validatePhone(this)

val String.usernameValidation: ValidationResult
    get() = FormValidator.validateUsername(this)