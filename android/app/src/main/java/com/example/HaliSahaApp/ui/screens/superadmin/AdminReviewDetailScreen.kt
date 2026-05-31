package com.example.HaliSahaApp.ui.screens.superadmin

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
import com.example.HaliSahaApp.data.models.AdminDocumentType
import com.example.HaliSahaApp.data.models.AdminProfile
import com.example.HaliSahaApp.ui.components.PrimaryButton
import com.example.HaliSahaApp.ui.viewmodels.SuperAdminViewModel
import com.example.HaliSahaApp.utils.AppColors
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminReviewDetailScreen(
    adminId: String,
    onBack: () -> Unit,
    viewModel: SuperAdminViewModel = viewModel()
) {
    val allAdmins by viewModel.allAdmins.collectAsState()
    val pendingAdmins by viewModel.pendingAdmins.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    
    val admin = allAdmins.find { it.id == adminId } ?: pendingAdmins.find { it.id == adminId }

    var checkTaxMatches by remember { mutableStateOf(false) }
    var checkLicenseValid by remember { mutableStateOf(false) }
    var checkIdMatches by remember { mutableStateOf(false) }
    var checkPhotosReal by remember { mutableStateOf(false) }
    var checkGibVerified by remember { mutableStateOf(false) }

    val allChecksPassed = checkTaxMatches && checkLicenseValid && checkIdMatches && checkPhotosReal && checkGibVerified

    var showRejectSheet by remember { mutableStateOf(false) }
    var showSuspendSheet by remember { mutableStateOf(false) }
    var actionReason by remember { mutableStateOf("") }
    
    var viewingDocURL by remember { mutableStateOf<String?>(null) }
    var viewingDocTitle by remember { mutableStateOf("") }

    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Başvuru İncelemesi", fontWeight = FontWeight.Bold, fontSize = 18.sp) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Geri")
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background)
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        if (admin == null) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                if (isLoading) CircularProgressIndicator(color = AppColors.Primary)
                else Text("Başvuru bulunamadı", color = AppColors.TextSecondary)
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            BusinessInfoCard(admin)

            DocumentsSection(
                admin = admin,
                onViewDoc = { url, title ->
                    viewingDocURL = url
                    viewingDocTitle = title
                }
            )

            FacilityPhotosSection(
                admin = admin,
                onViewDoc = { url ->
                    viewingDocURL = url
                    viewingDocTitle = "Saha Fotoğrafı"
                }
            )

            ChecklistCard(
                checkTaxMatches = checkTaxMatches, onTaxMatchesChange = { checkTaxMatches = it },
                checkLicenseValid = checkLicenseValid, onLicenseValidChange = { checkLicenseValid = it },
                checkIdMatches = checkIdMatches, onIdMatchesChange = { checkIdMatches = it },
                checkPhotosReal = checkPhotosReal, onPhotosRealChange = { checkPhotosReal = it },
                checkGibVerified = checkGibVerified, onGibVerifiedChange = { checkGibVerified = it }
            )

            GibVerifyCard {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://interaktifvd.gib.gov.tr"))
                context.startActivity(intent)
            }

            ActionButtons(
                admin = admin,
                allChecksPassed = allChecksPassed,
                onApprove = { viewModel.approveAdmin(adminId) { onBack() } },
                onRejectClick = { actionReason = ""; showRejectSheet = true },
                onSuspendClick = { actionReason = ""; showSuspendSheet = true },
                isLoading = isLoading
            )
            
            Spacer(modifier = Modifier.height(24.dp))
        }

        if (showRejectSheet) {
            ActionReasonSheet(
                title = "Başvuruyu Reddet",
                description = "Red sebebini detaylı yazın. Başvuru sahibi bu mesajı görerek belgelerini düzeltebilir.",
                actionLabel = "Reddet",
                reason = actionReason,
                onReasonChange = { actionReason = it },
                onDismiss = { showRejectSheet = false },
                onConfirm = {
                    scope.launch { sheetState.hide() }.invokeOnCompletion {
                        viewModel.rejectAdmin(adminId, actionReason) {
                            showRejectSheet = false
                            onBack()
                        }
                    }
                },
                sheetState = sheetState
            )
        }

        if (showSuspendSheet) {
            ActionReasonSheet(
                title = "Hesabı Askıya Al",
                description = "Askıya alma sebebini yazın. Bu sebep işletmeciye gösterilecek.",
                actionLabel = "Askıya Al",
                reason = actionReason,
                onReasonChange = { actionReason = it },
                onDismiss = { showSuspendSheet = false },
                onConfirm = {
                    scope.launch { sheetState.hide() }.invokeOnCompletion {
                        viewModel.suspendAdmin(adminId, actionReason) {
                            showSuspendSheet = false
                            onBack()
                        }
                    }
                },
                sheetState = sheetState
            )
        }

        if (viewingDocURL != null) {
            DocumentViewerDialog(
                url = viewingDocURL!!,
                title = viewingDocTitle,
                onDismiss = { viewingDocURL = null }
            )
        }
    }
}

