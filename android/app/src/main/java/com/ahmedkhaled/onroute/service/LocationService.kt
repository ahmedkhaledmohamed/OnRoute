package com.ahmedkhaled.onroute.service

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.maps.model.LatLng
import kotlinx.coroutines.delay
import kotlinx.coroutines.tasks.await

class LocationService(private val context: Context) {
    private val fusedClient = LocationServices.getFusedLocationProviderClient(context)

    fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    @SuppressLint("MissingPermission")
    suspend fun getCurrentLocation(): LatLng? {
        if (!hasLocationPermission()) return null

        // Try high accuracy first (handles GPS cold starts after travel),
        // then fall back to balanced, then last known location
        val priorities = listOf(
            Priority.PRIORITY_HIGH_ACCURACY,
            Priority.PRIORITY_BALANCED_POWER_ACCURACY,
        )

        for (priority in priorities) {
            try {
                val location = fusedClient.getCurrentLocation(priority, null).await()
                if (location != null) return LatLng(location.latitude, location.longitude)
            } catch (_: Exception) { }
            delay(500)
        }

        return try {
            val last = fusedClient.lastLocation.await()
            last?.let { LatLng(it.latitude, it.longitude) }
        } catch (_: Exception) {
            null
        }
    }
}
