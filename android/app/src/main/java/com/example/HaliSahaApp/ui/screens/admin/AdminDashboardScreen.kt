package com.example.HaliSahaApp.ui.screens.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.models.FacilityStatus
import com.example.HaliSahaApp.ui.viewmodels.AdminDashboardViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.asShortCurrency
import kotlinx.coroutines.launch
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminDashboardScreen(
    navController: NavController, // AdminMain için
    viewModel: AdminDashboardViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val pullRefreshState = rememberPullToRefreshState()
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Admin Paneli", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background),
                actions = {
                    IconButton(onClick = { /* Settings */ }) {
                        Icon(Icons.Default.Settings, null)
                    }
                }
            )
        },
        containerColor = AppColors.Background
    ) { padding ->

        PullToRefreshBox(
            isRefreshing = uiState.isLoading,
            onRefresh = { scope.launch { viewModel.loadData() } },
            state = pullRefreshState,
            modifier = Modifier.padding(padding)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                // Header
                AdminHeader()

                // Stats Cards
                AdminStatsSection(uiState)

                // Quick Actions
                AdminQuickActions(navController)

                // Today's Bookings
                AdminSectionHeader(title = "Bugünkü Rezervasyonlar", action = "Tümü") {
                    navController.navigate(AdminTab.BOOKINGS.route)
                }

                if (uiState.todayBookings.isEmpty()) {
                    Box(modifier = Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                        Text("Bugün için rezervasyon yok", color = Color.Gray)
                    }
                } else {
                    uiState.todayBookings.take(3).forEach { booking ->
                        AdminBookingDetailCard(booking = booking, onAction = {})
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }

                // My Facilities
                AdminSectionHeader(title = "Tesislerim", action = "Yönet") {
                    navController.navigate(AdminTab.FACILITIES.route)
                }

                uiState.facilities.forEach { facility ->
                    AdminFacilityCard(facility = facility)
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
fun AdminHeader() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Column {
            Text("Hoş Geldiniz 👋", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text("6 Şubat 2026", style = MaterialTheme.typography.bodyMedium, color = Color.Gray)
        }
        Spacer(modifier = Modifier.weight(1f))

        // Notification Bell (Badge'li)
        Box {
            Surface(shape = CircleShape, color = AppColors.Surface, shadowElevation = 2.dp) {
                Icon(Icons.Default.Notifications, null, modifier = Modifier.padding(8.dp))
            }
            Box(
                modifier = Modifier
                    .size(16.dp)
                    .background(Color.Red, CircleShape)
                    .align(Alignment.TopEnd)
            ) {
                Text("3", color = Color.White, fontSize = 10.sp, modifier = Modifier.align(Alignment.Center))
            }
        }
    }
}

@Composable
fun AdminStatsSection(uiState: com.example.HaliSahaApp.ui.viewmodels.AdminDashboardUiState) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            AdminStatCard("Bugün", "${uiState.stats.todayBookings}", "rezervasyon", Icons.Default.CalendarToday, Color.Blue, Modifier.weight(1f))
            AdminStatCard("Bekleyen", "${uiState.stats.pendingBookings}", "onay", Icons.Default.AccessTime, Color(0xFFFF9800), Modifier.weight(1f))
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            AdminStatCard("Bu Ay", uiState.stats.monthlyRevenue.asShortCurrency, "gelir", Icons.Default.AttachMoney, Color.Green, Modifier.weight(1f))
            AdminStatCard("Ortalama", String.format("%.1f", uiState.stats.averageRating), "puan", Icons.Default.Star, Color.Yellow, Modifier.weight(1f))
        }
    }
}

@Composable
fun AdminStatCard(title: String, value: String, subtitle: String, icon: ImageVector, color: Color, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row {
                Icon(icon, null, tint = color)
                Spacer(modifier = Modifier.weight(1f))
            }
            Spacer(modifier = Modifier.height(8.dp))
            Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(subtitle, style = MaterialTheme.typography.labelMedium, color = Color.Gray)
        }
    }
}

@Composable
fun AdminQuickActions(navController: NavController) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Hızlı İşlemler", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            // weight(1f) modifier'ını BURADA veriyoruz:
            QuickActionButton("Yeni Saha", Icons.Default.Add, AppColors.Primary, Modifier.weight(1f)) { }
            QuickActionButton("Rezervasyonlar", Icons.Default.List, Color.Blue, Modifier.weight(1f)) { navController.navigate(AdminTab.BOOKINGS.route) }
            QuickActionButton("Raporlar", Icons.Default.Assessment, Color.Magenta, Modifier.weight(1f)) { navController.navigate(AdminTab.REPORTS.route) }
        }
    }
}

@Composable
fun QuickActionButton(
    title: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier, // Modifier parametresi alıyor
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        modifier = modifier // Dışarıdan gelen modifier'ı kullanıyoruz
    ) {
        Column(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(icon, null, tint = color)
            Spacer(modifier = Modifier.height(4.dp))
            Text(title, style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
fun AdminSectionHeader(title: String, action: String, onClick: () -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
        Spacer(modifier = Modifier.weight(1f))
        TextButton(onClick = onClick) { Text(action) }
    }
}

@Composable
fun AdminFacilityCard(facility: Facility) {
    Card(colors = CardDefaults.cardColors(containerColor = AppColors.Surface)) {
        Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Surface(shape = RoundedCornerShape(8.dp), color = AppColors.Primary.copy(alpha = 0.1f), modifier = Modifier.size(50.dp)) {
                Box(contentAlignment = Alignment.Center) { Icon(Icons.Default.SportsSoccer, null, tint = AppColors.Primary) }
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(facility.name, fontWeight = FontWeight.Bold)
                Text(facility.address, style = MaterialTheme.typography.labelSmall, color = Color.Gray)
            }
            Spacer(modifier = Modifier.weight(1f))

            // Status Badge
            val statusColor = when (facility.status) {
                FacilityStatus.approved -> AppColors.Success
                FacilityStatus.pending -> AppColors.Warning
                else -> Color.Gray
            }
            Surface(color = statusColor.copy(alpha = 0.1f), shape = RoundedCornerShape(4.dp)) {
                Text(
                    facility.status.displayName,
                    color = statusColor,
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
        }
    }
}
