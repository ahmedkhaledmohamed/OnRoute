package com.ahmedkhaled.onroute.service

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.UUID

object AnalyticsService {
    private const val BASE_URL = "https://backend-navy-iota.vercel.app"
    private const val PREFS_NAME = "onroute_analytics"
    private const val KEY_ANONYMOUS_ID = "anonymous_id"

    private val client = OkHttpClient()
    private var anonymousId: String = ""

    fun init(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        anonymousId = prefs.getString(KEY_ANONYMOUS_ID, null) ?: run {
            val id = UUID.randomUUID().toString()
            prefs.edit().putString(KEY_ANONYMOUS_ID, id).apply()
            id
        }
    }

    fun track(event: String, properties: Map<String, Any> = emptyMap()) {
        if (anonymousId.isEmpty()) return

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val props = JSONObject()
                properties.forEach { (k, v) -> props.put(k, v) }

                val body = JSONObject().apply {
                    put("event", event)
                    put("anonymousId", anonymousId)
                    put("properties", props)
                }

                val request = Request.Builder()
                    .url("$BASE_URL/api/event")
                    .post(body.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                client.newCall(request).execute().close()
            } catch (_: Exception) { }
        }
    }
}
