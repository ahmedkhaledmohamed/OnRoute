package com.ahmedkhaled.onroute.ui.screen

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.ahmedkhaled.onroute.ui.component.DetourBadge
import com.ahmedkhaled.onroute.ui.component.RouteInputPanel
import com.ahmedkhaled.onroute.viewmodel.RouteViewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@Composable
fun MainScreen(viewModel: RouteViewModel = viewModel()) {
    val toronto = LatLng(43.6532, -79.3832)
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(toronto, 12f)
    }
    val scope = rememberCoroutineScope()

    val locationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            scope.launch {
                viewModel.locationService.getCurrentLocation()?.let { latLng ->
                    viewModel.useCurrentLocation(latLng)
                }
            }
        }
    }

    // Fit camera to route when it changes
    LaunchedEffect(viewModel.routePoints) {
        if (viewModel.routePoints.size >= 2) {
            val boundsBuilder = LatLngBounds.Builder()
            viewModel.routePoints.forEach { boundsBuilder.include(it) }
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLngBounds(boundsBuilder.build(), 100)
            )
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        GoogleMap(
            modifier = Modifier.fillMaxSize(),
            cameraPositionState = cameraPositionState,
            properties = MapProperties(isMyLocationEnabled = false),
            uiSettings = MapUiSettings(zoomControlsEnabled = false)
        ) {
            // Route polyline
            if (viewModel.routePoints.isNotEmpty()) {
                Polyline(
                    points = viewModel.routePoints,
                    color = Color(0xFF2196F3),
                    width = 12f
                )
            }

            // POI markers
            viewModel.filteredResults.forEach { poi ->
                val isSelected = viewModel.selectedPOI == poi
                MarkerInfoWindow(
                    state = MarkerState(position = poi.latLng),
                    title = poi.name,
                    alpha = if (viewModel.selectedPOI != null && !isSelected) 0.3f else 1.0f,
                    onClick = {
                        viewModel.selectedPOI = poi
                        false
                    }
                ) {
                    DetourBadge(poi = poi)
                }
            }
        }

        // Bottom panel
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            // Trip info pill
            if (viewModel.routeDurationFormatted != null) {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    tonalElevation = 4.dp,
                    modifier = Modifier.padding(bottom = 8.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(
                            Icons.Default.DirectionsCar,
                            null,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            "${viewModel.routeDurationFormatted} · ${viewModel.routeDistanceFormatted}",
                            fontSize = 14.sp
                        )
                    }
                }
            }

            // Loading indicator
            if (viewModel.isLoading) {
                Surface(
                    shape = RoundedCornerShape(20.dp),
                    tonalElevation = 4.dp,
                    modifier = Modifier.padding(bottom = 8.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                        Text("Searching...", fontSize = 13.sp)
                    }
                }
            }

            // Error
            if (viewModel.errorMessage != null) {
                Surface(
                    shape = RoundedCornerShape(10.dp),
                    color = MaterialTheme.colorScheme.errorContainer,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp)
                ) {
                    Text(
                        viewModel.errorMessage ?: "",
                        modifier = Modifier.padding(12.dp),
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        fontSize = 13.sp
                    )
                }
            }

            RouteInputPanel(
                viewModel = viewModel,
                onSearch = { viewModel.search() },
                onCurrentLocation = {
                    locationPermissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
                }
            )
        }
    }
}
