package com.example.HaliSahaApp.ui.screens.booking

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.HaliSahaApp.data.models.Booking
import com.example.HaliSahaApp.data.services.PaymentMethod
import com.example.HaliSahaApp.ui.components.*
import com.example.HaliSahaApp.ui.viewmodels.FacilityDetailUiState
import com.example.HaliSahaApp.ui.viewmodels.FacilityDetailViewModel
import com.example.HaliSahaApp.utils.*

enum class BookingStep(val index: Int, val title: String) {
    SUMMARY(0, "Özet"),
    PAYMENT(1, "Ödeme"),
    CONFIRMATION(2, "Onay")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingFlowScreen(
    viewModel: FacilityDetailViewModel,
    onDismiss: () -> Unit,
    onBookingCompleted: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    var currentStep by remember { mutableStateOf(BookingStep.SUMMARY) }
    var selectedPaymentMethod by remember { mutableStateOf(PaymentMethod.CREDIT_CARD) }
    var createdBooking by remember { mutableStateOf<Booking?>(null) }



    // Payment Form State
    var cardNumber by remember { mutableStateOf("") }
    var cardHolder by remember { mutableStateOf("") }
    var expiryDate by remember { mutableStateOf("") }
    var cvv by remember { mutableStateOf("") }

    // Alert State
    var showErrorDialog by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { Text(currentStep.title, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    if (currentStep != BookingStep.CONFIRMATION) {
                        TextButton(onClick = onDismiss) {
                            Text("İptal", color = AppColors.Error)
                        }
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(containerColor = AppColors.Background)
            )
        },
        bottomBar = {
            if (currentStep != BookingStep.CONFIRMATION) {
                BookingBottomBar(
                    currentStep = currentStep,
                    totalPrice = uiState.depositAmount, // Kapora ödeniyor
                    isLoading = uiState.isLoading,
                    onNext = {
                        if (currentStep == BookingStep.SUMMARY) {
                            currentStep = BookingStep.PAYMENT
                        } else {
                            // Ödeme Yap
                            viewModel.createBooking(
                                paymentMethod = selectedPaymentMethod,
                                onSuccess = { newBooking ->
                                    createdBooking = newBooking
                                    currentStep = BookingStep.CONFIRMATION // Move to the confirmation step
                                },
                                onError = { error ->
                                    // Show payment error
                                }
                            )
                        }
                    },
                    onBack = {
                        if (currentStep == BookingStep.PAYMENT) currentStep = BookingStep.SUMMARY
                    },
                    isPaymentValid = selectedPaymentMethod == PaymentMethod.WALLET || (cardNumber.isNotEmpty() && cvv.isNotEmpty())
                )
            }
        },
        containerColor = AppColors.Background
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
        ) {
            // Steps Indicator
            if (currentStep != BookingStep.CONFIRMATION) {
                BookingStepIndicator(currentStep = currentStep)
            }

            // Content
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                when (currentStep) {
                    BookingStep.SUMMARY -> BookingSummaryStep(uiState)
                    BookingStep.PAYMENT -> BookingPaymentStep(
                        selectedMethod = selectedPaymentMethod,
                        onMethodSelect = { selectedPaymentMethod = it },
                        cardNumber = cardNumber, onCardNumberChange = { cardNumber = it },
                        cardHolder = cardHolder, onCardHolderChange = { cardHolder = it },
                        expiryDate = expiryDate, onExpiryChange = { expiryDate = it },
                        cvv = cvv, onCvvChange = { cvv = it },
                        amount = uiState.depositAmount
                    )
                    BookingStep.CONFIRMATION -> BookingConfirmationStep(
                        booking = createdBooking,
                        onGoHome = {
                            onDismiss()
                            onBookingCompleted()
                        }
                    )
                }
            }
        }
    }

    if (showErrorDialog) {
        AlertDialog(
            onDismissRequest = { showErrorDialog = false },
            title = { Text("Hata") },
            text = { Text(errorMessage) },
            confirmButton = { TextButton(onClick = { showErrorDialog = false }) { Text("Tamam") } }
        )
    }
}

// MARK: - Steps UI

@Composable
fun BookingStepIndicator(currentStep: BookingStep) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        BookingStep.entries.forEach { step ->
            Box(
                modifier = Modifier
                    .weight(1f)
                    .height(4.dp)
                    .clip(CircleShape)
                    .background(
                        if (step.index <= currentStep.index) AppColors.Primary else Color.Gray.copy(alpha = 0.3f)
                    )
            )
        }
    }
}

