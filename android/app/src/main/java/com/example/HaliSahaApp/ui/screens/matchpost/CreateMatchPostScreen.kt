package com.example.HaliSahaApp.ui.screens.matchpost

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Notes
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.example.HaliSahaApp.data.models.PlayerPosition
import com.example.HaliSahaApp.data.models.SkillLevel
import com.example.HaliSahaApp.ui.viewmodels.CreateMatchPostViewModel
import com.example.HaliSahaApp.utils.AppColors

// MARK: - Create Match Post Screen
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateMatchPostScreen(
    navController: NavController,
    bookingId: String,
    viewModel: CreateMatchPostViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(bookingId) {
        viewModel.initWithBookingId(bookingId)
    }

    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = {
                    Text(
                        "Maç İlanı",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 17.sp
                    )
                },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Geri"
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = AppColors.Background
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(AppColors.Background)
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // 1. Hero Summary (Maç bilgileri)
            HeroSummarySection(
                facilityName = uiState.facilityName,
                pitchName = uiState.pitchName,
                facilityAddress = uiState.facilityAddress,
                matchDate = uiState.matchDate,
                timeSlot = uiState.timeSlot,
                ticketNumber = uiState.ticketNumber,
                title = uiState.title,
                onTitleChange = { viewModel.onTitleChange(it) }
            )

            // 2. Kadro Bilgisi
            PlayerCountSection(
                neededPlayers = uiState.neededPlayers,
                currentPlayers = uiState.currentPlayers,
                maxPlayers = uiState.maxPlayers,
                isRosterValid = uiState.isRosterValid,
                rosterHint = uiState.rosterHint,
                onNeededChange = { viewModel.onNeededPlayersChange(it) },
                onCurrentChange = { viewModel.onCurrentPlayersChange(it) },
                onMaxChange = { viewModel.onMaxPlayersChange(it) }
            )

            // 3. Oyuncu Beklentisi
            ExpectationsSection(
                skillLevel = uiState.skillLevel,
                preferredPositions = uiState.preferredPositions,
                hasCostPerPlayer = uiState.hasCostPerPlayer,
                costPerPlayerText = uiState.costPerPlayerText,
                onSkillLevelChange = { viewModel.onSkillLevelChange(it) },
                onTogglePosition = { viewModel.togglePosition(it) },
                onHasCostChange = { viewModel.onHasCostPerPlayerChange(it) },
                onCostTextChange = { viewModel.onCostPerPlayerTextChange(it) }
            )

            // 4. Not
            DescriptionSection(
                description = uiState.description,
                onDescriptionChange = { viewModel.onDescriptionChange(it) }
            )

            // 5. İlanı Yayınla
            PublishSection(
                canSubmit = uiState.canSubmit,
                isSaving = uiState.isSaving,
                onPublish = { viewModel.createPost() }
            )

            Spacer(modifier = Modifier.height(32.dp))
        }
    }

    // Alerts
    if (uiState.showSuccess) {
        AlertDialog(
            onDismissRequest = { },
            title = { Text("İlan Oluşturuldu") },
            text = { Text("Maç ilanınız Keşfet ekranında oyunculara gösterilecek.") },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.clearSuccess()
                    navController.popBackStack()
                }) {
                    Text("Tamam", color = AppColors.Primary)
                }
            }
        )
    }

    if (uiState.showError) {
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text("İlan Oluşturulamadı") },
            text = { Text(uiState.errorMessage) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text("Tamam")
                }
            }
        )
    }
}

// MARK: - Hero Summary Section
@Composable
private fun HeroSummarySection(
    facilityName: String,
    pitchName: String,
    facilityAddress: String,
    matchDate: String,
    timeSlot: String,
    ticketNumber: String,
    title: String,
    onTitleChange: (String) -> Unit
) {
    CardSection {
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            // Tesis bilgisi
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Surface(
                    modifier = Modifier.size(56.dp),
                    shape = RoundedCornerShape(12.dp),
                    color = AppColors.Primary.copy(alpha = 0.14f)
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Filled.SportsSoccer,
                            contentDescription = null,
                            tint = AppColors.Primary,
                            modifier = Modifier.size(28.dp)
                        )
                    }
                }

                Column(
                    verticalArrangement = Arrangement.spacedBy(5.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = facilityName,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 2
                    )
                    Text(
                        text = pitchName,
                        fontSize = 14.sp,
                        color = AppColors.TextSecondary
                    )
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.LocationOn,
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = AppColors.TextSecondary
                        )
                        Text(
                            text = facilityAddress,
                            fontSize = 12.sp,
                            color = AppColors.TextSecondary,
                            maxLines = 2
                        )
                    }
                }
            }

            // Info Chips
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                InfoChip(icon = Icons.Filled.CalendarMonth, title = matchDate)
                InfoChip(icon = Icons.Filled.Schedule, title = timeSlot)
                InfoChip(icon = Icons.Filled.ConfirmationNumber, title = ticketNumber)
            }

            // İlan başlığı
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "İlan başlığı",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold
                )
                OutlinedTextField(
                    value = title,
                    onValueChange = onTitleChange,
                    placeholder = { Text("Örn. Akşam maçına 4 oyuncu aranıyor") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = AppColors.Primary,
                        unfocusedBorderColor = AppColors.TextTertiary.copy(alpha = 0.3f)
                    ),
                    singleLine = true
                )
            }
        }
    }
}

