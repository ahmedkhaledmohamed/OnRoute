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
    val priceLevel: String? = null,
    val phoneNumber: String? = null,
    val todayHours: String? = null,
    val types: List<String>,
    val photoReference: String? = null
) {
    val latLng: LatLng get() = LatLng(lat, lng)

    val priceLevelDisplay: String? get() = when (priceLevel) {
        "PRICE_LEVEL_INEXPENSIVE" -> "$"
        "PRICE_LEVEL_MODERATE" -> "$$"
        "PRICE_LEVEL_EXPENSIVE" -> "$$$"
        "PRICE_LEVEL_VERY_EXPENSIVE" -> "$$$$"
        else -> null
    }

    val detourColor: Color
        get() {
            val minutes = detourSeconds / 60
            return when {
                minutes < 3 -> Color(0xFF33B249)
                minutes < 7 -> Color(0xFFE6B312)
                minutes < 15 -> Color(0xFFF28018)
                else -> Color(0xFFE63333)
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
data class StopResults(
    val query: String,
    val results: List<POIResult>
)

@JsonClass(generateAdapter = true)
data class SearchResponse(
    val results: List<POIResult>,
    val stops: List<StopResults>? = null,
    val route: RouteInfo,
    val cached: Boolean? = null
)

@JsonClass(generateAdapter = true)
data class SearchRequest(
    val origin: LatLngBody,
    val destination: LatLngBody,
    val query: String,
    val queries: List<String>? = null,
    val maxDetourMinutes: Int? = null,
    val openNow: Boolean = true,
    val travelMode: String = "DRIVE"
)

@JsonClass(generateAdapter = true)
data class LatLngBody(val lat: Double, val lng: Double)
