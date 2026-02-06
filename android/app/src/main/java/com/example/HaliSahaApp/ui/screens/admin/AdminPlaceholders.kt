package com.example.HaliSahaApp.ui.screens.admin

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.components.PrimaryButton
import com.example.HaliSahaApp.ui.screens.main.GenericPlaceholder
import com.example.HaliSahaApp.utils.AppIcons

@Composable
fun AdminDashboardPlaceholder() {
    GenericPlaceholder("Yönetim Paneli", AppIcons.Home, "İstatistikler ve özet burada olacak.")
}

@Composable
fun AdminBookingsPlaceholder() {
    GenericPlaceholder("Rezervasyon Yönetimi", AppIcons.Bookings, "Gelen rezervasyonları buradan yönetin.")
}

@Composable
fun AdminFacilitiesPlaceholder() {
    GenericPlaceholder("Tesislerim", AppIcons.Indoor, "Tesislerinizi ve sahalarınızı düzenleyin.")
}

@Composable
fun AdminReportsPlaceholder() {
    GenericPlaceholder("Raporlar", AppIcons.Filter, "Gelir ve doluluk raporları.")
}

@Composable
fun AdminSettingsPlaceholder(onLogout: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        GenericPlaceholder("Ayarlar", AppIcons.Settings, "Uygulama ve hesap ayarları.")

        Spacer(modifier = Modifier.height(32.dp))

        PrimaryButton(
            text = "Çıkış Yap",
            onClick = {
                AuthService.signOut()
                onLogout()
            },
            icon = AppIcons.Logout,
            style = com.example.HaliSahaApp.ui.components.ButtonStyle.Destructive
        )
    }
}