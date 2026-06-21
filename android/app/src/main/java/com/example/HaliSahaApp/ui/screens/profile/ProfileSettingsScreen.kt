package com.example.HaliSahaApp.ui.screens.profile

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.utils.AppColors
import java.util.Calendar

// MARK: - Profile Settings Screen
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileSettingsScreen(
    navController: NavController,
    onLogout: () -> Unit
) {
    val context = LocalContext.current

    // UI State
    var matchReminders by remember { mutableStateOf(true) }
    var showLogoutDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showFinalDeleteDialog by remember { mutableStateOf(false) }
    var showResetOnboardingDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        "Ayarlar",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 17.sp
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Geri"
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                )
            )
        }
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
            // HESAP
            SettingsSection(title = "HESAP") {
                SettingsRow(
                    icon = Icons.Filled.Person,
                    iconColor = Color(0xFF2E7D32),
                    title = "Profili Düzenle",
                    showChevron = true,
                    onClick = {
                        Toast.makeText(context, "Profil düzenleme yakında eklenecek", Toast.LENGTH_SHORT).show()
                    }
                )
                SettingsDivider()
                SettingsRow(
                    icon = Icons.Filled.CreditCard,
                    iconColor = Color(0xFF2E7D32),
                    title = "Fatura Adresi",
                    showChevron = true,
                    onClick = {
                        Toast.makeText(context, "Fatura adresi yakında eklenecek", Toast.LENGTH_SHORT).show()
                    }
                )
                SettingsDivider()
                SettingsRow(
                    icon = Icons.Filled.Lock,
                    iconColor = Color(0xFF2E7D32),
                    title = "Şifre Değiştir",
                    showChevron = true,
                    onClick = {
                        Toast.makeText(context, "Şifre değiştirme yakında eklenecek", Toast.LENGTH_SHORT).show()
                    }
                )
            }

            // BİLDİRİMLER
            SettingsSection(
                title = "BİLDİRİMLER",
                footer = "Push ve sohbet bildirimleri yakında eklenecek."
            ) {
                // Maç Hatırlatmaları toggle
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    SettingsIconBox(
                        icon = Icons.Filled.CalendarMonth,
                        iconColor = Color(0xFF9C27B0)
                    )
                    Spacer(modifier = Modifier.width(14.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Maç Hatırlatmaları",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = "Maçtan 24 ve 2 saat önce hatırlatma alırsın",
                            fontSize = 11.sp,
                            color = AppColors.TextSecondary
                        )
                    }
                    Switch(
                        checked = matchReminders,
                        onCheckedChange = { matchReminders = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = Color(0xFF2E7D32),
                            uncheckedThumbColor = Color.White,
                            uncheckedTrackColor = AppColors.TextTertiary
                        )
                    )
                }
                SettingsDivider()
                // Bildirimler Açık
                SettingsRow(
                    icon = Icons.Filled.CheckCircle,
                    iconColor = Color(0xFF4CAF50),
                    title = "Bildirimler Açık",
                    showChevron = false
                )
            }

            // UYGULAMA
            SettingsSection(title = "UYGULAMA") {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    SettingsIconBox(
                        icon = Icons.Filled.Language,
                        iconColor = Color(0xFF3F51B5)
                    )
                    Spacer(modifier = Modifier.width(14.dp))
                    Text(
                        text = "Dil",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "Türkçe",
                        fontSize = 14.sp,
                        color = AppColors.TextSecondary
                    )
                }
                SettingsDivider()
                SettingsRow(
                    icon = Icons.Filled.Storage,
                    iconColor = Color(0xFF757575),
                    title = "Veri ve Depolama",
                    showChevron = true,
                    onClick = {
                        Toast.makeText(context, "Veri yönetimi yakında eklenecek", Toast.LENGTH_SHORT).show()
                    }
                )
            }

            // DESTEK VE SÖZLEŞMELER
            SettingsSection(title = "DESTEK VE SÖZLEŞMELER") {
                SettingsRow(
                    icon = Icons.AutoMirrored.Filled.HelpOutline,
                    iconColor = Color(0xFF1E88E5),
                    title = "Yardım Merkezi",
                    showChevron = false,
                    onClick = {
                        Toast.makeText(context, "Yardım merkezi yakında eklenecek", Toast.LENGTH_SHORT).show()
                    }
                )
                SettingsDivider()
                SettingsRow(
                    icon = Icons.AutoMirrored.Filled.Send,
                    iconColor = Color(0xFF1E88E5),
                    title = "Bize Ulaşın",
                    showChevron = false,
                    onClick = {
                        try {
                            val intent = Intent(Intent.ACTION_SENDTO).apply {
                                data = Uri.parse("mailto:destek@alohalısaha.com")
                            }
                            context.startActivity(intent)
                        } catch (e: Exception) {
                            Toast.makeText(context, "E-posta uygulaması bulunamadı", Toast.LENGTH_SHORT).show()
                        }
                    }
                )
                SettingsDivider()
                SettingsRow(
                    icon = Icons.Filled.Description,
                    iconColor = Color(0xFF757575),
                    title = "Kullanım Koşulları",
                    showChevron = false,
                    onClick = {
                        Toast.makeText(context, "Kullanım koşulları yakında eklenecek", Toast.LENGTH_SHORT).show()
                    }
                )
                SettingsDivider()
                SettingsRow(
                    icon = Icons.Filled.Security,
                    iconColor = Color(0xFF4CAF50),
                    title = "Gizlilik Politikası",
                    showChevron = false,
                    onClick = {
                        Toast.makeText(context, "Gizlilik politikası yakında eklenecek", Toast.LENGTH_SHORT).show()
                    }
                )
            }

            // ÇIKIŞ YAP + HESABI SİL
            SettingsSection {
                SettingsRow(
                    icon = Icons.AutoMirrored.Filled.ExitToApp,
                    iconColor = Color(0xFFFF9800),
                    title = "Çıkış Yap",
                    titleColor = Color(0xFFFF9800),
                    showChevron = false,
                    onClick = { showLogoutDialog = true }
                )
                SettingsDivider()
                SettingsRow(
                    icon = Icons.Filled.Delete,
                    iconColor = Color(0xFFF44336),
                    title = "Hesabı Sil",
                    titleColor = Color(0xFFF44336),
                    showChevron = false,
                    onClick = { showDeleteDialog = true }
                )
            }

            // GELİŞTİRİCİ
            SettingsSection(
                title = "GELİŞTİRİCİ",
                footer = "Onboarding cevaplarını siler ve çıkış yapar. Tekrar giriş yaptığında onboarding'i baştan görürsün."
            ) {
                SettingsRow(
                    icon = Icons.Filled.Refresh,
                    iconColor = Color(0xFF9C27B0),
                    title = "Onboarding'i Sıfırla (Test)",
                    titleColor = Color(0xFF9C27B0),
                    showChevron = false,
                    onClick = { showResetOnboardingDialog = true }
                )
            }

            // VERSİYON
            SettingsSection {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Versiyon",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Spacer(modifier = Modifier.weight(1f))
                    Text(
                        text = "1.0 (1)",
                        fontSize = 14.sp,
                        color = AppColors.TextSecondary
                    )
                }
            }

            // Copyright Footer
            Text(
                text = "ALO Halısaha © ${Calendar.getInstance().get(Calendar.YEAR)}",
                fontSize = 11.sp,
                color = AppColors.TextSecondary,
                modifier = Modifier.fillMaxWidth(),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }
    }

    // MARK: - Dialogs

    // Çıkış Yap Dialog
    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text("Çıkış Yap") },
            text = { Text("Hesabınızdan çıkış yapmak istediğinizden emin misiniz?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showLogoutDialog = false
                        AuthService.signOut()
                        onLogout()
                    }
                ) {
                    Text("Çıkış Yap", color = Color(0xFFF44336))
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text("Vazgeç")
                }
            }
        )
    }

    // Hesabı Sil - İlk Onay
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Hesabı Sil") },
            text = {
                Text("Hesabınızı silmek üzeresiniz. Tüm verileriniz kalıcı olarak silinecek ve bu işlem geri alınamaz.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        showFinalDeleteDialog = true
                    }
                ) {
                    Text("Devam Et", color = Color(0xFFF44336))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Vazgeç")
                }
            }
        )
    }

    // Hesabı Sil - Son Onay
    if (showFinalDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showFinalDeleteDialog = false },
            title = { Text("Son Onay") },
            text = {
                Text("Bu işlemi onaylamak için \"Hesabı Sil\" seçeneğine dokunun.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showFinalDeleteDialog = false
                        Toast.makeText(context, "Hesap silme işlemi yakında eklenecek", Toast.LENGTH_LONG).show()
                    }
                ) {
                    Text("Hesabı Sil", color = Color(0xFFF44336))
                }
            },
            dismissButton = {
                TextButton(onClick = { showFinalDeleteDialog = false }) {
                    Text("Vazgeç")
                }
            }
        )
    }

    // Onboarding Sıfırla Dialog
    if (showResetOnboardingDialog) {
        AlertDialog(
            onDismissRequest = { showResetOnboardingDialog = false },
            title = { Text("Onboarding'i Sıfırla") },
            text = {
                Text("Onboarding cevapların silinecek ve hesabından çıkış yapılacaksın. Tekrar giriş yaptığında onboarding'i baştan göreceksin.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showResetOnboardingDialog = false
                        AuthService.signOut()
                        onLogout()
                    }
                ) {
                    Text("Sıfırla ve Çıkış Yap", color = Color(0xFFF44336))
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetOnboardingDialog = false }) {
                    Text("Vazgeç")
                }
            }
        )
    }
}

