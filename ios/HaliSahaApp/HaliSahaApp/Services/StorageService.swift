//
//  StorageService.swift
//  HaliSahaApp
//
//  Firebase Storage işlemleri - Fotoğraf yükleme/silme
//  DÜZELTİLMİŞ VERSİYON: downloadImage kaldırıldı (ImageCacheService kullanılacak)
//
//  Created by Mehmet Mert Mazıcı on 27.01.2026.
//

import Foundation
import FirebaseStorage
import UIKit

// MARK: - Storage Service
@MainActor
final class StorageService {
    
    // MARK: - Singleton
    static let shared = StorageService()
    
    // MARK: - Private Properties
    private let storage = Storage.storage()
    private let maxImageSize: Int64 = 5 * 1024 * 1024 // 5MB
    private let compressionQuality: CGFloat = 0.7
    private let maxImageDimension: CGFloat = 1920 // Max genişlik/yükseklik
    
    // Retry ve timeout ayarları
    private let maxRetries = 3
    private let retryDelay: UInt64 = 1_000_000_000 // 1 saniye (nanoseconds)
    
    // Upload limiter
    private actor UploadLimiter {
        private var activeUploads = 0
        private let maxConcurrent = 3
        
        func acquire() async {
            while activeUploads >= maxConcurrent {
                await Task.yield()
            }
            activeUploads += 1
        }
        
        func release() {
            activeUploads = max(0, activeUploads - 1)
        }
    }
    
    private let uploadLimiter = UploadLimiter()
    
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
    func uploadFacilityImage(_ image: UIImage, facilityId: String) async throws -> String {
        let imageId = UUID().uuidString
        let ref = facilityImagesRef.child(facilityId).child("\(imageId).jpg")
        
        return try await uploadImage(image, to: ref)
    }
    
