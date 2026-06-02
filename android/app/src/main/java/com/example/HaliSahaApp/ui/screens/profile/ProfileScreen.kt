package com.example.HaliSahaApp.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.UserType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.ui.viewmodels.ProfileViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

// MARK: - Profile Screen
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    navController: NavController,
    onLogout: () -> Unit,
    viewModel: ProfileViewModel = viewModel()
) {
    val currentUser by AuthService.currentUser.collectAsState()
    val bookingStats by viewModel.bookingStats.collectAsState()

    // İlk yüklemede verileri çek
    LaunchedEffect(Unit) {
        viewModel.loadAll()
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        "Profil",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 17.sp
                    )
                },
                actions = {
                    IconButton(onClick = {
                        navController.navigate(Screen.ProfileSettings.route)
                    }) {
                        Icon(
                            imageVector = AppIcons.Settings,
                            contentDescription = "Ayarlar",
                            tint = AppColors.TextPrimary
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                )
            )
        },
        contentWindowInsets = WindowInsets(0.dp)
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(AppColors.Background)
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // 1. Hero Section (Avatar + İsim + Pozisyon)
            HeroSection(
                fullName = currentUser?.fullName ?: "Kullanıcı",
                username = currentUser?.username ?: "",
                positionIcon = currentUser?.preferredPositionEnum?.icon ?: "👤",
                positionName = currentUser?.preferredPositionEnum?.displayName ?: "Belirtilmemiş",
                initials = getInitials(currentUser?.firstName, currentUser?.lastName),
                profileImageUrl = currentUser?.profileImageURL
            )

            // 2. Stats Card
            StatsCard(
                totalMatches = bookingStats.total.toString(),
                attendanceRate = if (bookingStats.total > 0)
                    "%${(bookingStats.completed * 100) / maxOf(bookingStats.total, 1)}"
                else "—",
                reliabilityScore = String.format("%.1f", currentUser?.reliabilityScore ?: 0.0)
            )

            // 3. Quick Actions Grid
            QuickActionsGrid(
                favoritesCount = viewModel.favoritesCount,
                completedMatches = bookingStats.completed,
                upcomingCount = bookingStats.upcoming
            )

            // 4. Account Info Section
            AccountInfoSection(
                email = currentUser?.email ?: "—",
                phone = currentUser?.phone?.ifEmpty { "—" } ?: "—",
                memberSince = viewModel.memberSinceText
            )

            // 5. Version Footer
            VersionFooter()
        }
    }
}

