package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.Review
import com.example.HaliSahaApp.data.services.BookingService
import com.example.HaliSahaApp.data.services.ReviewService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ReviewsViewModel : ViewModel() {
    private val reviewService = ReviewService
    private val bookingService = BookingService
    
    private val _reviews = MutableStateFlow<List<Review>>(emptyList())
    val reviews: StateFlow<List<Review>> = _reviews.asStateFlow()

    private val _targetBooking = MutableStateFlow<Booking?>(null)
    val targetBooking: StateFlow<Booking?> = _targetBooking.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    fun fetchReviews(facilityId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val fetched = reviewService.fetchReviews(facilityId)
                _reviews.value = fetched
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Değerlendirmeler yüklenemedi."
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun fetchBooking(bookingId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val booking = bookingService.fetchBooking(bookingId)
                _targetBooking.value = booking
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Rezervasyon bilgisi alınamadı."
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun submitReview(
        booking: Booking,
        rating: Double,
        comment: String,
        userFullName: String,
        userProfileImage: String?,
        onSuccess: () -> Unit
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                reviewService.createReview(
                    booking = booking,
                    rating = rating,
                    comment = comment,
                    userFullName = userFullName,
                    userProfileImage = userProfileImage
                )
                onSuccess()
            } catch (e: Exception) {
                _error.value = e.localizedMessage ?: "Değerlendirme kaydedilemedi."
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun clearError() {
        _error.value = null
    }
}
