package com.example.HaliSahaApp.ui.screens.facility

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.Facility
import com.example.HaliSahaApp.data.models.Pitch
import com.example.HaliSahaApp.data.models.TimeSlot
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.viewmodels.FacilityDetailViewModel
import com.example.HaliSahaApp.utils.*
import java.util.Calendar
import java.util.Date
import java.util.Locale
import androidx.compose.foundation.lazy.items
import com.example.HaliSahaApp.ui.screens.booking.BookingFlowScreen

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FacilityDetailScreen(
    navController: NavController,
    facilityId: String
) {
    val viewModel: FacilityDetailViewModel = viewModel(
        factory = viewModelFactory {
            initializer {
                FacilityDetailViewModel(facilityId = facilityId)
            }
        }
    )

    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    // TopBar Scroll davranışı için state
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    // NOT: isLoading kontrolünü sadece ilk veri yüklemesi için kullanıyoruz.
    // showBookingFlow aktifken (booking oluşturma sırasında isLoading=true olabilir),
    // Dialog'u yok etmemek için burada showBookingFlow kontrolü ekliyoruz.
    if (!uiState.showBookingFlow && (uiState.facility == null && uiState.isLoading)) {
        LoadingView()
        return
    }

    // facility hala null ise (loading bitti ama veri gelmedi), boş ekran göster
    if (uiState.facility == null) {
        LoadingView()
        return
    }

    val facility = uiState.facility!!

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        facility.name,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        color = AppColors.TextPrimary, // Başlık Rengi
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Geri",
                            tint = AppColors.TextPrimary // İkon Rengi
                        )
                    }
                },
                actions = {
                    IconButton(onClick = {
                        val sendIntent = Intent().apply {
                            action = Intent.ACTION_SEND
                            putExtra(Intent.EXTRA_TEXT, "${facility.name} - ${facility.address}")
                            type = "text/plain"
                        }
                        context.startActivity(Intent.createChooser(sendIntent, null))
                    }) {
                        Icon(Icons.Default.Share, contentDescription = "Paylaş", tint = AppColors.TextPrimary)
                    }
                    IconButton(onClick = { viewModel.toggleFavorite() }) {
                        Icon(
                            imageVector = if (uiState.isFavorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                            contentDescription = "Favori",
                            tint = if (uiState.isFavorite) Color.Red else AppColors.TextPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = Color.Transparent, // Şeffaf arkaplan
                    scrolledContainerColor = AppColors.Surface
                ),
                scrollBehavior = scrollBehavior
            )
        },
        bottomBar = {
            FacilityBottomBar(
                totalPrice = uiState.totalPrice,
                duration = uiState.selectedDuration,
                canBook = uiState.canProceedToBooking,
                onBook = { viewModel.proceedToBooking() }
            )
        },
        containerColor = AppColors.Background // Ana Arkaplan (Açık Gri)
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = paddingValues.calculateBottomPadding()), // Sadece bottom padding
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // 1. Hero Image
            item { HeroSection(facility = facility) }

            // 2. Info Header
            item { HeaderSection(facility = facility) }

            // 3. Divider
            item { HorizontalDivider(thickness = 8.dp, color = Color.Gray.copy(alpha = 0.1f)) }

            // 4. Pitches
            item { PitchesSection(uiState = uiState, onSelectPitch = { viewModel.selectPitch(it) }) }

            // 5. Divider
            item { HorizontalDivider(thickness = 8.dp, color = Color.Gray.copy(alpha = 0.1f)) }

            // 6. Date Selection
            item { DateSelectionSection(selectedDate = uiState.selectedDate, onSelectDate = { viewModel.selectDate(it) }) }

            // 7. Time Slots
            item {
                TimeSlotsSection(
                    uiState = uiState,
                    onSelectSlot = { viewModel.selectTimeSlot(it) }
                )
            }

            // 8. Divider
            item { HorizontalDivider(thickness = 8.dp, color = Color.Gray.copy(alpha = 0.1f)) }

            // 9. Amenities
            item { AmenitiesSection(facility = facility) }

            // 10. Divider
            item { HorizontalDivider(thickness = 8.dp, color = Color.Gray.copy(alpha = 0.1f)) }

            // 11. Location
            item { LocationSection(facility = facility) }

            item { Spacer(modifier = Modifier.height(20.dp)) }
        }
    }

    if (uiState.showGuestAlert) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissGuestAlert() },
            title = { Text("Üye Girişi Gerekli", color = AppColors.TextPrimary) },
            text = { Text("Rezervasyon yapmak için üye girişi yapmanız gerekiyor.", color = AppColors.TextSecondary) },
            confirmButton = {
                TextButton(onClick = { viewModel.dismissGuestAlert() }) {
                    Text("Tamam", color = AppColors.Primary)
                }
            },
            containerColor = AppColors.Surface // Diyalog Rengi Beyaz
        )
    }
    if (uiState.showBookingFlow) {
        // Tam ekran dialog/sheet olarak açıyoruz
        androidx.compose.ui.window.Dialog(
            onDismissRequest = { /* Dismiss engellenebilir */ },
            properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false) // Full screen
        ) {
            BookingFlowScreen(
                viewModel = viewModel,
                onDismiss = { viewModel.closeBookingFlow() },
                onBookingCompleted = {
                    // iOS'taki gibi: dismiss() + NotificationCenter.post(.switchToBookingsTab)
                    viewModel.closeBookingFlow()
                    AppEventBus.tryEmit(AppEventBus.AppEvent.SwitchToBookingsTab)
                }
            )
        }
    }
}