// MARK: - Player Count Section
@Composable
private fun PlayerCountSection(
    neededPlayers: Int,
    currentPlayers: Int,
    maxPlayers: Int,
    isRosterValid: Boolean,
    rosterHint: String,
    onNeededChange: (Int) -> Unit,
    onCurrentChange: (Int) -> Unit,
    onMaxChange: (Int) -> Unit
) {
    CardSection {
        Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
            SectionTitle(title = "Kadro Bilgisi", icon = Icons.Filled.Groups)

            StepperRow(
                title = "Aranan oyuncu",
                subtitle = "İlanda görünecek eksik kişi sayısı",
                value = neededPlayers,
                onValueChange = onNeededChange
            )

            HorizontalDivider(color = AppColors.TextTertiary.copy(alpha = 0.15f))

            StepperRow(
                title = "Mevcut oyuncu",
                subtitle = "Şu an kesinleşen kişi sayısı",
                value = currentPlayers,
                onValueChange = onCurrentChange
            )

            HorizontalDivider(color = AppColors.TextTertiary.copy(alpha = 0.15f))

            StepperRow(
                title = "Maksimum kadro",
                subtitle = "Sahanın toplam oyuncu kapasitesi",
                value = maxPlayers,
                onValueChange = onMaxChange
            )

            // Roster hint
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = if (isRosterValid) Icons.Filled.CheckCircle else Icons.Filled.Warning,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = if (isRosterValid) AppColors.Primary else Color(0xFFFF9800)
                )
                Text(
                    text = rosterHint,
                    fontSize = 12.sp,
                    color = AppColors.TextSecondary
                )
            }
        }
    }
}

