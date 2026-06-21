package com.example.HaliSahaApp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.HaliSahaApp.data.models.UserType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.ui.screens.admin.AdminScreen
import com.example.HaliSahaApp.ui.screens.auth.AdminRegisterScreen
import com.example.HaliSahaApp.ui.screens.auth.ForgotPasswordScreen
import com.example.HaliSahaApp.ui.screens.auth.LoginScreen
import com.example.HaliSahaApp.ui.screens.auth.RegisterScreen
import com.example.HaliSahaApp.ui.screens.facility.FacilityDetailScreen
import com.example.HaliSahaApp.ui.screens.facility.FacilityListScreen
import com.example.HaliSahaApp.ui.screens.main.MainScreen
import com.example.HaliSahaApp.ui.screens.splash.SplashScreen
import com.example.HaliSahaApp.ui.screens.superadmin.SuperAdminScreen
import com.example.HaliSahaApp.ui.screens.admin.onboarding.AdminOnboardingScreen
import com.example.HaliSahaApp.ui.screens.reviews.ReviewsListScreen
import com.example.HaliSahaApp.ui.screens.notifications.NotificationsListScreen
import com.example.HaliSahaApp.ui.theme.HaliSahaAppTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Edge-to-edge modunu etkinleştir (Android 15+ zorunlu)
        // Edge-to-edge modunu etkinleştir
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            HaliSahaAppTheme {
                HaliSahaRoot()
            }
        }
    }
}

@Composable
fun HaliSahaRoot() {
    val navController = rememberNavController()

    // Auth durumlarını dinle
    val isAuthenticated by AuthService.isAuthenticated.collectAsState()
    val currentUser by AuthService.currentUser.collectAsState()

    // Başlangıç rotamız Splash
    NavHost(navController = navController, startDestination = Screen.Splash.route) {

        // 1. SPLASH SCREEN
        composable(Screen.Splash.route) {
            SplashScreen(onSplashFinished = {
                // YÖNLENDİRME MANTIĞI GÜNCELLENDİ:
                // Giriş yapmışsa VEYA Misafir ise -> Ana Sayfaya git
                val isGuest = currentUser?.userTypeEnum == UserType.GUEST
                val isAdmin = currentUser?.userTypeEnum == UserType.ADMIN
                val isSuperAdmin = currentUser?.userTypeEnum == UserType.SUPER_ADMIN

                if (isAuthenticated || isGuest) {
                    if (isSuperAdmin) {
                        navController.navigate(Screen.SuperAdminMain.route) {
                            popUpTo(Screen.Splash.route) { inclusive = true }
                        }
                    } else if (isAdmin) {
                        navController.navigate(Screen.AdminOnboarding.route) { // Go to Onboarding/Verification first
                            popUpTo(Screen.Splash.route) { inclusive = true }
                        }
                    } else {
                        navController.navigate(Screen.Main.route) { // Değilse Ana Sayfaya
                            popUpTo(Screen.Splash.route) { inclusive = true }
                        }
                    }
                } else {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
                    }
                }
            })
        }

        // 2. LOGIN SCREEN
        composable(Screen.Login.route) {
            LoginScreen(navController = navController)
        }

        // 3. REGISTER SCREEN
        composable(Screen.Register.route) {
            RegisterScreen(navController = navController)
        }

        // 4. FORGOT PASSWORD
        composable(Screen.ForgotPassword.route) {
            ForgotPasswordScreen(navController = navController, viewModel = viewModel())
        }

        // 5. ADMIN REGISTER
        composable(Screen.AdminRegister.route) {
            AdminRegisterScreen(navController = navController, viewModel = viewModel())
        }

        // 6. MAIN SCREEN (MainTabView)
        composable(Screen.Main.route) {
            // MainScreenPlaceholder yerine gerçek MainScreen'i kullanıyoruz
            MainScreen(onLogout = {
                navController.navigate(Screen.Login.route) {
                    popUpTo(0) { inclusive = true }
                }
            })
        }
        composable("facility_list") {
            FacilityListScreen(navController = navController)
        }
        composable(
            route = Screen.FacilityDetail.route,
            // Arguments tanımı opsiyonel çünkü String parametre default olarak alınır
        ) { backStackEntry ->
            val facilityId = backStackEntry.arguments?.getString("facilityId")
            if (facilityId != null) {
                FacilityDetailScreen(
                    navController = navController,
                    facilityId = facilityId
                )
            }
        }

        // 8. FACILITY LIST SCREEN (Zaten eklemiştik ama kontrol et)
        composable(Screen.FacilityList.route) {
            FacilityListScreen(navController = navController)
        }
        composable(Screen.AdminMain.route) {
            AdminScreen(onLogout = {
                navController.navigate(Screen.Login.route) {
                    popUpTo(0) { inclusive = true }
                }
            })
        }
        
        composable(Screen.SuperAdminMain.route) {
            SuperAdminScreen(onLogout = {
                navController.navigate(Screen.Login.route) {
                    popUpTo(0) { inclusive = true }
                }
            })
        }
        
        composable(Screen.AdminOnboarding.route) {
            AdminOnboardingScreen(
                onApproved = {
                    navController.navigate(Screen.AdminMain.route) {
                        popUpTo(Screen.AdminOnboarding.route) { inclusive = true }
                    }
                },
                onLogout = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(0) { inclusive = true }
                    }
                }
            )
        }
        
        composable(
            route = Screen.ReviewsList.route,
            arguments = listOf(navArgument("facilityId") { type = NavType.StringType })
        ) { backStackEntry ->
            val facilityId = backStackEntry.arguments?.getString("facilityId")
            if (facilityId != null) {
                ReviewsListScreen(
                    facilityId = facilityId,
                    onBack = { navController.popBackStack() }
                )
            }
        }
        
        composable(Screen.NotificationsList.route) {
            NotificationsListScreen(onBack = { navController.popBackStack() })
        }
        
        composable(
            route = Screen.WriteReview.route,
            arguments = listOf(navArgument("bookingId") { type = NavType.StringType })
        ) { backStackEntry ->
            val bookingId = backStackEntry.arguments?.getString("bookingId")
            if (bookingId != null) {
                com.example.HaliSahaApp.ui.screens.reviews.WriteReviewScreen(
                    bookingId = bookingId,
                    onBack = { navController.popBackStack() },
                    onSuccess = { navController.popBackStack() }
                )
            }
        }
    }
}
