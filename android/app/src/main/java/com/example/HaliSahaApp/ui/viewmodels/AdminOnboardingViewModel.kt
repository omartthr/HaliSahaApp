package com.example.HaliSahaApp.ui.viewmodels

import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.AdminProfile
import com.example.HaliSahaApp.data.models.VerificationDocuments
import com.example.HaliSahaApp.data.remote.StorageService
import com.example.HaliSahaApp.data.services.AdminService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class AdminOnboardingViewModel : ViewModel() {
    private val adminService = AdminService
    private val storageService = StorageService
    
    val myAdminProfile = adminService.myAdminProfile
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        adminService.startMyAdminProfileListener()
    }
    
    override fun onCleared() {
        super.onCleared()
        // DONT stop listener here if it's shared, but for safety:
        // adminService.stopMyAdminProfileListener()
    }

    fun submitDocuments(
        taxPlateUri: Uri,
        businessLicenseUri: Uri,
        idFrontUri: Uri,
        idBackUri: Uri,
        facilityUris: List<Uri>,
        onSuccess: () -> Unit
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                // Upload documents
                val taxUrl = storageService.uploadVerificationDocument(taxPlateUri, "taxCertificate")
                val licenseUrl = storageService.uploadVerificationDocument(businessLicenseUri, "businessLicense")
                val frontUrl = storageService.uploadVerificationDocument(idFrontUri, "idFront")
                val backUrl = storageService.uploadVerificationDocument(idBackUri, "idBack")
                
                val facilityUrls = mutableListOf<String>()
                facilityUris.forEachIndexed { index, uri ->
                    val url = storageService.uploadVerificationDocument(uri, "facilityPhoto_$index")
                    facilityUrls.add(url)
                }

                val documents = VerificationDocuments(
                    taxCertificateURL = taxUrl,
                    businessLicenseURL = licenseUrl,
                    idFrontURL = frontUrl,
                    idBackURL = backUrl,
                    facilityPhotoURLs = facilityUrls
                )

                adminService.submitVerificationDocuments(documents)
                onSuccess()
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Belgeler yüklenirken bir hata oluştu"
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun clearError() {
        _error.value = null
    }
}