@Composable
fun BusinessInfoCard(admin: AdminProfile) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier.size(50.dp).background(AppColors.Primary.copy(alpha = 0.1f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.Store, contentDescription = null, tint = AppColors.Primary, modifier = Modifier.size(24.dp))
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(admin.businessName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
                Spacer(modifier = Modifier.height(4.dp))
                AdminStatusBadge(admin.approvalStatus)
            }
        }
        
        HorizontalDivider(color = Color.Gray.copy(alpha = 0.2f))
        
        InfoRow(label = "Vergi No", value = admin.taxNumber)
        InfoRow(label = "Başvuru", value = formatDate(admin.createdAt))
        admin.documentsSubmittedAt?.let { InfoRow(label = "Belge Gönderim", value = formatDate(it)) }
        admin.reviewedAt?.let { InfoRow(label = "Son İnceleme", value = formatDate(it)) }
    }
}

@Composable
fun InfoRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary)
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium, color = AppColors.TextPrimary)
    }
}

@Composable
fun DocumentsSection(admin: AdminProfile, onViewDoc: (String, String) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Description, contentDescription = null, tint = AppColors.Primary)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Belgeler", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
        }
        
        DocumentRow(title = AdminDocumentType.TAX_CERTIFICATE.displayName, url = admin.documents.taxCertificateURL, icon = Icons.Default.Receipt, onViewDoc = onViewDoc)
        DocumentRow(title = AdminDocumentType.BUSINESS_LICENSE.displayName, url = admin.documents.businessLicenseURL, icon = Icons.Default.AccountBalance, onViewDoc = onViewDoc)
        DocumentRow(title = AdminDocumentType.ID_FRONT.displayName, url = admin.documents.idFrontURL, icon = Icons.Default.Badge, onViewDoc = onViewDoc)
        DocumentRow(title = AdminDocumentType.ID_BACK.displayName, url = admin.documents.idBackURL, icon = Icons.Default.Badge, onViewDoc = onViewDoc)
    }
}

@Composable
fun DocumentRow(title: String, url: String?, icon: ImageVector, onViewDoc: (String, String) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.Background, RoundedCornerShape(10.dp))
            .clickable(enabled = url != null) { url?.let { onViewDoc(it, title) } }
            .padding(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier.size(56.dp).background(AppColors.Primary.copy(alpha = 0.1f), RoundedCornerShape(10.dp)),
            contentAlignment = Alignment.Center
        ) {
            if (url != null) {
                AsyncImage(
                    model = url,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(10.dp))
                )
            } else {
                Icon(icon, contentDescription = null, tint = AppColors.Primary)
            }
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium, color = AppColors.TextPrimary)
            Text(if (url != null) "Görüntülemek için dokun" else "Yüklenmedi", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        }
        if (url != null) {
            Icon(Icons.Default.ZoomIn, contentDescription = null, tint = AppColors.Primary)
        }
    }
}

@Composable
fun FacilityPhotosSection(admin: AdminProfile, onViewDoc: (String) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.PhotoLibrary, contentDescription = null, tint = AppColors.Primary)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Saha Fotoğrafları (${admin.documents.facilityPhotoURLs.size})", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
        }
        
        if (admin.documents.facilityPhotoURLs.isEmpty()) {
            Text("Saha fotoğrafı yüklenmedi.", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(3),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.height(110.dp) // Height for 1 row of photos roughly
            ) {
                items(admin.documents.facilityPhotoURLs) { url ->
                    Box(
                        modifier = Modifier
                            .height(100.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .clickable { onViewDoc(url) }
                            .background(Color.Gray.copy(alpha = 0.15f))
                    ) {
                        AsyncImage(
                            model = url,
                            contentDescription = null,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ChecklistCard(
    checkTaxMatches: Boolean, onTaxMatchesChange: (Boolean) -> Unit,
    checkLicenseValid: Boolean, onLicenseValidChange: (Boolean) -> Unit,
    checkIdMatches: Boolean, onIdMatchesChange: (Boolean) -> Unit,
    checkPhotosReal: Boolean, onPhotosRealChange: (Boolean) -> Unit,
    checkGibVerified: Boolean, onGibVerifiedChange: (Boolean) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(14.dp))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Checklist, contentDescription = null, tint = AppColors.Primary)
            Spacer(modifier = Modifier.width(8.dp))
            Text("İnceleme Checklist'i", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
        }
        Text("Aşağıdaki kontrolleri belgelere bakarak doğrula:", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        
        CheckRow(isOn = checkTaxMatches, text = "Vergi numarası ve unvan vergi levhasıyla eşleşiyor", onClick = { onTaxMatchesChange(!checkTaxMatches) })
        CheckRow(isOn = checkLicenseValid, text = "İşyeri ruhsatı geçerli ve faaliyet konusu spor tesisi", onClick = { onLicenseValidChange(!checkLicenseValid) })
        CheckRow(isOn = checkIdMatches, text = "Kimlik adı vergi levhası sahibi/yetkilisiyle aynı", onClick = { onIdMatchesChange(!checkIdMatches) })
        CheckRow(isOn = checkPhotosReal, text = "Saha fotoğrafları gerçek (stock değil) ve tabela uyumlu", onClick = { onPhotosRealChange(!checkPhotosReal) })
        CheckRow(isOn = checkGibVerified, text = "GİB üzerinden vergi numarası teyit edildi", onClick = { onGibVerifiedChange(!checkGibVerified) })
    }
}

@Composable
fun CheckRow(isOn: Boolean, text: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = if (isOn) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
            contentDescription = null,
            tint = if (isOn) AppColors.Primary else Color.Gray,
            modifier = Modifier.size(24.dp)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Text(text, style = MaterialTheme.typography.bodyMedium, color = AppColors.TextPrimary)
    }
}

@Composable
fun GibVerifyCard(onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFF2196F3).copy(alpha = 0.08f), RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Default.Language, contentDescription = null, tint = Color(0xFF2196F3))
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text("GİB'de Vergi No Sorgula", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium, color = AppColors.TextPrimary)
            Text("interaktifvd.gib.gov.tr", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        }
        Icon(Icons.AutoMirrored.Filled.OpenInNew, contentDescription = null, tint = Color(0xFF2196F3))
    }
}

