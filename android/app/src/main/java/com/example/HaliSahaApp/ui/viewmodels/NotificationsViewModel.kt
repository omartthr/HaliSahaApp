package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.remote.FirebaseService
import com.example.HaliSahaApp.data.services.AppNotificationService
import kotlinx.coroutines.launch

class NotificationsViewModel : ViewModel() {
    private val notificationService = AppNotificationService
    private val firebaseService = FirebaseService
    
    val notifications = notificationService.notifications
    val unreadCount = notificationService.unreadCount
    val isLoading = notificationService.isLoading
    
    init {
        val userId = firebaseService.currentUserId
        if (userId != null) {
            notificationService.startListening(userId)
        }
    }
    
    override fun onCleared() {
        super.onCleared()
        // If we want to keep listening globally, don't stop here.
        // notificationService.stopListening() 
    }
    
    fun markAsRead(id: String) {
        viewModelScope.launch {
            notificationService.markAsRead(id)
        }
    }
    
    fun markAllAsRead() {
        viewModelScope.launch {
            notificationService.markAllAsRead()
        }
    }
    
    fun deleteNotification(id: String) {
        viewModelScope.launch {
            notificationService.delete(id)
        }
    }
}
