package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
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

    LaunchedEffect(Unit) {
        viewModel.loadData()
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Onay Bekleyenler", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                )
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        if (isLoading && pendingAdmins.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = AppColors.Primary)
            }
        } else if (pendingAdmins.isEmpty()) {
            PendingEmptyState(modifier = Modifier.padding(padding))
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    PendingSummaryHeader(count = pendingAdmins.size)
                }
                
                items(pendingAdmins) { admin ->
                    PendingAdminCard(
                        admin = admin,
                        onClick = { navController.navigate("admin_review/${admin.id}") }
                    )
                }
            }
        }
    }
}

@Composable
fun PendingSummaryHeader(count: Int) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .background(Color(0xFFFF9800).copy(alpha = 0.15f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(AppIcons.Time, contentDescription = null, tint = Color(0xFFFF9800))
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column {
            Text("$count başvuru", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
            Text("incelenmeyi bekliyor", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        }
    }
}

@Composable
fun PendingAdminCard(admin: AdminProfile, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
            .clickable { onClick() }
            .padding(14.dp),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .background(AppColors.Primary.copy(alpha = 0.1f), RoundedCornerShape(12.dp)),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Default.Storefront, contentDescription = null, tint = AppColors.Primary)
        }
        
        Spacer(modifier = Modifier.width(14.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = admin.businessName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text("Vergi No: ${admin.taxNumber}", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
            
            admin.documentsSubmittedAt?.let { submitted ->
                Spacer(modifier = Modifier.height(4.dp))
                val sdf = SimpleDateFormat("dd MMM, HH:mm", Locale("tr", "TR"))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(AppIcons.Calendar, contentDescription = null, modifier = Modifier.size(12.dp), tint = AppColors.TextSecondary)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Gönderim: ${sdf.format(submitted)}", style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
                }
            }
        }
        
        Spacer(modifier = Modifier.width(8.dp))
        
        Column(horizontalAlignment = Alignment.End) {
            AdminStatusBadge(status = admin.approvalStatus)
            Spacer(modifier = Modifier.height(8.dp))
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = AppColors.TextSecondary)
        }
    }
}

@Composable
fun AdminStatusBadge(status: AdminApprovalStatus) {
    val color = when (status) {
        AdminApprovalStatus.PENDING -> Color(0xFFFF9800)
        AdminApprovalStatus.APPROVED -> AppColors.Primary
        AdminApprovalStatus.REJECTED, AdminApprovalStatus.SUSPENDED -> Color.Red
    }
    Text(
        text = status.displayName,
        fontSize = 11.sp,
        fontWeight = FontWeight.SemiBold,
        color = color,
        modifier = Modifier
            .background(color.copy(alpha = 0.15f), RoundedCornerShape(12.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    )
}

@Composable
fun PendingEmptyState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(110.dp)
                .background(AppColors.Primary.copy(alpha = 0.1f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(50.dp), tint = AppColors.Primary)
        }
        Spacer(modifier = Modifier.height(16.dp))
        Text("Bekleyen başvuru yok", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = AppColors.TextPrimary)
        Text("Yeni başvuru geldiğinde burada görünecek.", style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary)
    }
}
