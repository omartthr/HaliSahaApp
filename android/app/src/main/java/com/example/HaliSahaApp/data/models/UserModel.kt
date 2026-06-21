package com.example.HaliSahaApp.data.models

import android.location.Location

data class UserLocation(
    val latitude: Double,
    val longitude: Double
) {
    // Google Maps LatLng'sine çevirmek için kolaylık (İleride lazım olacak)
    // fun toGmsLatLng() = com.google.android.gms.maps.model.LatLng(latitude, longitude)

    // İki nokta arası mesafe hesaplama (km)
    fun distanceTo(other: UserLocation): Double {
        val results = FloatArray(1)
        Location.distanceBetween(latitude, longitude, other.latitude, other.longitude, results)
        return results[0] / 1000.0 // Metreyi km'ye çevir
    }
}