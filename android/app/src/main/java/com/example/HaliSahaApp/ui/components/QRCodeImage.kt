package com.example.HaliSahaApp.ui.components

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel

/**
 * iOS'taki QRCodeImage bileşeninin Android/Compose muadili.
 *
 * CoreImage.CIFilter.qrCodeGenerator() yerine ZXing kütüphanesi kullanılıyor.
 * Yüksek hata düzeltme seviyesi (H) ile QR kod üretir — kısmen kirli/yıpranmış
 * kodlar bile okunabilir.
 *
 * @param data QR kod içeriği (JSON veya bilet numarası)
 * @param size QR kod boyutu (dp)
 * @param foregroundColor QR kodunun ön plan rengi (default: siyah)
 * @param backgroundColor QR kodunun arka plan rengi (default: beyaz)
 */
@Composable
fun QRCodeImage(
    data: String,
    size: Dp = 220.dp,
    foregroundColor: Color = Color.Black,
    backgroundColor: Color = Color.White
) {
    val bitmap = remember(data, foregroundColor, backgroundColor) {
        generateQRCodeBitmap(
            data = data,
            sizePx = 600, // Yüksek çözünürlük
            foregroundColor = foregroundColor.toArgb(),
            backgroundColor = backgroundColor.toArgb()
        )
    }

    val cornerRadius = size * 0.08f
    val padding = size * 0.06f

    Box(
        modifier = Modifier
            .size(size + padding * 2)
            .clip(RoundedCornerShape(cornerRadius))
            .background(backgroundColor),
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = "QR Kod",
                contentScale = ContentScale.Fit,
                modifier = Modifier.size(size)
            )
        } else {
            // Fallback: veri boş veya QR üretimi başarısız
            Icon(
                imageVector = Icons.Default.QrCode,
                contentDescription = "QR Kod",
                tint = foregroundColor,
                modifier = Modifier.size(size * 0.7f)
            )
        }
    }
}

/**
 * ZXing kütüphanesi ile QR kod bitmap'i üretir.
 *
 * iOS'taki eşdeğeri:
 * ```swift
 * let filter = CIFilter.qrCodeGenerator()
 * filter.message = Data(data.utf8)
 * filter.correctionLevel = "H"
 * ```
 */
private fun generateQRCodeBitmap(
    data: String,
    sizePx: Int,
    foregroundColor: Int,
    backgroundColor: Int
): Bitmap? {
    if (data.isEmpty()) return null

    return try {
        val hints = mapOf(
            EncodeHintType.ERROR_CORRECTION to ErrorCorrectionLevel.H, // Yüksek hata düzeltme (iOS: "H")
            EncodeHintType.MARGIN to 1,
            EncodeHintType.CHARACTER_SET to "UTF-8"
        )

        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(data, BarcodeFormat.QR_CODE, sizePx, sizePx, hints)

        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        for (x in 0 until sizePx) {
            for (y in 0 until sizePx) {
                bitmap.setPixel(x, y, if (bitMatrix[x, y]) foregroundColor else backgroundColor)
            }
        }
        bitmap
    } catch (e: Exception) {
        null
    }
}
