package com.example.HaliSahaApp.ui.screens.admin

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

// MARK: - Admin Tab Enum
enum class AdminTab(
    val route: String,
    val title: String,
    val icon: ImageVector
) {
    DASHBOARD("admin_dashboard", "Panel", AppIcons.Home), // square.grid.2x2 ikonu material'da yoksa Home veya Dashboard
    BOOKINGS("admin_bookings", "Rezervasyonlar", AppIcons.Bookings),
    FACILITIES("admin_facilities", "Tesisler", AppIcons.Indoor),
    REPORTS("admin_reports", "Raporlar", AppIcons.Filter), // chart.bar yerine
    SETTINGS("admin_settings", "Ayarlar", AppIcons.Settings)
}

@Composable
fun AdminScreen(onLogout: () -> Unit) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    val haptic = LocalHapticFeedback.current

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = AppColors.Surface,
                contentColor = AppColors.Primary
            ) {
                AdminTab.entries.forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(imageVector = tab.icon, contentDescription = tab.title) },
                        label = { Text(tab.title) },
                        selected = currentRoute == tab.route,
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = AppColors.Primary,
                            selectedTextColor = AppColors.Primary,
                            indicatorColor = AppColors.Primary.copy(alpha = 0.1f),
                            unselectedIconColor = AppColors.TextSecondary,
                            unselectedTextColor = AppColors.TextSecondary
                        ),
                        onClick = {
                            haptic.performHapticFeedback(androidx.compose.ui.hapticfeedback.HapticFeedbackType.LongPress)
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = AdminTab.DASHBOARD.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(AdminTab.DASHBOARD.route) { AdminDashboardScreen(navController) }
            composable(AdminTab.BOOKINGS.route) { AdminBookingsScreen(navController) }
            composable(AdminTab.FACILITIES.route) { AdminFacilitiesScreen(navController) } // GÜNCELLENDİ
            composable(AdminTab.REPORTS.route) { AdminReportsScreen(navController) }       // GÜNCELLENDİ
            composable(AdminTab.SETTINGS.route) { AdminSettingsScreen(onLogout) }
        }
    }
}