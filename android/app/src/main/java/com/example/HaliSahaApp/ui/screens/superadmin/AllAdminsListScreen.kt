package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Storefront
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.AdminApprovalStatus
import com.example.HaliSahaApp.data.models.AdminProfile
import com.example.HaliSahaApp.ui.viewmodels.SuperAdminViewModel
import com.example.HaliSahaApp.utils.AppColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AllAdminsListScreen(
    navController: NavController,
    viewModel: SuperAdminViewModel = viewModel()
) {
    val allAdmins by viewModel.allAdmins.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    var statusFilter by remember { mutableStateOf<AdminApprovalStatus?>(null) }
    var searchText by remember { mutableStateOf("") }

    val filteredAdmins = remember(allAdmins, statusFilter, searchText) {
        val trimmedSearch = searchText.trim().lowercase()
        allAdmins.filter { admin ->
            val matchesStatus = statusFilter == null || admin.approvalStatus == statusFilter
            val matchesSearch = trimmedSearch.isEmpty() ||
                    admin.businessName.lowercase().contains(trimmedSearch) ||
                    admin.taxNumber.lowercase().contains(trimmedSearch)
            matchesStatus && matchesSearch
        }
    }

    LaunchedEffect(Unit) {
        viewModel.loadData()
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("İşletmeciler", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                )
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Search Bar
            AdminSearchBar(
                searchText = searchText,
                onSearchChange = { searchText = it }
            )

            // Filter Chips
            AdminFilterChips(
                selectedFilter = statusFilter,
                onSelect = { statusFilter = it }
            )

            if (isLoading && allAdmins.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = AppColors.Primary)
                }
            } else if (filteredAdmins.isEmpty()) {
                AdminEmptyState(searchText = searchText, hasFilter = statusFilter != null)
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(filteredAdmins) { admin ->
                        AllAdminsCard(
                            admin = admin,
                            onClick = { navController.navigate("admin_review/${admin.id}") }
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun AdminSearchBar(searchText: String, onSearchChange: (String) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .height(44.dp)
            .background(AppColors.Surface, RoundedCornerShape(12.dp))
            .padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Default.Search, contentDescription = null, tint = Color.Gray)
        Spacer(modifier = Modifier.width(8.dp))
        BasicTextField(
            value = searchText,
            onValueChange = onSearchChange,
            modifier = Modifier.weight(1f),
            singleLine = true,
            decorationBox = { innerTextField ->
                if (searchText.isEmpty()) {
                    Text("İşletme adı veya vergi no", color = Color.Gray, fontSize = 14.sp)
                }
                innerTextField()
            }
        )
        if (searchText.isNotEmpty()) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Temizle",
                tint = Color.Gray,
                modifier = Modifier.clickable { onSearchChange("") }
            )
        }
    }
}

@Composable
fun AdminFilterChips(
    selectedFilter: AdminApprovalStatus?,
    onSelect: (AdminApprovalStatus?) -> Unit
) {
    val filters = listOf(null) + AdminApprovalStatus.entries

    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(bottom = 8.dp)
    ) {
        items(filters) { filter ->
            val isSelected = selectedFilter == filter
            val label = filter?.displayName ?: "Hepsi"

            Surface(
                shape = CircleShape,
                color = if (isSelected) AppColors.Primary else AppColors.Surface,
                modifier = Modifier
                    .clickable { onSelect(filter) }
                    .border(
                        width = 1.dp,
                        color = if (isSelected) Color.Transparent else Color.Gray.copy(alpha = 0.2f),
                        shape = CircleShape
                    )
            ) {
                Text(
                    text = label,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = if (isSelected) Color.White else AppColors.TextPrimary,
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp)
                )
            }
        }
    }
}

@Composable
fun AllAdminsCard(admin: AdminProfile, onClick: () -> Unit) {
    val badgeColor = when (admin.approvalStatus) {
        AdminApprovalStatus.PENDING -> Color(0xFFFF9800)
        AdminApprovalStatus.APPROVED -> AppColors.Primary
        AdminApprovalStatus.REJECTED, AdminApprovalStatus.SUSPENDED -> Color.Red
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(AppColors.CardBackground, RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(44.dp)
                .background(badgeColor.copy(alpha = 0.12f), RoundedCornerShape(10.dp)),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Default.Storefront, contentDescription = null, tint = badgeColor)
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = admin.businessName,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text("VKN: ${admin.taxNumber}", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        }

        Spacer(modifier = Modifier.width(8.dp))

        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = admin.approvalStatus.displayName,
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                color = badgeColor,
                modifier = Modifier
                    .background(badgeColor.copy(alpha = 0.15f), CircleShape)
                    .padding(horizontal = 8.dp, vertical = 3.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = AppColors.TextSecondary, modifier = Modifier.size(16.dp))
        }
    }
}

@Composable
fun AdminEmptyState(searchText: String, hasFilter: Boolean) {
    Column(
        modifier = Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(Icons.Default.Person, contentDescription = null, modifier = Modifier.size(44.dp), tint = Color.Gray)
        Spacer(modifier = Modifier.height(14.dp))
        val title = if (searchText.isEmpty()) "Sonuç yok" else "\"$searchText\" için sonuç yok"
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = AppColors.TextPrimary)
        if (hasFilter) {
            Spacer(modifier = Modifier.height(4.dp))
            Text("Farklı bir filtre seçin veya filtreyi kaldırın.", style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        }
    }
}
