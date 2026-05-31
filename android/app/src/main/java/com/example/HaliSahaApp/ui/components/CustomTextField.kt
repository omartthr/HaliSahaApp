package com.example.HaliSahaApp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.UIConstants

@Composable
fun CustomTextField(
    modifier: Modifier = Modifier,
    title: String = "",
    placeholder: String,
    value: String,
    onValueChange: (String) -> Unit,
    leadingIcon: ImageVector? = null,
    keyboardType: KeyboardType = KeyboardType.Text,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    imeAction: ImeAction = ImeAction.Next,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    isEnabled: Boolean = true,
    errorMessage: String? = null,
    trailingIcon: @Composable (() -> Unit)? = null
) {
    var isFocused by remember { mutableStateOf(false) }

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Title
        if (title.isNotEmpty()) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = AppColors.TextPrimary
            )
        }

        // Input Field Container
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = isEnabled,
            textStyle = TextStyle(
                fontSize = 16.sp,
                color = if (isEnabled) AppColors.TextPrimary else Color.Gray
            ),
            keyboardOptions = KeyboardOptions(
                keyboardType = keyboardType,
                imeAction = imeAction
            ),
            keyboardActions = keyboardActions,
            visualTransformation = visualTransformation,
            cursorBrush = SolidColor(AppColors.Primary),
            singleLine = true,
            decorationBox = { innerTextField ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                        .background(
                            color = if (isEnabled) AppColors.Background else Color.Gray.copy(alpha = 0.1f),
                            shape = RoundedCornerShape(UIConstants.CornerRadiusMedium)
                        )
                        .border(
                            width = if (isFocused) 2.dp else 1.dp,
                            color = when {
                                errorMessage != null -> AppColors.Error
                                isFocused -> AppColors.Primary
                                else -> Color.Gray.copy(alpha = 0.3f)
                            },
                            shape = RoundedCornerShape(UIConstants.CornerRadiusMedium)
                        )
                        .padding(horizontal = 16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Leading Icon
                    if (leadingIcon != null) {
                        Icon(
                            imageVector = leadingIcon,
                            contentDescription = null,
                            tint = if (isFocused) AppColors.Primary else Color.Gray,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                    }

                    Box(modifier = Modifier.weight(1f)) {
                        if (value.isEmpty()) {
                            Text(
                                text = placeholder,
                                color = Color.Gray.copy(alpha = 0.6f),
                                fontSize = 16.sp
                            )
                        }
                        innerTextField()
                    }

                    // Trailing Icon (Password Toggle or Custom)
                    if (trailingIcon != null) {
                        trailingIcon()
                    }
                }
            },
            modifier = Modifier.onFocusChanged { isFocused = it.isFocused }
        )

        // Error Message
        if (!errorMessage.isNullOrEmpty()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Error,
                    contentDescription = null,
                    tint = AppColors.Error,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = errorMessage,
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.Error
                )
            }
        }
    }
}

// MARK: - Password TextField Wrapper
@Composable
fun PasswordTextField(
    title: String = "Şifre",
    placeholder: String = "••••••••",
    value: String,
    onValueChange: (String) -> Unit,
    errorMessage: String? = null,
    imeAction: ImeAction = ImeAction.Done
) {
    var isVisible by remember { mutableStateOf(false) }

    CustomTextField(
        title = title,
        placeholder = placeholder,
        value = value,
        onValueChange = onValueChange,
        errorMessage = errorMessage,
        visualTransformation = if (isVisible) VisualTransformation.None else PasswordVisualTransformation(),
        keyboardType = KeyboardType.Password,
        imeAction = imeAction,
        trailingIcon = {
            IconButton(onClick = { isVisible = !isVisible }) {
                Icon(
                    imageVector = if (isVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                    contentDescription = "Toggle Password",
                    tint = Color.Gray
                )
            }
        }
    )
}