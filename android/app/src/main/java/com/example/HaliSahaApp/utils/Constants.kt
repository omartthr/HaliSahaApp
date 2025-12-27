package com.example.HaliSahaApp.utils

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ConfirmationNumber
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.LocalCafe
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.StarHalf
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.WbSunny
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

// MARK: - App Constants
object AppConstants {

    // MARK: - App Info
    const val APP_NAME = "HaliSaha"
    // Versiyon bilgisi Extensions.kt içindeki Context.appVersion ile alınır, buraya hardcode etmiyoruz.

    // MARK: - Pagination
    const val DEFAULT_PAGE_SIZE = 20L
    const val MESSAGES_PAGE_SIZE = 50L

    // MARK: - Validation
    const val MIN_PASSWORD_LENGTH = 6
    const val MAX_USERNAME_LENGTH = 30
    const val MIN_USERNAME_LENGTH = 3
    const val MAX_DESCRIPTION_LENGTH = 500
    const val MAX_COMMENT_LENGTH = 1000
    const val PHONE_NUMBER_LENGTH = 10 // Türkiye için

    // MARK: - Business Rules
    const val DEPOSIT_PERCENTAGE = 0.20  // %20 kapora
    const val FREE_CANCELLATION_HOURS = 24
    val MATCH_REMINDER_HOURS = listOf(24, 2)
    const val MAX_GROUP_MEMBERS = 30
    const val MAX_IMAGES_PER_FACILITY = 10
    const val MAX_IMAGES_PER_REVIEW = 5

    // MARK: - Map
    const val DEFAULT_LATITUDE = 41.0082  // İstanbul
    const val DEFAULT_LONGITUDE = 28.9784
    const val DEFAULT_MAP_ZOOM = 12f      // Google Maps Zoom seviyesi (Swift'teki Span yerine)
    const val NEARBY_RADIUS_KM = 10.0

    // MARK: - Animation (Millis cinsinden)
    const val DEFAULT_ANIMATION_DURATION = 300
    const val SHORT_ANIMATION_DURATION = 150
    const val LONG_ANIMATION_DURATION = 500
}

// MARK: - UI Constants
object UIConstants {

    // MARK: - Spacing
    val PaddingSmall = 8.dp
    val PaddingMedium = 16.dp
    val PaddingLarge = 24.dp
    val PaddingXLarge = 32.dp

    // MARK: - Corner Radius
    val CornerRadiusSmall = 8.dp
    val CornerRadiusMedium = 12.dp
    val CornerRadiusLarge = 16.dp
    val CornerRadiusXLarge = 24.dp

    // MARK: - Button Heights
    val ButtonHeight = 50.dp
    val SmallButtonHeight = 36.dp

    // MARK: - Icon Sizes
    val IconSizeSmall = 16.dp
    val IconSizeMedium = 24.dp
    val IconSizeLarge = 32.dp
    val IconSizeXLarge = 48.dp

    // MARK: - Card
    val CardElevation = 4.dp

    // MARK: - Tab Bar
    val TabBarHeight = 80.dp // Android BottomNavigation standartı genelde 56-80 arasıdır

    // MARK: - Profile Image
    val ProfileImageSizeSmall = 40.dp
    val ProfileImageSizeMedium = 60.dp
    val ProfileImageSizeLarge = 100.dp
}

// MARK: - App Colors
object AppColors {

    // MARK: - Fallback Colors (Hex)
    val Primary = Color(0xFF2E7D32)      // Yeşil
    val Secondary = Color(0xFF1565C0)    // Mavi
    val Accent = Color(0xFFFF6F00)       // Turuncu
    val Background = Color(0xFFF5F5F5)   // Açık gri
    val Surface = Color.White

    // MARK: - Text Colors
    val TextPrimary = Color(0xFF212121)
    val TextSecondary = Color(0xFF757575)
    val TextTertiary = Color(0xFFBDBDBD)

    // MARK: - Status Colors
    val Success = Color(0xFF4CAF50)
    val Warning = Color(0xFFFF9800)
    val Error = Color(0xFFF44336)
    val Info = Color(0xFF2196F3)

    // Hex String to Color Helper
    fun fromHex(hex: String): Color {
        return try {
            val cleanHex = hex.trim().removePrefix("#")
            val colorLong = when (cleanHex.length) {
                6 -> "FF$cleanHex".toLong(16) // Alpha yoksa tam opak yap
                8 -> cleanHex.toLong(16)
                else -> 0xFF000000 // Hatalıysa siyah dön
            }
            Color(colorLong)
        } catch (e: Exception) {
            Color.Black
        }
    }
}

// MARK: - App Icons (Material Icons Mapping)
object AppIcons {

