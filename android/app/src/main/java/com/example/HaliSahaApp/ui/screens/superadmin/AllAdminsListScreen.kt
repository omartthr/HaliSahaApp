package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
import com.example.HaliSahaApp.ui.viewmodels.SuperAdminViewModel
import com.example.HaliSahaApp.utils.AppColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AllAdminsListScreen(
    navController: NavController,
    viewModel: SuperAdminViewModel = viewModel()
) {
    val allAdmins by viewModel.allAdmins.collectAsState()
    
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(title = { Text("Tüm İşletmeler") })
        }
    ) { padding ->
        if (allAdmins.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Kayıtlı işletme bulunmuyor.", color = AppColors.TextSecondary)
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding).fillMaxSize().padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(allAdmins) { admin ->
                    AdminRowCard(
                        admin = admin, 
                        onClick = {
                            navController.navigate("admin_review/${admin.id}")
                        }
                    )
                }
            }
        }
    }
}
