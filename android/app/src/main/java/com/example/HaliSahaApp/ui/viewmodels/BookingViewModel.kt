package com.example.HaliSahaApp.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.BookingStatus
import com.example.HaliSahaApp.data.services.BookingService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// MARK: - Filter Enum
enum class BookingFilter(val displayName: String) {
    UPCOMING("Yaklaşan"),
    PAST("Geçmiş"),
    CANCELLED("İptal")
}

// MARK: - UI State
data class BookingsUiState(
    val bookings: List<Booking> = emptyList(),
    val filteredBookings: List<Booking> = emptyList(),
    val selectedFilter: BookingFilter = BookingFilter.UPCOMING,
    val isLoading: Boolean = false,
    val error: String? = null
)

// MARK: - ViewModel
// iOS BookingsViewModel'den port edildi:
//   - filteredBookings computed property mantığı
//   - loadBookings() async task yapısı
//   - hata yönetimi
class BookingsViewModel : ViewModel() {

    private val bookingService = BookingService
    private val _uiState = MutableStateFlow(BookingsUiState())
    val uiState: StateFlow<BookingsUiState> = _uiState.asStateFlow()

    init {
        loadBookings()
    }

    fun loadBookings() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            try {
                val bookings = bookingService.fetchUserBookings()
                println("📋 BookingsViewModel: ${bookings.size} rezervasyon yüklendi")

                // Debug: her rezervasyonun durumunu logla
                bookings.forEach { booking ->
                    println("  → ${booking.facilityName} | status=${booking.status} | isPast=${booking.isPast} | id=${booking.id}")
                }

                _uiState.update {
                    it.copy(bookings = bookings, isLoading = false)
                }
                applyFilter()
            } catch (e: Exception) {
                println("❌ BookingsViewModel: Rezervasyon yüklenemedi: ${e.message}")
                e.printStackTrace()
                _uiState.update { it.copy(isLoading = false, error = e.localizedMessage) }
            }
        }
    }

    fun setFilter(filter: BookingFilter) {
        _uiState.update { it.copy(selectedFilter = filter) }
        applyFilter()
    }

    // iOS BookingsViewModel.filteredBookings mantığından port edildi:
    //
    // iOS:
    //   case .upcoming: return bookings.filter { !$0.isPast && $0.status == .confirmed }
    //   case .past:     return bookings.filter { $0.isPast || $0.status == .completed }
    //   case .cancelled: return bookings.filter { $0.status == .cancelled }
    //
    // Android'de pending durumunu da upcoming'e ekliyoruz çünkü:
    // 1. Yeni oluşturulan booking'ler 'pending' ile başlıyor
    // 2. processPayment sonrası 'confirmed' oluyor
    // 3. Ancak auto-confirm kapalıysa 'pending' kalabilir
    // 4. Kullanıcı kendi oluşturduğu 'pending' booking'leri de görmeli
    private fun applyFilter() {
        val currentState = _uiState.value
        val result = when (currentState.selectedFilter) {
            BookingFilter.UPCOMING -> currentState.bookings.filter {
                !it.isPast && (it.status == BookingStatus.confirmed || it.status == BookingStatus.pending)
            }
            BookingFilter.PAST -> currentState.bookings.filter {
                it.isPast || it.status == BookingStatus.completed
            }
            BookingFilter.CANCELLED -> currentState.bookings.filter {
                it.status == BookingStatus.cancelled
            }
        }
        println("📋 BookingsViewModel: Filtre=${currentState.selectedFilter}, Sonuç=${result.size} adet")
        _uiState.update { it.copy(filteredBookings = result) }
    }

    suspend fun refresh() {
        loadBookings()
    }
}
