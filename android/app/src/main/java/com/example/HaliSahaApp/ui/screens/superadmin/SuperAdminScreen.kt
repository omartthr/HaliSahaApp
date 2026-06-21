package com.example.HaliSahaApp.ui.screens.superadmin

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

enum class SuperAdminTab(val route: String, val title: String, val icon: ImageVector) {
    PENDING("superadmin_pending", "Onay Bekleyen", AppIcons.Time),
    ALL_ADMINS("superadmin_all", "Tüm İşletmeler", AppIcons.Profile),
    STATS("superadmin_stats", "İstatistikler", AppIcons.Filter)
}

@Composable
fun SuperAdminScreen(onLogout: () -> Unit) {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = AppColors.Surface,
                contentColor = AppColors.Primary
            ) {
                SuperAdminTab.entries.forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = tab.title) },
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
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = SuperAdminTab.PENDING.route,
            modifier = Modifier.padding(padding)
        ) {
            composable(SuperAdminTab.PENDING.route) { 
                PendingApprovalsListScreen(navController, onLogout) 
            }
            composable(SuperAdminTab.ALL_ADMINS.route) { 
                AllAdminsListScreen(navController) 
            }
            composable(SuperAdminTab.STATS.route) { 
                SuperAdminStatsScreen() 
            }
            
            composable("admin_review/{adminId}") { backStackEntry ->
                val adminId = backStackEntry.arguments?.getString("adminId") ?: return@composable
                AdminReviewDetailScreen(
                    adminId = adminId,
                    onBack = { navController.popBackStack() }
                )
            }
        }
    }
}
