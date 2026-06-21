package com.example.HaliSahaApp.ui.screens.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Print
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material3.*
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
import com.example.HaliSahaApp.ui.components.LoadingView
import com.example.HaliSahaApp.ui.screens.booking.StatusBadge
import com.example.HaliSahaApp.ui.viewmodels.AdminBookingFilter
import com.example.HaliSahaApp.ui.viewmodels.AdminBookingsViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.asShortCurrency
import com.example.HaliSahaApp.utils.formattedTurkish
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminBookingsScreen(
    navController: NavController,
    viewModel: AdminBookingsViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedBooking by remember { mutableStateOf<Booking?>(null) }
    var showActionSheet by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Rezervasyonlar", fontWeight = FontWeight.Bold) },
                actions = {
                    IconButton(onClick = { /* Export */ }) {
                        Icon(Icons.Default.Share, contentDescription = "Dışa Aktar")
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background)
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Filter Tabs
            AdminFilterTabs(
                selectedFilter = uiState.selectedFilter,
                viewModel = viewModel
            )

            // Date Picker
            AdminDatePicker(
                selectedDate = uiState.selectedDate,
                onPrevious = { viewModel.changeDate(-1) },
                onNext = { viewModel.changeDate(1) }
            )

            // Content
            if (uiState.isLoading) {
                LoadingView()
            } else if (uiState.filteredBookings.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Rezervasyon Bulunamadı", color = Color.Gray)
                }
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Summary
                    item {
                        AdminBookingSummary(
                            total = uiState.filteredBookings.size,
                            confirmed = uiState.confirmedCount,
                            pending = uiState.pendingCount,
                            revenue = uiState.totalRevenue
                        )
                    }

                    // Bookings
                    items(uiState.filteredBookings) { booking ->
                        AdminBookingDetailCard(
                            booking = booking,
                            onAction = {
                                selectedBooking = booking
                                showActionSheet = true
                            }
                        )
                    }
                }
            }
        }
    }

    // Action Sheet (BottomSheet)
    if (showActionSheet && selectedBooking != null) {
        ModalBottomSheet(onDismissRequest = { showActionSheet = false }) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("İşlemler", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(16.dp))

                val booking = selectedBooking!!

                if (booking.status == BookingStatus.pending) {
                    Button(onClick = { viewModel.confirmBooking(booking); showActionSheet = false }, modifier = Modifier.fillMaxWidth()) {
                        Text("Onayla")
                    }
                    Button(
                        onClick = { viewModel.rejectBooking(booking); showActionSheet = false },
                        colors = ButtonDefaults.buttonColors(containerColor = AppColors.Error),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Reddet")
                    }
                }

                // Diğer durumlar için butonlar eklenebilir

                Spacer(modifier = Modifier.height(32.dp))
            }
        }
    }
}

@Composable
fun AdminFilterTabs(selectedFilter: AdminBookingFilter, viewModel: AdminBookingsViewModel) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(AdminBookingFilter.entries) { filter ->
            val isSelected = selectedFilter == filter
            val count = viewModel.countForFilter(filter)

            Surface(
                onClick = { viewModel.applyFilter(filter) },
                shape = RoundedCornerShape(20.dp),
                color = if (isSelected) AppColors.Primary else AppColors.Surface
            ) {
                Row(modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        filter.displayName,
                        color = if (isSelected) Color.White else AppColors.TextPrimary,
                        style = MaterialTheme.typography.labelLarge
                    )
                    if (count > 0) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Surface(
                            shape = CircleShape,
                            color = if (isSelected) Color.White else Color.LightGray.copy(alpha = 0.5f)
                        ) {
                            Text(
                                "$count",
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = if (isSelected) AppColors.Primary else Color.Black
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun AdminDatePicker(selectedDate: Date, onPrevious: () -> Unit, onNext: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.Surface)
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onPrevious) {
            Icon(Icons.Default.ChevronLeft, null, tint = AppColors.Primary)
        }

        Text(
            selectedDate.formattedTurkish(),
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Bold
        )

        IconButton(onClick = onNext) {
            Icon(Icons.Default.ChevronRight, null, tint = AppColors.Primary)
        }
    }
}

@Composable
fun AdminBookingSummary(total: Int, confirmed: Int, pending: Int, revenue: Double) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.Surface, RoundedCornerShape(12.dp))
            .padding(16.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        SummaryItem("$total", "Toplam", Color.Blue)
        SummaryItem("$confirmed", "Onaylı", Color.Green)
        SummaryItem("$pending", "Bekleyen", Color(0xFFFF9800)) // Orange
        SummaryItem(revenue.asShortCurrency, "Gelir", AppColors.Primary)
    }
}

@Composable
fun SummaryItem(value: String, label: String, color: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(value, fontWeight = FontWeight.Bold, color = color, fontSize = 16.sp)
        Text(label, style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
    }
}

@Composable
fun AdminBookingDetailCard(booking: Booking, onAction: () -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            // Header
            Row {
                Column {
                    Text(booking.userFullName, fontWeight = FontWeight.Bold)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Phone, null, modifier = Modifier.size(12.dp), tint = Color.Gray)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(booking.userPhone, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                    }
                }
                Spacer(modifier = Modifier.weight(1f))
                StatusBadge(status = booking.status)
            }

            HorizontalDivider(color = AppColors.Background)

            // Details
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                DetailColumn(Icons.Default.SportsSoccer, booking.pitchName)
                DetailColumn(Icons.Default.CalendarToday, booking.formattedDate)
                DetailColumn(Icons.Default.Schedule, booking.timeSlotString)
            }

            HorizontalDivider(color = AppColors.Background)

            // Footer
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column {
                    Text("Ödenen", style = MaterialTheme.typography.labelSmall, color = Color.Gray)
                    Text(booking.depositAmount.asShortCurrency, fontWeight = FontWeight.SemiBold, color = AppColors.Success)
                }
                Spacer(modifier = Modifier.weight(1f))
                IconButton(onClick = onAction) {
                    Icon(Icons.Default.MoreVert, null, tint = AppColors.Primary)
                }
            }
        }
    }
}

@Composable
fun DetailColumn(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, null, tint = Color.Gray, modifier = Modifier.size(16.dp))
        Spacer(modifier = Modifier.height(4.dp))
        Text(text, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Medium)
    }
}
