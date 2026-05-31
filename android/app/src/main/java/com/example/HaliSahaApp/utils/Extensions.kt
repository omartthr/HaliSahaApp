package com.example.HaliSahaApp.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.text.format.DateUtils
import android.util.Patterns
import android.view.inputmethod.InputMethodManager
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

// MARK: - Date Extensions
val localeTR = Locale("tr", "TR")

fun Date.formattedTurkish(): String = SimpleDateFormat("d MMMM yyyy", localeTR).format(this)

fun Date.shortFormatted(): String = SimpleDateFormat("d MMM", localeTR).format(this)

fun Date.withDayName(): String = SimpleDateFormat("d MMMM yyyy, EEEE", localeTR).format(this)

fun Date.timeFormatted(): String = SimpleDateFormat("HH:mm", localeTR).format(this)

fun Date.relativeTime(): String {
    return DateUtils.getRelativeTimeSpanString(
        this.time,
        System.currentTimeMillis(),
        DateUtils.MINUTE_IN_MILLIS
    ).toString()
}

fun Date.shortRelativeTime(): String {
    return DateUtils.getRelativeTimeSpanString(
        this.time,
        System.currentTimeMillis(),
        DateUtils.MINUTE_IN_MILLIS,
        DateUtils.FORMAT_ABBREV_RELATIVE
    ).toString()
}

fun Date.isToday(): Boolean = DateUtils.isToday(this.time)

fun Date.isYesterday(): Boolean {
    val calendar = Calendar.getInstance()
    calendar.add(Calendar.DAY_OF_YEAR, -1)
    val yesterday = calendar.time
    val fmt = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
    return fmt.format(this) == fmt.format(yesterday)
}

fun Date.isTomorrow(): Boolean {
    val calendar = Calendar.getInstance()
    calendar.add(Calendar.DAY_OF_YEAR, 1)
    val tomorrow = calendar.time
    val fmt = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
    return fmt.format(this) == fmt.format(tomorrow)
}

fun Date.isWeekend(): Boolean {
    val calendar = Calendar.getInstance()
    calendar.time = this
    val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
    return dayOfWeek == Calendar.SATURDAY || dayOfWeek == Calendar.SUNDAY
}

fun Date.addingDays(days: Int): Date {
    val calendar = Calendar.getInstance()
    calendar.time = this
    calendar.add(Calendar.DAY_OF_YEAR, days)
    return calendar.time
}

fun Date.addingHours(hours: Int): Date {
    val calendar = Calendar.getInstance()
    calendar.time = this
    calendar.add(Calendar.HOUR_OF_DAY, hours)
    return calendar.time
}

// MARK: - String Extensions

val String.isValidEmail: Boolean
    get() = this.isNotEmpty() && Patterns.EMAIL_ADDRESS.matcher(this).matches()

val String.isValidPhoneNumber: Boolean
    get() {
        // Basit kontrol: 5 ile başlamalı ve toplam 10 hane olmalı (başında 0 olmadan)
        val cleanNumber = this.replace(" ", "").replace("-", "").replace("+90", "").replaceFirst("^0+".toRegex(), "")
        return cleanNumber.matches(Regex("^5[0-9]{9}$"))
    }

val String.formattedPhoneNumber: String
    get() {
        val cleanNumber = this.filter { it.isDigit() }
        if (cleanNumber.length < 10) return this

        // Son 10 haneyi al (varsa baştaki 0 veya 90'ı atlamak için)
        val lastTen = cleanNumber.takeLast(10)

        // 5XX XXX XX XX formatı
        return "${lastTen.substring(0, 3)} ${lastTen.substring(3, 6)} ${lastTen.substring(6, 8)} ${lastTen.substring(8)}"
    }

val String.capitalizedFirst: String
    get() = this.replaceFirstChar { if (it.isLowerCase()) it.titlecase(localeTR) else it.toString() }

val String.isValidURL: Boolean
    get() = Patterns.WEB_URL.matcher(this).matches()

// MARK: - Double Extensions

val Double.asCurrency: String
    get() {
        val format = NumberFormat.getCurrencyInstance(localeTR)
        format.currency = java.util.Currency.getInstance("TRY")
        return format.format(this)
    }

