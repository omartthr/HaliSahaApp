package com.example.HaliSahaApp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.HaliSahaApp.data.models.UserType
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.ui.screens.auth.AdminRegisterScreen
import com.example.HaliSahaApp.ui.screens.auth.ForgotPasswordScreen
import com.example.HaliSahaApp.ui.screens.auth.LoginScreen
import com.example.HaliSahaApp.ui.screens.auth.RegisterScreen
import com.example.HaliSahaApp.ui.screens.facility.FacilityDetailScreen
import com.example.HaliSahaApp.ui.screens.facility.FacilityListScreen
import com.example.HaliSahaApp.ui.screens.main.MainScreen
import com.example.HaliSahaApp.ui.screens.splash.SplashScreen
import com.example.HaliSahaApp.ui.theme.HaliSahaAppTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
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
                val isGuest = currentUser?.userType == UserType.GUEST

                if (isAuthenticated || isGuest) {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
                    }
                } else {
                    // Değilse -> Login'e git
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
    }
}