package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.HourglassEmpty
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.PersonOutline
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.viewmodels.SuperAdminViewModel
import com.example.HaliSahaApp.utils.AppColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SuperAdminStatsScreen(
    viewModel: SuperAdminViewModel = viewModel()
) {
    val allAdmins by viewModel.allAdmins.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val currentUser by AuthService.currentUser.collectAsState()

    val total = allAdmins.size
    val pending = allAdmins.count { it.approvalStatus == AdminApprovalStatus.PENDING && it.documentsSubmittedAt != null }
    val approved = allAdmins.count { it.approvalStatus == AdminApprovalStatus.APPROVED }
    val rejected = allAdmins.count { it.approvalStatus == AdminApprovalStatus.REJECTED }

    LaunchedEffect(Unit) {
        viewModel.loadData()
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("İstatistik", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                )
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (isLoading) {
                LinearProgressIndicator(
                    modifier = Modifier.fillMaxWidth(),
                    color = AppColors.Primary
                )
            }

            // Stats Grid
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                item {
                    StatCard(title = "Toplam İşletmeci", value = total.toString(), icon = Icons.Default.Group, color = AppColors.Primary)
                }
                item {
                    StatCard(title = "Onay Bekleyen", value = pending.toString(), icon = Icons.Default.HourglassEmpty, color = Color(0xFFFF9800))
                }
                item {
                    StatCard(title = "Onaylı", value = approved.toString(), icon = Icons.Default.CheckCircle, color = AppColors.Primary)
                }
                item {
                    StatCard(title = "Reddedilen", value = rejected.toString(), icon = Icons.Default.Warning, color = Color.Red)
                }
            }

            // Pending Highlight
            if (pending > 0) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFFFF9800).copy(alpha = 0.1f), RoundedCornerShape(12.dp))
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Info, contentDescription = null, tint = Color(0xFFFF9800))
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "$pending başvuru inceleme bekliyor",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.TextPrimary
                        )
                        Text(
                            text = "\"Onay Bekleyenler\" sekmesinden inceleyebilirsin.",
                            style = MaterialTheme.typography.bodySmall,
                            color = AppColors.TextSecondary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Sign Out Card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
                    .padding(14.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .background(AppColors.Primary.copy(alpha = 0.15f), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Default.PersonOutline, contentDescription = null, tint = AppColors.Primary)
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text("Süper Admin Hesabı", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = AppColors.TextPrimary)
                        Text(currentUser?.email ?: "—", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
                    }
                }

                Button(
                    onClick = {
                        try {
                            AuthService.signOut()
                        } catch (e: Exception) {
                            // handle error
                        }
                    },
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.Surface, contentColor = AppColors.Primary),
                    border = androidx.compose.foundation.BorderStroke(1.dp, AppColors.Primary)
                ) {
                    Icon(Icons.AutoMirrored.Filled.ExitToApp, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Çıkış Yap", fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
fun StatCard(title: String, value: String, icon: ImageVector, color: Color) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
            .padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .background(color.copy(alpha = 0.15f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, contentDescription = null, tint = color)
        }

        Text(
            text = value,
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )

        Text(
            text = title,
            style = MaterialTheme.typography.bodySmall,
            color = AppColors.TextSecondary
        )
    }
}
