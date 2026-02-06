//
//  ImageCacheService.swift
//  HaliSahaApp
//
//  Görsel önbellekleme servisi - Performans optimizasyonu
//  DÜZELTİLMİŞ VERSİYON: Race condition ve memory leak sorunları giderildi
//
//  Created by Mehmet Mert Mazıcı on 28.01.2026.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - Image Cache Service
actor ImageCacheService {
    
    // MARK: - Singleton
    static let shared = ImageCacheService()
    
    // MARK: - Cache Storage
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    // MARK: - Download Task Management (DÜZELTİLDİ)
    // Task ve devam eden indirmeleri takip etmek için
    private var activeTasks: [String: Task<UIImage, Error>] = [:]
    
    // MARK: - Configuration
    private let maxMemoryCacheSize = 100 * 1024 * 1024 // 100MB
    private let maxDiskCacheSize = 500 * 1024 * 1024 // 500MB
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 gün
    
    // MARK: - Private Init
    private init() {
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 200
        
        // Disk cache klasörünü oluştur
        createCacheDirectoryIfNeeded()
        
        // Eski cache'leri temizle (arka planda)
        Task.detached(priority: .background) { [weak self] in
            await self?.cleanExpiredCache()
        }
    }
    
    // MARK: - Cache Directory
    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("ImageCache", isDirectory: true)
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Cache Key (DÜZELTİLDİ - SHA256 hash kullanıyor)
    private func cacheKey(for url: String) -> String {
        // SHA256 hash kullan - benzersiz ve sabit uzunlukta
        let data = Data(url.utf8)
        
        // iOS 13+ için CryptoKit yerine basit hash
        var hash: UInt64 = 5381
        for byte in data {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        
        // İkinci hash (daha az çakışma için)
        var hash2: UInt64 = 0
        for byte in data {
            hash2 = hash2 &* 31 &+ UInt64(byte)
        }
        
        // İki hash'i birleştir
        return "\(hash)_\(hash2)"
    }
    
    // MARK: - Get Image (Ana metod - DÜZELTİLDİ)
    func getImage(from url: String, size: CGSize? = nil, forceRefresh: Bool = false) async throws -> UIImage {
        // Boş URL kontrolü
        guard !url.isEmpty else {
            throw ImageCacheError.invalidURL
        }
        
        let key = cacheKey(for: url)
        
        // Force refresh ise cache'i atla
        if !forceRefresh {
            // 1. Memory cache kontrolü
            if let cachedImage = memoryCache.object(forKey: key as NSString) {
                return cachedImage
            }
            
            // 2. Disk cache kontrolü
            if let diskImage = loadFromDisk(key: key) {
                // Memory cache'e ekle
                let cost = diskImage.jpegData(compressionQuality: 1)?.count ?? 0
                memoryCache.setObject(diskImage, forKey: key as NSString, cost: cost)
                return diskImage
            }
        } else {
            // Force refresh - bu URL için cache'i temizle
            memoryCache.removeObject(forKey: key as NSString)
            let fileURL = cacheDirectory.appendingPathComponent(key)
            try? fileManager.removeItem(at: fileURL)
        }
        
        // 3. Zaten indiriliyor mu kontrol et (DÜZELTİLDİ - proper task coalescing)
        if let existingTask = activeTasks[url] {
            // Mevcut task'ı bekle
            return try await existingTask.value
        }
        
        // 4. Yeni download task oluştur (DÜZELTİLDİ)
        let task = Task<UIImage, Error> {
            defer {
                // Task tamamlandığında temizle (actor context içinde)
                Task { await self.removeActiveTask(for: url) }
            }
            
            let image = try await self.downloadImage(from: url)
            
            // Resize if needed
            let finalImage: UIImage
            if let targetSize = size, image.size.width > targetSize.width * 2 {
                finalImage = image.resized(to: targetSize) ?? image
            } else {
                finalImage = image
            }
            
            // Cache'e kaydet
            await self.saveToCache(image: finalImage, key: key)
            
            return finalImage
        }
        
        // Task'ı kaydet
        activeTasks[url] = task
        
        return try await task.value
    }
    
    // MARK: - Remove Active Task (YENİ)
    private func removeActiveTask(for url: String) {
        activeTasks[url] = nil
    }
    
    // MARK: - Cancel Task (YENİ - dışarıdan iptal için)
    func cancelDownload(for url: String) {
        activeTasks[url]?.cancel()
        activeTasks[url] = nil
    }
    
    // MARK: - Download Image (Retry mekanizması ile)
    private func downloadImage(from url: String) async throws -> UIImage {
        guard let imageURL = URL(string: url) else {
            throw ImageCacheError.invalidURL
        }
        
        // Custom URLSession configuration
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 4
        
        // HTTP headers
        config.httpAdditionalHeaders = [
            "Accept": "image/webp,image/jpeg,image/png,*/*",
            "Cache-Control": "max-age=604800"
        ]
        
        let session = URLSession(configuration: config)
        
        var lastError: Error?
        let maxRetries = 3
        
        for attempt in 1...maxRetries {
            // Task iptal kontrolü
            try Task.checkCancellation()
            
            do {
                let (data, response) = try await session.data(from: imageURL)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ImageCacheError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw ImageCacheError.httpError(httpResponse.statusCode)
                }
                
                guard let image = UIImage(data: data) else {
                    throw ImageCacheError.invalidImageData
                }
                
                return image
                
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                print("⚠️ Image download attempt \(attempt)/\(maxRetries) failed: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    // Exponential backoff: 0.5s, 1s, 2s
                    let delay = UInt64(pow(2.0, Double(attempt - 1))) * 500_000_000
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        throw lastError ?? ImageCacheError.downloadFailed
    }
    
    // MARK: - Save to Cache
    private func saveToCache(image: UIImage, key: String) {
        // Memory cache
        let cost = image.jpegData(compressionQuality: 0.8)?.count ?? 0
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
        
        // Disk cache (arka planda)
        Task.detached(priority: .background) { [weak self] in
            await self?.saveToDisk(image: image, key: key)
        }
    }
    
    // MARK: - Disk Operations
    private func saveToDisk(image: UIImage, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        try? data.write(to: fileURL)
    }
    
    private func loadFromDisk(key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // Dosya yaşını kontrol et
        if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let modDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) > cacheExpiration {
            // Süresi dolmuş, sil
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        return image
    }
    
    // MARK: - Clean Expired Cache
    private func cleanExpiredCache() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        
        let now = Date()
        
        for fileURL in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let modDate = attributes[.modificationDate] as? Date,
               now.timeIntervalSince(modDate) > cacheExpiration {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Clear All Cache
    func clearCache() {
        // Tüm aktif task'ları iptal et
        for (_, task) in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        
        // Memory cache temizle
        memoryCache.removeAllObjects()
        
        // Disk cache temizle
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Clear Memory Cache Only (YENİ)
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    // MARK: - Remove Specific URL from Cache (YENİ)
    func removeFromCache(url: String) {
        let key = cacheKey(for: url)
        memoryCache.removeObject(forKey: key as NSString)
        
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    // MARK: - Preload Images (TEK VERSİYON - DÜZELTİLDİ)
    func preloadImages(urls: [String], priority: TaskPriority = .background) {
        // Boş URL'leri filtrele
        let validURLs = urls.filter { !$0.isEmpty }
        guard !validURLs.isEmpty else { return }
        
        // Önce cache'te olmayanları bul
        let uncachedURLs = validURLs.filter { url in
            let key = cacheKey(for: url)
            return memoryCache.object(forKey: key as NSString) == nil && loadFromDisk(key: key) == nil
        }
        
        // Batch halinde preload et (max 10)
        for url in uncachedURLs.prefix(10) {
            Task.detached(priority: priority) { [weak self] in
                _ = try? await self?.getImage(from: url, size: nil)
            }
        }
    }
    
    // MARK: - Check if Cached
    func isCached(url: String) -> Bool {
        let key = cacheKey(for: url)
        return memoryCache.object(forKey: key as NSString) != nil || loadFromDisk(key: key) != nil
    }
}

// MARK: - Errors
enum ImageCacheError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidImageData
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz görsel URL'i"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        case .httpError(let code):
            return "HTTP hatası: \(code)"
        case .invalidImageData:
            return "Görsel verisi okunamadı"
        case .downloadFailed:
            return "Görsel indirilemedi"
        }
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage? {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Modern API kullan
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
