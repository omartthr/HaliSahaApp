package com.example.HaliSahaApp.ui.screens.auth

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Key
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.example.HaliSahaApp.ui.components.CustomTextField
import com.example.HaliSahaApp.ui.components.PrimaryButton
import com.example.HaliSahaApp.ui.viewmodels.AuthViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppStrings

@Composable
fun ForgotPasswordScreen(
    navController: NavController,
    viewModel: AuthViewModel
) {
    val uiState by viewModel.uiState.collectAsState()
    val email by viewModel.email.collectAsState()
    var emailSent by remember { mutableStateOf(false) }
    val context = LocalContext.current

    // Başarı durumu kontrolü
    LaunchedEffect(uiState.successMessage) {
        if (uiState.successMessage != null) {
            emailSent = true
            viewModel.clearError() // Mesajı temizle ki tekrar girince kalmasın
        }
    }

    // Hata mesajı
    LaunchedEffect(uiState.error) {
        if (uiState.error != null) {
            Toast.makeText(context, uiState.error, Toast.LENGTH_LONG).show()
            viewModel.clearError()
        }
    }

    Scaffold(
        topBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = { navController.popBackStack() }) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Geri"
                    )
                }
                Text(
                    text = "Şifremi Unuttum",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        },
        containerColor = AppColors.Background
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            if (emailSent) {
                SuccessContent(email = email, onBackToLogin = { navController.popBackStack() }) {
                    emailSent = false
                }
            } else {
                FormContent(
                    email = email,
                    onEmailChange = { viewModel.email.value = it },
                    isLoading = uiState.isLoading,
                    onSubmit = { viewModel.resetPassword() },
                    onCancel = { navController.popBackStack() }
                )
            }
        }
    }
}

@Composable
private fun FormContent(
    email: String,
    onEmailChange: (String) -> Unit,
    isLoading: Boolean,
    onSubmit: () -> Unit,
    onCancel: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Spacer(modifier = Modifier.height(20.dp))

        // Icon
        Box(
            modifier = Modifier
                .size(100.dp)
                .background(AppColors.Primary.copy(alpha = 0.1f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Key,
                contentDescription = null,
                tint = AppColors.Primary,
                modifier = Modifier.size(40.dp)
            )
        }

        // Title & Desc
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = "Şifrenizi mi Unuttunuz?",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary,
                textAlign = TextAlign.Center
            )
        }

        // Form
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.Surface, RoundedCornerShape(16.dp))
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            CustomTextField(
                title = "E-posta",
                placeholder = "ornek@email.com",
                value = email,
                onValueChange = onEmailChange,
                leadingIcon = Icons.Default.Email,
                keyboardType = KeyboardType.Email
            )

            PrimaryButton(
                text = "Sıfırlama Bağlantısı Gönder",
                onClick = onSubmit,
                isLoading = isLoading,
                icon = Icons.AutoMirrored.Filled.Send
            )
        }

        // Back Button
        TextButton(onClick = onCancel) {
            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("Giriş sayfasına dön")
        }
    }
}

@Composable
private fun SuccessContent(
    email: String,
    onBackToLogin: () -> Unit,
    onRetry: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        Spacer(modifier = Modifier.height(20.dp))

        Box(
            modifier = Modifier
                .size(100.dp)
                .background(AppColors.Success.copy(alpha = 0.1f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = null,
                tint = AppColors.Success,
                modifier = Modifier.size(50.dp)
            )
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(
                text = "E-posta Gönderildi!",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Şifre sıfırlama bağlantısı $email adresine gönderildi.",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary,
                textAlign = TextAlign.Center
            )
        }

        // Instructions
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.Surface, RoundedCornerShape(16.dp))
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            InstructionRow(1, "E-posta kutunuzu kontrol edin")
            InstructionRow(2, "\"Şifreyi Sıfırla\" bağlantısına tıklayın")
            InstructionRow(3, "Yeni şifrenizi belirleyin")
        }

        // Info Box
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.Warning.copy(alpha = 0.1f), RoundedCornerShape(12.dp))
                .padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Icon(
                imageVector = Icons.Default.Info,
                contentDescription = null,
                tint = AppColors.Warning,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = "E-postayı bulamıyorsanız spam/gereksiz klasörünü kontrol edin.",
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.TextSecondary
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        PrimaryButton(text = "Giriş Sayfasına Dön", onClick = onBackToLogin)

        TextButton(onClick = onRetry) {
            Text("Farklı bir e-posta dene", color = AppColors.Primary)
        }
    }
}

@Composable
private fun InstructionRow(step: Int, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(24.dp)
                .background(AppColors.Primary, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = step.toString(),
                color = Color.White,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold
            )
        }
        Spacer(modifier = Modifier.width(16.dp))
        Text(text = text, style = MaterialTheme.typography.bodyMedium)
    }
}