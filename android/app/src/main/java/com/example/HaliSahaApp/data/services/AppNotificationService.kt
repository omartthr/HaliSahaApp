package com.example.HaliSahaApp.data.services

import com.example.HaliSahaApp.data.models.AppNotification
import com.example.HaliSahaApp.data.remote.FirebaseService
import com.example.HaliSahaApp.data.remote.FirestoreField
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.Query
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await

// MARK: - App Notification Service
object AppNotificationService {
    private val firebaseService = FirebaseService

    // MARK: - StateFlows
    private val _notifications = MutableStateFlow<List<AppNotification>>(emptyList())
    val notifications: StateFlow<List<AppNotification>> = _notifications.asStateFlow()

    private val _unreadCount = MutableStateFlow(0)
    val unreadCount: StateFlow<Int> = _unreadCount.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    // MARK: - Private
    private var listener: ListenerRegistration? = null
    private var listeningUserId: String? = null

    // MARK: - Listener

    fun startListening(userId: String) {
        if (listeningUserId == userId) return
        stopListening()
        
        listeningUserId = userId
        _isLoading.value = true

        val query = firebaseService.notificationsCollection
            .whereEqualTo("userId", userId)
            .orderBy(FirestoreField.CREATED_AT, Query.Direction.DESCENDING)
            .limit(100)

        listener = query.addSnapshotListener { snapshot, error ->
            _isLoading.value = false

            if (error != null) {
                // Ignore errors for now
                return@addSnapshotListener
            }

            val docs = snapshot?.documents ?: emptyList()
            val items = docs.mapNotNull { it.toObject(AppNotification::class.java) }
            
            _notifications.value = items
            _unreadCount.value = items.count { !it.isRead }
        }
    }

    fun stopListening() {
        listener?.remove()
        listener = null
        listeningUserId = null
    }

    fun clearAll() {
        stopListening()
        _notifications.value = emptyList()
        _unreadCount.value = 0
    }

    // MARK: - Write

    suspend fun notify(notification: AppNotification) {
        try {
            firebaseService.createDocument(
                collection = firebaseService.notificationsCollection,
                data = notification
            )
        } catch (e: Exception) {
            // Silently ignore notification write errors
        }
    }

    // MARK: - Read State

    suspend fun markAsRead(id: String) {
        try {
            firebaseService.updateDocument(
                collection = firebaseService.notificationsCollection,
                documentId = id,
                fields = mapOf("isRead" to true)
            )
        } catch (e: Exception) {
            // Ignore
        }
    }

    suspend fun markAllAsRead() {
        val unread = _notifications.value.filter { !it.isRead && it.id != null }
        if (unread.isEmpty()) return

        val batch = firebaseService.db.batch()
        for (n in unread) {
            n.id?.let { id ->
                val ref = firebaseService.notificationsCollection.document(id)
                batch.update(ref, mapOf("isRead" to true))
            }
        }

        try {
            batch.commit().await()
        } catch (e: Exception) {
            // Ignore
        }
    }

    // MARK: - Delete

    suspend fun delete(id: String) {
        try {
            firebaseService.deleteDocument(
                collection = firebaseService.notificationsCollection,
                documentId = id
            )
        } catch (e: Exception) {
            // Ignore
        }
    }
}
