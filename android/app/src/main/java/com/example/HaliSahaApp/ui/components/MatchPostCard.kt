package com.example.HaliSahaApp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.HaliSahaApp.data.models.MatchPost
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.UIConstants

@Composable
fun MatchPostCard(
    matchPost: MatchPost,
    onClick: () -> Unit = {}
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Avatar
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .background(AppColors.Primary.copy(alpha = 0.1f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = matchPost.creatorName.take(1).uppercase(),
                        style = MaterialTheme.typography.titleMedium,
                        color = AppColors.Primary,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                Column {
                    Text(
                        text = matchPost.creatorName,
                        style = MaterialTheme.typography.labelLarge,
                        color = AppColors.TextPrimary,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = matchPost.formattedDate,
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Players Needed Badge
                Surface(
                    color = AppColors.Primary,
                    shape = RoundedCornerShape(20.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.PersonAdd,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(12.dp)
                        )
                        Text(
                            text = "${matchPost.availableSlots} kişi",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
            }

            // Title
            Text(
                text = matchPost.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Info Row (Location & Time)
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                // Location
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(
                        imageVector = Icons.Filled.LocationOn,
                        contentDescription = null,
                        tint = AppColors.TextSecondary,
                        modifier = Modifier.size(14.dp)
                    )
                    Text(
                        text = matchPost.facilityName,
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }

                // Time
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(
                        imageVector = Icons.Filled.Schedule,
                        contentDescription = null,
                        tint = AppColors.TextSecondary,
                        modifier = Modifier.size(14.dp)
                    )
                    Text(
                        text = matchPost.timeSlot,
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }
            }

            // Bottom Row (Skill & Cost)
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Skill Level
                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(text = matchPost.skillLevel.icon, style = MaterialTheme.typography.bodySmall)
                    Text(
                        text = matchPost.skillLevel.displayName,
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Cost
                matchPost.formattedCostPerPlayer?.let { cost ->
                    Text(
                        text = cost,
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = AppColors.Primary
                    )
                }
            }

            // Progress Bar
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                LinearProgressIndicator(
                    progress = { matchPost.currentPlayers.toFloat() / matchPost.maxPlayers.toFloat() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = AppColors.Primary,
                    trackColor = AppColors.Background
                )

                Text(
                    text = "${matchPost.currentPlayers}/${matchPost.maxPlayers} oyuncu",
                    style = MaterialTheme.typography.labelSmall,
                    color = AppColors.TextSecondary
                )
            }
        }
    }
}
