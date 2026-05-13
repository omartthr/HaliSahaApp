package com.example.HaliSahaApp.data.remote

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import com.google.firebase.storage.FirebaseStorage
import com.google.firebase.storage.StorageMetadata
import com.google.firebase.storage.StorageReference
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.tasks.await
import java.io.ByteArrayOutputStream
import java.util.UUID

object StorageService {

    private val storage = FirebaseStorage.getInstance()
    private const val MAX_IMAGE_SIZE: Long = 5 * 1024 * 1024 // 5MB
    private const val COMPRESSION_QUALITY = 70 // 0-100 aralığında
    private const val MAX_IMAGE_DIMENSION = 1920f

    private const val MAX_RETRIES = 3
    private const val RETRY_DELAY_MS = 1000L

    // Upload Limiter (Maksimum 3 eşzamanlı yükleme)
    // Kotlin'de Semaphore veya Mutex kullanılabilir, basitlik adına bir Mutex ile sırayla işleme alacağız
    private val uploadMutex = Mutex()

    // Referanslar
    private val facilityImagesRef: StorageReference get() = storage.reference.child("facilities")
    private val pitchImagesRef: StorageReference get() = storage.reference.child("pitches")
    private val userImagesRef: StorageReference get() = storage.reference.child("users")
    private val adminVerificationsRef: StorageReference get() = storage.reference.child("admin_verifications")

    // MARK: - Upload Functions

    suspend fun uploadFacilityImage(bitmap: Bitmap, facilityId: String): String {
        val imageId = UUID.randomUUID().toString()
        val ref = facilityImagesRef.child(facilityId).child("$imageId.jpg")
        return uploadImage(bitmap, ref)
    }

    suspend fun uploadFacilityImages(bitmaps: List<Bitmap>, facilityId: String): List<String> = coroutineScope {
        val deferredUrls = bitmaps.map { bitmap ->
            async {
                uploadFacilityImage(bitmap, facilityId)
            }
        }
        deferredUrls.awaitAll()
    }

    suspend fun uploadPitchImage(bitmap: Bitmap, facilityId: String, pitchId: String): String {
        val imageId = UUID.randomUUID().toString()
        val ref = pitchImagesRef.child(facilityId).child(pitchId).child("$imageId.jpg")
        return uploadImage(bitmap, ref)
    }

    suspend fun uploadPitchImages(bitmaps: List<Bitmap>, facilityId: String, pitchId: String): List<String> = coroutineScope {
        val deferredUrls = bitmaps.map { bitmap ->
            async {
                uploadPitchImage(bitmap, facilityId, pitchId)
            }
        }
        deferredUrls.awaitAll()
    }

    suspend fun uploadUserProfileImage(bitmap: Bitmap, userId: String): String {
        val ref = userImagesRef.child(userId).child("profile.jpg")
        return uploadImage(bitmap, ref)
    }

    suspend fun uploadVerificationDocument(uri: Uri, documentType: String): String {
        val userId = com.example.HaliSahaApp.data.remote.FirebaseService.currentUserId 
            ?: throw FirebaseError.NotAuthenticated
        val imageId = UUID.randomUUID().toString()
        val ref = adminVerificationsRef.child(userId).child("${documentType}_$imageId.jpg")
        
        // Actually, uploadImage requires a Bitmap. I'll just upload the Uri directly 
        // to avoid loading large images into memory unless necessary, or use putFile.
        return performUploadUri(uri, ref)
    }

    // MARK: - Core Upload & Optimization

    private suspend fun uploadImage(bitmap: Bitmap, ref: StorageReference): String {
        val imageData = optimizeImage(bitmap)
        
        if (imageData.size > MAX_IMAGE_SIZE) {
            throw FirebaseError.Unknown("Dosya boyutu çok büyük (max 5MB)")
        }

        return performUpload(imageData, ref)
    }

    private fun optimizeImage(bitmap: Bitmap): ByteArray {
        val width = bitmap.width.toFloat()
        val height = bitmap.height.toFloat()

        var ratio = minOf(MAX_IMAGE_DIMENSION / width, MAX_IMAGE_DIMENSION / height)
        if (ratio > 1.0f) ratio = 1.0f // Eğer resim 1920'den küçükse büyütme

        val newWidth = (width * ratio).toInt()
        val newHeight = (height * ratio).toInt()

        val resizedBitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
        
        val baos = ByteArrayOutputStream()
        resizedBitmap.compress(Bitmap.CompressFormat.JPEG, COMPRESSION_QUALITY, baos)
        return baos.toByteArray()
    }

    private suspend fun performUploadUri(uri: Uri, ref: StorageReference): String {
        var lastException: Exception? = null

        for (attempt in 1..MAX_RETRIES) {
            try {
                uploadMutex.withLock {
                    ref.putFile(uri).await()
                }
                val downloadUrl = ref.downloadUrl.await()
                return downloadUrl.toString()
            } catch (e: Exception) {
                lastException = e
                if (attempt < MAX_RETRIES) {
                    val delayTime = RETRY_DELAY_MS * (1 shl (attempt - 1)) // 1s, 2s, 4s
                    delay(delayTime)
                }
            }
        }
        throw lastException ?: FirebaseError.Unknown("Yükleme işlemi $MAX_RETRIES deneme sonrası başarısız oldu.")
    }

    private suspend fun performUpload(data: ByteArray, ref: StorageReference): String {
        val metadata = StorageMetadata.Builder()
            .setContentType("image/jpeg")
            .build()

        var lastException: Exception? = null

        for (attempt in 1..MAX_RETRIES) {
            try {
                uploadMutex.withLock {
                    ref.putBytes(data, metadata).await()
                }
                val downloadUrl = ref.downloadUrl.await()
                return downloadUrl.toString()
            } catch (e: Exception) {
                lastException = e
                if (attempt < MAX_RETRIES) {
                    val delayTime = RETRY_DELAY_MS * (1 shl (attempt - 1)) // 1s, 2s, 4s
                    delay(delayTime)
                }
            }
        }
        throw lastException ?: FirebaseError.Unknown("Yükleme işlemi $MAX_RETRIES deneme sonrası başarısız oldu.")
    }

    // MARK: - Deletion

    suspend fun deleteImage(url: String) {
        if (url.isEmpty()) return
        try {
            val ref = storage.getReferenceFromUrl(url)
            ref.delete().await()
        } catch (e: Exception) {
            // Hata loglanabilir
            println("Delete image failed for url: $url, error: ${e.localizedMessage}")
        }
    }

    suspend fun deleteImages(urls: List<String>) = coroutineScope {
        val deferredDeletes = urls.filter { it.isNotEmpty() }.map { url ->
            async {
                deleteImage(url)
            }
        }
        deferredDeletes.awaitAll()
    }

    suspend fun deleteFacilityImages(facilityId: String) {
        val ref = facilityImagesRef.child(facilityId)
        deleteFolder(ref)
    }

    suspend fun deletePitchImages(facilityId: String, pitchId: String) {
        val ref = pitchImagesRef.child(facilityId).child(pitchId)
        deleteFolder(ref)
    }

    private suspend fun deleteFolder(ref: StorageReference) {
        try {
            val result = ref.listAll().await()

            // Listedeki dosyaları paralel sil
            coroutineScope {
                result.items.map { item ->
                    async { item.delete().await() }
                }.awaitAll()
            }

            // Alt klasörleri dolaşıp sil
            for (prefix in result.prefixes) {
                deleteFolder(prefix)
            }
        } catch (e: Exception) {
            println("Delete folder failed: ${e.localizedMessage}")
        }
    }
}