    // MARK: - Tab Bar Icons
    val Home = Icons.Filled.Home
    val Map = Icons.Filled.Map
    val Bookings = Icons.Filled.ConfirmationNumber // Ticket yerine
    val Chat = Icons.AutoMirrored.Filled.Chat // Bubble yerine
    val Profile = Icons.Filled.Person

    // MARK: - Common Icons
    val Search = Icons.Filled.Search
    val Filter = Icons.Filled.FilterList
    val Star = Icons.Filled.Star
    val StarEmpty = Icons.Filled.StarBorder
    val StarHalf = Icons.Filled.StarHalf
    val Location = Icons.Filled.LocationOn
    val Phone = Icons.Filled.Call
    val Calendar = Icons.Filled.DateRange
    val Clock = Icons.Filled.Schedule
    val Person = Icons.Filled.Person
    val PersonGroup = Icons.Filled.Groups
    val Notification = Icons.Filled.Notifications
    val Settings = Icons.Filled.Settings
    val Camera = Icons.Filled.CameraAlt
    val Photo = Icons.Filled.Image
    val Send = Icons.AutoMirrored.Filled.Send
    val Close = Icons.Filled.Close
    val Back = Icons.AutoMirrored.Filled.ArrowBack
    val Forward = Icons.AutoMirrored.Filled.ArrowForward
    val Down = Icons.Filled.KeyboardArrowDown
    val Up = Icons.Filled.KeyboardArrowUp
    val Check = Icons.Filled.Check
    val Plus = Icons.Filled.Add
    val Minus = Icons.Filled.Remove
    val Edit = Icons.Filled.Edit
    val Trash = Icons.Filled.Delete
    val Share = Icons.Filled.Share
    val QrCode = Icons.Filled.QrCode
    val Logout = Icons.AutoMirrored.Filled.ExitToApp

    // MARK: - Feature Icons
    val Parking = Icons.Filled.DirectionsCar
    val Shower = Icons.Filled.WaterDrop
    val Cafe = Icons.Filled.LocalCafe
    val Wifi = Icons.Filled.Wifi
    val Indoor = Icons.Filled.Home
    val Outdoor = Icons.Filled.WbSunny
    val Lighting = Icons.Filled.Lightbulb

    // MARK: - Status Icons
    val Success = Icons.Filled.CheckCircle
    val Warning = Icons.Filled.Warning
    val Error = Icons.Filled.Error
    val Info = Icons.Filled.Info
}

// MARK: - App Strings (Sabit Metinler)
// Not: Büyük projelerde res/values/strings.xml tercih edilir ama
// yapıyı bozmamak için burada tutuyoruz.
object AppStrings {

    // MARK: - Common
    const val OK = "Tamam"
    const val CANCEL = "İptal"
    const val SAVE = "Kaydet"
    const val DELETE = "Sil"
    const val EDIT = "Düzenle"
    const val DONE = "Bitti"
    const val NEXT = "İleri"
    const val BACK = "Geri"
    const val CLOSE = "Kapat"
    const val RETRY = "Tekrar Dene"
    const val LOADING = "Yükleniyor..."
    const val ERROR = "Hata"
    const val SUCCESS = "Başarılı"

    // MARK: - Auth
    const val LOGIN = "Giriş Yap"
    const val REGISTER = "Kayıt Ol"
    const val LOGOUT = "Çıkış Yap"
    const val FORGOT_PASSWORD = "Şifremi Unuttum"
    const val EMAIL = "E-posta"
    const val PASSWORD = "Şifre"
    const val CONFIRM_PASSWORD = "Şifre Tekrar"
    const val CONTINUE_AS_GUEST = "Misafir Olarak Devam Et"
    const val SIGN_IN_WITH_APPLE = "Apple ile Giriş"
    const val SIGN_IN_WITH_GOOGLE = "Google ile Giriş"

    // MARK: - Tab Bar
    const val TAB_EXPLORE = "Keşfet"
    const val TAB_MAP = "Harita"
    const val TAB_BOOKINGS = "Randevularım"
    const val TAB_CHAT = "Sohbet"
    const val TAB_PROFILE = "Profil"

    // MARK: - Alerts
    const val GUEST_ALERT_TITLE = "Üye Girişi Gerekli"
    const val GUEST_ALERT_MESSAGE = "Bu özelliği kullanmak için üye girişi yapmanız gerekiyor."

    // MARK: - Empty States
    const val NO_RESULTS = "Sonuç bulunamadı"
    const val NO_BOOKINGS = "Henüz rezervasyonunuz yok"
    const val NO_MESSAGES = "Henüz mesajınız yok"
    const val NO_NOTIFICATIONS = "Bildiriminiz yok"
}