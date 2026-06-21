package com.example.HaliSahaApp.ui.screens.admin.onboarding

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.rememberAsyncImagePainter
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
import com.example.HaliSahaApp.ui.viewmodels.AdminOnboardingViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AdminOnboardingScreen(
    onApproved: () -> Unit,
    onLogout: () -> Unit,
    viewModel: AdminOnboardingViewModel = viewModel()
) {
    val profile by viewModel.myAdminProfile.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    LaunchedEffect(profile) {
        if (profile?.approvalStatus == AdminApprovalStatus.APPROVED) {
            onApproved()
        }
    }

    if (profile == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = AppColors.Primary)
        }
        return
    }

    val status = profile?.approvalStatus ?: AdminApprovalStatus.PENDING

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("İşletme Hesabı", color = AppColors.TextPrimary) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                ),
                actions = {
                    IconButton(onClick = onLogout) {
                        Icon(AppIcons.Logout, contentDescription = "Çıkış Yap", tint = AppColors.Error)
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(modifier = Modifier.padding(paddingValues).fillMaxSize()) {
            when (status) {
                AdminApprovalStatus.PENDING -> {
                    if (profile?.documentsSubmittedAt == null) {
                        DocumentUploadView(
                            isLoading = isLoading,
                            onSubmit = { tax, license, front, back, facilities ->
                                viewModel.submitDocuments(tax, license, front, back, facilities, onSuccess = {})
                            }
                        )
                    } else {
                        PendingApprovalView()
                    }
                }
                AdminApprovalStatus.REJECTED -> {
                    RejectedView(
                        reason = profile?.rejectionReason,
                        onReupload = {
                            // Belge sıfırlama işlemi (VM üzerinden documentsSubmittedAt silinerek vs.)
                            // Şimdilik upload view'a geri dönebilir veya admin desteki ile halledebiliriz
                        }
                    )
                }
                AdminApprovalStatus.SUSPENDED -> {
                    SuspendedView(reason = profile?.rejectionReason)
                }
                AdminApprovalStatus.APPROVED -> {
                    // Navigate to Dashboard
                }
            }

            if (error != null) {
                AlertDialog(
                    onDismissRequest = { viewModel.clearError() },
                    title = { Text("Hata") },
                    text = { Text(error!!) },
                    confirmButton = {
                        TextButton(onClick = { viewModel.clearError() }) {
                            Text("Tamam")
                        }
                    }
                )
            }
        }
    }
}

@Composable
fun DocumentUploadView(
    isLoading: Boolean,
    onSubmit: (Uri, Uri, Uri, Uri, List<Uri>) -> Unit
) {
    var taxPlateUri by remember { mutableStateOf<Uri?>(null) }
    var businessLicenseUri by remember { mutableStateOf<Uri?>(null) }
    var idFrontUri by remember { mutableStateOf<Uri?>(null) }
    var idBackUri by remember { mutableStateOf<Uri?>(null) }
    var facilityUris by remember { mutableStateOf<List<Uri>>(emptyList()) }

    val canSubmit = taxPlateUri != null && businessLicenseUri != null && idFrontUri != null && idBackUri != null && facilityUris.isNotEmpty()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Belge Yükleme",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        Text(
            text = "İşletme hesabınızın onaylanması için aşağıdaki belgeleri eksiksiz olarak yüklemeniz gerekmektedir.",
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary
        )

        DocumentPickerItem(title = "Vergi Levhası", uri = taxPlateUri) { taxPlateUri = it }
        DocumentPickerItem(title = "İşyeri Açma ve Çalışma Ruhsatı", uri = businessLicenseUri) { businessLicenseUri = it }
        DocumentPickerItem(title = "Kimlik Ön Yüzü (Yetkili)", uri = idFrontUri) { idFrontUri = it }
        DocumentPickerItem(title = "Kimlik Arka Yüzü (Yetkili)", uri = idBackUri) { idBackUri = it }

        Text("Tesis Fotoğrafları (En az 1 adet)", fontWeight = FontWeight.Bold)
        // Çoklu fotoğraf seçimi basitleştirildi
        DocumentPickerItem(title = "Tesis Fotoğrafı Ekle", uri = facilityUris.firstOrNull()) { 
            if (it != null) {
                facilityUris = listOf(it) // Basitlik için 1 fotoğraf tutuyoruz şimdilik
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = {
                if (canSubmit) {
                    onSubmit(taxPlateUri!!, businessLicenseUri!!, idFrontUri!!, idBackUri!!, facilityUris)
                }
            },
            modifier = Modifier.fillMaxWidth().height(50.dp),
            enabled = canSubmit && !isLoading,
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)
        ) {
            if (isLoading) {
                CircularProgressIndicator(color = AppColors.Surface, modifier = Modifier.size(24.dp))
            } else {
                Text("Belgeleri Gönder", color = AppColors.Surface, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun DocumentPickerItem(title: String, uri: Uri?, onUriSelected: (Uri?) -> Unit) {
    val launcher = rememberLauncherForActivityResult(contract = ActivityResultContracts.GetContent()) { selectedUri ->
        onUriSelected(selectedUri)
    }

    Card(
        modifier = Modifier.fillMaxWidth().clickable { launcher.launch("image/*") },
        colors = CardDefaults.cardColors(containerColor = AppColors.CardBackground)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (uri != null) {
                Image(
                    painter = rememberAsyncImagePainter(uri),
                    contentDescription = null,
                    modifier = Modifier.size(60.dp).clip(RoundedCornerShape(8.dp)),
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = Modifier.size(60.dp).background(AppColors.Background, RoundedCornerShape(8.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(AppIcons.Camera, contentDescription = null, tint = AppColors.Primary)
                }
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(title, fontWeight = FontWeight.Medium, color = AppColors.TextPrimary)
                Text(if (uri != null) "Değiştir" else "Yükle", color = AppColors.Primary, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

@Composable
fun PendingApprovalView() {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(AppIcons.Time, contentDescription = null, tint = AppColors.Warning, modifier = Modifier.size(80.dp))
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = "Onay Bekleniyor",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Belgeleriniz inceleniyor. Bu işlem 1-3 iş günü sürebilir. Onaylandığında size bildirim göndereceğiz.",
            textAlign = TextAlign.Center,
            color = AppColors.TextSecondary
        )
    }
}

@Composable
fun RejectedView(reason: String?, onReupload: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(AppIcons.Error, contentDescription = null, tint = AppColors.Error, modifier = Modifier.size(80.dp))
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = "Başvurunuz Reddedildi",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Card(
            colors = CardDefaults.cardColors(containerColor = AppColors.Error.copy(alpha = 0.1f)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Red Nedeni:", fontWeight = FontWeight.Bold, color = AppColors.Error)
                Text(reason ?: "Belirtilmedi", color = AppColors.TextPrimary)
            }
        }
        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick = onReupload,
            modifier = Modifier.fillMaxWidth().height(50.dp),
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)
        ) {
            Text("Belgeleri Tekrar Yükle", color = AppColors.Surface)
        }
    }
}

@Composable
fun SuspendedView(reason: String?) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(AppIcons.Error, contentDescription = null, tint = AppColors.Error, modifier = Modifier.size(80.dp))
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = "Hesabınız Askıya Alındı",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = reason ?: "Hesabınız kurallarımıza aykırı davranışlar sebebiyle askıya alınmıştır.",
            textAlign = TextAlign.Center,
            color = AppColors.TextSecondary
        )
    }
}