// MARK: - Hero Section
@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun HeroSection(facility: Facility) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(300.dp) // Edge to edge olacağı için biraz daha yüksek
    ) {
        if (facility.images.isNotEmpty()) {
            val pagerState = androidx.compose.foundation.pager.rememberPagerState(
                pageCount = { facility.images.size }
            )
            androidx.compose.foundation.pager.HorizontalPager(
                state = pagerState,
                modifier = Modifier.fillMaxSize()
            ) { page ->
                coil.compose.AsyncImage(
                    model = facility.images[page],
                    contentDescription = "Saha Görseli",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = androidx.compose.ui.layout.ContentScale.Crop
                )
            }
            
            // Pager Indicator
            Row(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.Center
            ) {
                repeat(facility.images.size) { iteration ->
                    val color = if (pagerState.currentPage == iteration) Color.White else Color.White.copy(alpha = 0.5f)
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .clip(CircleShape)
                            .background(color)
                            .size(8.dp)
                    )
                }
            }
        } else {
            // Placeholder
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.linearGradient(
                            colors = listOf(Color(0xFF2E7D32), Color(0xFF1B5E20))
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.SportsSoccer,
                    contentDescription = null,
                    tint = Color.White.copy(alpha = 0.3f),
                    modifier = Modifier.size(80.dp)
                )
            }
        }

        Surface(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(16.dp),
            color = Color.Black.copy(alpha = 0.6f),
            shape = RoundedCornerShape(20.dp)
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Star, null, tint = AppColors.Warning, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "${facility.formattedRating} (${facility.totalReviews})",
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp
                )
            }
        }
    }
}

// MARK: - Header Section
@Composable
fun HeaderSection(facility: Facility) {
    var showFullDesc by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = facility.name,
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary // SİYAH YAZI
        )

        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.LocationOn, null, tint = AppColors.Primary, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = facility.address,
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary // GRİ YAZI
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Phone, null, tint = AppColors.Primary, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = facility.phone,
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary
            )
        }

        if (facility.description.isNotEmpty()) {
            Text(
                text = facility.description,
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary, // GRİ YAZI
                maxLines = if (showFullDesc) Int.MAX_VALUE else 2,
                overflow = TextOverflow.Ellipsis
            )
            if (facility.description.length > 100) {
                Text(
                    text = if (showFullDesc) "Daha az" else "Devamını oku",
                    color = AppColors.Primary,
                    style = MaterialTheme.typography.labelMedium,
                    modifier = Modifier.clickable { showFullDesc = !showFullDesc }
                )
            }
        }

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TagView(
                text = if (facility.amenities.isIndoor) "Kapalı Alan" else "Açık Alan",
                icon = if (facility.amenities.isIndoor) AppIcons.Indoor else AppIcons.Outdoor,
                style = TagStyle.Filled // Dolu stil (Yeşil arkaplan, beyaz yazı)
            )
            if (facility.amenities.hasParking) {
                TagView(text = "Otopark", icon = AppIcons.Parking, style = TagStyle.Outlined)
            }
        }
    }
}

// MARK: - Pitches Section
@Composable
fun PitchesSection(uiState: com.example.HaliSahaApp.ui.viewmodels.FacilityDetailUiState, onSelectPitch: (Pitch) -> Unit) {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            "Sahalar",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary // Başlık Rengi
        )

        LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            items(items = uiState.pitches) { pitch ->
                PitchSelectionCard(
                    pitch = pitch,
                    isSelected = uiState.selectedPitch?.id == pitch.id,
                    onClick = { onSelectPitch(pitch) }
                )
            }
        }
    }
}

