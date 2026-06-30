package com.ahmedkhaled.onroute.viewmodel

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.ahmedkhaled.onroute.model.*
import com.ahmedkhaled.onroute.model.RecentSearch
import com.ahmedkhaled.onroute.model.RecentSearchStore
import com.ahmedkhaled.onroute.model.SavedRoute
import com.ahmedkhaled.onroute.model.SavedRoutesStore
import com.ahmedkhaled.onroute.service.AnalyticsService
import com.ahmedkhaled.onroute.service.ApiService
import com.ahmedkhaled.onroute.service.DirectionsService
import com.ahmedkhaled.onroute.service.LocationService
import com.ahmedkhaled.onroute.service.PlaceAutocompleteService
import com.ahmedkhaled.onroute.service.PlaceSuggestion
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.places.api.Places
import com.google.maps.android.PolyUtil
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class RouteViewModel(application: Application) : AndroidViewModel(application) {

    var originQuery by mutableStateOf("")
        private set
    var destinationQuery by mutableStateOf("")
        private set
    var originLatLng by mutableStateOf<LatLng?>(null)
        private set
    var destinationLatLng by mutableStateOf<LatLng?>(null)
        private set
    var originName by mutableStateOf<String?>(null)
        private set
    var destinationName by mutableStateOf<String?>(null)
        private set

    var originSuggestions by mutableStateOf<List<PlaceSuggestion>>(emptyList())
        private set
    var destinationSuggestions by mutableStateOf<List<PlaceSuggestion>>(emptyList())
        private set

    var travelMode by mutableStateOf(TravelMode.DRIVE)
    var searchQuery by mutableStateOf("coffee")
        private set
    var additionalQueries by mutableStateOf<List<String>>(emptyList())
    var stopResults by mutableStateOf<List<StopResults>>(emptyList())
        private set
    var selectedCategory by mutableStateOf<Category?>(Category.COFFEE)
    var maxDetourMinutes by mutableStateOf(15f)
    var openNowOnly by mutableStateOf(true)

    var routePoints by mutableStateOf<List<LatLng>>(emptyList())
        private set
    var routeDurationFormatted by mutableStateOf<String?>(null)
        private set
    var routeDistanceFormatted by mutableStateOf<String?>(null)
        private set
    var poiResults by mutableStateOf<List<POIResult>>(emptyList())
        private set
    var selectedPOI by mutableStateOf<POIResult?>(null)
    var detourRoutePoints by mutableStateOf<List<LatLng>>(emptyList())
        private set
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)

    val isSearchReady: Boolean
        get() = originLatLng != null && destinationLatLng != null

    val filteredResults: List<POIResult>
        get() = poiResults.filter { poi ->
            val withinDetour = poi.detourSeconds <= (maxDetourMinutes * 60).toInt()
            val openFilter = !openNowOnly || poi.isOpenNow
            val isForward = isAheadOnRoute(poi)
            withinDetour && openFilter && isForward
        }

    private val placesService = PlaceAutocompleteService(Places.createClient(application))
    val locationService = LocationService(application)
    private val apiService = ApiService.create()
    private val directionsService = DirectionsService()
    val savedRoutesStore = SavedRoutesStore(application)
    private val recentSearchStore = RecentSearchStore(application)

    var savedRoutes by mutableStateOf<List<SavedRoute>>(emptyList())
        private set
    var recentSearches by mutableStateOf<List<RecentSearch>>(emptyList())
        private set

    init {
        savedRoutes = savedRoutesStore.load()
        recentSearches = recentSearchStore.load()
    }

    private var originDebounceJob: Job? = null
    private var destinationDebounceJob: Job? = null
    private var originResolveId = 0
    private var destinationResolveId = 0

    fun updateOriginQuery(query: String) {
        if (query == originQuery) return
        originQuery = query
        originLatLng = null
        originName = null
        originDebounceJob?.cancel()
        originDebounceJob = viewModelScope.launch {
            delay(300)
            originSuggestions = placesService.getSuggestions(query)
        }
    }

    fun updateDestinationQuery(query: String) {
        if (query == destinationQuery) return
        destinationQuery = query
        destinationLatLng = null
        destinationName = null
        destinationDebounceJob?.cancel()
        destinationDebounceJob = viewModelScope.launch {
            delay(300)
            destinationSuggestions = placesService.getSuggestions(query)
        }
    }

    fun selectOriginSuggestion(suggestion: PlaceSuggestion) {
        originQuery = suggestion.title
        originSuggestions = emptyList()
        val requestId = ++originResolveId
        viewModelScope.launch {
            placesService.resolvePlace(suggestion.placeId)?.let { (latLng, name) ->
                if (requestId == originResolveId) {
                    originLatLng = latLng
                    originName = name.ifEmpty { suggestion.title }
                }
            }
        }
    }

    fun selectDestinationSuggestion(suggestion: PlaceSuggestion) {
        destinationQuery = suggestion.title
        destinationSuggestions = emptyList()
        val requestId = ++destinationResolveId
        viewModelScope.launch {
            placesService.resolvePlace(suggestion.placeId)?.let { (latLng, name) ->
                if (requestId == destinationResolveId) {
                    destinationLatLng = latLng
                    destinationName = name.ifEmpty { suggestion.title }
                }
            }
        }
    }

    fun useCurrentLocation(latLng: LatLng) {
        originQuery = "Current Location"
        originLatLng = latLng
        originName = "Current Location"
        originSuggestions = emptyList()
    }

    private var categoryDebounceJob: Job? = null

    fun selectCategory(category: Category) {
        selectedCategory = category
        searchQuery = category.query
        categoryDebounceJob?.cancel()
        categoryDebounceJob = viewModelScope.launch {
            delay(300)
            if (isSearchReady) search()
        }
    }

    fun search() {
        val origin = originLatLng ?: return
        val destination = destinationLatLng ?: return
        isLoading = true
        errorMessage = null
        poiResults = emptyList()
        selectedPOI = null

        viewModelScope.launch {
            try {
                val allQueries = if (additionalQueries.isNotEmpty()) listOf(searchQuery) + additionalQueries else null
                val response = apiService.search(
                    SearchRequest(
                        origin = LatLngBody(origin.latitude, origin.longitude),
                        destination = LatLngBody(destination.latitude, destination.longitude),
                        query = searchQuery,
                        queries = allQueries,
                        maxDetourMinutes = maxDetourMinutes.toInt(),
                        openNow = openNowOnly,
                        travelMode = travelMode.apiValue
                    )
                )

                routePoints = PolyUtil.decode(response.route.encodedPolyline)

                val minutes = response.route.durationSeconds / 60
                routeDurationFormatted = if (minutes >= 60) "${minutes / 60}h ${minutes % 60}min" else "$minutes min"
                val km = response.route.distanceMeters / 1000.0
                routeDistanceFormatted = if (km >= 10) "%.0f km".format(km) else "%.1f km".format(km)

                poiResults = response.results
                stopResults = response.stops ?: emptyList()
                if (response.results.isEmpty()) {
                    errorMessage = "No places found along this route. Try a different category."
                }
                isLoading = false
                AnalyticsService.track("search_executed", mapOf(
                    "category" to (selectedCategory?.name ?: "custom"),
                    "travelMode" to travelMode.apiValue,
                    "resultCount" to response.results.size,
                ))
                val o = originLatLng
                val d = destinationLatLng
                if (o != null && d != null) {
                    recentSearchStore.add(
                        originName ?: "Origin", o,
                        destinationName ?: "Destination", d,
                        searchQuery
                    )
                    recentSearches = recentSearchStore.load()
                }
            } catch (e: Exception) {
                errorMessage = e.message ?: "Search failed"
                isLoading = false
            }
        }
    }

    fun swapOriginDestination() {
        val tmpQuery = originQuery
        val tmpLatLng = originLatLng
        val tmpName = originName
        originQuery = destinationQuery
        originLatLng = destinationLatLng
        originName = destinationName
        destinationQuery = tmpQuery
        destinationLatLng = tmpLatLng
        destinationName = tmpName
    }

    fun addStop(category: Category) {
        if (!additionalQueries.contains(category.query)) {
            additionalQueries = additionalQueries + category.query
            if (isSearchReady) search()
        }
    }

    fun removeStop(index: Int) {
        if (index < additionalQueries.size) {
            additionalQueries = additionalQueries.toMutableList().apply { removeAt(index) }
            if (isSearchReady) search()
        }
    }

    fun loadRecentSearch(recent: RecentSearch) {
        originQuery = recent.originName
        originLatLng = recent.originLatLng
        originName = recent.originName
        destinationQuery = recent.destinationName
        destinationLatLng = recent.destinationLatLng
        destinationName = recent.destinationName
        originSuggestions = emptyList()
        destinationSuggestions = emptyList()
        routePoints = emptyList()

        val cat = Category.entries.firstOrNull { it.query == recent.category }
        if (cat != null) {
            selectedCategory = cat
            searchQuery = cat.query
        }

        search()
    }

    fun loadSavedRoute(saved: SavedRoute) {
        originQuery = saved.originName
        originLatLng = saved.originLatLng
        originName = saved.originName
        destinationQuery = saved.destinationName
        destinationLatLng = saved.destinationLatLng
        destinationName = saved.destinationName
        originSuggestions = emptyList()
        destinationSuggestions = emptyList()
        routePoints = emptyList()

        val cat = Category.entries.firstOrNull { it.query == saved.defaultCategory }
        if (cat != null) {
            selectedCategory = cat
            searchQuery = cat.query
        }

        search()
    }

    fun saveCurrentRoute(name: String) {
        val origin = originLatLng ?: return
        val dest = destinationLatLng ?: return
        val route = SavedRoute(
            id = java.util.UUID.randomUUID().toString(),
            name = name,
            originLat = origin.latitude,
            originLng = origin.longitude,
            originName = originName ?: "Origin",
            destinationLat = dest.latitude,
            destinationLng = dest.longitude,
            destinationName = destinationName ?: "Destination",
            defaultCategory = searchQuery,
            createdAt = System.currentTimeMillis()
        )
        savedRoutesStore.save(route)
        savedRoutes = savedRoutesStore.load()
    }

    fun deleteSavedRoute(route: SavedRoute) {
        savedRoutesStore.delete(route)
        savedRoutes = savedRoutesStore.load()
    }

    fun selectPOI(poi: POIResult) {
        selectedPOI = poi
        AnalyticsService.track("poi_selected", mapOf(
            "detourSeconds" to poi.detourSeconds,
            "rating" to poi.rating,
        ))
        val origin = originLatLng ?: return
        val destination = destinationLatLng ?: return

        viewModelScope.launch {
            val detour = directionsService.getDetourRoute(origin, poi.latLng, destination, travelMode.apiValue)
            if (detour != null) {
                detourRoutePoints = detour.points
            }
        }
    }

    fun clearDetour() {
        selectedPOI = null
        detourRoutePoints = emptyList()
    }

    fun clearOrigin() {
        originQuery = ""
        originLatLng = null
        originName = null
        originSuggestions = emptyList()
    }

    fun clearDestination() {
        destinationQuery = ""
        destinationLatLng = null
        destinationName = null
        destinationSuggestions = emptyList()
    }

    private fun isAheadOnRoute(poi: POIResult): Boolean {
        if (routePoints.size < 2) return true
        val poiLatLng = poi.latLng
        var closestIndex = 0
        var closestDist = Double.MAX_VALUE
        for (i in routePoints.indices) {
            val d = distanceBetween(poiLatLng, routePoints[i])
            if (d < closestDist) {
                closestDist = d
                closestIndex = i
            }
        }
        val progress = closestIndex.toDouble() / (routePoints.size - 1)
        return progress > 0.05
    }

    private fun distanceBetween(a: LatLng, b: LatLng): Double {
        val dx = a.latitude - b.latitude
        val dy = a.longitude - b.longitude
        return dx * dx + dy * dy
    }
}
