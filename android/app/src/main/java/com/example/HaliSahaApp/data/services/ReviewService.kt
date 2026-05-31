package com.example.HaliSahaApp.data.services

import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.Review
import com.example.HaliSahaApp.data.remote.FirebaseService
import com.example.HaliSahaApp.data.remote.FirestoreField
import com.google.firebase.firestore.Query
import kotlinx.coroutines.tasks.await
import java.util.Date
import kotlin.math.max
import kotlin.math.roundToInt

object ReviewService {
    private val firebaseService = FirebaseService

    // MARK: - Fetch

    suspend fun fetchReviews(facilityId: String): List<Review> {
        return try {
            val query = firebaseService.reviewsCollection
                .whereEqualTo("facilityId", facilityId)
                .whereEqualTo("isHidden", false)
                .orderBy(FirestoreField.CREATED_AT, Query.Direction.DESCENDING)
                .limit(100)
            
            firebaseService.fetchDocuments(query)
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun fetchReviewsByCurrentUser(): List<Review> {
        val userId = firebaseService.currentUserId ?: return emptyList()
        return try {
            val query = firebaseService.reviewsCollection
                .whereEqualTo("userId", userId)
                .orderBy(FirestoreField.CREATED_AT, Query.Direction.DESCENDING)
            
            firebaseService.fetchDocuments(query)
        } catch (e: Exception) {
            emptyList()
        }
    }

    suspend fun hasReviewed(bookingId: String): Boolean {
        val userId = firebaseService.currentUserId ?: return false
        return try {
            val query = firebaseService.reviewsCollection
                .whereEqualTo("userId", userId)
                .whereEqualTo("bookingId", bookingId)
                .limit(1)
            
            val reviews: List<Review> = firebaseService.fetchDocuments(query)
            reviews.isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    // MARK: - Create

    suspend fun createReview(
        booking: Booking,
        rating: Double,
        comment: String?,
        userFullName: String,
        userProfileImage: String?
    ): Review {
        val userId = firebaseService.currentUserId ?: throw ReviewError.NotAuthenticated
        if (userId != booking.userId) throw ReviewError.PermissionDenied
        
        if (hasReviewed(booking.id ?: "")) throw ReviewError.AlreadyReviewed

        val finalComment = comment?.trim()?.takeIf { it.isNotEmpty() }

        val review = Review(
            facilityId = booking.facilityId,
            pitchId = booking.pitchId,
            bookingId = booking.id ?: "",
            userId = userId,
            userName = userFullName,
            userProfileImage = userProfileImage,
            overallRating = rating,
            cleanlinessRating = rating,
            surfaceRating = rating,
            serviceRating = rating,
            facilitiesRating = rating,
            valueForMoneyRating = rating,
            comment = finalComment,
            isVerified = true
        )

        val documentId = firebaseService.createDocument(firebaseService.reviewsCollection, review)
        val savedReview = review.copy(id = documentId)

        updateFacilityRating(booking.facilityId, RatingDelta.Add(rating))
        notifyFacilityOwner(booking.facilityId, savedReview)

        return savedReview
    }

    // MARK: - Delete

    suspend fun deleteReview(review: Review) {
        val userId = firebaseService.currentUserId ?: throw ReviewError.NotAuthenticated
        if (review.userId != userId) throw ReviewError.PermissionDenied
        val id = review.id ?: throw ReviewError.NotFound

        firebaseService.deleteDocument(firebaseService.reviewsCollection, id)
        updateFacilityRating(review.facilityId, RatingDelta.Remove(review.overallRating))
    }

    // MARK: - Helpers

    private sealed class RatingDelta {
        data class Add(val rating: Double) : RatingDelta()
        data class Remove(val rating: Double) : RatingDelta()
    }

    private suspend fun updateFacilityRating(facilityId: String, delta: RatingDelta) {
        val facilityRef = firebaseService.facilitiesCollection.document(facilityId)
        val db = firebaseService.db

        try {
            db.runTransaction { transaction ->
                val snapshot = transaction.get(facilityRef)
                
                val currentAvg = snapshot.getDouble("averageRating") ?: 0.0
                val currentCount = snapshot.getLong("totalReviews")?.toInt() ?: 0

                val newAvg: Double
                val newCount: Int

                when (delta) {
                    is RatingDelta.Add -> {
                        newCount = currentCount + 1
                        newAvg = ((currentAvg * currentCount) + delta.rating) / newCount
                    }
                    is RatingDelta.Remove -> {
                        newCount = max(0, currentCount - 1)
                        if (newCount == 0) {
                            newAvg = 0.0
                        } else {
                            val total = (currentAvg * currentCount) - delta.rating
                            newAvg = max(0.0, total / newCount)
                        }
                    }
                }

                val roundedAvg = (newAvg * 10).roundToInt() / 10.0

                transaction.update(
                    facilityRef,
                    mapOf(
                        "averageRating" to roundedAvg,
                        "totalReviews" to newCount,
                        FirestoreField.UPDATED_AT to Date()
                    )
                )
                null
            }.await()
        } catch (e: Exception) {
            // Ignore transaction error
        }
    }

    private suspend fun notifyFacilityOwner(facilityId: String, review: Review) {
        try {
            val facility = FacilityService.fetchFacility(facilityId)
            AppNotificationService.notify(
                com.example.HaliSahaApp.data.models.AppNotification.reviewReceived(
                    adminId = facility.ownerId,
                    facilityName = facility.name,
                    review = review
                )
            )
        } catch (e: Exception) {
            // Ignore notification error
        }
    }
}

sealed class ReviewError(message: String) : Exception(message) {
    object NotAuthenticated : ReviewError("Bu işlem için giriş yapmanız gerekiyor.")
    object AlreadyReviewed : ReviewError("Bu rezervasyon için zaten değerlendirme yaptınız.")
    object PermissionDenied : ReviewError("Bu işlem için yetkiniz yok.")
    object NotFound : ReviewError("Yorum bulunamadı.")
    class Unknown(message: String) : ReviewError(message)
}

class ReviewDistribution(reviews: List<Review>) {
    val counts: Map<Int, Int>
    val total: Int = reviews.size

    init {
        val map = mutableMapOf(1 to 0, 2 to 0, 3 to 0, 4 to 0, 5 to 0)
        for (review in reviews) {
            val raw = review.overallRating.roundToInt()
            val star = raw.coerceIn(1, 5)
            map[star] = (map[star] ?: 0) + 1
        }
        counts = map
    }

    fun getPercentage(star: Int): Double {
        if (total == 0) return 0.0
        val count = counts[star] ?: 0
        return count.toDouble() / total.toDouble()
    }

    fun getCount(star: Int): Int = counts[star] ?: 0
}
