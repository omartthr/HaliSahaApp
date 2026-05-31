package com.example.HaliSahaApp.ui.screens.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Group
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.data.remote.ChatService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ChatListViewModel : ViewModel() {

    private val chatService = ChatService

    private val _groups = MutableStateFlow<List<Group>>(emptyList())
    val groups: StateFlow<List<Group>> = _groups.asStateFlow()

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        fetchGroups()
    }

    private fun fetchGroups() {
        val currentUserId = AuthService.currentUser.value?.id
        if (currentUserId == null) {
            _error.value = "Kullanıcı girişi yapılmamış."
            _isLoading.value = false
            return
        }

        viewModelScope.launch {
            _isLoading.value = true
            try {
                chatService.getUserGroupsFlow(currentUserId).collect { groupsList ->
                    _groups.value = groupsList
                    _isLoading.value = false
                }
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Gruplar yüklenirken bir hata oluştu."
                _isLoading.value = false
            }
        }
    }
}
