package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.HaliSahaApp.ui.viewmodels.SuperAdminViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SuperAdminStatsScreen(
    viewModel: SuperAdminViewModel = viewModel()
) {
    val allAdmins by viewModel.allAdmins.collectAsState()
    val pendingAdmins by viewModel.pendingAdmins.collectAsState()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(title = { Text("İstatistikler") })
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Genel Durum", style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Kayıtlı İşletme Sayısı: ${allAdmins.size}")
                    Text("Bekleyen Onay Sayısı: ${pendingAdmins.size}")
                }
            }
            
            Text("Buraya detaylı istatistik grafikleri eklenecek.")
        }
    }
}
