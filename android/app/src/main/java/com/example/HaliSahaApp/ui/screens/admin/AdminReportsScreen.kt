package com.example.HaliSahaApp.ui.screens.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.ui.viewmodels.AdminReportsViewModel
import com.example.HaliSahaApp.ui.viewmodels.ReportPeriod
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.asShortCurrency

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminReportsScreen(
    navController: NavController,
    viewModel: AdminReportsViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Raporlar", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background),
                actions = {
                    IconButton(onClick = { /* Export */ }) {
                        Icon(Icons.Default.Share, "Dışa Aktar")
                    }
                }
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Period Selector
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ReportPeriod.entries.forEach { period ->
                    val isSelected = uiState.selectedPeriod == period
                    FilterChip(
                        selected = isSelected,
                        onClick = { /* Change Period */ },
                        label = { Text(period.displayName) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = AppColors.Primary,
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }

            // Revenue Chart Placeholder
            RevenueChartCard(totalRevenue = uiState.totalRevenue)

            // Key Metrics Grid
            Text("Temel Metrikler", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

            // Grid için fixed height verdik, normalde LazyVerticalGrid Scroll içinde olmaz
            // Basit row/column ile yapalım
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    MetricCard("Toplam Rezervasyon", "${uiState.totalBookings}", Icons.Default.DateRange, Color.Blue, Modifier.weight(1f))
                    MetricCard("Ortalama Gelir", uiState.averageRevenue.asShortCurrency, Icons.Default.TrendingUp, Color.Green, Modifier.weight(1f))
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    MetricCard("Doluluk Oranı", "%${uiState.occupancyRate}", Icons.Default.Percent, Color.Magenta, Modifier.weight(1f))
                    MetricCard("İptal Oranı", "%${uiState.cancellationRate}", Icons.Default.Close, Color.Red, Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
fun RevenueChartCard(totalRevenue: Double) {
    Card(colors = CardDefaults.cardColors(containerColor = AppColors.Surface)) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row {
                Column {
                    Text("Toplam Gelir", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
                    Text(totalRevenue.asShortCurrency, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                }
                Spacer(modifier = Modifier.weight(1f))
                Text("+12%", color = AppColors.Success, fontWeight = FontWeight.Bold)
            }
            Spacer(modifier = Modifier.height(16.dp))
            // Chart Placeholder Box
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .background(Color.Gray.copy(alpha = 0.1f), RoundedCornerShape(8.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text("Grafik Alanı (Kütüphane Gerekli)", color = Color.Gray)
            }
        }
    }
}

@Composable
fun MetricCard(title: String, value: String, icon: ImageVector, color: Color, modifier: Modifier) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Icon(icon, null, tint = color)
            Spacer(modifier = Modifier.height(8.dp))
            Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(title, style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
        }
    }
}