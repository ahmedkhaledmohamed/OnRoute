package com.ahmedkhaled.onroute.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.vector.ImageVector

enum class Category(val label: String, val query: String, val icon: ImageVector) {
    COFFEE("Coffee", "coffee", Icons.Default.LocalCafe),
    FOOD("Food", "restaurant", Icons.Default.Restaurant),
    GAS("Gas", "gas station", Icons.Default.LocalGasStation),
    GROCERY("Grocery", "grocery store", Icons.Default.ShoppingCart),
    PHARMACY("Pharmacy", "pharmacy", Icons.Default.LocalPharmacy),
    EV_CHARGING("EV Charging", "EV charging station", Icons.Default.EvStation)
}
