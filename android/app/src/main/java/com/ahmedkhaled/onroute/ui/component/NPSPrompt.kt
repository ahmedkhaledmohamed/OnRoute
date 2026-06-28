package com.ahmedkhaled.onroute.ui.component

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
fun NPSPrompt(onDismiss: () -> Unit) {
    var selectedScore by remember { mutableIntStateOf(-1) }
    var comment by remember { mutableStateOf("") }
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
                Icon(Icons.Default.CheckCircle, null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(32.dp))
                Spacer(modifier = Modifier.height(8.dp))
                Text("Thanks for your feedback!", fontSize = 14.sp)
                LaunchedEffect(Unit) {
                    kotlinx.coroutines.delay(1500)
                    onDismiss()
                }
            } else {
                Text("How likely are you to recommend OnRoute?", fontSize = 14.sp, fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(12.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    (0..10).forEach { score ->
                        Surface(
                            onClick = { selectedScore = score },
                            shape = CircleShape,
                            color = if (selectedScore == score) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier.size(28.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    "$score",
                                    fontSize = 10.sp,
                                    color = if (selectedScore == score) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }

                Row(modifier = Modifier.fillMaxWidth().padding(top = 4.dp)) {
                    Text("Not likely", fontSize = 10.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(modifier = Modifier.weight(1f))
                    Text("Very likely", fontSize = 10.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = comment,
                    onValueChange = { comment = it },
                    placeholder = { Text("Any other feedback? (optional)", fontSize = 12.sp) },
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = LocalTextStyle.current.copy(fontSize = 12.sp),
                    minLines = 1,
                    maxLines = 3
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    TextButton(onClick = onDismiss) { Text("Not now", fontSize = 12.sp) }
                    Button(
                        onClick = {
                            submitNPS(selectedScore, comment)
                            submitted = true
                        },
                        enabled = selectedScore >= 0
                    ) { Text("Submit", fontSize = 12.sp) }
                }
            }
        }
    }
}

private fun submitNPS(score: Int, comment: String) {
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val body = JSONObject().apply {
                put("anonymousId", AnalyticsService.anonymousId)
                put("score", score)
                put("comment", comment)
                put("platform", "Android")
            }
            val request = Request.Builder()
                .url("https://backend-navy-iota.vercel.app/api/feedback")
                .post(body.toString().toRequestBody("application/json".toMediaType()))
                .build()
            OkHttpClient().newCall(request).execute().close()
        } catch (_: Exception) { }
    }
}
