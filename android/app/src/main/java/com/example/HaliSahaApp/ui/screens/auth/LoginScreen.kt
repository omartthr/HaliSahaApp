package com.example.HaliSahaApp.ui.screens.auth

import android.app.Activity
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.ui.viewmodels.AuthViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppStrings

@Composable
fun LoginScreen(
    navController: NavController,
    viewModel: AuthViewModel = viewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()

    // Form States
    val email by viewModel.email.collectAsState()
    val password by viewModel.password.collectAsState()

    // Hata Mesajları
    LaunchedEffect(uiState.error) {
        if (uiState.error != null) {
            Toast.makeText(context, uiState.error, Toast.LENGTH_LONG).show()
            viewModel.clearError()
        }
    }

    Box(modifier = Modifier.fillMaxSize().background(AppColors.Background)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(32.dp)
        ) {
            Spacer(modifier = Modifier.height(20.dp))

            // 1. Logo & Welcome
            LoginHeaderSection()

            // 2. Login Form
            LoginFormSection(
                email = email,
                password = password,
                onEmailChange = { viewModel.email.value = it },
                onPasswordChange = { viewModel.password.value = it },
                onForgotPasswordClick = { navController.navigate(Screen.ForgotPassword.route) },
                onLoginClick = { viewModel.login() },
                isLoading = uiState.isLoading
            )

            // 3. Divider
            LoginDividerSection()

            // 4. Social Login (Sadece Google kaldı)
            LoginSocialSection(
                isLoading = uiState.isLoading,
                onGoogleClick = {
                    // Google Sign In eklendiğinde burası dolacak
                    Toast.makeText(context, "Google Giriş yakında...", Toast.LENGTH_SHORT).show()
                }
            )

            // 5. Guest Mode
            LoginGuestSection(
                onGuestClick = { viewModel.continueAsGuest() }
            )

            // 6. Register Link
            LoginRegisterLinkSection(
                onRegisterClick = { navController.navigate(Screen.Register.route) }
            )

            Spacer(modifier = Modifier.height(20.dp))
        }

        // Loading Overlay
        if (uiState.isLoading) {
            LoadingView()
        }
    }
}

// MARK: - Sections

@Composable
fun LoginHeaderSection() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.padding(top = 20.dp)
    ) {
        // Logo Container
        Box(
            modifier = Modifier
                .size(100.dp)
                .background(AppColors.Primary.copy(alpha = 0.1f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.SportsSoccer,
                contentDescription = null,
                tint = AppColors.Primary,
                modifier = Modifier.size(40.dp)
            )
        }

        // Text
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Hoş Geldiniz!",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary
            )
            Text(
                text = "Halı saha kiralayın, takım kurun, maça başlayın!",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }
}

@Composable
fun LoginFormSection(
    email: String,
    password: String,
    onEmailChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    onForgotPasswordClick: () -> Unit,
    onLoginClick: () -> Unit,
    isLoading: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.Surface, RoundedCornerShape(20.dp))
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        // Email
        CustomTextField(
            title = AppStrings.EMAIL,
            placeholder = "ornek@email.com",
            value = email,
            onValueChange = onEmailChange,
            leadingIcon = Icons.Default.Email,
            keyboardType = KeyboardType.Email
        )

        // Password
        PasswordTextField(
            title = AppStrings.PASSWORD,
            value = password,
            onValueChange = onPasswordChange,
            imeAction = ImeAction.Done
        )

        // Forgot Password Link
        Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
            Text(
                text = AppStrings.FORGOT_PASSWORD,
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.Primary,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.clickable { onForgotPasswordClick() }
            )
        }

        // Login Button
        PrimaryButton(
            text = AppStrings.LOGIN,
            onClick = onLoginClick,
            isLoading = isLoading,
            icon = Icons.AutoMirrored.Filled.ArrowForward
        )
    }
}

@Composable
fun LoginDividerSection() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        HorizontalDivider(modifier = Modifier.weight(1f), color = androidx.compose.ui.graphics.Color.Gray.copy(alpha = 0.3f))
        Text(
            text = "veya",
            style = MaterialTheme.typography.bodySmall,
            color = AppColors.TextSecondary,
            modifier = Modifier.padding(horizontal = 16.dp)
        )
        HorizontalDivider(modifier = Modifier.weight(1f), color = androidx.compose.ui.graphics.Color.Gray.copy(alpha = 0.3f))
    }
}

@Composable
fun LoginSocialSection(
    isLoading: Boolean,
    onGoogleClick: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        // Google Button
        Button(
            onClick = onGoogleClick,
            enabled = !isLoading,
            colors = ButtonDefaults.buttonColors(
                containerColor = androidx.compose.ui.graphics.Color.White,
                contentColor = androidx.compose.ui.graphics.Color.Black
            ),
            border = androidx.compose.foundation.BorderStroke(1.dp, androidx.compose.ui.graphics.Color.Gray.copy(alpha = 0.3f)),
            shape = RoundedCornerShape(12.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
        ) {
            Text("Google ile Devam Et", fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
fun LoginGuestSection(onGuestClick: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(top = 8.dp)
    ) {
        Text(
            text = "Hemen göz atmak ister misiniz?",
            style = MaterialTheme.typography.bodySmall,
            color = AppColors.TextSecondary
        )

        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.clickable { onGuestClick() }
        ) {
            Icon(
                imageVector = Icons.Default.Visibility,
                contentDescription = null,
                tint = AppColors.Primary,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = AppStrings.CONTINUE_AS_GUEST,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = AppColors.Primary
            )
        }
    }
}

@Composable
fun LoginRegisterLinkSection(onRegisterClick: () -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier.fillMaxWidth().padding(bottom = 20.dp)
    ) {
        Text(
            text = "Hesabınız yok mu? ",
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary
        )
        Text(
            text = AppStrings.REGISTER,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.Primary,
            modifier = Modifier.clickable { onRegisterClick() }
        )
    }
}