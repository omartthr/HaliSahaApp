package com.example.HaliSahaApp.ui.screens.auth

import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.viewmodels.AuthViewModel
import com.example.HaliSahaApp.utils.AppColors

@Composable
fun AdminRegisterScreen(
    navController: NavController,
    viewModel: AuthViewModel
) {
    var currentStep by remember { mutableStateOf(0) }
    var agreedToTerms by remember { mutableStateOf(false) }
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    LaunchedEffect(uiState) {
        if (uiState.error != null) {
            Toast.makeText(context, uiState.error, Toast.LENGTH_LONG).show()
            viewModel.clearError()
        }
        if (uiState.isSuccess) {
            Toast.makeText(context, uiState.successMessage ?: "Kayıt Başarılı!", Toast.LENGTH_LONG).show()
            navController.popBackStack() // Login'e dön
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
                IconButton(onClick = {
                    if (currentStep > 0) currentStep-- else navController.popBackStack()
                }) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Geri")
                }
                Text(
                    text = "İşletme Kaydı",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(start = 8.dp)
                )
            }
        },
        containerColor = AppColors.Background
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            ProgressBar(currentStep, 2)

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(24.dp)
            ) {
                if (currentStep == 0) {
                    AdminAccountStep(viewModel)
                } else {
                    BusinessInfoStep(viewModel, agreedToTerms) { agreedToTerms = it }
                }
            }

            // Bottom Buttons
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.Background)
                    .padding(24.dp)
            ) {
                if (currentStep == 0) {
                    PrimaryButton(
                        text = "Devam Et",
                        onClick = { currentStep++ },
                        isEnabled = viewModel.isStep1Valid() && viewModel.isStep2Valid()
                    )
                } else {
                    PrimaryButton(
                        text = "İşletme Kaydı Oluştur",
                        onClick = { viewModel.registerAsAdmin() },
                        isLoading = uiState.isLoading,
                        isEnabled = viewModel.businessName.value.isNotEmpty() && viewModel.taxNumber.value.isNotEmpty() && agreedToTerms,
                        icon = Icons.Default.Check
                    )
                }
            }
        }
    }
}

@Composable
fun AdminAccountStep(viewModel: AuthViewModel) {
    val email by viewModel.email.collectAsState()
    val password by viewModel.password.collectAsState()
    val confirm by viewModel.confirmPassword.collectAsState()
    val name by viewModel.firstName.collectAsState()
    val surname by viewModel.lastName.collectAsState()

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        HeaderSection(Icons.Default.Person, "Hesap Bilgileri", "İşletme sahibi bilgilerini girin")

        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            CustomTextField(
                modifier = Modifier.weight(1f),
                title = "Ad",
                placeholder = "Adınız",
                value = name,
                onValueChange = { viewModel.firstName.value = it }
            )
            CustomTextField(
                modifier = Modifier.weight(1f),
                title = "Soyad",
                placeholder = "Soyadınız",
                value = surname,
                onValueChange = { viewModel.lastName.value = it }
            )
        }

        CustomTextField(
            title = "E-posta",
            placeholder = "isletme@email.com",
            value = email,
            onValueChange = { viewModel.email.value = it },
            keyboardType = KeyboardType.Email
        )

        PasswordTextField(
            title = "Şifre",
            value = password,
            onValueChange = { viewModel.password.value = it }
        )

        PasswordTextField(
            title = "Şifre Tekrar",
            value = confirm,
            onValueChange = { viewModel.confirmPassword.value = it },
            imeAction = ImeAction.Done
        )
    }
}

@Composable
fun BusinessInfoStep(
    viewModel: AuthViewModel,
    agreedToTerms: Boolean,
    onTermsChanged: (Boolean) -> Unit
) {
    val businessName by viewModel.businessName.collectAsState()
    val taxNumber by viewModel.taxNumber.collectAsState()
    val phone by viewModel.phone.collectAsState()

    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        HeaderSection(Icons.Default.Business, "İşletme Bilgileri", "Tesis bilgilerini girin")

        CustomTextField(
            title = "İşletme Adı",
            placeholder = "Halı Saha İşletmesi",
            value = businessName,
            onValueChange = { viewModel.businessName.value = it },
            leadingIcon = Icons.Default.Business
        )

        CustomTextField(
            title = "Vergi Numarası",
            placeholder = "1234567890",
            value = taxNumber,
            onValueChange = { viewModel.taxNumber.value = it },
            leadingIcon = Icons.Default.Description,
            keyboardType = KeyboardType.Number
        )

        CustomTextField(
            title = "Telefon",
            placeholder = "5XX XXX XX XX",
            value = phone,
            onValueChange = { viewModel.phone.value = it },
            keyboardType = KeyboardType.Phone
        )

        // Terms
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.Surface, RoundedCornerShape(12.dp))
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = agreedToTerms,
                onCheckedChange = onTermsChanged,
                colors = CheckboxDefaults.colors(checkedColor = AppColors.Primary)
            )
            Column {
                Text("Kullanım koşullarını kabul ediyorum", style = MaterialTheme.typography.bodyMedium)
                Text("Koşulları oku", color = AppColors.Primary, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold)
            }
        }

        // Info
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.Info.copy(alpha = 0.1f), RoundedCornerShape(12.dp))
                .padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Icon(Icons.Default.Info, contentDescription = null, tint = AppColors.Info)
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text("Onay Süreci", fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
                Text(
                    "Kaydınız incelendikten sonra hesabınız aktif edilecektir (1-2 iş günü).",
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextSecondary
                )
            }
        }
    }
}