// MARK: - Hero Section
@Composable
private fun HeroSection(
    fullName: String,
    username: String,
    positionIcon: String,
    positionName: String,
    initials: String,
    profileImageUrl: String?
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 18.dp),
        contentAlignment = Alignment.TopCenter
    ) {
        // Yeşil gradient kart arka planı
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 58.dp)
                .height(240.dp)
                .clip(RoundedCornerShape(24.dp))
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            Color(0xFF3E7F37),
                            Color(0xFF28652A)
                        ),
                        start = Offset(0f, 0f),
                        end = Offset(Float.POSITIVE_INFINITY, Float.POSITIVE_INFINITY)
                    )
                )
        ) {
            // Dekoratif daireler
            Box(
                modifier = Modifier
                    .size(220.dp)
                    .offset(x = 160.dp, y = (-25).dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.10f))
            )
            Box(
                modifier = Modifier
                    .size(150.dp)
                    .offset(x = (-150).dp, y = 95.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.08f))
            )
        }

        // Avatar + Bilgiler (kartın üstünde)
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(0.dp)
        ) {
            // Avatar
            Box(contentAlignment = Alignment.BottomEnd) {
                Surface(
                    modifier = Modifier
                        .size(124.dp)
                        .shadow(8.dp, CircleShape),
                    shape = CircleShape,
                    color = Color.Transparent,
                    border = androidx.compose.foundation.BorderStroke(5.dp, AppColors.Background)
                ) {
                    // Avatar placeholder veya gerçek fotoğraf
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(Color(0xFF4CAF50), Color(0xFF2E7D32))
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = initials,
                            fontSize = 38.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White
                        )
                    }
                }

                // Kamera butonu
                Surface(
                    modifier = Modifier
                        .size(40.dp)
                        .offset(x = (-3).dp, y = (-4).dp),
                    shape = CircleShape,
                    color = Color(0xFF69A95B),
                    border = androidx.compose.foundation.BorderStroke(4.dp, AppColors.Background)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Filled.CameraAlt,
                            contentDescription = "Fotoğraf Değiştir",
                            tint = Color.White,
                            modifier = Modifier.size(15.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // İsim
            Text(
                text = fullName,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            // @username
            if (username.isNotEmpty()) {
                Text(
                    text = "@$username",
                    fontSize = 14.sp,
                    color = Color.White.copy(alpha = 0.68f),
                    maxLines = 1
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Pozisyon badge
            Surface(
                shape = RoundedCornerShape(50),
                color = Color.White.copy(alpha = 0.16f)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(text = positionIcon, fontSize = 12.sp)
                    Text(
                        text = positionName,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White.copy(alpha = 0.85f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // "Profili Düzenle" butonu
            Surface(
                shape = RoundedCornerShape(50),
                color = Color.White,
                shadowElevation = 4.dp,
                modifier = Modifier.padding(top = 2.dp)
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 22.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Filled.Edit,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = Color(0xFF2E7D32)
                    )
                    Text(
                        text = "Profili Düzenle",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF2E7D32)
                    )
                }
            }
        }
    }
}

// MARK: - Stats Card
@Composable
private fun StatsCard(
    totalMatches: String,
    attendanceRate: String,
    reliabilityScore: String
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = AppColors.CardBackground,
        shadowElevation = 2.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            StatTile(
                icon = Icons.Filled.SportsSoccer,
                value = totalMatches,
                label = "Toplam Maç"
            )

            // Divider
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(50.dp)
                    .background(AppColors.TextTertiary.copy(alpha = 0.3f))
            )

            StatTile(
                icon = Icons.Filled.Groups,
                value = attendanceRate,
                label = "Katılım"
            )

            // Divider
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(50.dp)
                    .background(AppColors.TextTertiary.copy(alpha = 0.3f))
            )

            StatTile(
                icon = Icons.Filled.Star,
                value = reliabilityScore,
                label = "Güvenilirlik",
                valueColor = Color(0xFFFF9800)
            )
        }
    }
}

@Composable
private fun StatTile(
    icon: ImageVector,
    value: String,
    label: String,
    valueColor: Color = AppColors.TextPrimary
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
        modifier = Modifier.width(100.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(18.dp),
            tint = Color(0xFF2E7D32)
        )
        Text(
            text = value,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = valueColor
        )
        Text(
            text = label,
            fontSize = 10.sp,
            color = AppColors.TextSecondary
        )
    }
}

// MARK: - Quick Actions Grid
@Composable
private fun QuickActionsGrid(
    favoritesCount: Int,
    completedMatches: Int,
    upcomingCount: Int
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Hızlı Erişim",
            fontSize = 17.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 4.dp)
        )

        // Favorilerim + Geçmişim yan yana
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            QuickActionTile(
                icon = Icons.Filled.Favorite,
                iconColor = Color(0xFFE53935),
                title = "Favorilerim",
                subtitle = if (favoritesCount == 0) "Henüz favori yok" else "$favoritesCount saha",
                badge = favoritesCount,
                modifier = Modifier.weight(1f)
            )

            QuickActionTile(
                icon = Icons.Filled.EmojiEvents,
                iconColor = Color(0xFFFF9800),
                title = "Geçmişim",
                subtitle = "$completedMatches tamamlandı",
                badge = 0,
                modifier = Modifier.weight(1f)
            )
        }

        // Randevularım — tam genişlikte, ortalı
        QuickActionTileCentered(
            icon = Icons.Filled.ConfirmationNumber,
            iconColor = Color(0xFF1E88E5),
            title = "Randevularım",
            subtitle = if (upcomingCount == 0) "Yaklaşan yok" else "$upcomingCount yaklaşan"
        )
    }
}

