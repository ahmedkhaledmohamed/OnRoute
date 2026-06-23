package com.ahmedkhaled.onroute.ui.component

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ahmedkhaled.onroute.model.POIResult

@Composable
fun DetourBadge(poi: POIResult, modifier: Modifier = Modifier) {
    Text(
        text = poi.detourFormatted,
        color = Color.White,
        fontSize = 10.sp,
        fontWeight = FontWeight.Bold,
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(poi.detourColor)
            .padding(horizontal = 6.dp, vertical = 3.dp)
    )
}
