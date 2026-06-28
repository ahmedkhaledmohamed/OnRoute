package com.ahmedkhaled.onroute.ui.component

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ahmedkhaled.onroute.service.AnalyticsService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

@Composable
fun EmailPrompt(onDismiss: (submitted: Boolean) -> Unit) {
    var email by remember { mutableStateOf("") }
    var submitted by remember { mutableStateOf(false) }

    Surface(
        shape = RoundedCornerShape(16.dp),
        tonalElevation = 8.dp,
        shadowElevation = 4.dp,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (submitted) {
                Icon(Icons.Default.Email, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(28.dp))
                Spacer(modifier = Modifier.height(8.dp))
                Text("You're on the list!", fontSize = 14.sp, fontWeight = FontWeight.Medium)
                LaunchedEffect(Unit) {
                    kotlinx.coroutines.delay(1500)
                    onDismiss(true)
                }
            } else {
                Text("Get OnRoute updates", fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(4.dp))
                Text("We'll let you know when new features drop.", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(modifier = Modifier.height(12.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        placeholder = { Text("your@email.com", fontSize = 12.sp) },
                        modifier = Modifier.weight(1f),
                        textStyle = LocalTextStyle.current.copy(fontSize = 12.sp),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
                    )
                    Button(
                        onClick = {
                            submitEmail(email)
                            submitted = true
                        },
                        enabled = email.contains("@"),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
                    ) { Text("Join", fontSize = 12.sp) }
                }

                Spacer(modifier = Modifier.height(4.dp))
                TextButton(onClick = { onDismiss(false) }) {
                    Text("No thanks", fontSize = 11.sp)
                }
            }
        }
    }
}

private fun submitEmail(email: String) {
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val body = JSONObject().apply {
                put("email", email.lowercase().trim())
                put("anonymousId", AnalyticsService.anonymousId)
                put("platform", "Android")
            }
            val request = Request.Builder()
                .url("https://backend-navy-iota.vercel.app/api/subscribe")
                .post(body.toString().toRequestBody("application/json".toMediaType()))
                .build()
            OkHttpClient().newCall(request).execute().close()
        } catch (_: Exception) { }
    }
}