@Composable
fun PitchSelectionCard(pitch: Pitch, isSelected: Boolean, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        // Seçiliyse Açık Yeşil, Değilse BEYAZ (Surface)
        color = if (isSelected) AppColors.Primary.copy(alpha = 0.1f) else AppColors.Surface,
        border = if (isSelected) androidx.compose.foundation.BorderStroke(2.dp, AppColors.Primary)
        else androidx.compose.foundation.BorderStroke(1.dp, Color.Gray.copy(alpha = 0.3f)),
        modifier = Modifier.width(140.dp)
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row {
                Text(
                    pitch.name,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    color = AppColors.TextPrimary // SİYAH YAZI
                )
                Spacer(modifier = Modifier.weight(1f))
                if (isSelected) Icon(Icons.Default.CheckCircle, null, tint = AppColors.Primary, modifier = Modifier.size(16.dp))
            }
            Text(
                pitch.size.displayName,
                style = MaterialTheme.typography.labelSmall,
                color = AppColors.TextSecondary // GRİ YAZI
            )
            Text(
                "${pitch.pricing.daytimePrice.toInt()} ₺",
                fontWeight = FontWeight.Medium,
                color = AppColors.Primary
            )
        }
    }
}

// MARK: - Date Selection
@Composable
fun DateSelectionSection(selectedDate: Date, onSelectDate: (Date) -> Unit) {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            "Tarih Seçin",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )

        LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            items(14) { offset ->
                val calendar = Calendar.getInstance()
                calendar.add(Calendar.DAY_OF_YEAR, offset)
                val date = calendar.time
                val isSelected = date.shortFormatted() == selectedDate.shortFormatted()

                DateSelectionButton(date = date, isSelected = isSelected) {
                    onSelectDate(date)
                }
            }
        }
    }
}

@Composable
fun DateSelectionButton(date: Date, isSelected: Boolean, onClick: () -> Unit) {
    val dayName = java.text.SimpleDateFormat("EEE", Locale("tr", "TR")).format(date)
    val dayNumber = java.text.SimpleDateFormat("d", Locale("tr", "TR")).format(date)

    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        // Seçiliyse YEŞİL, Değilse BEYAZ
        color = if (isSelected) AppColors.Primary else AppColors.Surface,
        // Seçili değilse gri kenarlık
        border = if (isSelected) null else androidx.compose.foundation.BorderStroke(1.dp, Color.Gray.copy(alpha = 0.3f)),
        modifier = Modifier.size(width = 50.dp, height = 60.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Seçiliyse BEYAZ YAZI, Değilse GRİ/SİYAH
            Text(
                dayName,
                style = MaterialTheme.typography.labelSmall,
                color = if (isSelected) Color.White else AppColors.TextSecondary
            )
            Text(
                dayNumber,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (isSelected) Color.White else AppColors.TextPrimary
            )
        }
    }
}

// MARK: - Time Slots
@Composable
fun TimeSlotsSection(uiState: com.example.HaliSahaApp.ui.viewmodels.FacilityDetailUiState, onSelectSlot: (TimeSlot) -> Unit) {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "Saat Seçin",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary
            )
            Spacer(modifier = Modifier.weight(1f))
            if (uiState.selectedStartHour != null && uiState.selectedEndHour != null) {
                Text(
                    text = String.format("%02d:00 - %02d:00", uiState.selectedStartHour, uiState.selectedEndHour),
                    color = AppColors.Primary,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        // Custom Flow Grid
        val slots = uiState.availableTimeSlots
        val columns = 4
        val rows = (slots.size + columns - 1) / columns

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            for (i in 0 until rows) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                    for (j in 0 until columns) {
                        val index = i * columns + j
                        if (index < slots.size) {
                            val slot = slots[index]
                            val isSelected = uiState.selectedStartHour?.let { start ->
                                uiState.selectedEndHour?.let { end ->
                                    slot.hour >= start && slot.hour < end
                                }
                            } ?: false

                            Box(modifier = Modifier.weight(1f)) {
                                TimeSlotButton(slot = slot, isSelected = isSelected) {
                                    onSelectSlot(slot)
                                }
                            }
                        } else {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }

        // Legend
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            LegendItem(AppColors.Primary, "Seçili")
            LegendItem(Color.Gray.copy(alpha = 0.5f), "Müsait") // Daha belirgin gri
            LegendItem(Color.Gray.copy(alpha = 0.2f), "Dolu")
        }
    }
}

@Composable
fun TimeSlotButton(slot: TimeSlot, isSelected: Boolean, onClick: () -> Unit) {
    val bgColor = when {
        isSelected -> AppColors.Primary
        !slot.isAvailable -> Color.Gray.copy(alpha = 0.1f) // Doluysa şeffaf gri
        else -> AppColors.Surface // Müsaitse Beyaz
    }

    val textColor = when {
        isSelected -> Color.White
        !slot.isAvailable -> Color.Gray.copy(alpha = 0.5f)
        else -> AppColors.TextPrimary // Siyah
    }

    val border = if (!isSelected && slot.isAvailable)
        androidx.compose.foundation.BorderStroke(1.dp, Color.Gray.copy(alpha = 0.3f))
    else null

    Surface(
        onClick = onClick,
        enabled = slot.isAvailable,
        shape = RoundedCornerShape(8.dp),
        color = bgColor,
        border = border,
        modifier = Modifier.fillMaxWidth().height(45.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = String.format("%02d:00", slot.hour),
                style = MaterialTheme.typography.labelMedium,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
                color = textColor
            )
            if (slot.price > 0 && slot.isAvailable) {
                Text(
                    text = "${slot.price.toInt()} ₺",
                    style = MaterialTheme.typography.labelSmall,
                    fontSize = 10.sp,
                    color = textColor.copy(alpha = 0.8f)
                )
            }
        }
    }
}

