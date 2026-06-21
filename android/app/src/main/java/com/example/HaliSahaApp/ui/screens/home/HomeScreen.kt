package com.example.HaliSahaApp.ui.screens.home

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField // <-- BasicTextField importu
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox // <-- YENİ BİLEŞEN
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.ui.viewmodels.HomeFilter
import com.example.HaliSahaApp.ui.viewmodels.HomeViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    navController: NavController,
    viewModel: HomeViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val currentUser by AuthService.currentUser.collectAsState()

    // Bottom Sheet State
    var showNotifications by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState()
    val scope = rememberCoroutineScope()

    // Pull to Refresh State (Material3 1.3+)
    val pullRefreshState = rememberPullToRefreshState()

    Scaffold(
        topBar = {
            HomeTopBar(
                onNotificationClick = { navController.navigate(Screen.NotificationsList.route) }
            )
        },
        containerColor = AppColors.Background,
        contentWindowInsets = WindowInsets(0.dp)
    ) { paddingValues ->

        // YENİ YAPI: PullToRefreshBox
        // Bu kutu, içeriği otomatik olarak kaydırılabilir yapar ve yenileme ikonunu yönetir.
        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = {
                scope.launch { viewModel.refreshData() }
            },
            state = pullRefreshState,
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            indicator = {
                // Varsayılan indikatör
                androidx.compose.material3.pulltorefresh.PullToRefreshDefaults.Indicator(
                    state = pullRefreshState,
                    isRefreshing = uiState.isRefreshing,
                    containerColor = AppColors.Surface,
                    color = AppColors.Primary,
                    modifier = Modifier.align(Alignment.TopCenter)
                )
            }
        ) {
            // İÇERİK
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // 1. Header
                HomeHeaderSection(userName = currentUser?.firstName)

                // 2. Search & Filter Bar
                HomeSearchSection(
                    searchText = uiState.searchText,
                    onSearchChange = { viewModel.onSearchTextChange(it) },
                    hasActiveFilters = uiState.hasActiveFilters,
                    onFilterClick = { /* Filtre aç */ }
                )

                // 3. Filter Chips
                HomeFilterChips(
                    selectedFilter = uiState.selectedFilter,
                    onSelect = { viewModel.onFilterSelect(it) }
                )

                Spacer(modifier = Modifier.height(16.dp))

                // 4. Content
                if (uiState.isLoading) {
                    HomeLoadingSection()
                } else {
                    HomeContentSection(
                        uiState = uiState,
                        viewModel = viewModel,
                        navController = navController
                    )
                }

                Spacer(modifier = Modifier.height(16.dp)) // Sadece standart bir içerik alt boşluğu
            }
        }
    }
}

// MARK: - Top Bar
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeTopBar(onNotificationClick: () -> Unit) {
    TopAppBar(
        title = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.SportsSoccer,
                    contentDescription = null,
                    tint = AppColors.Primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Alo HalıSaha",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary
                )
            }
        },
        actions = {
            IconButton(onClick = onNotificationClick) {
                Box {
                    Icon(
                        imageVector = Icons.Default.Notifications,
                        contentDescription = "Bildirimler",
                        tint = AppColors.TextPrimary
                    )
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(Color.Red, CircleShape)
                            .align(Alignment.TopEnd)
                    )
                }
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(containerColor = AppColors.Background)
    )
}

// MARK: - Header Section
@Composable
fun HomeHeaderSection(userName: String?) {
    if (userName != null) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Merhaba, $userName \uD83D\uDC4B",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary
                )
                Text(
                    text = "Bugün maç yapmaya ne dersin?",
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppColors.TextSecondary
                )
            }

            Surface(
                shape = CircleShape,
                color = AppColors.Primary.copy(alpha = 0.1f),
                modifier = Modifier.size(50.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = userName.take(1).uppercase(),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.Primary
                    )
                }
            }
        }
    }
}

// MARK: - Search Section
@Composable
fun HomeSearchSection(
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
                        Text("Saha ara...", color = Color.Gray)
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

        IconButton(
            onClick = onFilterClick,
            modifier = Modifier
                .size(50.dp)
                .background(AppColors.Surface, RoundedCornerShape(12.dp))
        ) {
            Icon(
                imageVector = AppIcons.Filter,
                contentDescription = "Filtre",
                tint = if (hasActiveFilters) AppColors.Primary else Color.Gray
            )
        }
    }
}

// MARK: - Filter Chips Section
@Composable
fun HomeFilterChips(
    selectedFilter: HomeFilter,
    onSelect: (HomeFilter) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier.padding(bottom = 16.dp)
    ) {
        items(HomeFilter.entries) { filter ->
            val isSelected = selectedFilter == filter

            Surface(
                shape = RoundedCornerShape(20.dp),
                color = if (isSelected) AppColors.Primary else AppColors.Surface,
                border = if (isSelected) null else androidx.compose.foundation.BorderStroke(1.dp, Color.Gray.copy(alpha = 0.3f)),
                modifier = Modifier.clickable { onSelect(filter) }
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (isSelected) {
                        Icon(
                            imageVector = filter.icon,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                    }
                    Text(
                        text = filter.displayName,
                        style = MaterialTheme.typography.labelLarge,
                        color = if (isSelected) Color.White else AppColors.TextPrimary
                    )
                }
            }
        }
    }
}

