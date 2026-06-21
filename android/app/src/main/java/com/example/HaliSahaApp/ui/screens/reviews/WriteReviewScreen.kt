package com.example.HaliSahaApp.ui.screens.reviews

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.HaliSahaApp.data.remote.AuthService
import com.example.HaliSahaApp.ui.components.LoadingView
import com.example.HaliSahaApp.ui.viewmodels.ReviewsViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WriteReviewScreen(
    bookingId: String,
    onBack: () -> Unit,
    onSuccess: () -> Unit,
    viewModel: ReviewsViewModel = viewModel()
) {
    val booking by viewModel.targetBooking.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    val error by viewModel.error.collectAsState()
    val currentUser by AuthService.currentUser.collectAsState()

    var rating by remember { mutableStateOf(5.0) }
    var comment by remember { mutableStateOf("") }

    LaunchedEffect(bookingId) {
        viewModel.fetchBooking(bookingId)
    }

    if (isLoading && booking == null) {
        LoadingView()
        return
    }

    if (booking == null) {
        Scaffold(
            topBar = {
                CenterAlignedTopAppBar(
                    title = { Text("Değerlendir") },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(AppIcons.ArrowLeft, contentDescription = "Geri")
                        }
                    }
                )
            }
        ) { padding ->
            Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(error ?: "Rezervasyon bulunamadı.")
            }
        }
        return
    }

    val currentBooking = booking!!

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Değerlendir") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(AppIcons.ArrowLeft, contentDescription = "İptal")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            Text(currentBooking.facilityName, style = MaterialTheme.typography.titleLarge)
            
            StarRatingSelector(rating = rating, onRatingChange = { rating = it })

            OutlinedTextField(
                value = comment,
                onValueChange = { comment = it },
                label = { Text("Yorumunuz (İsteğe bağlı)") },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(150.dp),
                maxLines = 5
            )

            Button(
                onClick = {
                    viewModel.submitReview(
                        booking = currentBooking,
                        rating = rating,
                        comment = comment,
                        userFullName = currentUser?.fullName ?: "Misafir",
                        userProfileImage = currentUser?.profileImageURL,
                        onSuccess = onSuccess
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                enabled = !isLoading,
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)
            ) {
                if (isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(24.dp), color = AppColors.Surface)
                } else {
                    Text("Gönder", color = AppColors.Surface)
                }
            }

            if (error != null) {
                Text(error!!, color = AppColors.Error)
            }
        }
    }
}

@Composable
fun StarRatingSelector(rating: Double, onRatingChange: (Double) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        for (i in 1..5) {
            val isSelected = i <= rating
            Icon(
                AppIcons.Star,
                contentDescription = "$i Yıldız",
                tint = if (isSelected) AppColors.Warning else AppColors.TextSecondary.copy(alpha = 0.3f),
                modifier = Modifier
                    .size(48.dp)
                    .clickable { onRatingChange(i.toDouble()) }
            )
        }
    }
}
