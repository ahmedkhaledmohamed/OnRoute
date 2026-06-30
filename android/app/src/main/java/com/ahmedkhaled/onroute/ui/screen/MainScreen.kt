package com.ahmedkhaled.onroute.ui.screen

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import android.content.Intent
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.History
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.mutableIntStateOf
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
import com.google.android.gms.maps.model.MapStyleOptions
import com.google.maps.android.compose.*
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(viewModel: RouteViewModel = viewModel()) {
    val cameraPositionState = rememberCameraPositionState {
        position = CameraPosition.fromLatLngZoom(LatLng(0.0, 0.0), 2f)
    }
    val scope = rememberCoroutineScope()
    val sheetState = rememberBottomSheetScaffoldState()
    val isDark = isSystemInDarkTheme()

    val mapProperties = remember(isDark) {
        MapProperties(
            mapStyleOptions = if (isDark) {
                MapStyleOptions(DARK_MAP_STYLE)
            } else null,
            isMyLocationEnabled = false
        )
    }

    var hasRequestedLocation by remember { mutableStateOf(false) }
    var showNPSPrompt by remember { mutableStateOf(false) }
    var showEmailPrompt by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("onroute_prompts", android.content.Context.MODE_PRIVATE) }
    var searchCount by remember { mutableIntStateOf(prefs.getInt("searchCount", 0)) }

    val locationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            scope.launch {
                viewModel.locationService.getCurrentLocation()?.let { latLng ->
                    if (!hasRequestedLocation) {
                        cameraPositionState.animate(
                            CameraUpdateFactory.newLatLngZoom(latLng, 13f)
                        )
                        hasRequestedLocation = true
                    }
                    viewModel.useCurrentLocation(latLng)
                }
            }
        }
    }

    LaunchedEffect(Unit) {
        if (viewModel.locationService.hasLocationPermission()) {
            viewModel.locationService.getCurrentLocation()?.let { latLng ->
                cameraPositionState.animate(
                    CameraUpdateFactory.newLatLngZoom(latLng, 13f)
                )
                hasRequestedLocation = true
            }
        } else {
            locationPermissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
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
            searchCount++
            prefs.edit().putInt("searchCount", searchCount).apply()
            if (searchCount == 5 && !prefs.getBoolean("hasSubmittedNPS", false)) {
                kotlinx.coroutines.delay(2000)
                showNPSPrompt = true
            }
            if (searchCount == 1 && !prefs.getBoolean("hasSeenEmailPrompt", false)) {
                kotlinx.coroutines.delay(3000)
                showEmailPrompt = true
            }
        }
    }

    LaunchedEffect(viewModel.selectedPOI) {
        if (viewModel.selectedPOI != null && sheetState.bottomSheetState.hasExpandedState) {
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
                properties = mapProperties,
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
                    .padding(horizontal = 8.dp)
                    .padding(bottom = 8.dp)
                    .navigationBarsPadding()
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
                                Icon(viewModel.travelMode.icon, null, modifier = Modifier.size(14.dp))
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

                if (showNPSPrompt) {
                    NPSPrompt(onDismiss = {
                        showNPSPrompt = false
                        prefs.edit().putBoolean("hasSubmittedNPS", true).apply()
                    })
                    Spacer(modifier = Modifier.height(8.dp))
                }

                if (showEmailPrompt) {
                    EmailPrompt(onDismiss = { _ ->
                        showEmailPrompt = false
                        prefs.edit().putBoolean("hasSeenEmailPrompt", true).apply()
                    })
                    Spacer(modifier = Modifier.height(8.dp))
                }

                if (viewModel.routePoints.isEmpty() && viewModel.savedRoutes.isNotEmpty()) {
                    SavedRoutesBar(
                        routes = viewModel.savedRoutes,
                        onSelect = { viewModel.loadSavedRoute(it) },
                        modifier = Modifier.padding(bottom = 8.dp)
                    )
                }

                if (viewModel.routePoints.isEmpty() && viewModel.savedRoutes.isEmpty() && viewModel.recentSearches.isNotEmpty()) {
                    Row(
                        modifier = Modifier
                            .horizontalScroll(rememberScrollState())
                            .padding(start = 12.dp, end = 12.dp, bottom = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        viewModel.recentSearches.take(5).forEach { recent ->
                            Surface(
                                onClick = { viewModel.loadRecentSearch(recent) },
                                shape = RoundedCornerShape(20.dp),
                                tonalElevation = 2.dp
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Icon(Icons.Default.History, null, modifier = Modifier.size(12.dp))
                                    Text("${recent.originName} → ${recent.destinationName}", fontSize = 11.sp, maxLines = 1)
                                }
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
        val selectedPoi = viewModel.selectedPOI
        AnimatedVisibility(visible = selectedPoi != null) {
            Column {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        selectedPoi?.name ?: "",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.weight(1f),
                        maxLines = 1
                    )
                    FilledTonalButton(
                        onClick = {
                            selectedPoi?.let { poi ->
                                NavigationService.openGoogleMaps(
                                    context, poi,
                                    viewModel.originName,
                                    viewModel.destinationName,
                                    viewModel.travelMode.apiValue
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
            if (viewModel.isSearchReady) {
                IconButton(
                    onClick = {
                        val shareUrl = buildShareUrl(viewModel)
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, "${viewModel.originName ?: "A"} → ${viewModel.destinationName ?: "B"} — ${viewModel.filteredResults.size} stops found on OnRoute\n$shareUrl")
                        }
                        context.startActivity(Intent.createChooser(intent, "Share route"))
                    },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(Icons.Default.Share, "Share route", modifier = Modifier.size(18.dp))
                }
                IconButton(
                    onClick = {
                        val name = "${viewModel.originName ?: "A"} → ${viewModel.destinationName ?: "B"}"
                        viewModel.saveCurrentRoute(name)
                    },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(Icons.Default.Bookmark, "Save route", modifier = Modifier.size(18.dp))
                }
            }
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
                                viewModel.destinationName,
                                viewModel.travelMode.apiValue
                            )
                        }
                    )
                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                }
            }
        }
    }
}

private fun buildShareUrl(viewModel: RouteViewModel): String {
    val base = "https://backend-navy-iota.vercel.app/api/share"
    val params = mutableListOf<String>()
    viewModel.originLatLng?.let {
        params.add("oLat=${it.latitude}")
        params.add("oLng=${it.longitude}")
    }
    viewModel.destinationLatLng?.let {
        params.add("dLat=${it.latitude}")
        params.add("dLng=${it.longitude}")
    }
    params.add("oName=${java.net.URLEncoder.encode(viewModel.originName ?: "Origin", "UTF-8")}")
    params.add("dName=${java.net.URLEncoder.encode(viewModel.destinationName ?: "Destination", "UTF-8")}")
    params.add("query=${java.net.URLEncoder.encode(viewModel.searchQuery, "UTF-8")}")
    params.add("results=${viewModel.filteredResults.size}")
    return "$base?${params.joinToString("&")}"
}

private const val DARK_MAP_STYLE = """[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]"""
