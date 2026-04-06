package com.example.HaliSahaApp.ui.screens.map

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.ui.components.FacilityCard
import com.example.HaliSahaApp.ui.viewmodels.MapViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.maps.android.compose.GoogleMap
import com.google.maps.android.compose.MapProperties
import com.google.maps.android.compose.MapUiSettings
import com.google.maps.android.compose.MarkerComposable
import com.google.maps.android.compose.MarkerState
import com.google.maps.android.compose.rememberCameraPositionState
// import com.google.android.gms.maps.CameraUpdateFactory (Şimdilik kapalı)
// import com.google.android.gms.maps.model.CameraPosition
// import com.google.android.gms.maps.model.LatLng
// import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MapScreen(
    navController: NavController,
    viewModel: MapViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // Bottom Sheet State
    val sheetState = rememberModalBottomSheetState()
    var showFilterSheet by remember { mutableStateOf(false) }
    var showListSheet by remember { mutableStateOf(false) }

    val cameraPositionState = rememberCameraPositionState {
        position = uiState.cameraPosition ?: CameraPosition.fromLatLngZoom(LatLng(41.0082, 28.9784), 10f)
    }

    LaunchedEffect(uiState.cameraPosition) {
        uiState.cameraPosition?.let {
            cameraPositionState.animate(CameraUpdateFactory.newCameraPosition(it))
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {

        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = MapProperties(isMyLocationEnabled = uiState.userLocation != null),
            uiSettings = MapUiSettings(zoomControlsEnabled = false, myLocationButtonEnabled = false)
        ) {
            // Pinler (Marker)
            uiState.filteredFacilities.forEach { facility ->
                val isSelected = uiState.selectedFacility?.id == facility.id

                MarkerComposable(
                    state = MarkerState(position = LatLng(facility.latitude, facility.longitude)),
                    title = facility.name,
                    onClick = {
                        viewModel.selectFacility(facility)
                        true
                    }
                ) {
                    FacilityMapPin(isSelected = isSelected)
                }
            }
        }

        // 2. ÜST BAR (Arama ve Filtre)
        Column(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 48.dp, start = 16.dp, end = 16.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp)
                    .shadow(4.dp, RoundedCornerShape(12.dp))
                    .background(AppColors.Surface, RoundedCornerShape(12.dp))
                    .padding(horizontal = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Search, contentDescription = null, tint = Color.Gray)
                Spacer(modifier = Modifier.width(8.dp))

                // Basit TextField yerine Text (tıklayınca arama açılabilir) veya BasicTextField
                androidx.compose.foundation.text.BasicTextField(
                    value = uiState.searchText,
                    onValueChange = { viewModel.onSearchTextChange(it) },
                    modifier = Modifier.weight(1f),
                    singleLine = true,
                    decorationBox = { innerTextField ->
                        if (uiState.searchText.isEmpty()) {
                            Text("Saha ara...", color = Color.Gray)
                        }
                        innerTextField()
                    }
                )

                if (uiState.searchText.isNotEmpty()) {
                    IconButton(onClick = { viewModel.onSearchTextChange("") }) {
                        Icon(Icons.Default.Close, contentDescription = "Temizle", tint = Color.Gray)
                    }
                }

                // Filtre Butonu
                IconButton(onClick = { showFilterSheet = true }) {
                    Icon(
                        imageVector = if (uiState.hasActiveFilters) AppIcons.Filter else Icons.Default.FilterList,
                        contentDescription = "Filtre",
                        tint = if (uiState.hasActiveFilters) AppColors.Primary else Color.Gray
                    )
                }
            }

            // Sonuç Sayısı (Filtre aktifse)
            if (uiState.hasActiveFilters) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .background(AppColors.Surface.copy(alpha = 0.9f), RoundedCornerShape(8.dp))
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${uiState.filteredFacilities.size} saha bulundu",
                        style = MaterialTheme.typography.labelSmall,
                        color = AppColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Temizle",
                        style = MaterialTheme.typography.labelSmall,
                        color = AppColors.Primary,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.clickable { viewModel.clearFilters() }
                    )
                }
            }
        }

        // 3. ALT KONTROLLER (Liste ve Konum Butonları)
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 100.dp, start = 16.dp, end = 16.dp) // BottomBar üstünde kalmalı
                .fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Bottom
        ) {
            // Liste Görünümü Butonu
            FloatingActionButton(
                onClick = { showListSheet = true },
                containerColor = AppColors.Surface,
                contentColor = AppColors.Primary
            ) {
                Row(modifier = Modifier.padding(horizontal = 16.dp)) {
                    Icon(Icons.Default.List, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Liste", fontWeight = FontWeight.Bold)
                }
            }

            // Konum Butonu
            FloatingActionButton(
                onClick = {
                    viewModel.requestLocationPermission(context)
                    viewModel.centerOnUserLocation()
                },
                containerColor = AppColors.Surface,
                contentColor = if (uiState.userLocation != null) AppColors.Primary else AppColors.TextPrimary
            ) {
                Icon(Icons.Default.MyLocation, contentDescription = "Konumum")
            }
        }

        // 4. DETAY KARTI (Seçili Tesis Varsa)
        if (uiState.selectedFacility != null) {
            val facility = uiState.selectedFacility!!

            FacilityMapCard(
                facility = facility,
                distance = viewModel.getDistanceString(facility),
                onClose = { viewModel.selectFacility(null) },
                onNavigate = { /* Harita uygulamasını aç */ },
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 100.dp, start = 16.dp, end = 16.dp)
            )
        }
    }

    // LIST SHEET
    if (showListSheet) {
        ModalBottomSheet(
            onDismissRequest = { showListSheet = false },
            sheetState = sheetState,
            containerColor = AppColors.Background
        ) {
            FacilityListSheetContent(
                facilities = uiState.filteredFacilities,
                onFacilityClick = {
                    viewModel.selectFacility(it)
                    scope.launch { sheetState.hide() }.invokeOnCompletion { showListSheet = false }
                },
                onClose = {
                    scope.launch { sheetState.hide() }.invokeOnCompletion { showListSheet = false }
                }
            )
        }
    }

    // FILTER SHEET (Basit Placeholder)
    if (showFilterSheet) {
        ModalBottomSheet(onDismissRequest = { showFilterSheet = false }) {
            Box(modifier = Modifier.height(200.dp).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Text("Filtreleme Seçenekleri Yakında...")
            }
        }
    }
}

