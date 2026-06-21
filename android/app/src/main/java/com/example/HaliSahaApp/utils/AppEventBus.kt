package com.example.HaliSahaApp.utils

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * iOS'un NotificationCenter mekanizmasının Android karşılığı.
 * Ekranlar arası iletişim için global event bus.
 * 
 * Kullanım:
 *   Yayın: AppEventBus.emit(AppEvent.SwitchToBookingsTab)
 *   Dinleme: AppEventBus.events.collect { event -> ... }
 */
object AppEventBus {

    sealed class AppEvent {
        object SwitchToBookingsTab : AppEvent()
        object SwitchToHomeTab : AppEvent()
    }

    private val _events = MutableSharedFlow<AppEvent>(extraBufferCapacity = 1)
    val events = _events.asSharedFlow()

    suspend fun emit(event: AppEvent) {
        _events.emit(event)
    }

    // Coroutine scope gerektirmeyen tryEmit versiyonu
    fun tryEmit(event: AppEvent) {
        _events.tryEmit(event)
    }
}