val Double.asShortCurrency: String
    get() = "${this.toInt()} ₺"

val Double.asRating: String
    get() = String.format(Locale.US, "%.1f", this)

val Double.asPercentage: String
    get() = String.format("%%%d", this.toInt())

// MARK: - Int Extensions

val Int.asHourString: String
    get() = String.format("%02d:00", this)

fun Int.asTimeRange(endHour: Int): String {
    return "${this.asHourString} - ${endHour.asHourString}"
}

// MARK: - Compose Modifier Extensions (View Extensions Karşılığı)

/**
 * Koşullu Modifier ekleme
 */
fun Modifier.conditional(condition: Boolean, modifier: Modifier.() -> Modifier): Modifier {
    return if (condition) {
        then(modifier(Modifier))
    } else {
        this
    }
}

/**
 * Klavyeyi gizlemek için Context Extension
 */
fun Context.hideKeyboard(activity: Activity) {
    val inputMethodManager = activity.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
    val currentFocusedView = activity.currentFocus
    currentFocusedView?.let {
        inputMethodManager.hideSoftInputFromWindow(it.windowToken, InputMethodManager.HIDE_NOT_ALWAYS)
    }
}

/**
 * Ripple efekti olmadan tıklama özelliği (SwiftUI'daki onTapGesture gibi sade)
 */
fun Modifier.noRippleClickable(onClick: () -> Unit): Modifier = composed {
    clickable(indication = null,
        interactionSource = remember { MutableInteractionSource() }) {
        onClick()
    }
}

/**
 * Kart gölgesi (Swift'teki cardShadow karşılığı)
 */
fun Modifier.cardShadow(
    color: Color = Color.Black,
    alpha: Float = 0.1f,
    cornerRadius: Dp = 12.dp,
    shadowRadius: Dp = 8.dp
): Modifier {
    return this.shadow(
        elevation = shadowRadius,
        shape = androidx.compose.foundation.shape.RoundedCornerShape(cornerRadius),
        spotColor = color.copy(alpha = alpha)
    )
}

// MARK: - Array/List Extensions

fun <T> List<T>.safeGet(index: Int): T? {
    return if (index in 0 until size) this[index] else null
}

// List içindeki Identifiable objeleri bulmak için (Kotlin'de 'id' property'si olan generic bir yapı olmadığı için inline kullanıyoruz)
inline fun <T> Iterable<T>.firstWithId(predicate: (T) -> Boolean): T? {
    return this.find(predicate)
}

// MARK: - Optional String Extension (Kotlin'de String? için)

val String?.isNilOrEmpty: Boolean
    get() = this.isNullOrEmpty()

val String?.orEmpty: String
    get() = this ?: ""

// MARK: - Context / App Version Helpers

val Context.appVersion: String
    get() = try {
        val pInfo = packageManager.getPackageInfo(packageName, 0)
        pInfo.versionName ?: "1.0" // <-- Soru işareti ve tırnakları ekledik
    } catch (e: Exception) {
        "1.0"
    }

val Context.buildNumber: String
    get() = try {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            packageManager.getPackageInfo(packageName, 0).longVersionCode.toString()
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0).versionCode.toString()
        }
    } catch (e: Exception) {
        "1"
    }

val Context.fullVersion: String
    get() = "$appVersion ($buildNumber)"

// MARK: - Encodable Extension Karşılığı (Gson Kullanarak)
// Not: build.gradle'a 'com.google.code.gson:gson:2.10.1' eklenmeli
fun Any.asDictionary(): Map<String, Any> {
    val gson = Gson()
    val json = gson.toJson(this)
    val type = object : TypeToken<Map<String, Any>>() {}.type
    return gson.fromJson(json, type)
}

// MARK: - Intent Helpers (URL açma, arama yapma vb.)
fun Context.openUrl(url: String) {
    try {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    } catch (e: Exception) {
        e.printStackTrace()
    }
}

fun Context.dialPhoneNumber(phoneNumber: String) {
    try {
        val intent = Intent(Intent.ACTION_DIAL).apply {
            data = Uri.parse("tel:$phoneNumber")
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    } catch (e: Exception) {
        e.printStackTrace()
    }
}