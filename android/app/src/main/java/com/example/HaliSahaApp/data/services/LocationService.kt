package com.example.HaliSahaApp.data.services

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.net.Uri
import android.os.Looper
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.example.HaliSahaApp.data.models.UserLocation
import com.example.HaliSahaApp.utils.AppConstants
import com.google.android.gms.location.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

// MARK: - Location Error
sealed class LocationError(message: String) : Exception(message) {
    object PermissionDenied : LocationError("Konum izni reddedildi. Ayarlardan izin verebilirsiniz.")
    object LocationDisabled : LocationError("Konum servisi kapalı. Lütfen konumu açın.")
    object NetworkError : LocationError("Ağ hatası veya konum alınamadı.")
    class Unknown(message: String) : LocationError(message)
}

// MARK: - Location Service (Singleton)
@SuppressLint("MissingPermission") // İzin kontrollerini fonksiyon içinde yapıyoruz
object LocationService {

    private var fusedLocationClient: FusedLocationProviderClient? = null

    // UI State (Swift'teki @Published karşılıkları)
    private val _userLocation = MutableStateFlow<UserLocation?>(null)
    val userLocation: StateFlow<UserLocation?> = _userLocation.asStateFlow()

    private val _isLocating = MutableStateFlow(false)
    val isLocating: StateFlow<Boolean> = _isLocating.asStateFlow()

    private val _locationError = MutableStateFlow<LocationError?>(null)
    val locationError: StateFlow<LocationError?> = _locationError.asStateFlow()

    // Varsayılan Konum (İstanbul)
    val defaultLocation = UserLocation(
        AppConstants.DEFAULT_LATITUDE,
        AppConstants.DEFAULT_LONGITUDE
    )

    // Init (Application onCreate içinde çağrılmalı)
    fun initialize(context: Context) {
        if (fusedLocationClient == null) {
            fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
        }
    }

    // MARK: - Permissions Helper
    fun hasLocationPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
    }

    // MARK: - Get Current Location (One Shot)
    suspend fun getCurrentLocation(context: Context): UserLocation {
        // İzin Kontrolü
        if (!hasLocationPermission(context)) {
            _locationError.value = LocationError.PermissionDenied
            throw LocationError.PermissionDenied
        }

        initialize(context)
        _isLocating.value = true

        return try {
            // Priority.PRIORITY_HIGH_ACCURACY kullanarak anlık konum al
            val location: Location? = fusedLocationClient?.getCurrentLocation(
                Priority.PRIORITY_HIGH_ACCURACY,
                null // CancellationToken
            )?.await()

            if (location != null) {
                val userLoc = UserLocation(location.latitude, location.longitude)
                _userLocation.value = userLoc
                _isLocating.value = false
                userLoc
            } else {
                _isLocating.value = false
                _locationError.value = LocationError.NetworkError
                throw LocationError.NetworkError
            }
        } catch (e: Exception) {
            _isLocating.value = false
            val error = LocationError.Unknown(e.localizedMessage ?: "Bilinmeyen hata")
            _locationError.value = error
            throw error
        }
    }

    // MARK: - Start Updating Location (Continuous)
    private var locationCallback: LocationCallback? = null

    fun startUpdatingLocation(context: Context) {
        if (!hasLocationPermission(context)) {
            _locationError.value = LocationError.PermissionDenied
            return
        }

        initialize(context)

        if (_isLocating.value) return // Zaten çalışıyorsa tekrar başlatma
        _isLocating.value = true

        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            10000 // 10 saniyede bir güncelle
        ).apply {
            setMinUpdateDistanceMeters(100f) // 100 metre değişince güncelle (Swift ile aynı)
        }.build()

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { location ->
                    _userLocation.value = UserLocation(location.latitude, location.longitude)
                    _locationError.value = null
                }
            }

            override fun onLocationAvailability(availability: LocationAvailability) {
                if (!availability.isLocationAvailable) {
                    _locationError.value = LocationError.LocationDisabled
                }
            }
        }

        fusedLocationClient?.requestLocationUpdates(
            locationRequest,
            locationCallback!!,
            Looper.getMainLooper()
        )
    }

    fun stopUpdatingLocation() {
        locationCallback?.let {
            fusedLocationClient?.removeLocationUpdates(it)
        }
        locationCallback = null
        _isLocating.value = false
    }

    // MARK: - Open Settings
    fun openSettings(context: Context) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}