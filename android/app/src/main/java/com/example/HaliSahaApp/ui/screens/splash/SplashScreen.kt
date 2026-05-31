package com.example.HaliSahaApp.ui.screens.splash

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.SportsSoccer // Sportscourt yerine
import androidx.compose.material3.*
import androidx.compose.runtime.*
import com.airbnb.lottie.compose.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.HaliSahaApp.utils.AppColors
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(onSplashFinished: () -> Unit) {
    var isAnimating by remember { mutableStateOf(false) }
    val composition by rememberLottieComposition(LottieCompositionSpec.RawRes(com.example.HaliSahaApp.R.raw.splash_soccer_field))
    val progress by animateLottieCompositionAsState(
        composition = composition,
        iterations = LottieConstants.IterateForever,
        speed = 2.0f // Animasyonu 2 kat hızlandırır
    )

    // Animasyon (Swift'teki scaleEffect karşılığı)
    val scale by animateFloatAsState(
        targetValue = if (isAnimating) 1.1f else 1.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        ), label = "logoScale"
    )

    // 2 saniye bekle ve bitir
    LaunchedEffect(true) {
        isAnimating = true
        delay(2000)
        onSplashFinished()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Primary), // Yeşil Arkaplan
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Logo Animasyonu
            Box(contentAlignment = Alignment.Center) {
                LottieAnimation(
                    composition = composition,
                    progress = { progress },
                    modifier = Modifier.size(180.dp)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // App Name
            Text(
                text = "Alo HalıSaha",
                fontSize = 36.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Maça Başla!",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.8f)
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Loading Indicator
            CircularProgressIndicator(
                color = Color.White,
                modifier = Modifier.scale(1.2f)
            )
        }
    }
}