@Composable
fun BookingSummaryStep(uiState: FacilityDetailUiState) {
    // Facility Info Card
    Card(colors = CardDefaults.cardColors(containerColor = AppColors.Surface)) {
        Row(modifier = Modifier.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = AppColors.Primary.copy(alpha = 0.1f),
                modifier = Modifier.size(60.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(Icons.Default.SportsSoccer, null, tint = AppColors.Primary)
                }
            }

            Column {
                Text(uiState.facility?.name ?: "", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Text(uiState.selectedPitch?.name ?: "", style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary)
            }
        }

        HorizontalDivider(color = AppColors.Background)

        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            InfoRow("Tarih", uiState.selectedDate.formattedTurkish())
            InfoRow("Saat", "${String.format("%02d:00", uiState.selectedStartHour)} - ${String.format("%02d:00", uiState.selectedEndHour)}")
            InfoRow("Süre", "${uiState.selectedDuration} saat")
            InfoRow("Konum", uiState.facility?.address ?: "")
        }
    }

    // Price Info
    Card(colors = CardDefaults.cardColors(containerColor = AppColors.Surface)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text("Fiyat Detayı", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

            PriceRow("Saha Ücreti", uiState.totalPrice)
            HorizontalDivider()
            PriceRow("Kapora (%20)", uiState.depositAmount, isBold = true)

            Text(
                "Kalan tutar sahada ödenecektir",
                style = MaterialTheme.typography.labelSmall,
                color = AppColors.TextSecondary
            )
        }
    }

    InfoBanner(
        type = BannerType.Info,
        message = "Maçtan 24 saat öncesine kadar ücretsiz iptal edebilirsiniz."
    )
}

@Composable
fun BookingPaymentStep(
    selectedMethod: PaymentMethod,
    onMethodSelect: (PaymentMethod) -> Unit,
    cardNumber: String, onCardNumberChange: (String) -> Unit,
    cardHolder: String, onCardHolderChange: (String) -> Unit,
    expiryDate: String, onExpiryChange: (String) -> Unit,
    cvv: String, onCvvChange: (String) -> Unit,
    amount: Double
) {
    Text("Ödeme Yöntemi", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        PaymentMethod.entries.forEach { method ->
            val isSelected = selectedMethod == method
            Surface(
                onClick = { onMethodSelect(method) },
                shape = RoundedCornerShape(12.dp),
                color = if (isSelected) AppColors.Primary.copy(alpha = 0.1f) else AppColors.Surface,
                border = if (isSelected) androidx.compose.foundation.BorderStroke(1.dp, AppColors.Primary) else null,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Icon placeholder
                    Icon(
                        imageVector = if(method == PaymentMethod.WALLET) Icons.Default.AccountBalanceWallet else Icons.Default.CreditCard,
                        contentDescription = null,
                        tint = if (isSelected) AppColors.Primary else Color.Gray
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(method.rawValue, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal)
                    Spacer(modifier = Modifier.weight(1f))
                    if (isSelected) Icon(Icons.Default.CheckCircle, null, tint = AppColors.Primary)
                }
            }
        }
    }

    if (selectedMethod == PaymentMethod.CREDIT_CARD || selectedMethod == PaymentMethod.DEBIT_CARD) {
        Card(colors = CardDefaults.cardColors(containerColor = AppColors.Surface)) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Text("Kart Bilgileri", fontWeight = FontWeight.Bold)

                CustomTextField(
                    placeholder = "1234 5678 9012 3456",
                    value = cardNumber,
                    onValueChange = onCardNumberChange,
                    keyboardType = androidx.compose.ui.text.input.KeyboardType.Number
                )

                CustomTextField(
                    placeholder = "AD SOYAD",
                    value = cardHolder,
                    onValueChange = onCardHolderChange
                )

                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    CustomTextField(
                        modifier = Modifier.weight(1f),
                        placeholder = "AA/YY",
                        value = expiryDate,
                        onValueChange = onExpiryChange,
                        keyboardType = androidx.compose.ui.text.input.KeyboardType.Number
                    )
                    CustomTextField(
                        modifier = Modifier.weight(1f),
                        placeholder = "CVV",
                        value = cvv,
                        onValueChange = onCvvChange,
                        keyboardType = androidx.compose.ui.text.input.KeyboardType.Number
                    )
                }
            }
        }
    }

    Surface(
        color = AppColors.Primary.copy(alpha = 0.1f),
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("Ödenecek Tutar", style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary)
            Text(amount.asCurrency, style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = AppColors.Primary)
        }
    }
}

