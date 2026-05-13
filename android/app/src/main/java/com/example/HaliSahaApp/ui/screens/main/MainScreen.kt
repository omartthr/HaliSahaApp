package com.example.HaliSahaApp.ui.screens.main

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.HaliSahaApp.data.models.UserType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.components.PrimaryButton
import com.example.HaliSahaApp.ui.screens.home.HomeScreen
import com.example.HaliSahaApp.ui.screens.map.MapScreen
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons
import androidx.navigation.NavType
import androidx.navigation.navArgument
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.ui.screens.booking.BookingsScreen
import com.example.HaliSahaApp.ui.screens.facility.FacilityDetailScreen
import com.example.HaliSahaApp.ui.screens.facility.FacilityListScreen

// MARK: - Tab Item Enum
enum class BottomTab(
    val route: String,
    val title: String,
    val icon: ImageVector,
    val isProtected: Boolean = false // Misafir giremez
) {
    HOME("home", "Keşfet", AppIcons.Home),
    MAP("map", "Harita", AppIcons.Map),
    BOOKINGS("bookings", "Randevularım", AppIcons.Bookings, isProtected = true),
    CHAT("chat", "Sohbet", AppIcons.Chat, isProtected = true),
    PROFILE("profile", "Profil", AppIcons.Profile, isProtected = true)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(onLogout: () -> Unit) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    val currentUser by AuthService.currentUser.collectAsState()
    val isGuest = currentUser?.userType == UserType.GUEST

    // Guest Alert Bottom Sheet State
    var showGuestSheet by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState()
    val haptic = LocalHapticFeedback.current

    // Scaffold
    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = AppColors.Surface,
                contentColor = AppColors.Primary
            ) {
                BottomTab.entries.forEach { tab ->
                    // Rozet (Badge) Mantığı (Test verileri)
                    val badgeCount = when (tab) {
                        BottomTab.CHAT -> 3
                        BottomTab.BOOKINGS -> 0
                        else -> 0
                    }

                    NavigationBarItem(
                        icon = {
                            if (badgeCount > 0) {
                                BadgedBox(badge = { Badge { Text("$badgeCount") } }) {
                                    Icon(imageVector = tab.icon, contentDescription = tab.title)
                                }
                            } else {
                                Icon(imageVector = tab.icon, contentDescription = tab.title)
                            }
                        },
                        label = { Text(tab.title, maxLines = 1, fontSize = 9.sp, softWrap = false) },
                        selected = currentRoute == tab.route,
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = AppColors.Primary,
                            selectedTextColor = AppColors.Primary,
                            indicatorColor = AppColors.Primary.copy(alpha = 0.1f),
                            unselectedIconColor = AppColors.TextSecondary,
                            unselectedTextColor = AppColors.TextSecondary
                        ),
                        onClick = {  
                            // Misafir Kontrolü
                            if (isGuest && tab.isProtected) {
                                haptic.performHapticFeedback(androidx.compose.ui.hapticfeedback.HapticFeedbackType.LongPress)
                                showGuestSheet = true
                            } else {
                                navController.navigate(tab.route) {
                                    // Geri tuşuna basınca Home'a dönsün
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        // İç Navigasyon (Tab'ler arası geçiş)
        NavHost(
            navController = navController,
            startDestination = BottomTab.HOME.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            // Mevcut Tab Rotaları
            composable(BottomTab.HOME.route) { HomeScreen(navController = navController) }
            composable(BottomTab.MAP.route) { MapScreen(navController = navController) }
            composable(BottomTab.BOOKINGS.route) {
                BookingsScreen(navController = navController) // Placeholder yerine gerçek ekran
            }
            composable(BottomTab.CHAT.route) { ChatScreenPlaceholder() }
            composable(BottomTab.PROFILE.route) { ProfileScreenPlaceholder(onLogout) }

            // 👇 EKSİK OLANLARI BURAYA EKLİYORUZ 👇

            // 1. Facility Detail
            composable(
                route = Screen.FacilityDetail.route,
                arguments = listOf(navArgument("facilityId") { type = NavType.StringType })
            ) { backStackEntry ->
                val facilityId = backStackEntry.arguments?.getString("facilityId")
                if (facilityId != null) {
                    FacilityDetailScreen(
                        navController = navController,
                        facilityId = facilityId
                    )
                }
            }

            // 2. Facility List (Tümünü Gör)
            composable(Screen.FacilityList.route) {
                FacilityListScreen(navController = navController)
            }
        }
    }

    // Guest Restriction Sheet
    if (showGuestSheet) {
        ModalBottomSheet(
            onDismissRequest = { showGuestSheet = false },
            sheetState = sheetState,
            containerColor = AppColors.Surface
        ) {
            GuestRestrictionContent(
                onLogin = {
                    showGuestSheet = false
                    AuthService.signOut() // Çıkış yapıp Login'e atacak (Main içindeki listener sayesinde)
                    onLogout()
                },
                onDismiss = { showGuestSheet = false }
            )
        }
    }
}

@Composable
fun GuestRestrictionContent(onLogin: () -> Unit, onDismiss: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp)
            .padding(bottom = 24.dp), // Safe area
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Icon
        Surface(
            modifier = Modifier.size(80.dp),
            shape = androidx.compose.foundation.shape.CircleShape,
            color = AppColors.Primary.copy(alpha = 0.1f)
        ) {
            Box(contentAlignment = Alignment.Center) {
                Icon(
                    imageVector = AppIcons.Person, // PersonBadgeExclamation simgesi material'da yok, Person kullandık
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(40.dp)
                )
            }
        }

        // Text
        Text(
            text = "Üye Girişi Gerekli",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )

        Text(
            text = "Bu özelliği kullanmak için üye girişi yapmanız veya kayıt olmanız gerekiyor.",
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Buttons
        PrimaryButton(
            text = "Giriş Yap / Kayıt Ol",
            onClick = onLogin,
            icon = AppIcons.Person
        )

        TextButton(onClick = onDismiss) {
            Text("Vazgeç", color = AppColors.TextSecondary)
        }
    }
}