// MARK: - Settings Section
@Composable
private fun SettingsSection(
    title: String? = null,
    footer: String? = null,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (title != null) {
            Text(
                text = title,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = AppColors.TextSecondary,
                letterSpacing = 0.5.sp,
                modifier = Modifier.padding(start = 4.dp)
            )
        }

        Surface(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            color = AppColors.CardBackground
        ) {
            Column(content = content)
        }

        if (footer != null) {
            Text(
                text = footer,
                fontSize = 11.sp,
                color = AppColors.TextSecondary,
                modifier = Modifier.padding(horizontal = 4.dp),
                lineHeight = 16.sp
            )
        }
    }
}

// MARK: - Settings Row
@Composable
private fun SettingsRow(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    titleColor: Color = AppColors.TextPrimary,
    showChevron: Boolean = false,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (onClick != null) Modifier.clickable(onClick = onClick)
                else Modifier
            )
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        SettingsIconBox(icon = icon, iconColor = iconColor)

        Text(
            text = title,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = titleColor,
            modifier = Modifier.weight(1f)
        )

        if (showChevron) {
            Icon(
                imageVector = Icons.Filled.ChevronRight,
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = AppColors.TextTertiary
            )
        }
    }
}

// MARK: - Settings Icon Box
@Composable
private fun SettingsIconBox(
    icon: ImageVector,
    iconColor: Color
) {
    Surface(
        modifier = Modifier.size(30.dp),
        shape = RoundedCornerShape(7.dp),
        color = iconColor.copy(alpha = 0.15f)
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
}

// MARK: - Settings Divider
@Composable
private fun SettingsDivider() {
    HorizontalDivider(
        modifier = Modifier.padding(start = 60.dp),
        color = AppColors.TextTertiary.copy(alpha = 0.15f)
    )
}
