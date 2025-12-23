//
//  FirebaseService.swift
//  HaliSahaApp
//
//  Ana Firebase yönetim sınıfı - Firestore referansları ve ortak işlemler
//
//  Created by Mehmet Mert Mazıcı on 23.12.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firebase Service (Singleton)
final class FirebaseService {
    
    // MARK: - Singleton
    static let shared = FirebaseService()
    
    // MARK: - Firestore Reference
    let db = Firestore.firestore()
    
    // MARK: - Collection References
    var usersCollection: CollectionReference {
        db.collection(FirestoreCollection.users)
    }
    
    var facilitiesCollection: CollectionReference {
        db.collection(FirestoreCollection.facilities)
    }
    
    var bookingsCollection: CollectionReference {
        db.collection(FirestoreCollection.bookings)
    }
    
    var groupsCollection: CollectionReference {
        db.collection(FirestoreCollection.groups)
    }
    
    var matchPostsCollection: CollectionReference {
        db.collection(FirestoreCollection.matchPosts)
    }
    
    var reviewsCollection: CollectionReference {
        db.collection(FirestoreCollection.reviews)
    }
    
    var notificationsCollection: CollectionReference {
        db.collection(FirestoreCollection.notifications)
    }
    
    // MARK: - Sub-collection References
    func pitchesCollection(for facilityId: String) -> CollectionReference {
        facilitiesCollection.document(facilityId).collection(FirestoreCollection.pitches)
    }
    
    func messagesCollection(for groupId: String) -> CollectionReference {
        groupsCollection.document(groupId).collection(FirestoreCollection.messages)
    }
    
    // MARK: - Private Init
    private init() {
        configureFirestore()
    }
    
    // MARK: - Configuration
    private func configureFirestore() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100 MB cache
        db.settings = settings
    }
    
    // MARK: - Current User
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isLoggedIn: Bool {
        Auth.auth().currentUser != nil
    }
}

// MARK: - Firestore Collection Names
struct FirestoreCollection {
    static let users = "users"
    static let facilities = "facilities"
    static let pitches = "pitches"
    static let bookings = "bookings"
    static let groups = "groups"
    static let messages = "messages"
    static let matchPosts = "match_posts"
    static let reviews = "reviews"
    static let notifications = "notifications"
    static let userReliabilityReviews = "user_reliability_reviews"
}

// MARK: - Firestore Field Names (Sorgu için)
struct FirestoreField {
    // Common
    static let id = "id"
    static let createdAt = "createdAt"
    static let updatedAt = "updatedAt"
    static let isActive = "isActive"
    
    // User
    static let email = "email"
    static let username = "username"
    static let userType = "userType"
    static let fcmToken = "fcmToken"
    
    // Facility
    static let ownerId = "ownerId"
    static let status = "status"
    static let latitude = "latitude"
    static let longitude = "longitude"
    
    // Booking
    static let userId = "userId"
    static let facilityId = "facilityId"
    static let pitchId = "pitchId"
    static let date = "date"
    static let startHour = "startHour"
    
    // Group
    static let memberIds = "memberIds"
    static let creatorId = "creatorId"
    
    // Match Post
    static let matchDate = "matchDate"
    static let expiresAt = "expiresAt"
    
    // Notification
    static let isRead = "isRead"
}

// MARK: - Firebase Error
enum FirebaseError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case permissionDenied
    case networkError
    case encodingError
    case decodingError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Oturum açmanız gerekiyor."
        case .documentNotFound:
            return "İstenen veri bulunamadı."
        case .permissionDenied:
            return "Bu işlem için yetkiniz yok."
        case .networkError:
            return "İnternet bağlantınızı kontrol edin."
        case .encodingError:
            return "Veri kodlama hatası."
        case .decodingError:
            return "Veri çözümleme hatası."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Generic CRUD Operations
extension FirebaseService {
    
    /// Generic document fetch
    func fetchDocument<T: Decodable>(from collection: CollectionReference, documentId: String) async throws -> T {
        let document = try await collection.document(documentId).getDocument()
        
        guard document.exists else {
            throw FirebaseError.documentNotFound
        }
        
        do {
            return try document.data(as: T.self)
        } catch {
            throw FirebaseError.decodingError
        }
    }
    
    /// Generic document create
    func createDocument<T: Encodable>(in collection: CollectionReference, data: T, documentId: String? = nil) async throws -> String {
        do {
            if let documentId = documentId {
                try collection.document(documentId).setData(from: data)
                return documentId
            } else {
                let docRef = try collection.addDocument(from: data)
                return docRef.documentID
            }
        } catch {
            throw FirebaseError.encodingError
        }
    }
    
    /// Generic document update
    func updateDocument(in collection: CollectionReference, documentId: String, fields: [String: Any]) async throws {
        var updatedFields = fields
        updatedFields[FirestoreField.updatedAt] = FieldValue.serverTimestamp()
        
        try await collection.document(documentId).updateData(updatedFields)
    }
    
    /// Generic document delete
    func deleteDocument(from collection: CollectionReference, documentId: String) async throws {
        try await collection.document(documentId).delete()
    }
    
    /// Generic query fetch
    func fetchDocuments<T: Decodable>(query: Query) async throws -> [T] {
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: T.self)
        }
    }
}

// MARK: - Timestamp Helpers
extension FirebaseService {
    
    func serverTimestamp() -> FieldValue {
        FieldValue.serverTimestamp()
    }
    
    func timestampFromDate(_ date: Date) -> Timestamp {
        Timestamp(date: date)
    }
}
