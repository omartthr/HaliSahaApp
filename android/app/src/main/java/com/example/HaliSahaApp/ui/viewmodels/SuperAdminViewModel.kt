package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
import com.example.HaliSahaApp.data.models.AdminProfile
import com.example.HaliSahaApp.data.services.AdminService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class SuperAdminViewModel : ViewModel() {
    private val adminService = AdminService
    
    private val _pendingAdmins = MutableStateFlow<List<AdminProfile>>(emptyList())
    val pendingAdmins: StateFlow<List<AdminProfile>> = _pendingAdmins.asStateFlow()
    
    private val _allAdmins = MutableStateFlow<List<AdminProfile>>(emptyList())
    val allAdmins: StateFlow<List<AdminProfile>> = _allAdmins.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        loadData()
    }
    
    fun loadData() {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                _pendingAdmins.value = adminService.fetchPendingAdmins()
                _allAdmins.value = adminService.fetchAllAdmins()
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Veriler yüklenemedi."
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun approveAdmin(adminId: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                adminService.approveAdmin(adminId)
                loadData()
                onSuccess()
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Onaylama işlemi başarısız."
                _isLoading.value = false
            }
        }
    }
    
    fun rejectAdmin(adminId: String, reason: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                adminService.rejectAdmin(adminId, reason)
                loadData()
                onSuccess()
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Reddetme işlemi başarısız."
                _isLoading.value = false
            }
        }
    }
    
    fun suspendAdmin(adminId: String, reason: String, onSuccess: () -> Unit) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                adminService.suspendAdmin(adminId, reason)
                loadData()
                onSuccess()
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Askıya alma işlemi başarısız."
                _isLoading.value = false
            }
        }
    }
    
    fun clearError() {
        _error.value = null
    }
}