@Composable
fun BookingConfirmationStep(booking: Booking?, onGoHome: () -> Unit) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(24.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 20.dp)
    ) {
        // Yeşil Tik Animasyonu/İkonu
        Box(
            modifier = Modifier
                .size(100.dp)
                .background(Color(0xFFE8F5E9), CircleShape), // Açık yeşil arka plan
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = Color(0xFF4CAF50), // Koyu yeşil ikon
                modifier = Modifier.size(50.dp)
            )
        }

        // Başlıklar
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                "Rezervasyon Başarılı!",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                "Bilet numaranız e-posta adresinize gönderildi.",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        }

        if (booking != null) {
            // Bilet Kartı (Ekran görüntüsündeki gibi)
            Card(
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(4.dp),
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {

                    // Üst Kısım: Saha Adı ve QR
                    Row(verticalAlignment = Alignment.Top) {
                        Column {
                            Text(
                                booking.facilityName.uppercase(), // Büyük harf
                                fontWeight = FontWeight.Bold,
                                style = MaterialTheme.typography.titleMedium,
                                color = AppColors.TextPrimary
                            )
                            Text(
                                booking.pitchName,
                                style = MaterialTheme.typography.bodyMedium,
                                color = AppColors.TextSecondary
                            )
                        }
                        Spacer(modifier = Modifier.weight(1f))
                        Icon(
                            Icons.Default.QrCode,
                            null,
                            modifier = Modifier.size(32.dp),
                            tint = AppColors.TextPrimary
                        )
                    }

                    // Kesikli Çizgi (Divider)
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 4.dp),
                        thickness = 1.dp,
                        color = Color.LightGray
                    )

                    // Detaylar (Tarih, Saat, Süre)
                    Row(
                        horizontalArrangement = Arrangement.SpaceBetween,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        // Tarih
                        Column(horizontalAlignment = Alignment.Start) {
                            Text("Tarih", style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
                            Text(booking.formattedDate, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        }

                        // Saat
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text("Saat", style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
                            Text(booking.timeSlotString, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        }

                        // Süre
                        Column(horizontalAlignment = Alignment.End) {
                            Text("Süre", style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
                            Text("${booking.duration} saat", fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                        }
                    }

                    // Bilet No (Yeşil)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Text("Bilet No:", style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(booking.ticketNumber, fontWeight = FontWeight.Bold, color = Color(0xFF2E7D32), fontSize = 12.sp)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        // Butonlar
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            // Randevularıma Git (Yeşil Dolu)
            PrimaryButton(
                text = "Randevularıma Git",
                onClick = onGoHome, // Şimdilik Home'a, sonra direkt Randevular tabına yönlendirilebilir
                icon = Icons.Default.ConfirmationNumber, // Bilet ikonu
                style = ButtonStyle.Primary
            )

            // Ana Sayfaya Dön (Outline/Gri)
            PrimaryButton(
                text = "Ana Sayfaya Dön",
                onClick = onGoHome,
                style = ButtonStyle.Outline // Çerçeveli stil
            )
        }
    }
}

@Composable
fun InfoRow(label: String, value: String) {
    Row {
        Text(label, style = MaterialTheme.typography.bodySmall, color = AppColors.TextSecondary)
        Spacer(modifier = Modifier.weight(1f))
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
    }
}

@Composable
fun PriceRow(label: String, value: Double, isBold: Boolean = false) {
    Row {
        Text(label, fontWeight = if (isBold) FontWeight.Bold else FontWeight.Normal)
        Spacer(modifier = Modifier.weight(1f))
        Text(
            value.asCurrency,
            fontWeight = if (isBold) FontWeight.Bold else FontWeight.Normal,
            color = if (isBold) AppColors.Primary else AppColors.TextPrimary
        )
    }
}

@Composable
fun BookingBottomBar(
    currentStep: BookingStep,
    totalPrice: Double,
    isLoading: Boolean,
    onNext: () -> Unit,
    onBack: () -> Unit,
    isPaymentValid: Boolean
) {
    Surface(shadowElevation = 8.dp, color = AppColors.Surface) {
        Column {
            HorizontalDivider()
            Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                if (currentStep.index > 0) {
                    TextButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, null)
                        Text("Geri")
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                PrimaryButton(
                    text = if (currentStep == BookingStep.SUMMARY) "Ödemeye Geç" else "Ödemeyi Tamamla",
                    onClick = onNext,
                    fullWidth = false,
                    size = ButtonSize.Medium,
                    isLoading = isLoading,
                    isEnabled = if (currentStep == BookingStep.PAYMENT) isPaymentValid else true,
                    icon = if (currentStep == BookingStep.PAYMENT) Icons.Default.Lock else null
                )
            }
        }
    }
}