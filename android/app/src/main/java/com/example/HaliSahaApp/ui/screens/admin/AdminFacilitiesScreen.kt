package com.example.HaliSahaApp.ui.screens.admin

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.models.FacilityStatus
import com.example.HaliSahaApp.ui.viewmodels.AdminFacilitiesViewModel
import com.example.HaliSahaApp.utils.AppColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminFacilitiesScreen(
    navController: NavController,
    viewModel: AdminFacilitiesViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Tesislerim", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background)
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.padding(padding)
        ) {
            items(uiState.facilities) { facility ->
                AdminFacilityListCard(
                    facility = facility,
                    onClick = { /* Detay sayfasına git */ }
                )
            }

            // Add Button
            item {
                Surface(
                    onClick = { /* Yeni Tesis Ekle */ },
                    shape = RoundedCornerShape(16.dp),
                    color = Color.Transparent,
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(
                            width = 2.dp,
                            color = AppColors.Primary,
                            shape = RoundedCornerShape(16.dp)
                        ) // Dashed border Android'de biraz zahmetli, solid ile devam ediyoruz
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Default.Add, null, tint = AppColors.Primary)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Yeni Tesis Ekle", color = AppColors.Primary, fontWeight = FontWeight.Medium)
                    }
                }
            }
        }
    }
}

@Composable
fun AdminFacilityListCard(facility: Facility, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header
            Row {
                Box(
                    modifier = Modifier
                        .size(70.dp)
                        .background(AppColors.Primary.copy(alpha = 0.1f), RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Default.SportsSoccer, null, tint = AppColors.Primary, modifier = Modifier.size(30.dp))
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column {
                    Row {
                        Text(facility.name, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Spacer(modifier = Modifier.weight(1f))
                        StatusBadge(status = facility.status)
                    }

                    Text(facility.address, style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)

                    Spacer(modifier = Modifier.height(4.dp))

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Star, null, tint = AppColors.Warning, modifier = Modifier.size(14.dp))
                        Text(
                            "${facility.formattedRating} (${facility.totalReviews} değerlendirme)",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Quick Stats
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.Background, RoundedCornerShape(10.dp))
                    .padding(vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                QuickStat(value = "2", label = "Saha", icon = Icons.Default.SportsSoccer)
                VerticalDivider()
                QuickStat(value = "24", label = "Bu Ay", icon = Icons.Default.CalendarToday)
                VerticalDivider()
                QuickStat(value = "12.5K", label = "Gelir", icon = Icons.Default.AttachMoney) // Lira ikonu yoksa Money
            }
        }
    }
}

@Composable
fun StatusBadge(status: FacilityStatus) {
    val color = when(status) {
        FacilityStatus.APPROVED -> AppColors.Success
        FacilityStatus.PENDING -> AppColors.Warning
        else -> Color.Gray
    }
    Surface(
        color = color.copy(alpha = 0.1f),
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(
            status.displayName,
            color = color,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

@Composable
fun QuickStat(value: String, label: String, icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, null, tint = AppColors.TextSecondary, modifier = Modifier.size(12.dp))
            Spacer(modifier = Modifier.width(4.dp))
            Text(value, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyMedium)
        }
        Text(label, style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
    }
}

@Composable
fun VerticalDivider() {
    Box(
        modifier = Modifier
            .height(30.dp)
            .width(1.dp)
            .background(Color.Gray.copy(alpha = 0.3f))
    )
}