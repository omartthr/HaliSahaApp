//
//  Validators.swift
//  HaliSahaApp
//
//  Form doğrulama yardımcı fonksiyonları
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//

import Foundation

// MARK: - Validator Protocol
protocol Validator {
    associatedtype Value
    func validate(_ value: Value) -> ValidationResult
}

// MARK: - Validation Result
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ValidationResult(isValid: true, errorMessage: nil)
    
    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - Email Validator
struct EmailValidator: Validator {
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .invalid("E-posta adresi gerekli")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard predicate.evaluate(with: trimmed) else {
            return .invalid("Geçerli bir e-posta adresi girin")
        }
        
        return .valid
    }
}

// MARK: - Password Validator
struct PasswordValidator: Validator {
    let minLength: Int
    let requireUppercase: Bool
    let requireNumber: Bool
    let requireSpecialChar: Bool
    
    init(
        minLength: Int = 6,
        requireUppercase: Bool = false,
        requireNumber: Bool = false,
        requireSpecialChar: Bool = false
    ) {
        self.minLength = minLength
        self.requireUppercase = requireUppercase
        self.requireNumber = requireNumber
        self.requireSpecialChar = requireSpecialChar
    }
    
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else {
            return .invalid("Şifre gerekli")
        }
        
        guard value.count >= minLength else {
            return .invalid("Şifre en az \(minLength) karakter olmalı")
        }
        
        if requireUppercase {
            guard value.rangeOfCharacter(from: .uppercaseLetters) != nil else {
                return .invalid("Şifre en az bir büyük harf içermeli")
            }
        }
        
        if requireNumber {
            guard value.rangeOfCharacter(from: .decimalDigits) != nil else {
                return .invalid("Şifre en az bir rakam içermeli")
            }
        }
        
        if requireSpecialChar {
            let specialChars = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
            guard value.rangeOfCharacter(from: specialChars) != nil else {
                return .invalid("Şifre en az bir özel karakter içermeli")
            }
        }
        
        return .valid
    }
}

// MARK: - Phone Validator (Türkiye)
struct PhoneValidator: Validator {
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .invalid("Telefon numarası gerekli")
        }
        
        // Sadece rakamları al
        let digitsOnly = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Türkiye numarası: 5XX XXX XX XX (10 hane)
        // veya +90 5XX XXX XX XX (12 hane)
        // veya 0 5XX XXX XX XX (11 hane)
        
        let cleanNumber: String
        if digitsOnly.hasPrefix("90") && digitsOnly.count == 12 {
            cleanNumber = String(digitsOnly.dropFirst(2))
        } else if digitsOnly.hasPrefix("0") && digitsOnly.count == 11 {
            cleanNumber = String(digitsOnly.dropFirst(1))
        } else if digitsOnly.count == 10 {
            cleanNumber = digitsOnly
        } else {
            return .invalid("Geçerli bir telefon numarası girin")
        }
        
        // 5 ile başlamalı
        guard cleanNumber.hasPrefix("5") else {
            return .invalid("Telefon numarası 5 ile başlamalı")
        }
        
        return .valid
    }
}

// MARK: - Username Validator
struct UsernameValidator: Validator {
    let minLength: Int
    let maxLength: Int
    
    init(minLength: Int = 3, maxLength: Int = 30) {
        self.minLength = minLength
        self.maxLength = maxLength
    }
    
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmed.isEmpty else {
            return .invalid("Kullanıcı adı gerekli")
        }
        
        guard trimmed.count >= minLength else {
            return .invalid("Kullanıcı adı en az \(minLength) karakter olmalı")
        }
        
        guard trimmed.count <= maxLength else {
            return .invalid("Kullanıcı adı en fazla \(maxLength) karakter olabilir")
        }
        
        // Sadece harf, rakam ve alt çizgi
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard trimmed.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) else {
            return .invalid("Kullanıcı adı sadece harf, rakam ve _ içerebilir")
        }
        
        // Rakam ile başlamamalı
        guard !trimmed.first!.isNumber else {
            return .invalid("Kullanıcı adı rakam ile başlayamaz")
        }
        
        return .valid
    }
}

// MARK: - Required Field Validator
struct RequiredValidator: Validator {
    let fieldName: String
    
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .invalid("\(fieldName) gerekli")
        }
        
        return .valid
    }
}

// MARK: - Tax Number Validator (Türkiye)
struct TaxNumberValidator: Validator {
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            return .invalid("Vergi numarası gerekli")
        }
        
        // Sadece rakamları al
        let digitsOnly = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // 10 veya 11 hane olmalı
        guard digitsOnly.count == 10 || digitsOnly.count == 11 else {
            return .invalid("Vergi numarası 10 veya 11 hane olmalı")
        }
        
        return .valid
    }
}

// MARK: - Form Validator
struct FormValidator {
    
    static let email = EmailValidator()
    static let password = PasswordValidator()
    static let strongPassword = PasswordValidator(
        minLength: 8,
        requireUppercase: true,
        requireNumber: true
    )
    static let phone = PhoneValidator()
    static let username = UsernameValidator()
    static let taxNumber = TaxNumberValidator()
    
    static func required(_ fieldName: String) -> RequiredValidator {
        RequiredValidator(fieldName: fieldName)
    }
    
    // MARK: - Convenience Methods
    
    static func validateEmail(_ email: String) -> ValidationResult {
        self.email.validate(email)
    }
    
    static func validatePassword(_ password: String) -> ValidationResult {
        self.password.validate(password)
    }
    
    static func validatePhone(_ phone: String) -> ValidationResult {
        self.phone.validate(phone)
    }
    
    static func validateUsername(_ username: String) -> ValidationResult {
        self.username.validate(username)
    }
    
    static func validatePasswordMatch(_ password: String, _ confirm: String) -> ValidationResult {
        guard password == confirm else {
            return .invalid("Şifreler eşleşmiyor")
        }
        return .valid
    }
}

// MARK: - String Extension for Validation
extension String {
    
    var emailValidation: ValidationResult {
        FormValidator.validateEmail(self)
    }
    
    var passwordValidation: ValidationResult {
        FormValidator.validatePassword(self)
    }
    
    var phoneValidation: ValidationResult {
        FormValidator.validatePhone(self)
    }
    
    var usernameValidation: ValidationResult {
        FormValidator.validateUsername(self)
    }
}
