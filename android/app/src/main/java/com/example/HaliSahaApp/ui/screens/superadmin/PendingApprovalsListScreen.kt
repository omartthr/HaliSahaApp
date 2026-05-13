package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.AdminProfile
import com.example.HaliSahaApp.ui.viewmodels.SuperAdminViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons
import java.text.SimpleDateFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PendingApprovalsListScreen(
    navController: NavController,
    onLogout: () -> Unit,
    viewModel: SuperAdminViewModel = viewModel()
) {
    val pendingAdmins by viewModel.pendingAdmins.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Bekleyen Onaylar") },
                actions = {
                    IconButton(onClick = onLogout) {
                        Icon(AppIcons.Logout, contentDescription = "Çıkış Yap", tint = AppColors.Error)
                    }
                }
            )
        }
    ) { padding ->
        if (isLoading && pendingAdmins.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (pendingAdmins.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(AppIcons.CheckCircle, contentDescription = null, tint = AppColors.Success, modifier = Modifier.size(64.dp))
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("İncelenecek başvuru bulunmuyor.", color = AppColors.TextSecondary)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding).fillMaxSize().padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(pendingAdmins) { admin ->
                    AdminRowCard(
                        admin = admin, 
                        onClick = {
                            navController.navigate("admin_review/${admin.id}")
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun AdminRowCard(admin: AdminProfile, onClick: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = AppColors.CardBackground)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(admin.businessName, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
                Spacer(modifier = Modifier.height(4.dp))
                val sdf = SimpleDateFormat("dd MMM yyyy, HH:mm", Locale("tr", "TR"))
                val dateStr = admin.documentsSubmittedAt?.let { sdf.format(it) } ?: "Bilinmiyor"
                Text("Başvuru: $dateStr", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
            }
            Icon(AppIcons.ChevronRight, contentDescription = null, tint = AppColors.TextSecondary)
        }
    }
}
