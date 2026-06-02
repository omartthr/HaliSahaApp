package com.example.HaliSahaApp.ui.screens.chat

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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.HaliSahaApp.data.models.Group
import com.example.HaliSahaApp.ui.components.LoadingView
import com.example.HaliSahaApp.ui.navigation.Screen
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatListScreen(
    navController: NavController,
    viewModel: ChatListViewModel = viewModel()
) {
    val groups by viewModel.groups.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sohbet", fontWeight = FontWeight.Bold) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = AppColors.Surface,
                    titleContentColor = AppColors.TextPrimary
                )
            )
        },
        containerColor = AppColors.Background,
        contentWindowInsets = WindowInsets(0.dp)
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when {
                isLoading -> {
                    LoadingView()
                }
                error != null -> {
                    Text(
                        text = error!!,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                groups.isEmpty() -> {
                    EmptyChatView()
                }
                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = 8.dp)
                    ) {
                        items(groups) { group ->
                            ChatListItem(
                                group = group,
                                onClick = {
                                    group.id?.let {
                                        navController.navigate(Screen.ChatDetail.createRoute(it))
                                    }
                                }
                            )
                            Divider(color = AppColors.Surface, thickness = 1.dp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ChatListItem(group: Group, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Group Image
        if (group.imageURL != null) {
            AsyncImage(
                model = group.imageURL,
                contentDescription = group.name,
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(AppColors.Surface),
                contentScale = ContentScale.Crop
            )
        } else {
            // Placeholder icon based on group type
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(AppColors.Primary.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = when(group.groupType.rawValue) {
                        "team" -> AppIcons.PersonGroup
                        "match" -> AppIcons.Calendar
                        else -> AppIcons.Person
                    },
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(28.dp)
                )
            }
        }

        Spacer(modifier = Modifier.width(16.dp))

        // Text Content
        Column(modifier = Modifier.weight(1f)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = group.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                if (group.lastMessage != null) {
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = group.lastMessage.timeAgo,
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(4.dp))
            
            if (group.lastMessage != null) {
                val prefix = if (group.groupType.rawValue != "private") "${group.lastMessage.senderName}: " else ""
                Text(
                    text = "$prefix${group.lastMessage.previewText}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppColors.TextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            } else {
                Text(
                    text = "Henüz mesaj yok",
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppColors.TextSecondary,
                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
                )
            }
        }
    }
}

@Composable
fun EmptyChatView() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = AppIcons.Chat,
            contentDescription = null,
            tint = AppColors.Primary.copy(alpha = 0.5f),
            modifier = Modifier.size(80.dp)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "Sohbet Bulunamadı",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Henüz hiçbir gruba katılmadınız veya mesajınız yok.",
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}
