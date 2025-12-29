package com.example.HaliSahaApp.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.UIConstants

enum class ButtonStyle {
    Primary, Secondary, Outline, Destructive, Ghost
}

enum class ButtonSize {
    Small, Medium, Large
}

@Composable
fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: ButtonStyle = ButtonStyle.Primary,
    size: ButtonSize = ButtonSize.Large,
    isLoading: Boolean = false,
    isEnabled: Boolean = true,
    fullWidth: Boolean = true
) {
    val height = when (size) {
        ButtonSize.Small -> 36.dp
        ButtonSize.Medium -> 44.dp
        ButtonSize.Large -> 52.dp
    }

    val containerColor = when (style) {
        ButtonStyle.Primary -> AppColors.Primary
        ButtonStyle.Secondary -> AppColors.Surface
        ButtonStyle.Destructive -> AppColors.Error
        else -> Color.Transparent
    }

    val contentColor = when (style) {
        ButtonStyle.Primary, ButtonStyle.Destructive -> Color.White
        ButtonStyle.Secondary, ButtonStyle.Outline, ButtonStyle.Ghost -> AppColors.Primary
        else -> AppColors.Primary
    }

    val border = if (style == ButtonStyle.Outline) BorderStroke(2.dp, AppColors.Primary) else null

    Button(
        onClick = onClick,
        enabled = isEnabled && !isLoading,
        colors = ButtonDefaults.buttonColors(
            containerColor = containerColor,
            contentColor = contentColor,
            disabledContainerColor = if (style == ButtonStyle.Outline) Color.Transparent else Color.Gray.copy(alpha = 0.3f),
            disabledContentColor = Color.Gray
        ),
        border = border,
        shape = RoundedCornerShape(UIConstants.CornerRadiusMedium),
        modifier = modifier
            .height(height)
            .then(if (fullWidth) Modifier.fillMaxWidth() else Modifier),
        elevation = if (style == ButtonStyle.Primary) ButtonDefaults.buttonElevation(4.dp) else null
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(20.dp),
                color = contentColor,
                strokeWidth = 2.dp
            )
        } else {
            Row(horizontalArrangement = Arrangement.Center) {
                if (icon != null) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    text = text,
                    fontSize = if (size == ButtonSize.Small) 14.sp else 16.sp,
                    fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold
                )
            }
        }
    }
}