    // MARK: - Upload Multiple Facility Images (İYİLEŞTİRİLDİ)
    func uploadFacilityImages(_ images: [UIImage], facilityId: String) async throws -> [String] {
        var urls: [String] = []
        var errors: [Error] = []
        
        // Paralel yükleme için TaskGroup kullan
        await withTaskGroup(of: Result<String, Error>.self) { group in
            for image in images {
                group.addTask {
                    do {
                        let url = try await self.uploadFacilityImage(image, facilityId: facilityId)
                        return .success(url)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            for await result in group {
                switch result {
                case .success(let url):
                    urls.append(url)
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        
        // Eğer hiç yükleme başarılı olmadıysa hata fırlat
        if urls.isEmpty && !errors.isEmpty {
            throw errors.first!
        }
        
        return urls
    }
    
    // MARK: - Upload Pitch Image
    func uploadPitchImage(_ image: UIImage, facilityId: String, pitchId: String) async throws -> String {
        let imageId = UUID().uuidString
        let ref = pitchImagesRef.child(facilityId).child(pitchId).child("\(imageId).jpg")
        
        return try await uploadImage(image, to: ref)
    }
    
    // MARK: - Upload Multiple Pitch Images (İYİLEŞTİRİLDİ)
    func uploadPitchImages(_ images: [UIImage], facilityId: String, pitchId: String) async throws -> [String] {
        var urls: [String] = []
        var errors: [Error] = []
        
        await withTaskGroup(of: Result<String, Error>.self) { group in
            for image in images {
                group.addTask {
                    do {
                        let url = try await self.uploadPitchImage(image, facilityId: facilityId, pitchId: pitchId)
                        return .success(url)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            for await result in group {
                switch result {
                case .success(let url):
                    urls.append(url)
                case .failure(let error):
                    errors.append(error)
                }
            }
        }
        
        if urls.isEmpty && !errors.isEmpty {
            throw errors.first!
        }
        
        return urls
    }
    
    // MARK: - Upload User Profile Image
    func uploadUserProfileImage(_ image: UIImage, userId: String) async throws -> String {
        let ref = userImagesRef.child(userId).child("profile.jpg")
        return try await uploadImage(image, to: ref)
    }
    
    // MARK: - Generic Upload (with Retry & Optimization)
    private func uploadImage(_ image: UIImage, to ref: StorageReference) async throws -> String {
        // Upload limiter
        await uploadLimiter.acquire()
        defer { Task { await uploadLimiter.release() } }
        
        // Görüntüyü optimize et (boyut küçültme)
        let optimizedImage = optimizeImage(image)
        
        // Görüntüyü sıkıştır
        guard let imageData = optimizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw StorageError.compressionFailed
        }
        
        // Boyut kontrolü
        if imageData.count > maxImageSize {
            // Daha fazla sıkıştır
            guard let reducedData = optimizedImage.jpegData(compressionQuality: 0.5) else {
                throw StorageError.compressionFailed
            }
            
            if reducedData.count > maxImageSize {
                throw StorageError.fileTooLarge
            }
            
            return try await performUpload(data: reducedData, to: ref)
        }
        
        return try await performUpload(data: imageData, to: ref)
    }
    
    // MARK: - Optimize Image (YENİ)
    private func optimizeImage(_ image: UIImage) -> UIImage {
        let maxDim = maxImageDimension
        
        // Boyut kontrolü
        if image.size.width <= maxDim && image.size.height <= maxDim {
            return image
        }
        
        // Aspect ratio'yu koru
        let widthRatio = maxDim / image.size.width
        let heightRatio = maxDim / image.size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )
        
        // Yeniden boyutlandır
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Perform Upload (Retry logic)
    private func performUpload(data: Data, to ref: StorageReference) async throws -> String {
        // Metadata oluştur
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Retry mekanizması ile yükle
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                _ = try await ref.putDataAsync(data, metadata: metadata)
                let downloadURL = try await ref.downloadURL()
                return downloadURL.absoluteString
            } catch {
                lastError = error
                print("⚠️ Upload attempt \(attempt)/\(maxRetries) failed: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    // Üstel backoff: 1s, 2s, 4s
                    let delay = retryDelay * UInt64(1 << (attempt - 1))
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        throw lastError ?? StorageError.uploadFailed("Unknown error after \(maxRetries) attempts")
    }
    
    // MARK: - Delete Image
    func deleteImage(at url: String) async throws {
        guard !url.isEmpty else { return }
        
        guard let ref = try? storage.reference(forURL: url) else {
            throw StorageError.invalidURL
        }
        
        do {
            try await ref.delete()
        } catch {
            // Dosya zaten silinmişse hata verme
            let nsError = error as NSError
            if nsError.domain == StorageErrorDomain && nsError.code == StorageErrorCode.objectNotFound.rawValue {
                print("⚠️ Image already deleted: \(url)")
                return
            }
            throw StorageError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Multiple Images (İYİLEŞTİRİLDİ)
    func deleteImages(at urls: [String]) async throws {
        let validURLs = urls.filter { !$0.isEmpty }
        guard !validURLs.isEmpty else { return }
        
        // Paralel silme
        await withTaskGroup(of: Void.self) { group in
            for url in validURLs {
                group.addTask {
                    try? await self.deleteImage(at: url)
                }
            }
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
        do {
            let result = try await ref.listAll()
            
            // Paralel silme
            await withTaskGroup(of: Void.self) { group in
                for item in result.items {
                    group.addTask {
                        try? await item.delete()
                    }
                }
            }
            
            // Alt klasörleri sil
            for prefix in result.prefixes {
                try await deleteFolder(prefix)
            }
        } catch {
            // Klasör boşsa veya yoksa hata verme
            let nsError = error as NSError
            if nsError.domain == StorageErrorDomain && nsError.code == StorageErrorCode.objectNotFound.rawValue {
                return
            }
            throw error
        }
    }
}

// MARK: - Storage Error
enum StorageError: LocalizedError {
    case compressionFailed
    case fileTooLarge
    case invalidURL
    case uploadFailed(String)
    case downloadFailed(String)
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
        case .downloadFailed(let message):
            return "İndirme hatası: \(message)"
        case .deleteFailed(let message):
            return "Silme hatası: \(message)"
        }
    }
}
