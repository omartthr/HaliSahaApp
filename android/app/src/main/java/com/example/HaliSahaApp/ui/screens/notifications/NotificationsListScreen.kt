package com.example.HaliSahaApp.ui.screens.notifications

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.HaliSahaApp.data.models.AppNotification
import com.example.HaliSahaApp.data.models.NotificationType
import com.example.HaliSahaApp.ui.viewmodels.NotificationsViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons
import java.text.SimpleDateFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsListScreen(
    onBack: () -> Unit,
    viewModel: NotificationsViewModel = viewModel()
) {
    val notifications by viewModel.notifications.collectAsState()
    val unreadCount by viewModel.unreadCount.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Bildirimler") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(AppIcons.ArrowLeft, contentDescription = "Geri")
                    }
                },
                actions = {
                    if (unreadCount > 0) {
                        TextButton(onClick = { viewModel.markAllAsRead() }) {
                            Text("Tümünü Okundu İşaretle")
                        }
                    }
                }
            )
        }
    ) { padding ->
        if (isLoading && notifications.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (notifications.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(AppIcons.Notification, contentDescription = null, modifier = Modifier.size(64.dp), tint = AppColors.TextSecondary)
                    Spacer(modifier = Modifier.height(16.dp))
                    Text("Henüz bildiriminiz yok.", color = AppColors.TextSecondary)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding).fillMaxSize().padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(notifications, key = { it.id ?: it.hashCode() }) { notification ->
                    NotificationCell(
                        notification = notification,
                        onClick = {
                            if (!notification.isRead) {
                                notification.id?.let { viewModel.markAsRead(it) }
                            }
                            // Navigate based on notification.referenceId if needed
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun NotificationCell(notification: AppNotification, onClick: () -> Unit) {
    val backgroundColor = if (notification.isRead) AppColors.CardBackground else AppColors.Primary.copy(alpha = 0.05f)
    
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = backgroundColor)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.Top
        ) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(AppColors.Primary.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                val icon = when (notification.type) {
                    NotificationType.SYSTEM, NotificationType.PROMOTIONAL, NotificationType.FACILITY_APPROVED, NotificationType.FACILITY_REJECTED -> AppIcons.Info
                    NotificationType.BOOKING_REMINDER, NotificationType.BOOKING_CONFIRMED, NotificationType.BOOKING_CANCELLED -> AppIcons.Bookings
                    NotificationType.REVIEW_RECEIVED -> AppIcons.Star
                    NotificationType.MATCH_INVITE, NotificationType.JOIN_REQUEST, NotificationType.JOIN_REQUEST_ACCEPTED, NotificationType.JOIN_REQUEST_REJECTED, NotificationType.NEW_MESSAGE, NotificationType.NEW_FOLLOWER -> AppIcons.PersonGroup
                }
                Icon(icon, contentDescription = null, tint = AppColors.Primary, modifier = Modifier.size(20.dp))
            }
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(notification.title, fontWeight = if (notification.isRead) FontWeight.Normal else FontWeight.Bold, color = AppColors.TextPrimary)
                Spacer(modifier = Modifier.height(4.dp))
                Text(notification.body, style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary)
                val dateStr = notification.formattedDate
                Text(dateStr, style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary.copy(alpha = 0.7f))
            }
            if (!notification.isRead) {
                Box(modifier = Modifier.size(8.dp).clip(CircleShape).background(AppColors.Primary))
            }
        }
    }
}
