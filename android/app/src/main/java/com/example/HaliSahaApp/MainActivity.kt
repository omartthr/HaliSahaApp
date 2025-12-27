package com.example.HaliSahaApp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.ui.screens.auth.AdminRegisterScreen
import com.example.HaliSahaApp.ui.screens.auth.ForgotPasswordScreen
import com.example.HaliSahaApp.ui.screens.auth.LoginScreen
import com.example.HaliSahaApp.ui.screens.auth.RegisterScreen
import com.example.HaliSahaApp.ui.screens.main.MainScreenPlaceholder
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
    // Auth durumunu anlık takip et
    val isAuthenticated by AuthService.isAuthenticated.collectAsState()

    // Başlangıç rotamız Splash. Splash bittiğinde duruma göre yönlendirecek.
    NavHost(navController = navController, startDestination = Screen.Splash.route) {

        // 1. SPLASH SCREEN
        composable(Screen.Splash.route) {
            SplashScreen(onSplashFinished = {
                // Yönlendirme Mantığı (Swift ile aynı)
                if (isAuthenticated) {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
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

        // 4. FORGOT PASSWORD SCREEN
        composable(Screen.ForgotPassword.route) {
            // ViewModel paylaşımı gerekmediği için burada yeni instance oluşturabiliriz
            // veya Login'den pass edebiliriz. Basitlik adına burada oluşturuyoruz.
            ForgotPasswordScreen(navController = navController, viewModel = viewModel())
        }

        // 5. ADMIN REGISTER SCREEN
        composable(Screen.AdminRegister.route) { // Screen.kt'ye bunu eklediğinden emin ol
            AdminRegisterScreen(navController = navController, viewModel = viewModel())
        }

        // 6. MAIN SCREEN (Giriş yapıldıktan sonra)
        composable(Screen.Main.route) {
            MainScreenPlaceholder(onLogout = {
                // Çıkış yapılınca Login'e at ve geçmişi temizle
                navController.navigate(Screen.Login.route) {
                    popUpTo(0) { inclusive = true } // Tüm stack'i temizle
                }
            })
        }
    }
}