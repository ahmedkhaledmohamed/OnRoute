package com.ahmedkhaled.onroute

import android.app.Application
import com.google.android.libraries.places.api.Places

class OnRouteApp : Application() {
    override fun onCreate() {
        super.onCreate()
        if (!Places.isInitialized()) {
            Places.initializeWithNewPlacesApiEnabled(this, BuildConfig.MAPS_API_KEY)
        }
    }
}
