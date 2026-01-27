package com.example.HaliSahaApp.ui.screens.facility

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.viewmodels.FacilityListViewModel
import com.example.HaliSahaApp.ui.viewmodels.SortOption
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FacilityListScreen(
    navController: NavController,
    viewModel: FacilityListViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Bottom Sheet State
    var showFilterSheet by remember { mutableStateOf(false) }
    var showSortMenu by remember { mutableStateOf(false) }

    // Pull to Refresh
    val pullRefreshState = rememberPullToRefreshState()
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Tüm Sahalar", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background),
                navigationIcon = {
                    // Eğer geri dönmek istersen diye (Navigation stack durumuna göre)
                    // IconButton(onClick = { navController.popBackStack() }) {
                    //     Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Geri")
                    // }
                }
            )
        },
        containerColor = AppColors.Background
    ) { paddingValues ->

        PullToRefreshBox(
            isRefreshing = uiState.isLoading,
            onRefresh = { viewModel.loadFacilities() },
            state = pullRefreshState,
            modifier = Modifier.padding(paddingValues)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                // 1. Search Bar & Filter Button
                FacilityListSearchBar(
                    searchText = uiState.searchText,
                    onSearchChange = { viewModel.onSearchTextChange(it) },
                    hasActiveFilters = uiState.filters.hasActiveFilters,
                    onFilterClick = { showFilterSheet = true }
                )

                // 2. Results Header (Count & Sort)
                if (uiState.filteredFacilities.isNotEmpty()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "${uiState.filteredFacilities.size} saha",
                            style = MaterialTheme.typography.bodyMedium,
                            color = AppColors.TextSecondary
                        )

                        Spacer(modifier = Modifier.weight(1f))

                        // Sort Dropdown
                        Box {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.clickable { showSortMenu = true }
                            ) {
                                Text(
                                    text = uiState.sortOption.displayName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = AppColors.Primary
                                )
                                Icon(
                                    imageVector = Icons.Default.KeyboardArrowDown,
                                    contentDescription = null,
                                    tint = AppColors.Primary,
                                    modifier = Modifier.size(16.dp)
                                )
                            }

                            DropdownMenu(
                                expanded = showSortMenu,
                                onDismissRequest = { showSortMenu = false },
                                containerColor = AppColors.Surface
                            ) {
                                SortOption.entries.forEach { option ->
                                    DropdownMenuItem(
                                        text = { Text(option.displayName) },
                                        onClick = {
                                            viewModel.onSortOptionChange(option)
                                            showSortMenu = false
                                        }
                                    )
                                }
                            }
                        }
                    }
                }

                // 3. Content List
                if (uiState.isLoading && uiState.facilities.isEmpty()) {
                    // Loading State
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        repeat(5) { SkeletonView(height = 120.dp, cornerRadius = 16.dp) }
                    }
                } else if (uiState.filteredFacilities.isEmpty()) {
                    // Empty State
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        EmptyStateView(
                            icon = AppIcons.Indoor,
                            title = "Saha Bulunamadı",
                            message = if (uiState.hasActiveFilters) "Arama kriterlerinize uygun saha bulunamadı." else "Henüz kayıtlı saha bulunmuyor.",
                            buttonTitle = if (uiState.hasActiveFilters) "Filtreleri Temizle" else null,
                            onButtonClick = { viewModel.clearFilters() }
                        )
                    }
                } else {
                    // List State (EKSİK OLAN KISIM BURASIYDI)
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(uiState.filteredFacilities) { facility ->
                            FacilityCard(
                                facility = facility,
                                showDistance = true,
                                distance = viewModel.getDistance(facility),
                                onClick = {
                                    // Detay sayfasına yönlendirme (placeholder)
                                    // navController.navigate("facility_detail/${facility.id}")
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // Filter Sheet Placeholder
    if (showFilterSheet) {
        ModalBottomSheet(onDismissRequest = { showFilterSheet = false }) {
            Box(modifier = Modifier.height(200.dp).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text("Filtreleme Seçenekleri Yakında...")
            }
        }
    }
}

// MARK: - Components

@Composable
fun FacilityListSearchBar(
    searchText: String,
    onSearchChange: (String) -> Unit,
    hasActiveFilters: Boolean,
    onFilterClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Search Field
        Row(
            modifier = Modifier
                .weight(1f)
                .height(50.dp)
                .background(AppColors.Surface, RoundedCornerShape(12.dp))
                .padding(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = Color.Gray
            )
            Spacer(modifier = Modifier.width(8.dp))
            BasicTextField(
                value = searchText,
                onValueChange = onSearchChange,
                modifier = Modifier.weight(1f),
                singleLine = true,
                decorationBox = { innerTextField ->
                    if (searchText.isEmpty()) {
                        Text("Saha, konum ara...", color = Color.Gray)
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

        Spacer(modifier = Modifier.width(12.dp))

        // Filter Button
        IconButton(
            onClick = onFilterClick,
            modifier = Modifier
                .size(50.dp)
                .background(AppColors.Surface, RoundedCornerShape(12.dp))
        ) {
            Box {
                Icon(
                    imageVector = AppIcons.Filter,
                    contentDescription = "Filtre",
                    tint = if (hasActiveFilters) AppColors.Primary else Color.Gray
                )
                if (hasActiveFilters) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(AppColors.Primary, CircleShape)
                            .align(Alignment.TopEnd)
                    )
                }
            }
        }
    }
}