@Composable
fun ActionButtons(
    admin: AdminProfile,
    allChecksPassed: Boolean,
    onApprove: () -> Unit,
    onRejectClick: () -> Unit,
    onSuspendClick: () -> Unit,
    isLoading: Boolean
) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        if (admin.approvalStatus != AdminApprovalStatus.APPROVED) {
            Button(
                onClick = onApprove,
                enabled = allChecksPassed && !isLoading,
                modifier = Modifier.fillMaxWidth().height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary),
                shape = RoundedCornerShape(12.dp)
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Icon(Icons.Default.VerifiedUser, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Başvuruyu Onayla", fontWeight = FontWeight.Bold)
                }
            }
            if (!allChecksPassed) {
                Text(
                    text = "Onaylamak için tüm checklist maddelerini işaretleyin",
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
        
        if (admin.approvalStatus != AdminApprovalStatus.REJECTED) {
            Button(
                onClick = onRejectClick,
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth().height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Cancel, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Reddet", fontWeight = FontWeight.Bold)
            }
        }
        
        if (admin.approvalStatus == AdminApprovalStatus.APPROVED) {
            Button(
                onClick = onSuspendClick,
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth().height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Surface, contentColor = Color.Red),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color.Red),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Lock, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Askıya Al", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActionReasonSheet(
    title: String,
    description: String,
    actionLabel: String,
    reason: String,
    onReasonChange: (String) -> Unit,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit,
    sheetState: SheetState
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = AppColors.Background
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp).padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
            Text(description, style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary)
            
            OutlinedTextField(
                value = reason,
                onValueChange = onReasonChange,
                modifier = Modifier.fillMaxWidth().height(120.dp),
                placeholder = { Text("Sebep yazın...") },
                colors = OutlinedTextFieldDefaults.colors(
                    unfocusedContainerColor = AppColors.CardBackground,
                    focusedContainerColor = AppColors.CardBackground
                ),
                shape = RoundedCornerShape(10.dp)
            )
            
            val isEnabled = reason.trim().length >= 10
            
            Button(
                onClick = onConfirm,
                enabled = isEnabled,
                modifier = Modifier.fillMaxWidth().height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Send, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text(actionLabel, fontWeight = FontWeight.Bold)
            }
            
            if (!isEnabled) {
                Text("En az 10 karakter girin.", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
            }
        }
    }
}

@Composable
fun DocumentViewerDialog(url: String, title: String, onDismiss: () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)
    ) {
        Box(modifier = Modifier.fillMaxSize().background(Color.Black)) {
            AsyncImage(
                model = url,
                contentDescription = title,
                contentScale = ContentScale.Fit,
                modifier = Modifier.fillMaxSize()
            )
            
            Row(
                modifier = Modifier.fillMaxWidth().padding(top = 40.dp, start = 16.dp, end = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier.background(Color.Black.copy(alpha = 0.5f), CircleShape)
                ) {
                    Icon(Icons.Default.Close, contentDescription = "Kapat", tint = Color.White)
                }
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Color.White)
                Spacer(modifier = Modifier.size(48.dp))
            }
        }
    }
}

fun formatDate(date: Date): String {
    val formatter = SimpleDateFormat("d MMMM yyyy, HH:mm", Locale("tr", "TR"))
    return formatter.format(date)
}
