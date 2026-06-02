package com.example.HaliSahaApp.data.models

import com.google.firebase.firestore.DocumentId
import java.util.Date

// MARK: - Admin Approval Status
enum class AdminApprovalStatus(val rawValue: String, val displayName: String) {
    @com.google.firebase.firestore.PropertyName("pending") PENDING("pending", "Onay Bekliyor"),
    @com.google.firebase.firestore.PropertyName("approved") APPROVED("approved", "Onaylandı"),
    @com.google.firebase.firestore.PropertyName("rejected") REJECTED("rejected", "Reddedildi"),
    @com.google.firebase.firestore.PropertyName("suspended") SUSPENDED("suspended", "Askıya Alındı");
    
    val isActive: Boolean
        get() = this == APPROVED
}

// MARK: - Verification Document Type
enum class AdminDocumentType(val rawValue: String, val displayName: String) {
    @com.google.firebase.firestore.PropertyName("taxCertificate") TAX_CERTIFICATE("taxCertificate", "Vergi Levhası"),
    @com.google.firebase.firestore.PropertyName("businessLicense") BUSINESS_LICENSE("businessLicense", "İşyeri Ruhsatı"),
    @com.google.firebase.firestore.PropertyName("idFront") ID_FRONT("idFront", "Kimlik Ön Yüz"),
    @com.google.firebase.firestore.PropertyName("idBack") ID_BACK("idBack", "Kimlik Arka Yüz"),
    @com.google.firebase.firestore.PropertyName("facilityPhoto") FACILITY_PHOTO("facilityPhoto", "Saha Fotoğrafı");
}

// MARK: - Verification Documents
data class VerificationDocuments(
    val taxCertificateURL: String? = null,
    val businessLicenseURL: String? = null,
    val idFrontURL: String? = null,
    val idBackURL: String? = null,
    val facilityPhotoURLs: List<String> = emptyList()
) {
    val isComplete: Boolean
        get() {
            if (taxCertificateURL.isNullOrEmpty() ||
                businessLicenseURL.isNullOrEmpty() ||
                idFrontURL.isNullOrEmpty() ||
                idBackURL.isNullOrEmpty()
            ) {
                return false
            }
            return facilityPhotoURLs.size >= 3
        }
}

// MARK: - Admin Profile Model
data class AdminProfile(
    @DocumentId
    val id: String? = null,
    val businessName: String = "",
    val taxNumber: String = "",
    val approvalStatus: AdminApprovalStatus = AdminApprovalStatus.PENDING,
    val rejectionReason: String? = null,
    val documents: VerificationDocuments = VerificationDocuments(),
    val documentsSubmittedAt: Date? = null,
    val reviewedBy: String? = null,
    val reviewedAt: Date? = null,
    val approvedAt: Date? = null,
    val createdAt: Date = Date(),
    val updatedAt: Date = Date()
)
