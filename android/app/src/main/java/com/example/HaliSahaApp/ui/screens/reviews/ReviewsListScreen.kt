package com.example.HaliSahaApp.ui.screens.reviews

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.HaliSahaApp.data.models.Review
import com.example.HaliSahaApp.ui.viewmodels.ReviewsViewModel
import com.example.HaliSahaApp.utils.AppColors
import com.example.HaliSahaApp.utils.AppIcons
import java.text.SimpleDateFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReviewsListScreen(
    facilityId: String,
    onBack: () -> Unit,
    viewModel: ReviewsViewModel = viewModel()
) {
    val reviews by viewModel.reviews.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()

    LaunchedEffect(facilityId) {
        viewModel.fetchReviews(facilityId)
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text("Değerlendirmeler") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(AppIcons.ArrowLeft, contentDescription = "Geri")
                    }
                }
            )
        }
    ) { padding ->
        if (isLoading) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (reviews.isEmpty()) {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Henüz değerlendirme yapılmamış.", color = AppColors.TextSecondary)
            }
        } else {
            LazyColumn(
                modifier = Modifier.padding(padding).fillMaxSize().padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                contentPadding = PaddingValues(vertical = 16.dp)
            ) {
                items(reviews) { review ->
                    ReviewCard(review = review)
                }
            }
        }
    }
}

@Composable
fun ReviewCard(review: Review) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = AppColors.CardBackground)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (!review.userProfileImage.isNullOrEmpty()) {
                    AsyncImage(
                        model = review.userProfileImage,
                        contentDescription = "Profil",
                        modifier = Modifier.size(40.dp).clip(CircleShape),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Box(
                        modifier = Modifier.size(40.dp).clip(CircleShape).background(AppColors.Primary.copy(alpha = 0.2f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(review.userName.take(1), color = AppColors.Primary, fontWeight = FontWeight.Bold)
                    }
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(review.userName, fontWeight = FontWeight.Bold)
                    val sdf = SimpleDateFormat("dd MMM yyyy", Locale("tr", "TR"))
                    val dateStr = review.createdAt?.let { sdf.format(it) } ?: ""
                    Text(dateStr, style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
                }
                Row {
                    Icon(AppIcons.Star, contentDescription = null, tint = AppColors.Warning, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(String.format(Locale.US, "%.1f", review.overallRating), fontWeight = FontWeight.Bold)
                }
            }
            if (!review.comment.isNullOrEmpty()) {
                Spacer(modifier = Modifier.height(12.dp))
                Text(review.comment)
            }
        }
    }
}
