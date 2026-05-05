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
    case pending = "pending"       // Onay bekliyor
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

// MARK: - Admin Profile Model
struct AdminProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var businessName: String
    var taxNumber: String
    var approvalStatus: AdminApprovalStatus
    var rejectionReason: String?
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
        approvedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.businessName = businessName
        self.taxNumber = taxNumber
        self.approvalStatus = approvalStatus
        self.rejectionReason = rejectionReason
        self.approvedAt = approvedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