@Composable
fun LegendItem(color: Color, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(modifier = Modifier.size(10.dp).background(color, CircleShape))
        Spacer(modifier = Modifier.width(4.dp))
        Text(text, style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
    }
}

// MARK: - Amenities Section
@Composable
fun AmenitiesSection(facility: Facility) {
    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            "Özellikler",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )

        val amenities = facility.amenities.getActiveAmenities()
        val columns = 3
        val rows = (amenities.size + columns - 1) / columns

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            for (i in 0 until rows) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    for (j in 0 until columns) {
                        val index = i * columns + j
                        if (index < amenities.size) {
                            val (icon, name) = amenities[index]
                            Surface(
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(8.dp),
                                color = AppColors.Surface, // BEYAZ
                                border = androidx.compose.foundation.BorderStroke(1.dp, Color.Gray.copy(alpha = 0.2f))
                            ) {
                                Column(
                                    modifier = Modifier.padding(12.dp),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text(icon, fontSize = 20.sp)
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        name,
                                        style = MaterialTheme.typography.labelSmall,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis,
                                        color = AppColors.TextPrimary
                                    )
                                }
                            }
                        } else {
                            Spacer(modifier = Modifier.weight(1f))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Location Section
@Composable
fun LocationSection(facility: Facility) {
    val context = LocalContext.current

    Column(
        modifier = Modifier.padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            "Konum",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )

        // Map Preview
        val cameraPositionState = com.google.maps.android.compose.rememberCameraPositionState {
            position = com.google.android.gms.maps.model.CameraPosition.fromLatLngZoom(
                com.google.android.gms.maps.model.LatLng(facility.latitude, facility.longitude),
                14f
            )
        }

        com.google.maps.android.compose.GoogleMap(
            modifier = Modifier
                .fillMaxWidth()
                .height(150.dp)
                .clip(RoundedCornerShape(12.dp)),
            cameraPositionState = cameraPositionState,
            uiSettings = com.google.maps.android.compose.MapUiSettings(
                zoomControlsEnabled = false,
                scrollGesturesEnabled = false,
                zoomGesturesEnabled = false,
                rotationGesturesEnabled = false,
                tiltGesturesEnabled = false
            )
        ) {
            com.google.maps.android.compose.Marker(
                state = com.google.maps.android.compose.MarkerState(
                    position = com.google.android.gms.maps.model.LatLng(facility.latitude, facility.longitude)
                ),
                title = facility.name
            )
        }

        Button(
            onClick = {
                val gmmIntentUri = android.net.Uri.parse("google.navigation:q=${facility.latitude},${facility.longitude}")
                val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri)
                mapIntent.setPackage("com.google.android.apps.maps")
                try {
                    context.startActivity(mapIntent)
                } catch (e: Exception) {
                    val webIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://www.google.com/maps/search/?api=1&query=${facility.latitude},${facility.longitude}"))
                    context.startActivity(webIntent)
                }
            },
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.Surface, contentColor = AppColors.Primary),
            modifier = Modifier.fillMaxWidth(),
            border = androidx.compose.foundation.BorderStroke(1.dp, AppColors.Primary)
        ) {
            Icon(Icons.Default.Place, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Yol Tarifi Al")
        }
    }
}

// MARK: - Bottom Bar
@Composable
fun FacilityBottomBar(
    totalPrice: Double,
    duration: Int,
    canBook: Boolean,
    onBook: () -> Unit
) {
    Surface(
        shadowElevation = 16.dp, // Gölgeyi artırdım
        color = AppColors.Surface, // BEYAZ
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                if (duration > 0) {
                    Text(
                        text = "${totalPrice.toInt()} ₺",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.TextPrimary // SİYAH
                    )
                    Text(
                        text = "$duration saat",
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary // GRİ
                    )
                } else {
                    Text(
                        text = "Saat seçin",
                        style = MaterialTheme.typography.titleMedium,
                        color = AppColors.TextSecondary
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            PrimaryButton(
                text = "Rezervasyon Yap",
                onClick = onBook,
                isEnabled = canBook,
                fullWidth = false,
                size = ButtonSize.Medium
            )
        }
    }
}