// MARK: - Expectations Section
@Composable
private fun ExpectationsSection(
    skillLevel: SkillLevel,
    preferredPositions: List<PlayerPosition>,
    hasCostPerPlayer: Boolean,
    costPerPlayerText: String,
    onSkillLevelChange: (SkillLevel) -> Unit,
    onTogglePosition: (PlayerPosition) -> Unit,
    onHasCostChange: (Boolean) -> Unit,
    onCostTextChange: (String) -> Unit
) {
    var skillLevelExpanded by remember { mutableStateOf(false) }

    CardSection {
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            SectionTitle(title = "Oyuncu Beklentisi", icon = Icons.Filled.Tune)

            // Seviye Picker
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = "Seviye",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold
                )

                Box {
                    Surface(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { skillLevelExpanded = true },
                        shape = RoundedCornerShape(12.dp),
                        color = AppColors.Background
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = skillLevel.displayName,
                                fontSize = 14.sp,
                                color = AppColors.Primary,
                                fontWeight = FontWeight.Medium
                            )
                            Spacer(modifier = Modifier.weight(1f))
                            Icon(
                                imageVector = Icons.Filled.UnfoldMore,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp),
                                tint = AppColors.TextSecondary
                            )
                        }
                    }

                    DropdownMenu(
                        expanded = skillLevelExpanded,
                        onDismissRequest = { skillLevelExpanded = false }
                    ) {
                        SkillLevel.entries.forEach { level ->
                            DropdownMenuItem(
                                text = { Text(level.displayName) },
                                onClick = {
                                    onSkillLevelChange(level)
                                    skillLevelExpanded = false
                                }
                            )
                        }
                    }
                }
            }

            // Tercih edilen mevkiler
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(
                    text = "Tercih edilen mevkiler",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold
                )

                // 2x2 grid for positions
                val positions = PlayerPosition.entries.filter { it != PlayerPosition.UNSPECIFIED }
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    for (row in positions.chunked(2)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            row.forEach { position ->
                                val isSelected = position in preferredPositions
                                PositionChip(
                                    position = position,
                                    isSelected = isSelected,
                                    onClick = { onTogglePosition(position) },
                                    modifier = Modifier.weight(1f)
                                )
                            }
                            // Boş alan doldurmak için (tek sayıda pozisyon varsa)
                            if (row.size < 2) {
                                Spacer(modifier = Modifier.weight(1f))
                            }
                        }
                    }
                }
            }

            // Kişi başı ücret toggle
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Kişi başı ücret belirt",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "Boş bırakırsanız ilanda ücret gösterilmez.",
                            fontSize = 12.sp,
                            color = AppColors.TextSecondary
                        )
                    }
                    Switch(
                        checked = hasCostPerPlayer,
                        onCheckedChange = onHasCostChange,
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = AppColors.Primary,
                            uncheckedThumbColor = Color.White,
                            uncheckedTrackColor = AppColors.TextTertiary
                        )
                    )
                }

                AnimatedVisibility(visible = hasCostPerPlayer) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(AppColors.Background)
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = costPerPlayerText,
                            onValueChange = onCostTextChange,
                            placeholder = { Text("100") },
                            modifier = Modifier.weight(1f),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            shape = RoundedCornerShape(8.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = AppColors.Primary,
                                unfocusedBorderColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                focusedContainerColor = Color.Transparent
                            ),
                            singleLine = true
                        )
                        Text(
                            text = "₺ / kişi",
                            fontSize = 14.sp,
                            color = AppColors.TextSecondary
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Description Section
@Composable
private fun DescriptionSection(
    description: String,
    onDescriptionChange: (String) -> Unit
) {
    CardSection {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            SectionTitle(title = "Not", icon = Icons.AutoMirrored.Filled.Notes)

            OutlinedTextField(
                value = description,
                onValueChange = onDescriptionChange,
                placeholder = {
                    Text(
                        "Maç ortamı, aradığınız oyuncu tipi veya özel notlar...",
                        color = AppColors.TextSecondary.copy(alpha = 0.75f)
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .heightIn(min = 110.dp),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = AppColors.Primary,
                    unfocusedBorderColor = AppColors.TextTertiary.copy(alpha = 0.3f)
                ),
                maxLines = 6
            )
        }
    }
}

// MARK: - Publish Section
@Composable
private fun PublishSection(
    canSubmit: Boolean,
    isSaving: Boolean,
    onPublish: () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Button(
            onClick = onPublish,
            enabled = canSubmit && !isSaving,
            modifier = Modifier
                .fillMaxWidth()
                .height(54.dp),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = AppColors.Primary,
                disabledContainerColor = AppColors.Primary.copy(alpha = 0.4f)
            )
        ) {
            if (isSaving) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    color = Color.White,
                    strokeWidth = 2.dp
                )
            } else {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Send,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "İlanı Yayınla",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        Text(
            text = "İlan yayınlandıktan sonra oyuncular Keşfet ekranından başvurabilir.",
            fontSize = 12.sp,
            color = AppColors.TextSecondary,
            textAlign = TextAlign.Center
        )
    }
}

// MARK: - Reusable Components

@Composable
private fun CardSection(
    content: @Composable ColumnScope.() -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        color = AppColors.CardBackground,
        shadowElevation = 2.dp
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}

@Composable
private fun SectionTitle(title: String, icon: ImageVector) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = AppColors.Primary,
            modifier = Modifier.size(20.dp)
        )
        Text(
            text = title,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun InfoChip(icon: ImageVector, title: String) {
    Surface(
        shape = RoundedCornerShape(50),
        color = AppColors.Primary.copy(alpha = 0.10f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(12.dp),
                tint = AppColors.Primary
            )
            Text(
                text = title,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = AppColors.Primary,
                maxLines = 1
            )
        }
    }
}

@Composable
private fun StepperRow(
    title: String,
    subtitle: String,
    value: Int,
    onValueChange: (Int) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Text(
                text = title,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = subtitle,
                fontSize = 12.sp,
                color = AppColors.TextSecondary
            )
        }

        // Value + Stepper
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "$value",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = AppColors.Primary
            )

            // Minus button
            Surface(
                modifier = Modifier.size(32.dp),
                shape = RoundedCornerShape(8.dp),
                color = AppColors.Background,
                onClick = { onValueChange(value - 1) }
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Filled.Remove,
                        contentDescription = "Azalt",
                        modifier = Modifier.size(16.dp),
                        tint = AppColors.TextSecondary
                    )
                }
            }

            // Plus button
            Surface(
                modifier = Modifier.size(32.dp),
                shape = RoundedCornerShape(8.dp),
                color = AppColors.Background,
                onClick = { onValueChange(value + 1) }
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Filled.Add,
                        contentDescription = "Artır",
                        modifier = Modifier.size(16.dp),
                        tint = AppColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun PositionChip(
    position: PlayerPosition,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        color = if (isSelected) AppColors.Primary else AppColors.Background
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 10.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = position.icon,
                fontSize = 12.sp
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = position.displayName,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (isSelected) Color.White else AppColors.TextPrimary,
                maxLines = 1
            )
        }
    }
}
