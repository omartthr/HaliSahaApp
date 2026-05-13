//
//  AdminProfile.swift
//  HaliSahaApp
//
//  Saha sahibi admin'e özel profil verisi — users collection'ındaki
//  genel User kaydına ek olarak admins collection'ında tutulur.
//

import Foundation
import FirebaseFirestore

// MARK: - Admin Approval Status
enum AdminApprovalStatus: String, Codable {
    case pending = "pending"       // Onay bekliyor (henüz belge yüklenmedi veya inceleme aşamasında)
    case approved = "approved"     // Onaylandı
    case rejected = "rejected"     // Reddedildi
    case suspended = "suspended"   // Askıya alındı

    var displayName: String {
        switch self {
        case .pending:   return "Onay Bekliyor"
        case .approved:  return "Onaylandı"
        case .rejected:  return "Reddedildi"
        case .suspended: return "Askıya Alındı"
        }
    }

    var isActive: Bool {
        self == .approved
    }
}

// MARK: - Verification Document Type
enum AdminDocumentType: String, Codable, CaseIterable {
    case taxCertificate = "taxCertificate"        // Vergi levhası
    case businessLicense = "businessLicense"      // İşyeri açma ve çalışma ruhsatı
    case idFront = "idFront"                      // Kimlik ön yüz
    case idBack = "idBack"                        // Kimlik arka yüz
    case facilityPhoto = "facilityPhoto"          // Saha fotoğrafları (birden fazla)

    var displayName: String {
        switch self {
        case .taxCertificate:  return "Vergi Levhası"
        case .businessLicense: return "İşyeri Ruhsatı"
        case .idFront:         return "Kimlik Ön Yüz"
        case .idBack:          return "Kimlik Arka Yüz"
        case .facilityPhoto:   return "Saha Fotoğrafı"
        }
    }
}

// MARK: - Verification Documents
struct VerificationDocuments: Codable, Hashable {
    var taxCertificateURL: String?
    var businessLicenseURL: String?
    var idFrontURL: String?
    var idBackURL: String?
    var facilityPhotoURLs: [String]

    init(
        taxCertificateURL: String? = nil,
        businessLicenseURL: String? = nil,
        idFrontURL: String? = nil,
        idBackURL: String? = nil,
        facilityPhotoURLs: [String] = []
    ) {
        self.taxCertificateURL = taxCertificateURL
        self.businessLicenseURL = businessLicenseURL
        self.idFrontURL = idFrontURL
        self.idBackURL = idBackURL
        self.facilityPhotoURLs = facilityPhotoURLs
    }

    // En az 3 saha fotoğrafı + 4 zorunlu belge gerekli
    var isComplete: Bool {
        guard let tax = taxCertificateURL, !tax.isEmpty,
              let lic = businessLicenseURL, !lic.isEmpty,
              let idF = idFrontURL, !idF.isEmpty,
              let idB = idBackURL, !idB.isEmpty
        else { return false }
        return facilityPhotoURLs.count >= 3
    }
}

// MARK: - Admin Profile Model
struct AdminProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var businessName: String
    var taxNumber: String
    var approvalStatus: AdminApprovalStatus
    var rejectionReason: String?
    var documents: VerificationDocuments
    var documentsSubmittedAt: Date?
    var reviewedBy: String?              // Onay/red veren superAdmin uid
    var reviewedAt: Date?
    var approvedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initializer
    init(
        id: String? = nil,
        businessName: String,
        taxNumber: String,
        approvalStatus: AdminApprovalStatus = .pending,
        rejectionReason: String? = nil,
        documents: VerificationDocuments = VerificationDocuments(),
        documentsSubmittedAt: Date? = nil,
        reviewedBy: String? = nil,
        reviewedAt: Date? = nil,
        approvedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.businessName = businessName
        self.taxNumber = taxNumber
        self.approvalStatus = approvalStatus
        self.rejectionReason = rejectionReason
        self.documents = documents
        self.documentsSubmittedAt = documentsSubmittedAt
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
        self.approvedAt = approvedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // NOT: Custom init(from:) eklemiyoruz çünkü `@DocumentID` mekanizması
    // synthesized Codable üzerinden çalışıyor; manuel decode `id`'yi her zaman
    // nil bırakıyordu. Bu yüzden eski "documents" alanı olmayan adminleri Console'da
    // manuel düzeltmek gerekirse: `documents: { facilityPhotoURLs: [] }` ekle.
}
