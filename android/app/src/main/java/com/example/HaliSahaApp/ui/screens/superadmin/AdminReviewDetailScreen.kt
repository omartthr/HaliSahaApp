package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.rememberAsyncImagePainter
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
import com.example.HaliSahaApp.data.models.AdminProfile
import com.example.HaliSahaApp.ui.viewmodels.SuperAdminViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminReviewDetailScreen(
    adminId: String,
    onBack: () -> Unit,
    viewModel: SuperAdminViewModel = viewModel()
) {
    val allAdmins by viewModel.allAdmins.collectAsState()
    val pendingAdmins by viewModel.pendingAdmins.collectAsState()
    
    // admin hem pending listesinde hem de all admins listesinde olabilir, id ile bul.
    val admin = allAdmins.find { it.id == adminId } ?: pendingAdmins.find { it.id == adminId }
    val isLoading by viewModel.isLoading.collectAsState()
    
    var showRejectDialog by remember { mutableStateOf(false) }
    var rejectReason by remember { mutableStateOf("") }
    
    var showSuspendDialog by remember { mutableStateOf(false) }
    var suspendReason by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(admin?.businessName ?: "Detaylar") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(AppIcons.ArrowLeft, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { padding ->
        if (admin == null) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Admin bilgileri yüklenemedi.")
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            
            // Profil Bilgileri
            Card(
                colors = CardDefaults.cardColors(containerColor = AppColors.CardBackground),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("İşletme Bilgileri", fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Adı: ${admin.businessName}")
                    Text("Vergi No: ${admin.taxNumber}")
                    Text("Durum: ${admin.approvalStatus.displayName}")
                }
            }

            // Belgeler
            Text("Yüklenen Belgeler", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleMedium)
            
            val docs = admin.documents
            if (docs != null) {
                DocumentImageRow(title = "Vergi Levhası", url = docs.taxCertificateURL)
                DocumentImageRow(title = "İşyeri Ruhsatı", url = docs.businessLicenseURL)
                DocumentImageRow(title = "Kimlik (Ön)", url = docs.idFrontURL)
                DocumentImageRow(title = "Kimlik (Arka)", url = docs.idBackURL)
                
                docs.facilityPhotoURLs.forEachIndexed { index, url ->
                    DocumentImageRow(title = "Tesis Fotoğrafı ${index + 1}", url = url)
                }
            } else {
                Text("Henüz belge yüklenmemiş.", color = AppColors.TextSecondary)
            }

            Spacer(modifier = Modifier.height(24.dp))

            // İşlemler
            if (admin.approvalStatus == AdminApprovalStatus.PENDING) {
                Button(
                    onClick = { 
                        viewModel.approveAdmin(adminId, onSuccess = { onBack() }) 
                    },
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.Success)
                ) {
                    Text("Onayla", color = AppColors.Surface)
                }
                
                Button(
                    onClick = { showRejectDialog = true },
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.Error)
                ) {
                    Text("Reddet", color = AppColors.Surface)
                }
            } else if (admin.approvalStatus == AdminApprovalStatus.APPROVED) {
                Button(
                    onClick = { showSuspendDialog = true },
                    modifier = Modifier.fillMaxWidth().height(50.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.Warning)
                ) {
                    Text("Askıya Al", color = AppColors.Surface)
                }
            }
        }

        // Dialogs
        if (showRejectDialog) {
            ReasonDialog(
                title = "Başvuruyu Reddet",
                text = "Reddetme sebebini giriniz:",
                value = rejectReason,
                onValueChange = { rejectReason = it },
                onDismiss = { showRejectDialog = false },
                onConfirm = {
                    viewModel.rejectAdmin(adminId, rejectReason, onSuccess = { onBack() })
                    showRejectDialog = false
                }
            )
        }
        
        if (showSuspendDialog) {
            ReasonDialog(
                title = "Hesabı Askıya Al",
                text = "Askıya alma sebebini giriniz:",
                value = suspendReason,
                onValueChange = { suspendReason = it },
                onDismiss = { showSuspendDialog = false },
                onConfirm = {
                    viewModel.suspendAdmin(adminId, suspendReason, onSuccess = { onBack() })
                    showSuspendDialog = false
                }
            )
        }
    }
}

@Composable
fun ReasonDialog(
    title: String,
    text: String,
    value: String,
    onValueChange: (String) -> Unit,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = {
            Column {
                Text(text)
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = value,
                    onValueChange = onValueChange,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                enabled = value.isNotBlank()
            ) {
                Text("Onayla")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("İptal")
            }
        }
    )
}

@Composable
fun DocumentImageRow(title: String, url: String?) {
    if (url.isNullOrEmpty()) return
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = AppColors.Background)
    ) {
        Column(modifier = Modifier.padding(8.dp)) {
            Text(title, fontWeight = FontWeight.Medium, color = AppColors.TextSecondary)
            Spacer(modifier = Modifier.height(8.dp))
            Image(
                painter = rememberAsyncImagePainter(url),
                contentDescription = title,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentScale = ContentScale.Crop
            )
        }
    }
}
