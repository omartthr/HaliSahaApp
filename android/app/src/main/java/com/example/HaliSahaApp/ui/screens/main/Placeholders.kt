package com.example.HaliSahaApp.ui.screens.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.HaliSahaApp.data.models.UserType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.components.PrimaryButton
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

// MARK: - Generic Placeholder
@Composable
fun GenericPlaceholder(title: String, icon: ImageVector, message: String) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = AppColors.Primary.copy(alpha = 0.5f),
            modifier = Modifier.size(80.dp)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary
        )
    }
}

// MARK: - Map Placeholder
@Composable
fun MapScreenPlaceholder() {
    GenericPlaceholder(
        title = "Harita",
        icon = AppIcons.Map,
        message = "ADIM 4'te eklenecek"
    )
}

// MARK: - Bookings Placeholder
@Composable
fun BookingsScreenPlaceholder() {
    GenericPlaceholder(
        title = "Randevularım",
        icon = AppIcons.Bookings, // ConfirmationNumber
        message = "ADIM 5'te eklenecek"
    )
}

// MARK: - Chat Placeholder
@Composable
fun ChatScreenPlaceholder() {
    GenericPlaceholder(
        title = "Sohbet",
        icon = AppIcons.Chat,
        message = "ADIM 7'de eklenecek"
    )
}

// MARK: - Profile Placeholder
@Composable
fun ProfileScreenPlaceholder(onLogout: () -> Unit) {
    val currentUser by AuthService.currentUser.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        // Avatar
        Surface(
            modifier = Modifier.size(100.dp),
            shape = androidx.compose.foundation.shape.CircleShape,
            color = AppColors.Primary.copy(alpha = 0.1f)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = AppIcons.Person,
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(50.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // User Info
        if (currentUser != null) {
            Text(
                text = currentUser?.fullName ?: "Kullanıcı",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "@${currentUser?.username}",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary
            )

            if (currentUser?.userType != UserType.GUEST) {
                Spacer(modifier = Modifier.height(8.dp))
                SuggestionChip(
                    onClick = { },
                    label = {
                        Text("${currentUser?.preferredPosition?.icon} ${currentUser?.preferredPosition?.displayName}")
                    }
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        Text(
            text = "ADIM 8'de eklenecek",
            style = MaterialTheme.typography.labelSmall,
            color = Color.Gray
        )

        Spacer(modifier = Modifier.height(20.dp))

        // Logout
        PrimaryButton(
            text = "Çıkış Yap",
            onClick = {
                AuthService.signOut()
                onLogout()
            },
            icon = AppIcons.Logout, // ExitToApp
            style = com.example.HaliSahaApp.ui.components.ButtonStyle.Outline
        )

        Spacer(modifier = Modifier.height(32.dp))
    }
}