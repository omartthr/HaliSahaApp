package com.example.HaliSahaApp.ui.screens.main

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.components.PrimaryButton // Birazdan yazacağız veya Button kullan
import kotlinx.coroutines.launch

@Composable
fun MainScreenPlaceholder(onLogout: () -> Unit) {
    val scope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceBetween
    ) {
        Spacer(modifier = Modifier.height(20.dp))

        // Welcome
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = null,
                tint = Color.Green,
                modifier = Modifier.size(100.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = "Hoş Geldiniz!",
                fontSize = 28.sp,
                style = MaterialTheme.typography.titleLarge
            )
        }

        // Info
        Surface(
            color = Color.LightGray.copy(alpha = 0.3f),
            shape = MaterialTheme.shapes.medium,
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Ana sayfa eklencek beklemede kallll",
                modifier = Modifier.padding(16.dp),
                color = Color.Gray
            )
        }

        // Logout Button
        Button(
            onClick = {
                AuthService.signOut()
                onLogout()
            },
            modifier = Modifier.fillMaxWidth().height(50.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color.Red)
        ) {
            Icon(Icons.AutoMirrored.Filled.ExitToApp, contentDescription = null)
            Spacer(Modifier.width(8.dp))
            Text("Çıkış Yap")
        }

        Spacer(modifier = Modifier.height(20.dp))
    }
}