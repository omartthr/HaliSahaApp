package com.example.HaliSahaApp.ui.screens.auth

import android.widget.Toast
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.PlayerPosition
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.viewmodels.AuthUiState
import com.example.HaliSahaApp.ui.viewmodels.AuthViewModel
import com.example.HaliSahaApp.ui.viewmodels.PasswordStrength
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppStrings

@Composable
fun RegisterScreen(
    navController: NavController,
    viewModel: AuthViewModel = viewModel()
) {
    val context = LocalContext.current
    var currentStep by remember { mutableStateOf(0) }
    val totalSteps = 3
    val uiState by viewModel.uiState.collectAsState()

    // Hata/Başarı Mesajları
    LaunchedEffect(uiState) {
        if (uiState.error != null) {
            Toast.makeText(context, uiState.error, Toast.LENGTH_LONG).show()
            viewModel.clearError()
        }
        if (uiState.successMessage != null) {
            Toast.makeText(context, uiState.successMessage, Toast.LENGTH_LONG).show()
            viewModel.clearError()
        }
    }

    Scaffold(
        topBar = {
            // Basit bir geri butonu
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (currentStep > 0) {
                    IconButton(onClick = { currentStep-- }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Geri", modifier = Modifier.rotate(180f))
                    }
                } else {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Kapat", modifier = Modifier.rotate(180f))
                    }
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Kayıt Ol",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
        },
        containerColor = AppColors.Background
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Progress Bar
            ProgressBar(currentStep, totalSteps)

            // Step Content
            AnimatedContent(
                targetState = currentStep,
                transitionSpec = {
                    if (targetState > initialState) {
                        (slideInHorizontally { width -> width } + fadeIn()).togetherWith(slideOutHorizontally { width -> -width } + fadeOut())
                    } else {
                        (slideInHorizontally { width -> -width } + fadeIn()).togetherWith(slideOutHorizontally { width -> width } + fadeOut())
                    }
                },
                label = "stepTransition",
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 24.dp)
            ) { step ->
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                ) {
                    when (step) {
                        0 -> AccountInfoStep(viewModel)
                        1 -> PersonalInfoStep(viewModel)
                        2 -> PreferencesStep(viewModel)
                    }
                }
            }

            // Navigation Buttons (Bottom)
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
                    .background(AppColors.Background)
            ) {
                if (currentStep < totalSteps - 1) {
                    PrimaryButton(
                        text = "Devam Et",
                        onClick = { currentStep++ },
                        isEnabled = if (currentStep == 0) viewModel.isStep1Valid() else viewModel.isStep2Valid()
                    )
                } else {
                    PrimaryButton(
                        text = "Kayıt Ol",
                        onClick = { viewModel.register() },
                        isLoading = uiState.isLoading,
                        icon = Icons.Default.Check
                    )
                }
            }
        }
    }
}

// MARK: - Steps

@Composable
fun AccountInfoStep(viewModel: AuthViewModel) {
    val email by viewModel.email.collectAsState()
    val password by viewModel.password.collectAsState()
    val confirmPassword by viewModel.confirmPassword.collectAsState()

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        HeaderSection(
            icon = Icons.Default.PersonAdd,
            title = "Hesap Bilgilerinizi Girin"
        )

        CustomTextField(
            title = "E-posta",
            placeholder = "ornek@email.com",
            value = email,
            onValueChange = { viewModel.email.value = it },
            keyboardType = KeyboardType.Email
        )

        PasswordTextField(
            title = "Şifre",
            value = password,
            onValueChange = { viewModel.password.value = it }
        )

        // Şifre Gücü
        if (password.isNotEmpty()) {
            val strength = viewModel.getPasswordStrength()
            PasswordStrengthIndicator(strength)
        }

        PasswordTextField(
            title = "Şifre Tekrar",
            value = confirmPassword,
            onValueChange = { viewModel.confirmPassword.value = it },
            imeAction = ImeAction.Done
        )

        if (confirmPassword.isNotEmpty()) {
            val isMatch = password == confirmPassword
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = if (isMatch) Icons.Default.Check else Icons.Default.Close,
                    contentDescription = null,
                    tint = if (isMatch) AppColors.Success else AppColors.Error,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = if (isMatch) "Şifreler eşleşiyor" else "Şifreler eşleşmiyor",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (isMatch) AppColors.Success else AppColors.Error
                )
            }
        }
    }
}