@Composable
private fun QuickActionTile(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String,
    badge: Int,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        color = AppColors.CardBackground,
        shadowElevation = 2.dp
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon with badge
            Box {
                Surface(
                    modifier = Modifier.size(44.dp),
                    shape = RoundedCornerShape(10.dp),
                    color = iconColor.copy(alpha = 0.15f)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = icon,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                            tint = iconColor
                        )
                    }
                }

                if (badge > 0) {
                    Surface(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = 6.dp, y = (-6).dp),
                        shape = RoundedCornerShape(50),
                        color = Color(0xFFE53935),
                        border = androidx.compose.foundation.BorderStroke(2.dp, AppColors.CardBackground)
                    ) {
                        Text(
                            text = "$badge",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
            }

            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = subtitle,
                    fontSize = 12.sp,
                    color = AppColors.TextSecondary,
                    maxLines = 1
                )
            }
        }
    }
}

@Composable
private fun QuickActionTileCentered(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        color = AppColors.CardBackground,
        shadowElevation = 2.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 14.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier.size(44.dp),
                shape = RoundedCornerShape(10.dp),
                color = iconColor.copy(alpha = 0.15f)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = iconColor
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = subtitle,
                    fontSize = 12.sp,
                    color = AppColors.TextSecondary
                )
            }
        }
    }
}

// MARK: - Account Info Section
@Composable
private fun AccountInfoSection(
    email: String,
    phone: String,
    memberSince: String
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Hesap Bilgileri",
            fontSize = 17.sp,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 4.dp)
        )

        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            color = AppColors.CardBackground,
            shadowElevation = 2.dp
        ) {
            Column {
                AccountInfoRow(
                    icon = Icons.Filled.Email,
                    iconColor = Color(0xFF2E7D32),
                    title = "E-posta",
                    value = email
                )

                HorizontalDivider(
                    modifier = Modifier.padding(start = 56.dp),
                    color = AppColors.TextTertiary.copy(alpha = 0.2f)
                )

                AccountInfoRow(
                    icon = Icons.Filled.Phone,
                    iconColor = Color(0xFF2E7D32),
                    title = "Telefon",
                    value = phone
                )

                HorizontalDivider(
                    modifier = Modifier.padding(start = 56.dp),
                    color = AppColors.TextTertiary.copy(alpha = 0.2f)
                )

                AccountInfoRow(
                    icon = Icons.Filled.CalendarMonth,
                    iconColor = Color(0xFF2E7D32),
                    title = "Üyelik",
                    value = memberSince
                )
            }
        }
    }
}

@Composable
private fun AccountInfoRow(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Surface(
            modifier = Modifier.size(36.dp),
            shape = RoundedCornerShape(8.dp),
            color = iconColor.copy(alpha = 0.12f)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = iconColor
                )
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = title,
                fontSize = 12.sp,
                color = AppColors.TextSecondary
            )
            Text(
                text = value,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        Spacer(modifier = Modifier.weight(1f))
    }
}

// MARK: - Version Footer
@Composable
private fun VersionFooter() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = "ALO Halısaha",
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            color = AppColors.TextSecondary
        )
        Text(
            text = "Versiyon 1.0",
            fontSize = 10.sp,
            color = AppColors.TextSecondary
        )
    }
}

// MARK: - Helper
private fun getInitials(firstName: String?, lastName: String?): String {
    val first = firstName?.firstOrNull()?.uppercase() ?: ""
    val last = lastName?.firstOrNull()?.uppercase() ?: ""
    val combined = first + last
    return combined.ifEmpty { "?" }
}