// MARK: - Loading Section
@Composable
fun HomeLoadingSection() {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        repeat(3) {
            SkeletonView(height = 100.dp, cornerRadius = 16.dp)
        }
    }
}

// MARK: - Content Section
@Composable
fun HomeContentSection(
    uiState: com.example.HaliSahaApp.ui.viewmodels.HomeUiState,
    viewModel: HomeViewModel,
    navController: NavController
) {
    Column(verticalArrangement = Arrangement.spacedBy(24.dp)) {

        // 1. Featured Section
        if (uiState.featuredFacilities.isNotEmpty() && uiState.searchText.isEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionHeader(title = "Öne Çıkanlar", icon = Icons.Default.Star)
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(uiState.featuredFacilities) { facility ->
                        FeaturedFacilityCard(
                            facility = facility,
                            onClick = {
                                // GÜNCELLENEN KISIM:
                                facility.id?.let { id ->
                                    navController.navigate(Screen.FacilityDetail.createRoute(id))
                                }
                            }
                        )
                    }
                }
            }
        }

        // 2. Upcoming Matches
        if (uiState.upcomingMatches.isNotEmpty() && uiState.searchText.isEmpty()) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionHeader(title = "Oyuncu Aranan Maçlar", icon = AppIcons.PersonGroup, actionTitle = "Tümü") {}

                uiState.upcomingMatches.forEach { match ->
                    Box(modifier = Modifier.padding(horizontal = 16.dp)) {
                        MatchPostCard(matchPost = match)
                    }
                }
            }
        }

        // 3. Nearby / Filtered Results (GÜNCELLENDİ)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {

            // Başlık ve Aksiyon Mantığı
            val title = if (uiState.hasActiveFilters) "Sonuçlar" else "Yakındaki Sahalar"
            val icon = if (uiState.hasActiveFilters) AppIcons.Filter else AppIcons.Location

            val actionTitle = if (uiState.hasActiveFilters) "Temizle" else "Tümü"
            val onActionClick = {
                if (uiState.hasActiveFilters) {
                    viewModel.clearFilters()
                } else {
                    // Tümünü gör sayfasına git (FacilityListScreen)
                    // Önce Screen.kt'ye FacilityList rotasını eklemen lazım
                    navController.navigate("facility_list")
                }
            }

            SectionHeader(
                title = title,
                icon = icon,
                actionTitle = actionTitle,
                onAction = onActionClick
            )

            if (uiState.filteredFacilities.isEmpty()) {
                EmptyStateView(
                    icon = Icons.Default.Search,
                    title = "Saha Bulunamadı",
                    message = "Arama kriterlerinize uygun saha bulunamadı.",
                    buttonTitle = "Filtreleri Temizle",
                    onButtonClick = { viewModel.clearFilters() }
                )
            } else {
                // Sadece ilk 5 tanesini göster (.take(5))
                uiState.filteredFacilities.take(5).forEach { facility ->
                    Box(modifier = Modifier.padding(horizontal = 16.dp)) {
                        FacilityCard(
                            facility = facility,
                            showDistance = true,
                            distance = 2.5,
                            onClick = {
                                // GÜNCELLENEN KISIM:
                                facility.id?.let { id ->
                                    navController.navigate(Screen.FacilityDetail.createRoute(id))
                                }
                            }
                        )
                    }
                }

                // Eğer 5'ten fazla varsa "Tümünü Gör" butonu ekle
                if (uiState.filteredFacilities.size > 5) {
                    Button(
                        onClick = { navController.navigate("facility_list") },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = AppColors.Primary.copy(alpha = 0.1f),
                            contentColor = AppColors.Primary
                        ),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp)
                            .height(44.dp),
                        elevation = ButtonDefaults.buttonElevation(0.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "Tüm Sahaları Gör (${uiState.filteredFacilities.size})",
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Section Header Component
@Composable
fun SectionHeader(
    title: String,
    icon: ImageVector? = null,
    actionTitle: String? = null,
    onAction: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
            }
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        if (actionTitle != null && onAction != null) {
            Text(
                text = actionTitle,
                style = MaterialTheme.typography.labelLarge,
                color = AppColors.Primary,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.clickable(onClick = onAction)
            )
        }
    }
}

// MARK: - Notification Sheet
@Composable
fun NotificationsSheetView(onClose: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp)
            .heightIn(min = 300.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "Bildirimler",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.align(Alignment.Center)
            )
            IconButton(onClick = onClose, modifier = Modifier.align(Alignment.CenterEnd)) {
                Icon(Icons.Default.Close, contentDescription = "Kapat")
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        EmptyStateView(
            icon = Icons.Default.Notifications,
            title = "Bildiriminiz yok",
            message = "Şu an için yeni bir bildiriminiz bulunmuyor."
        )
    }
}

// MARK: - Notifications Placeholder Screen (Tam ekran)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsPlaceholderScreen(navController: NavController) {
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text("Bildirimler", fontWeight = FontWeight.SemiBold)
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                            contentDescription = "Geri"
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                )
            )
        },
        containerColor = AppColors.Background
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentAlignment = Alignment.Center
        ) {
            EmptyStateView(
                icon = Icons.Default.Notifications,
                title = "Bildiriminiz yok",
                message = "Şu an için yeni bir bildiriminiz bulunmuyor."
            )
        }
    }
}