@Composable
fun PersonalInfoStep(viewModel: AuthViewModel) {
    val firstName by viewModel.firstName.collectAsState()
    val lastName by viewModel.lastName.collectAsState()
    val username by viewModel.username.collectAsState()
    val phone by viewModel.phone.collectAsState()

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        HeaderSection(
            icon = Icons.Default.Person,
            title = "Kişisel Bilgilerinizi Girin"
        )

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            CustomTextField(
                modifier = Modifier.weight(1f),
                title = "Ad",
                placeholder = "Adınız",
                value = firstName,
                onValueChange = { viewModel.firstName.value = it }
            )
            CustomTextField(
                modifier = Modifier.weight(1f),
                title = "Soyad",
                placeholder = "Soyadınız",
                value = lastName,
                onValueChange = { viewModel.lastName.value = it }
            )
        }

        CustomTextField(
            title = "Kullanıcı Adı",
            placeholder = "kullanici_adi",
            value = username,
            onValueChange = { viewModel.username.value = it }
        )

        CustomTextField(
            title = "Telefon",
            placeholder = "5XX XXX XX XX",
            value = phone,
            onValueChange = { viewModel.phone.value = it },
            keyboardType = KeyboardType.Phone
        )
    }
}

@Composable
fun PreferencesStep(viewModel: AuthViewModel) {
    val preferredPosition by viewModel.preferredPosition.collectAsState()

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        HeaderSection(
            icon = Icons.Default.SportsSoccer,
            title = "Tercih Ettiğiniz Mevki",
            subtitle = "Maçlarda oynamayı tercih ettiğiniz pozisyonu seçin"
        )

        PlayerPosition.entries.filter { it != PlayerPosition.UNSPECIFIED }.forEach { position ->
            val isSelected = preferredPosition == position

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .border(
                        width = if (isSelected) 2.dp else 1.dp,
                        color = if (isSelected) AppColors.Primary else Color.Gray.copy(alpha = 0.3f),
                        shape = RoundedCornerShape(12.dp)
                    )
                    .background(if (isSelected) AppColors.Primary.copy(alpha = 0.1f) else Color.Transparent)
                    .clickable { viewModel.preferredPosition.value = position }
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(text = position.icon, fontSize = 24.sp)
                Spacer(modifier = Modifier.width(16.dp))
                Text(
                    text = position.displayName,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                    color = AppColors.TextPrimary
                )
                Spacer(modifier = Modifier.weight(1f))
                if (isSelected) {
                    Icon(Icons.Default.Check, contentDescription = null, tint = AppColors.Primary)
                }
            }
        }
    }
}

// MARK: - Components for Register

@Composable
fun ProgressBar(currentStep: Int, totalSteps: Int) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            repeat(totalSteps) { index ->
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(4.dp)
                        .clip(CircleShape)
                        .background(
                            if (index <= currentStep) AppColors.Primary else Color.Gray.copy(alpha = 0.3f)
                        )
                )
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Adım ${currentStep + 1}/$totalSteps",
            style = MaterialTheme.typography.bodySmall,
            color = AppColors.TextSecondary
        )
    }
}

@Composable
fun HeaderSection(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String? = null) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = AppColors.Primary,
            modifier = Modifier.size(50.dp)
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = AppColors.TextPrimary
        )
        if (subtitle != null) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

@Composable
fun PasswordStrengthIndicator(strength: PasswordStrength) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            repeat(3) { index ->
                Box(
                    modifier = Modifier
                        .width(20.dp)
                        .height(4.dp)
                        .clip(CircleShape)
                        .background(
                            if (index < strength.score) Color(strength.color) else Color.Gray.copy(alpha = 0.3f)
                        )
                )
            }
        }
        Text(
            text = strength.label,
            style = MaterialTheme.typography.bodySmall,
            color = Color(strength.color)
        )
    }
}