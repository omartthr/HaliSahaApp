package com.example.HaliSahaApp.data.remote

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.CollectionReference
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.PersistentCacheSettings
import com.google.firebase.firestore.Query
import kotlinx.coroutines.tasks.await

// Singleton Object
object FirebaseService {

    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
    val db: FirebaseFirestore = FirebaseFirestore.getInstance()

    init {
        configureFirestore()
    }

    private fun configureFirestore() {
        val settings = FirebaseFirestoreSettings.Builder()
            .setLocalCacheSettings(PersistentCacheSettings.newBuilder()
                .setSizeBytes(100 * 1024 * 1024) // 100 MB cache
                .build())
            .build()
        db.firestoreSettings = settings
    }

    // MARK: - Collection References
    // (Burada yukarıda oluşturduğumuz FirestoreCollection dosyasını kullanıyoruz)
    val usersCollection: CollectionReference get() = db.collection(FirestoreCollection.USERS)
    val facilitiesCollection: CollectionReference get() = db.collection(FirestoreCollection.FACILITIES)
    val bookingsCollection: CollectionReference get() = db.collection(FirestoreCollection.BOOKINGS)
    val groupsCollection: CollectionReference get() = db.collection(FirestoreCollection.GROUPS)
    val matchPostsCollection: CollectionReference get() = db.collection(FirestoreCollection.MATCH_POSTS)
    val reviewsCollection: CollectionReference get() = db.collection(FirestoreCollection.REVIEWS)
    val notificationsCollection: CollectionReference get() = db.collection(FirestoreCollection.NOTIFICATIONS)

    // MARK: - Sub-collection References
    fun pitchesCollection(facilityId: String): CollectionReference {
        return facilitiesCollection.document(facilityId).collection(FirestoreCollection.PITCHES)
    }

    fun messagesCollection(groupId: String): CollectionReference {
        return groupsCollection.document(groupId).collection(FirestoreCollection.MESSAGES)
    }

    // MARK: - Current User Helpers
    val currentUserId: String? get() = auth.currentUser?.uid
    val isLoggedIn: Boolean get() = auth.currentUser != null

    // MARK: - Generic CRUD Operations

    // Veri Çekme (Tekil)
    suspend inline fun <reified T> fetchDocument(
        collection: CollectionReference,
        documentId: String
    ): T {
        return try {
            val snapshot = collection.document(documentId).get().await()
            if (snapshot.exists()) {
                snapshot.toObject(T::class.java) ?: throw FirebaseError.DecodingError
            } else {
                throw FirebaseError.DocumentNotFound
            }
        } catch (e: Exception) {
            throw e as? FirebaseError ?: FirebaseError.Unknown(e.localizedMessage ?: "Hata")
        }
    }

    // Veri Ekleme / Oluşturma
    suspend fun <T : Any> createDocument(
        collection: CollectionReference,
        data: T,
        documentId: String? = null
    ): String {
        return try {
            if (documentId != null) {
                collection.document(documentId).set(data).await()
                documentId
            } else {
                val docRef = collection.add(data).await()
                docRef.id
            }
        } catch (e: Exception) {
            throw FirebaseError.EncodingError
        }
    }

    // Veri Güncelleme
    suspend fun updateDocument(
        collection: CollectionReference,
        documentId: String,
        fields: Map<String, Any>
    ) {
        try {
            val updatedFields = fields.toMutableMap()
            updatedFields[FirestoreField.UPDATED_AT] = FieldValue.serverTimestamp()
            collection.document(documentId).update(updatedFields).await()
        } catch (e: Exception) {
            throw FirebaseError.Unknown(e.localizedMessage ?: "Güncelleme hatası")
        }
    }

    // Veri Silme
    suspend fun deleteDocument(collection: CollectionReference, documentId: String) {
        try {
            collection.document(documentId).delete().await()
        } catch (e: Exception) {
            throw FirebaseError.Unknown(e.localizedMessage ?: "Silme hatası")
        }
    }

    // Sorgu ile Çoklu Veri Çekme
    suspend inline fun <reified T> fetchDocuments(query: Query): List<T> {
        return try {
            val snapshot = query.get().await()
            snapshot.documents.mapNotNull { it.toObject(T::class.java) }
        } catch (e: Exception) {
            throw FirebaseError.DecodingError
        }
    }
}