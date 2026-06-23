package com.ahmedkhaled.onroute.model

import androidx.compose.ui.graphics.Color
import com.google.android.gms.maps.model.LatLng
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class POIResult(
    val placeId: String,
    val name: String,
    val address: String,
    val lat: Double,
    val lng: Double,
    val detourSeconds: Int,
    val detourFormatted: String,
    val rating: Double,
    val userRatingCount: Int,
    val isOpenNow: Boolean,
    val types: List<String>,
    val photoReference: String? = null
) {
    val latLng: LatLng get() = LatLng(lat, lng)

    val detourColor: Color
        get() {
            val minutes = detourSeconds / 60
            return when {
                minutes < 3 -> Color(0xFF4CAF50)
                minutes < 7 -> Color(0xFFFFC107)
                minutes < 15 -> Color(0xFFFF9800)
                else -> Color(0xFFF44336)
            }
        }
}

@JsonClass(generateAdapter = true)
data class RouteInfo(
    val encodedPolyline: String,
    val durationSeconds: Int,
    val distanceMeters: Int
)

@JsonClass(generateAdapter = true)
data class SearchResponse(
    val results: List<POIResult>,
    val route: RouteInfo,
    val cached: Boolean? = null
)

@JsonClass(generateAdapter = true)
data class SearchRequest(
    val origin: LatLngBody,
    val destination: LatLngBody,
    val query: String,
    val maxDetourMinutes: Int? = null,
    val openNow: Boolean = true,
    val travelMode: String = "DRIVE"
)

@JsonClass(generateAdapter = true)
data class LatLngBody(val lat: Double, val lng: Double)
