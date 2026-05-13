package com.example.HaliSahaApp.data.services

import android.content.Context
import android.content.SharedPreferences
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.BookingStatus
import java.util.Calendar

object NotificationService {

    private const val PREFS_NAME = "notification_prefs"
    private const val KEY_PERMISSION_ASKED = "notifications.permissionAsked"
    private const val KEY_MATCH_REMINDERS = "settings.matchReminders"
    private const val IDENTIFIER_PREFIX = "booking_"

    private lateinit var prefs: SharedPreferences
    private lateinit var context: Context

    fun initialize(applicationContext: Context) {
        context = applicationContext
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    var hasAskedPermission: Boolean
        get() = prefs.getBoolean(KEY_PERMISSION_ASKED, false)
        set(value) = prefs.edit().putBoolean(KEY_PERMISSION_ASKED, value).apply()

    var matchRemindersEnabled: Boolean
        get() = prefs.getBoolean(KEY_MATCH_REMINDERS, true)
        set(value) = prefs.edit().putBoolean(KEY_MATCH_REMINDERS, value).apply()

    // MARK: - Schedule (single booking)

    fun scheduleReminders(booking: Booking) {
        if (!matchRemindersEnabled) return
        val bookingId = booking.id ?: return
        if (booking.status != BookingStatus.confirmed) return

        val reminderHours = listOf(24, 2)
        for (hours in reminderHours) {
            scheduleSingle(booking, bookingId, hours)
        }
    }

    fun cancelReminders(bookingId: String) {
        // Here you would cancel the PendingIntents for AlarmManager or WorkManager jobs
        // using the identifier prefix + bookingId
    }

    // MARK: - Sync (idempotent)

    fun syncReminders(bookings: List<Booking>) {
        if (!matchRemindersEnabled) {
            cancelAllOurReminders()
            return
        }

        val validBookings = bookings.filter { 
            it.id != null && it.status == BookingStatus.confirmed && !it.isPast
        }

        val reminderHours = listOf(24, 2)
        for (booking in validBookings) {
            val id = booking.id ?: continue
            for (hours in reminderHours) {
                scheduleSingle(booking, id, hours)
            }
        }
        
        // Normally we would also remove orphan reminders here
    }

    fun cancelAllOurReminders() {
        // Implementation to cancel all reminders starting with IDENTIFIER_PREFIX
    }

    fun cancelAllReminders() {
        // Implementation to cancel all reminders (logout)
    }

    private fun identifier(bookingId: String, hoursBefore: Int): String {
        return "$IDENTIFIER_PREFIX${bookingId}_${hoursBefore}h"
    }

    private fun scheduleSingle(booking: Booking, bookingId: String, hoursBefore: Int) {
        val calendar = Calendar.getInstance()
        calendar.time = booking.date
        calendar.set(Calendar.HOUR_OF_DAY, booking.startHour)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        
        calendar.add(Calendar.HOUR_OF_DAY, -hoursBefore)
        
        if (calendar.time.before(Calendar.getInstance().time)) {
            return // Past date
        }

        val identifier = identifier(bookingId, hoursBefore)
        
        // TODO: Implement actual AlarmManager or WorkManager scheduling using `identifier`
        // with content:
        // Title: "Maç Hatırlatması ⚽"
        // Body: "${booking.facilityName} – ${booking.timeSlotString}\nMaça $hoursBefore saat kaldı"
    }
}