// ... (FacilityMapPin, FacilityMapCard ve FacilityListSheetContent aynı kalsın) ...
@Composable
fun FacilityMapPin(isSelected: Boolean) {
    // ... (Aynı kod) ...
    val size = if (isSelected) 44.dp else 36.dp
    val iconSize = if (isSelected) 24.dp else 20.dp
    val color = if (isSelected) AppColors.Primary else Color.White
    val contentColor = if (isSelected) Color.White else AppColors.Primary

    Box(contentAlignment = Alignment.Center) {
        Surface(
            shape = CircleShape,
            color = color,
            shadowElevation = 6.dp,
            modifier = Modifier.size(size)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = Icons.Default.SportsSoccer,
                    contentDescription = null,
                    tint = contentColor,
                    modifier = Modifier.size(iconSize)
                )
            }
        }
    }
}

@Composable
fun FacilityMapCard(
    facility: Facility,
    distance: String,
    onClose: () -> Unit,
    onNavigate: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(8.dp)
    ) {
        Column {
            Box(modifier = Modifier.fillMaxWidth().padding(top = 8.dp), contentAlignment = Alignment.Center) {
                Box(modifier = Modifier.width(40.dp).height(4.dp).background(Color.Gray.copy(alpha = 0.3f), CircleShape))
            }

            Row(modifier = Modifier.padding(16.dp)) {
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(AppColors.Primary.copy(alpha = 0.1f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Default.SportsSoccer, contentDescription = null, tint = AppColors.Primary.copy(alpha = 0.5f))
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = facility.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Star, null, tint = AppColors.Warning, modifier = Modifier.size(14.dp))
                        Text(
                            text = "${facility.formattedRating} (${facility.totalReviews})",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }

                    if (distance.isNotEmpty()) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.LocationOn, null, tint = Color.Gray, modifier = Modifier.size(14.dp))
                            Text(text = distance, style = MaterialTheme.typography.bodySmall, color = Color.Gray)
                        }
                    }
                }

                IconButton(onClick = onClose, modifier = Modifier.size(24.dp)) {
                    Icon(Icons.Default.Close, null, tint = Color.Gray)
                }
            }

            Button(
                onClick = { /* Detay sayfasına git */ },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)
            ) {
                Text("Detayları Gör", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FacilityListSheetContent(
    facilities: List<Facility>,
    onFacilityClick: (Facility) -> Unit,
    onClose: () -> Unit
) {
    Column(modifier = Modifier.fillMaxHeight(0.9f)) {
        CenterAlignedTopAppBar(
            title = { Text("Sahalar", fontWeight = FontWeight.Bold) },
            navigationIcon = {
                TextButton(onClick = onClose) { Text("Harita") }
            },
            colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background)
        )

        LazyColumn(
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(facilities) { facility ->
                FacilityCard(
                    facility = facility,
                    showDistance = true,
                    distance = null,
                    onClick = { onFacilityClick(facility) }
                )
            }
        }
    }
}