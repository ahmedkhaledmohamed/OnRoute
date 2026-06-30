package com.ahmedkhaled.onroute.service

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.ahmedkhaled.onroute.model.POIResult
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.URLEncoder

object NavigationService {

    fun openGoogleMaps(
        context: Context,
        poi: POIResult,
        originName: String?,
        destinationName: String?,
        travelMode: String = "DRIVE"
    ) {
        val origin = URLEncoder.encode(originName ?: "", "UTF-8")
        val stop = URLEncoder.encode(poi.address, "UTF-8")
        val dest = URLEncoder.encode(destinationName ?: "", "UTF-8")
        val mode = when (travelMode) {
            "WALK" -> "walking"
            "BICYCLE" -> "bicycling"
            else -> "driving"
        }
        AnalyticsService.track("navigation_opened", mapOf("app" to "Google Maps"))
        recordVisit(poi)
        val url = "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&waypoints=$stop&travelmode=$mode"
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        context.startActivity(intent)
    }

    fun openWaze(context: Context, poi: POIResult) {
        AnalyticsService.track("navigation_opened", mapOf("app" to "Waze"))
        recordVisit(poi)
        val url = "waze://?ll=${poi.lat},${poi.lng}&navigate=yes"
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            context.startActivity(intent)
        } catch (e: Exception) {
            val webUrl = "https://waze.com/ul?ll=${poi.lat},${poi.lng}&navigate=yes"
            context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(webUrl)))
        }
    }

    fun copyAddress(context: Context, poi: POIResult) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("Address", poi.address))
    }

    private fun recordVisit(poi: POIResult) {
        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
            try {
                val body = org.json.JSONObject().apply {
                    put("placeId", poi.placeId)
                    put("placeName", poi.name)
                    put("lat", poi.lat)
                    put("lng", poi.lng)
                }
                val request = okhttp3.Request.Builder()
                    .url("https://backend-navy-iota.vercel.app/api/visit")
                    .addHeader("X-Anonymous-Id", AnalyticsService.anonymousId)
                    .post(body.toString().toRequestBody("application/json".toMediaType()))
                    .build()
                okhttp3.OkHttpClient().newCall(request).execute().close()
            } catch (_: Exception) { }
        }
    }

    fun sendFeedback(context: Context) {
        val subject = URLEncoder.encode("OnRoute Beta Feedback", "UTF-8")
        val body = URLEncoder.encode(
            "\n\n---\nOnRoute v1.0.0 (Android ${android.os.Build.VERSION.RELEASE})",
            "UTF-8"
        )
        val uri = Uri.parse("mailto:ahmed.khaled.a.mohamed@gmail.com?subject=$subject&body=$body")
        val intent = Intent(Intent.ACTION_SENDTO, uri)
        context.startActivity(intent)
    }
}
