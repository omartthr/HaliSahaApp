package com.example.HaliSahaApp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.StarHalf
import androidx.compose.material.icons.filled.TrendingDown
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.UIConstants

// MARK: - Quick Action Card
@Composable
fun QuickActionCard(
    title: String,
    subtitle: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {}
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(color.copy(alpha = 0.15f), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(24.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Text
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.TextPrimary
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextSecondary
                )
            }
        }
    }
}

// MARK: - Stats Card
@Composable
fun StatsCard(
    title: String,
    value: String,
    icon: ImageVector,
    color: Color,
    modifier: Modifier = Modifier,
    trend: String? = null,
    trendUp: Boolean = true
) {
    Card(
        modifier = modifier.fillMaxWidth(),
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
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = color,
                    modifier = Modifier.size(20.dp)
                )

                Spacer(modifier = Modifier.weight(1f))

                if (trend != null) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                        Icon(
                            imageVector = if (trendUp) Icons.Filled.TrendingUp else Icons.Filled.TrendingDown,
                            contentDescription = null,
                            tint = if (trendUp) AppColors.Success else AppColors.Error,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = trend,
                            style = MaterialTheme.typography.labelSmall,
                            color = if (trendUp) AppColors.Success else AppColors.Error
                        )
                    }
                }
            }

            // Value
            Text(
                text = value,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary
            )

            // Title
            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                color = AppColors.TextSecondary
            )
        }
    }
}

// MARK: - Info Banner
enum class BannerType(val color: Color, val icon: ImageVector) {
    Info(AppColors.Info, Icons.Filled.Info),
    Success(AppColors.Success, Icons.Default.Check), // Check import edilmeli
    Warning(AppColors.Warning, Icons.Default.Warning), // Warning import edilmeli
    Error(AppColors.Error, Icons.Default.Error) // Error import edilmeli
}

@Composable
fun InfoBanner(
    type: BannerType,
    message: String,
    modifier: Modifier = Modifier,
    actionTitle: String? = null,
    onAction: (() -> Unit)? = null,
    onDismiss: (() -> Unit)? = null
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(type.color.copy(alpha = 0.1f), RoundedCornerShape(12.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.Top
    ) {
        Icon(
            imageVector = type.icon,
            contentDescription = null,
            tint = type.color,
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextPrimary
            )

            if (actionTitle != null && onAction != null) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = actionTitle,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    color = type.color,
                    modifier = Modifier.clickable(onClick = onAction)
                )
            }
        }

        if (onDismiss != null) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Kapat",
                tint = AppColors.TextSecondary,
                modifier = Modifier
                    .size(20.dp)
                    .clickable(onClick = onDismiss)
            )
        }
    }
}

// MARK: - Tag View
enum class TagStyle { Filled, Outlined }

@Composable
fun TagView(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    color: Color = AppColors.Primary,
    style: TagStyle = TagStyle.Filled
) {
    val backgroundColor = if (style == TagStyle.Filled) color else color.copy(alpha = 0.1f)
    val contentColor = if (style == TagStyle.Filled) Color.White else color
    val border = if (style == TagStyle.Outlined) androidx.compose.foundation.BorderStroke(1.dp, color) else null

    Surface(
        modifier = modifier,
        color = backgroundColor,
        contentColor = contentColor,
        shape = CircleShape, // Capsule
        border = border
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            if (icon != null) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(12.dp)
                )
            }
            Text(
                text = text,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

// MARK: - Rating Stars View
@Composable
fun RatingStarsView(
    rating: Double,
    maxRating: Int = 5,
    size: Dp = 14.dp,
    color: Color = AppColors.Warning
) {
    Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
        repeat(maxRating) { index ->
            val icon = when {
                index + 1 <= rating -> Icons.Filled.Star
                index + 0.5 <= rating -> Icons.Filled.StarHalf
                else -> Icons.Filled.StarBorder
            }
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(size)
            )
        }
    }
}

// MARK: - Avatar View
@Composable
fun AvatarView(
    name: String,
    modifier: Modifier = Modifier,
    imageUrl: String? = null,
    size: Dp = 44.dp,
    backgroundColor: Color = AppColors.Primary.copy(alpha = 0.1f),
    textColor: Color = AppColors.Primary
) {
    Box(
        modifier = modifier
            .size(size)
            .background(backgroundColor, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        if (!imageUrl.isNullOrEmpty()) {
            // AsyncImage kütüphanesi (Coil) eklendiğinde burası güncellenecek
            // Şimdilik Placeholder
            Text(
                text = name.take(1).uppercase(),
                fontSize = (size.value * 0.4).sp,
                fontWeight = FontWeight.SemiBold,
                color = textColor
            )
        } else {
            Text(
                text = name.take(1).uppercase(),
                fontSize = (size.value * 0.4).sp,
                fontWeight = FontWeight.SemiBold,
                color = textColor
            )
        }
    }
}

// MARK: - Divider with Text
@Composable
fun DividerWithText(
    text: String,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        HorizontalDivider(modifier = Modifier.weight(1f), color = Color.Gray.copy(alpha = 0.3f))
        Text(
            text = text,
            style = MaterialTheme.typography.bodySmall,
            color = AppColors.TextSecondary,
            modifier = Modifier.padding(horizontal = 12.dp)
        )
        HorizontalDivider(modifier = Modifier.weight(1f), color = Color.Gray.copy(alpha = 0.3f))
    }
}

// MARK: - Badge View
@Composable
fun BadgeView(
    count: Int,
    modifier: Modifier = Modifier,
    maxCount: Int = 99,
    backgroundColor: Color = AppColors.Error,
    textColor: Color = Color.White,
    size: Dp = 18.dp
) {
    if (count > 0) {
        val text = if (count > maxCount) "$maxCount+" else "$count"
        val padding = if (count > 9) 4.dp else 0.dp

        Box(
            modifier = modifier
                .defaultMinSize(minWidth = size, minHeight = size)
                .background(backgroundColor, CircleShape)
                .padding(horizontal = padding),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                fontSize = (size.value * 0.6).sp,
                fontWeight = FontWeight.Bold,
                color = textColor
            )
        }
    }
}