// filepath: Services/StorageService.swift
//
//  StorageService.swift
//  HaliSahaApp
//
//  Firebase Storage işlemleri - Fotoğraf yükleme/silme
//
//  Created by Mehmet Mert Mazıcı on 27.01.2026.
//

import Foundation
import FirebaseStorage
import UIKit

// MARK: - Storage Service
final class StorageService {
    
    // MARK: - Singleton
    static let shared = StorageService()
    
    // MARK: - Private Properties
    private let storage = Storage.storage()
    private let maxImageSize: Int64 = 5 * 1024 * 1024 // 5MB
    private let compressionQuality: CGFloat = 0.7
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - Storage References
    private var facilityImagesRef: StorageReference {
        storage.reference().child("facilities")
    }
    
    private var pitchImagesRef: StorageReference {
        storage.reference().child("pitches")
    }
    
    private var userImagesRef: StorageReference {
        storage.reference().child("users")
    }
    
    // MARK: - Upload Facility Image
    @MainActor
    func uploadFacilityImage(_ image: UIImage, facilityId: String) async throws -> String {
        let imageId = UUID().uuidString
        let ref = facilityImagesRef.child(facilityId).child("\(imageId).jpg")
        
        return try await uploadImage(image, to: ref)
    }
    
    // MARK: - Upload Multiple Facility Images
    @MainActor
    func uploadFacilityImages(_ images: [UIImage], facilityId: String) async throws -> [String] {
        var urls: [String] = []
        
        for image in images {
            let url = try await uploadFacilityImage(image, facilityId: facilityId)
            urls.append(url)
        }
        
        return urls
    }
    
    // MARK: - Upload Pitch Image
    @MainActor
    func uploadPitchImage(_ image: UIImage, facilityId: String, pitchId: String) async throws -> String {
        let imageId = UUID().uuidString
        let ref = pitchImagesRef.child(facilityId).child(pitchId).child("\(imageId).jpg")
        
        return try await uploadImage(image, to: ref)
    }
    
    // MARK: - Upload Multiple Pitch Images
    @MainActor
    func uploadPitchImages(_ images: [UIImage], facilityId: String, pitchId: String) async throws -> [String] {
        var urls: [String] = []
        
        for image in images {
            let url = try await uploadPitchImage(image, facilityId: facilityId, pitchId: pitchId)
            urls.append(url)
        }
        
        return urls
    }
    
    // MARK: - Upload User Profile Image
    @MainActor
    func uploadUserProfileImage(_ image: UIImage, userId: String) async throws -> String {
        let ref = userImagesRef.child(userId).child("profile.jpg")
        return try await uploadImage(image, to: ref)
    }
    
    // MARK: - Generic Upload
    private func uploadImage(_ image: UIImage, to ref: StorageReference) async throws -> String {
        // Görüntüyü sıkıştır
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw StorageError.compressionFailed
        }
        
        // Boyut kontrolü
        if imageData.count > maxImageSize {
            throw StorageError.fileTooLarge
        }
        
        // Metadata oluştur
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Yükle
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        
        // URL al
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }
    
    // MARK: - Delete Image
    func deleteImage(at url: String) async throws {
        guard let ref = try? storage.reference(forURL: url) else {
            throw StorageError.invalidURL
        }
        
        try await ref.delete()
    }
    
    // MARK: - Delete Multiple Images
    func deleteImages(at urls: [String]) async throws {
        for url in urls {
            try await deleteImage(at: url)
        }
    }
    
    // MARK: - Delete All Facility Images
    func deleteFacilityImages(facilityId: String) async throws {
        let ref = facilityImagesRef.child(facilityId)
        try await deleteFolder(ref)
    }
    
    // MARK: - Delete All Pitch Images
    func deletePitchImages(facilityId: String, pitchId: String) async throws {
        let ref = pitchImagesRef.child(facilityId).child(pitchId)
        try await deleteFolder(ref)
    }
    
    // MARK: - Delete Folder
    private func deleteFolder(_ ref: StorageReference) async throws {
        let result = try await ref.listAll()
        
        for item in result.items {
            try await item.delete()
        }
        
        for prefix in result.prefixes {
            try await deleteFolder(prefix)
        }
    }
}

// MARK: - Storage Error
enum StorageError: LocalizedError {
    case compressionFailed
    case fileTooLarge
    case invalidURL
    case uploadFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Görüntü sıkıştırılamadı"
        case .fileTooLarge:
            return "Dosya boyutu çok büyük (max 5MB)"
        case .invalidURL:
            return "Geçersiz dosya URL'i"
        case .uploadFailed(let message):
            return "Yükleme hatası: \(message)"
        case .deleteFailed(let message):
            return "Silme hatası: \(message)"
        }
    }
}
