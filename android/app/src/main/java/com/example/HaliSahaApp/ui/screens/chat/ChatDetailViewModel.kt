package com.example.HaliSahaApp.ui.screens.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Group
import com.example.HaliSahaApp.data.models.Message
import com.example.HaliSahaApp.data.models.MessageType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.data.remote.ChatService
import com.example.HaliSahaApp.data.remote.FirebaseService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ChatDetailViewModel : ViewModel() {

    private val chatService = ChatService

    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: StateFlow<List<Message>> = _messages.asStateFlow()

    private val _group = MutableStateFlow<Group?>(null)
    val group: StateFlow<Group?> = _group.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private var currentGroupId: String? = null

    fun initGroup(groupId: String) {
        if (currentGroupId == groupId) return
        currentGroupId = groupId
        fetchGroupDetails(groupId)
        listenToMessages(groupId)
    }

    private fun fetchGroupDetails(groupId: String) {
        viewModelScope.launch {
            try {
                // Sadece group bilgisini tek seferlik çekiyoruz, arayüzde adını/resmini göstermek için.
                val groupData: Group = FirebaseService.fetchDocument(
                    collection = FirebaseService.groupsCollection,
                    documentId = groupId
                )
                _group.value = groupData
            } catch (e: Exception) {
                _error.value = "Grup bilgileri yüklenemedi."
            }
        }
    }

    private fun listenToMessages(groupId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                chatService.getMessagesFlow(groupId).collect { messagesList ->
                    _messages.value = messagesList
                    _isLoading.value = false
                    
                    // Okunmamış olanları okundu işaretle
                    markUnreadMessagesAsRead(groupId, messagesList)
                }
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Mesajlar yüklenirken bir hata oluştu."
                _isLoading.value = false
            }
        }
    }
    
    private fun markUnreadMessagesAsRead(groupId: String, messagesList: List<Message>) {
        val currentUserId = AuthService.currentUser.value?.id ?: return
        val unreadMessageIds = messagesList
            .filter { it.senderId != currentUserId && !it.readBy.contains(currentUserId) }
            .mapNotNull { it.id }
            
        if (unreadMessageIds.isNotEmpty()) {
            viewModelScope.launch {
                try {
                    chatService.markMessagesAsRead(groupId, unreadMessageIds, currentUserId)
                } catch (e: Exception) {
                    println("Okundu işareti güncellenemedi: \${e.message}")
                }
            }
        }
    }

    fun sendMessage(content: String) {
        val groupId = currentGroupId ?: return
        val currentUser = AuthService.currentUser.value ?: return
        
        if (content.isBlank()) return

        val currentUserId = currentUser.id ?: return

        val newMessage = Message(
            groupId = groupId,
            senderId = currentUserId,
            senderName = currentUser.fullName ?: "", // Ad soyad veya displayName
            content = content.trim(),
            messageType = MessageType.TEXT
        )

        viewModelScope.launch {
            try {
                chatService.sendMessage(groupId, newMessage)
            } catch (e: Exception) {
                _error.value = "Mesaj gönderilemedi: \${e.localizedMessage}"
            }
        }
    }
}
