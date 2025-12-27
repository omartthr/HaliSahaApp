package com.example.HaliSahaApp.ui.navigation

sealed class Screen(val route: String) {
    object Splash : Screen("splash")
    object Login : Screen("login")
    object Main : Screen("main")
    object Register : Screen("register")
    object ForgotPassword : Screen("forgot_password")
    object AdminRegister : Screen("admin_register")

}