//
//  Constants.swift
//  HaliSahaApp
//
//  Uygulama genelinde kullanılan sabit değerler
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//


import Foundation
import SwiftUI

// MARK: - App Constants
struct AppConstants {
    
    // MARK: - App Info
    static let appName = "HaliSaha"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Pagination
    static let defaultPageSize = 20
    static let messagesPageSize = 50
    
    // MARK: - Validation
    static let minPasswordLength = 6
    static let maxUsernameLength = 30
    static let minUsernameLength = 3
    static let maxDescriptionLength = 500
    static let maxCommentLength = 1000
    static let phoneNumberLength = 10 // Türkiye için (5XX XXX XXXX)
    
    // MARK: - Business Rules
    static let depositPercentage: Double = 0.20  // %20 kapora
    static let freeCancellationHours: Int = 24   // 24 saat öncesi ücretsiz iptal
    static let matchReminderHours: [Int] = [24, 2] // 24 saat ve 2 saat önce hatırlatma
    static let maxGroupMembers = 30
    static let maxImagesPerFacility = 10
    static let maxImagesPerReview = 5
    
    // MARK: - Map
    static let defaultLatitude = 41.0082  // İstanbul
    static let defaultLongitude = 28.9784
    static let defaultMapSpan = 0.05      // Harita zoom seviyesi
    static let nearbyRadiusKm: Double = 10.0
    
    // MARK: - Cache
    static let imageCacheLimit = 100      // MB
    static let dataCacheExpiration: TimeInterval = 300 // 5 dakika
    
    // MARK: - Animation
    static let defaultAnimationDuration: Double = 0.3
    static let shortAnimationDuration: Double = 0.15
    static let longAnimationDuration: Double = 0.5
}

// MARK: - UI Constants
struct UIConstants {
    
    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32
    
    // MARK: - Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 24
    
    // MARK: - Button Heights
    static let buttonHeight: CGFloat = 50
    static let smallButtonHeight: CGFloat = 36
    
    // MARK: - Icon Sizes
    static let iconSizeSmall: CGFloat = 16
    static let iconSizeMedium: CGFloat = 24
    static let iconSizeLarge: CGFloat = 32
    static let iconSizeXLarge: CGFloat = 48
    
    // MARK: - Card
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowOpacity: Double = 0.1
    
    // MARK: - Tab Bar
    static let tabBarHeight: CGFloat = 83
    
    // MARK: - Profile Image
    static let profileImageSizeSmall: CGFloat = 40
    static let profileImageSizeMedium: CGFloat = 60
    static let profileImageSizeLarge: CGFloat = 100
}

// MARK: - App Colors
struct AppColors {
    
    // MARK: - Primary Colors
    static let primary = Color("PrimaryColor")          // Ana renk (Yeşil tonu önerilir)
    static let secondary = Color("SecondaryColor")      // İkincil renk
    static let accent = Color("AccentColor")            // Vurgu rengi
    
    // MARK: - Background Colors
    static let background = Color("BackgroundColor")
    static let secondaryBackground = Color("SecondaryBackgroundColor")
    static let cardBackground = Color("CardBackgroundColor")
    
    // MARK: - Text Colors
    static let textPrimary = Color("TextPrimaryColor")
    static let textSecondary = Color("TextSecondaryColor")
    static let textTertiary = Color("TextTertiaryColor")
    
    // MARK: - Status Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // MARK: - Fallback Colors (Asset'ler hazır değilse)
    static let primaryFallback = Color(hex: "2E7D32")      // Yeşil
    static let secondaryFallback = Color(hex: "1565C0")    // Mavi
    static let accentFallback = Color(hex: "FF6F00")       // Turuncu
    static let backgroundFallback = Color(hex: "F5F5F5")   // Açık gri
}

// MARK: - App Images (SF Symbols & Asset Names)
struct AppImages {
    
    // MARK: - Tab Bar Icons
    static let tabHome = "house.fill"
    static let tabMap = "map.fill"
    static let tabBookings = "ticket.fill"
    static let tabChat = "bubble.left.and.bubble.right.fill"
    static let tabProfile = "person.fill"
    
    // MARK: - Common Icons
    static let search = "magnifyingglass"
    static let filter = "slider.horizontal.3"
    static let star = "star.fill"
    static let starEmpty = "star"
    static let starHalf = "star.leadinghalf.filled"
    static let heart = "heart.fill"
    static let heartEmpty = "heart"
    static let location = "location.fill"
    static let phone = "phone.fill"
    static let calendar = "calendar"
    static let clock = "clock.fill"
    static let person = "person.fill"
    static let personGroup = "person.3.fill"
    static let notification = "bell.fill"
    static let settings = "gearshape.fill"
    static let camera = "camera.fill"
    static let photo = "photo.fill"
    static let send = "paperplane.fill"
    static let close = "xmark"
    static let back = "chevron.left"
    static let forward = "chevron.right"
    static let down = "chevron.down"
    static let up = "chevron.up"
    static let check = "checkmark"
    static let plus = "plus"
    static let minus = "minus"
    static let edit = "pencil"
    static let trash = "trash.fill"
    static let share = "square.and.arrow.up"
    static let qrCode = "qrcode"
    
    // MARK: - Feature Icons
    static let parking = "car.fill"
    static let shower = "drop.fill"
    static let cafe = "cup.and.saucer.fill"
    static let wifi = "wifi"
    static let indoor = "house.fill"
    static let outdoor = "sun.max.fill"
    static let lighting = "lightbulb.fill"
    
    // MARK: - Status Icons
    static let success = "checkmark.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let error = "xmark.circle.fill"
    static let info = "info.circle.fill"
}

// MARK: - App Strings (Localizable için)
struct AppStrings {
    
    // MARK: - Common
    static let ok = "Tamam"
    static let cancel = "İptal"
    static let save = "Kaydet"
    static let delete = "Sil"
    static let edit = "Düzenle"
    static let done = "Bitti"
    static let next = "İleri"
    static let back = "Geri"
    static let close = "Kapat"
    static let retry = "Tekrar Dene"
    static let loading = "Yükleniyor..."
    static let error = "Hata"
    static let success = "Başarılı"
    
    // MARK: - Auth
    static let login = "Giriş Yap"
    static let register = "Kayıt Ol"
    static let logout = "Çıkış Yap"
    static let forgotPassword = "Şifremi Unuttum"
    static let email = "E-posta"
    static let password = "Şifre"
    static let confirmPassword = "Şifre Tekrar"
    static let continueAsGuest = "Misafir Olarak Devam Et"
    static let signInWithApple = "Apple ile Giriş"
    static let signInWithGoogle = "Google ile Giriş"
    
    // MARK: - Tab Bar
    static let tabExplore = "Keşfet"
    static let tabMap = "Harita"
    static let tabBookings = "Randevularım"
    static let tabChat = "Sohbet"
    static let tabProfile = "Profil"
    
    // MARK: - Guest Alert
    static let guestAlertTitle = "Üye Girişi Gerekli"
    static let guestAlertMessage = "Bu özelliği kullanmak için üye girişi yapmanız gerekiyor."
    
    // MARK: - Empty States
    static let noResults = "Sonuç bulunamadı"
    static let noBookings = "Henüz rezervasyonunuz yok"
    static let noMessages = "Henüz mesajınız yok"
    static let noNotifications = "Bildiriminiz yok"
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
