package com.ahmedkhaled.onroute.ui.screen

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Email
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.ahmedkhaled.onroute.service.NavigationService
import com.ahmedkhaled.onroute.ui.component.*
import com.ahmedkhaled.onroute.viewmodel.RouteViewModel
import androidx.compose.ui.platform.LocalContext
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.CameraPosition
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(viewModel: RouteViewModel = viewModel()) {
    val toronto = LatLng(43.6532, -79.3832)
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(toronto, 12f)
    }
    val scope = rememberCoroutineScope()
    val sheetState = rememberBottomSheetScaffoldState()

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

    LaunchedEffect(viewModel.routePoints) {
        if (viewModel.routePoints.size >= 2) {
            val boundsBuilder = LatLngBounds.Builder()
            viewModel.routePoints.forEach { boundsBuilder.include(it) }
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLngBounds(boundsBuilder.build(), 100)
            )
        }
    }

    LaunchedEffect(viewModel.poiResults) {
        if (viewModel.poiResults.isNotEmpty()) {
            sheetState.bottomSheetState.expand()
        }
    }

    BottomSheetScaffold(
        scaffoldState = sheetState,
        sheetPeekHeight = 0.dp,
        sheetShape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp),
        sheetContent = {
            ResultsSheet(viewModel = viewModel)
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            GoogleMap(
                modifier = Modifier.fillMaxSize(),
                cameraPositionState = cameraPositionState,
                uiSettings = MapUiSettings(zoomControlsEnabled = false)
            ) {
                val hasDetour = viewModel.detourRoutePoints.isNotEmpty()

                if (viewModel.routePoints.isNotEmpty()) {
                    Polyline(
                        points = viewModel.routePoints,
                        color = Color(0xFF2196F3).copy(alpha = if (hasDetour) 0.3f else 1f),
                        width = 12f
                    )
                }

                if (hasDetour) {
                    Polyline(
                        points = viewModel.detourRoutePoints,
                        color = Color(0xFFFF9800),
                        width = 12f
                    )
                }

                // A/B/C waypoint markers when POI selected
                if (viewModel.selectedPOI != null) {
                    viewModel.originLatLng?.let { origin ->
                        MarkerInfoWindow(state = MarkerState(position = origin)) {
                            WaypointMarker("A", Color(0xFF4CAF50), "Start")
                        }
                    }
                    viewModel.selectedPOI?.let { poi ->
                        MarkerInfoWindow(state = MarkerState(position = poi.latLng)) {
                            WaypointMarker("B", Color(0xFFFF9800), poi.name)
                        }
                    }
                    viewModel.destinationLatLng?.let { dest ->
                        MarkerInfoWindow(state = MarkerState(position = dest)) {
                            WaypointMarker("C", Color(0xFFF44336), "End")
                        }
                    }
                }

                viewModel.filteredResults.forEach { poi ->
                    val isSelected = viewModel.selectedPOI == poi
                    if (!isSelected) {
                        MarkerInfoWindow(
                            state = MarkerState(position = poi.latLng),
                            title = poi.name,
                            alpha = if (viewModel.selectedPOI != null) 0.2f else 1.0f,
                            onClick = {
                                viewModel.selectPOI(poi)
                                false
                            }
                        ) {
                            DetourBadge(poi = poi)
                        }
                    }
                }
            }

            // Bottom panel
            Column(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                if (viewModel.routeDurationFormatted != null) {
                    Row(
                        modifier = Modifier.padding(bottom = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(20.dp),
                            tonalElevation = 4.dp
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Icon(Icons.Default.DirectionsCar, null, modifier = Modifier.size(14.dp))
                                Text(
                                    "${viewModel.routeDurationFormatted} · ${viewModel.routeDistanceFormatted}",
                                    fontSize = 14.sp
                                )
                            }
                        }

                        if (viewModel.filteredResults.isNotEmpty()) {
                            FilledTonalButton(
                                onClick = { scope.launch { sheetState.bottomSheetState.expand() } },
                                shape = RoundedCornerShape(20.dp),
                                contentPadding = PaddingValues(horizontal = 14.dp, vertical = 8.dp)
                            ) {
                                Text("${viewModel.filteredResults.size} places", fontSize = 13.sp)
                            }
                        }
                    }
                }

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

                if (viewModel.errorMessage != null) {
                    Surface(
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.errorContainer,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Text(
                                viewModel.errorMessage ?: "",
                                modifier = Modifier.weight(1f),
                                color = MaterialTheme.colorScheme.onErrorContainer,
                                fontSize = 13.sp
                            )
                            TextButton(onClick = { viewModel.search() }) {
                                Text("Retry")
                            }
                            TextButton(onClick = { viewModel.errorMessage = null }) {
                                Text("Dismiss")
                            }
                        }
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
}

@Composable
private fun ResultsSheet(viewModel: RouteViewModel) {
    val context = LocalContext.current
    Column(modifier = Modifier.fillMaxWidth()) {
        // Selected POI header with Open in Maps + clear
        if (viewModel.selectedPOI != null) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    viewModel.selectedPOI?.name ?: "",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                    maxLines = 1
                )
                FilledTonalButton(
                    onClick = {
                        viewModel.selectedPOI?.let { poi ->
                            NavigationService.openGoogleMaps(
                                context, poi,
                                viewModel.originName,
                                viewModel.destinationName
                            )
                        }
                    },
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                ) {
                    Text("Open in Maps", fontSize = 12.sp)
                }
                IconButton(
                    onClick = { viewModel.clearDetour() },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(Icons.Default.Close, "Clear", modifier = Modifier.size(18.dp))
                }
            }
            HorizontalDivider()
        }

        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "${viewModel.filteredResults.size} places found",
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f)
            )
            IconButton(
                onClick = { NavigationService.sendFeedback(context) },
                modifier = Modifier.size(32.dp)
            ) {
                Icon(Icons.Default.Email, "Send feedback", modifier = Modifier.size(18.dp))
            }
        }

        CategoryBar(
            selectedCategory = viewModel.selectedCategory,
            onCategorySelected = { viewModel.selectCategory(it) }
        )

        Spacer(modifier = Modifier.height(8.dp))

        FiltersBar(
            maxDetourMinutes = viewModel.maxDetourMinutes,
            onMaxDetourChange = { viewModel.maxDetourMinutes = it },
            openNowOnly = viewModel.openNowOnly,
            onOpenNowChange = { viewModel.openNowOnly = it }
        )

        HorizontalDivider(modifier = Modifier.padding(top = 8.dp))

        if (viewModel.isLoading) {
            Box(modifier = Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (viewModel.filteredResults.isEmpty()) {
            Box(modifier = Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
                Text("No places found", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        } else {
            LazyColumn(modifier = Modifier.heightIn(max = 400.dp)) {
                items(viewModel.filteredResults, key = { it.placeId }) { poi ->
                    POIResultRow(
                        poi = poi,
                        isSelected = viewModel.selectedPOI == poi,
                        onTap = { viewModel.selectPOI(poi) },
                        onNavigate = {
                            NavigationService.openGoogleMaps(
                                context, poi,
                                viewModel.originName,
                                viewModel.destinationName
                            )
                        }
                    )
                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                }
            }
        }
    }
}
