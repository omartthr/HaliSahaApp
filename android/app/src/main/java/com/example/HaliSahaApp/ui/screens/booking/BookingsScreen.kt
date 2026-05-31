package com.example.HaliSahaApp.ui.screens.booking

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.BookingStatus
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.viewmodels.BookingFilter
import com.example.HaliSahaApp.ui.viewmodels.BookingsViewModel
import com.example.HaliSahaApp.utils.AppColors
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingsScreen(
    navController: NavController,
    viewModel: BookingsViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val pullRefreshState = rememberPullToRefreshState()
    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        viewModel.refresh()
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Randevularım", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background,
                    titleContentColor = AppColors.TextPrimary // <-- BUNU EKLE (Başlığı Siyah Yapar)
                )
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Filter Tabs
            BookingFilterTabs(
                selectedFilter = uiState.selectedFilter,
                onSelect = { viewModel.setFilter(it) }
            )

            // Content
            PullToRefreshBox(
                isRefreshing = uiState.isLoading,
                onRefresh = { scope.launch { viewModel.refresh() } },
                state = pullRefreshState,
                modifier = Modifier.fillMaxSize()
            ) {
                if (uiState.filteredBookings.isEmpty() && !uiState.isLoading) {
                    EmptyStateView(
                        icon = Icons.Default.CalendarMonth,
                        title = "Randevu Bulunamadı",
                        message = "Seçilen kategoride randevunuz yok.",
                        buttonTitle = if (uiState.selectedFilter == BookingFilter.UPCOMING) "Saha Bul" else null,
                        onButtonClick = {
                            // Home (Keşfet) tab'ına yönlendir
                            navController.navigate("home") {
                                popUpTo(navController.graph.startDestinationId) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(uiState.filteredBookings) { booking ->
                            BookingCard(
                                booking = booking,
                                onClick = {
                                    // Detay Sayfasına Git
                                    // navController.navigate("booking_detail/${booking.id}")
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun BookingFilterTabs(
    selectedFilter: BookingFilter,
    onSelect: (BookingFilter) -> Unit
) {
    Row(modifier = Modifier.background(AppColors.Surface)) {
        BookingFilter.entries.forEach { filter ->
            val isSelected = selectedFilter == filter
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clickable { onSelect(filter) }
                    .padding(vertical = 12.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = filter.displayName,
                    style = MaterialTheme.typography.titleSmall,
                    color = if (isSelected) AppColors.Primary else AppColors.TextSecondary,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                )
                Spacer(modifier = Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .height(2.dp)
                        .fillMaxWidth()
                        .background(if (isSelected) AppColors.Primary else Color.Transparent)
                )
            }
        }
    }
}

@Composable
fun BookingCard(booking: Booking, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header
            Row(verticalAlignment = Alignment.Top) {
                // Image Placeholder
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = AppColors.Primary.copy(alpha = 0.1f),
                    modifier = Modifier.size(50.dp)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.SportsSoccer, null, tint = AppColors.Primary)
                    }
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column {
                    Text(
                        booking.facilityName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.TextPrimary
                    )
                    Text(booking.pitchName, style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary)
                }

                Spacer(modifier = Modifier.weight(1f))

                StatusBadge(status = booking.status)
            }

            HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), color = AppColors.Background)

            // Info
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.CalendarMonth, null, tint = AppColors.TextSecondary, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(booking.formattedDate, style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)

                Spacer(modifier = Modifier.weight(1f))

                Icon(Icons.Default.Schedule, null, tint = AppColors.TextSecondary, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(booking.timeSlotString, style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
            }

            // Geri Sayım ve Bilet No (iOS BookingCard'daki gibi)
            // Sadece yaklaşan onaylı/bekleyen randevular için göster
            if (!booking.isPast && (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.pending)) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Timer,
                        null,
                        tint = AppColors.Primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = countdownText(booking),
                        style = MaterialTheme.typography.labelSmall,
                        color = AppColors.TextSecondary
                    )

                    Spacer(modifier = Modifier.weight(1f))

                    if (booking.ticketNumber.isNotEmpty()) {
                        Text(
                            text = booking.ticketNumber,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.Primary
                        )
                    }
                }
            }
        }
    }
}

/**
 * iOS BookingCard.countdownText(for:) fonksiyonunun Android muadili.
 * Yaklaşan randevuya ne kadar kaldığını gösterir.
 */
private fun countdownText(booking: Booking): String {
    val now = java.util.Calendar.getInstance()
    val bookingCal = java.util.Calendar.getInstance().apply {
        time = booking.date
        set(java.util.Calendar.HOUR_OF_DAY, booking.startHour.toInt())
        set(java.util.Calendar.MINUTE, 0)
        set(java.util.Calendar.SECOND, 0)
    }

    val diffMs = bookingCal.timeInMillis - now.timeInMillis
    val diffHours = java.util.concurrent.TimeUnit.MILLISECONDS.toHours(diffMs)
    val diffDays = java.util.concurrent.TimeUnit.MILLISECONDS.toDays(diffMs)

    return when {
        diffDays > 0 -> "$diffDays gün sonra"
        diffHours > 0 -> "$diffHours saat sonra"
        else -> "Bugün"
    }
}

@Composable
fun StatusBadge(status: BookingStatus) {
    // String renkten Compose Color'a dönüşüm
    val color = when(status.color) { // status.color "green", "red" gibi string dönüyor
        "green" -> AppColors.Success
        "orange" -> AppColors.Warning
        "red" -> AppColors.Error
        "blue" -> AppColors.Info
        "gray" -> Color.Gray
        else -> AppColors.Primary
    }

    Surface(
        color = color.copy(alpha = 0.1f),
        shape = RoundedCornerShape(12.dp)
    ) {
        Text(
            text = status.displayName,
            color = color,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}