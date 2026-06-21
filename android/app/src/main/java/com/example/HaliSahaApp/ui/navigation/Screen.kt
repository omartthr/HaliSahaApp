package com.example.HaliSahaApp.ui.navigation

sealed class Screen(val route: String) {
    object Splash : Screen("splash")
    object Login : Screen("login")
    object Main : Screen("main")
    object Register : Screen("register")
    object ForgotPassword : Screen("forgot_password")
    object AdminRegister : Screen("admin_register")
    object FacilityList : Screen("facility_list")
    object FacilityDetail : Screen("facility_detail/{facilityId}") {
        fun createRoute(facilityId: String) = "facility_detail/$facilityId"
    }
    object AdminMain : Screen("admin_main")
    object SuperAdminMain : Screen("superadmin_main")
    object AdminOnboarding : Screen("admin_onboarding")
    object ReviewsList : Screen("reviews/{facilityId}") {
        fun createRoute(facilityId: String) = "reviews/$facilityId"
    }
    object WriteReview : Screen("write_review/{bookingId}") {
        fun createRoute(bookingId: String) = "write_review/$bookingId"
    }
    object NotificationsList : Screen("notifications")
    object ChatDetail : Screen("chat_detail/{groupId}") {
        fun createRoute(groupId: String) = "chat_detail/$groupId"
    }
    object ProfileSettings : Screen("profile_settings")
    object CreateMatchPost : Screen("create_match_post/{bookingId}") {
        fun createRoute(bookingId: String) = "create_match_post/$bookingId"
    }
}