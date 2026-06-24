package com.ahmedkhaled.onroute.ui.component

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ahmedkhaled.onroute.model.TravelMode
import com.ahmedkhaled.onroute.service.PlaceSuggestion
import com.ahmedkhaled.onroute.viewmodel.RouteViewModel

@Composable
fun RouteInputPanel(
    viewModel: RouteViewModel,
    onSearch: () -> Unit,
    onCurrentLocation: () -> Unit,
    modifier: Modifier = Modifier
) {
    var originFocused by remember { mutableStateOf(false) }
    var destinationFocused by remember { mutableStateOf(false) }

    val activeSuggestions = when {
        originFocused -> viewModel.originSuggestions
        destinationFocused -> viewModel.destinationSuggestions
        else -> emptyList()
    }

    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        shadowElevation = 8.dp,
        tonalElevation = 2.dp
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            // Origin field
            OutlinedTextField(
                value = viewModel.originQuery,
                onValueChange = { viewModel.updateOriginQuery(it) },
                placeholder = { Text("From") },
                leadingIcon = {
                    Icon(
                        Icons.Default.Circle,
                        contentDescription = null,
                        tint = Color(0xFF4CAF50),
                        modifier = Modifier.size(12.dp)
                    )
                },
                trailingIcon = {
                    if (viewModel.originQuery.isEmpty()) {
                        IconButton(onClick = onCurrentLocation) {
                            Icon(Icons.Default.MyLocation, "Current location", tint = MaterialTheme.colorScheme.primary)
                        }
                    } else {
                        IconButton(onClick = { viewModel.clearOrigin() }) {
                            Icon(Icons.Default.Cancel, "Clear", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .onFocusChanged { originFocused = it.isFocused },
                shape = RoundedCornerShape(10.dp)
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Destination field
            Row(verticalAlignment = Alignment.CenterVertically) {
                OutlinedTextField(
                    value = viewModel.destinationQuery,
                    onValueChange = { viewModel.updateDestinationQuery(it) },
                    placeholder = { Text("To") },
                    leadingIcon = {
                        Icon(
                            Icons.Default.Circle,
                            contentDescription = null,
                            tint = Color(0xFFF44336),
                            modifier = Modifier.size(12.dp)
                        )
                    },
                    trailingIcon = {
                        if (viewModel.destinationQuery.isNotEmpty()) {
                            IconButton(onClick = { viewModel.clearDestination() }) {
                                Icon(Icons.Default.Cancel, "Clear", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    },
                    singleLine = true,
                    modifier = Modifier
                        .weight(1f)
                        .onFocusChanged { destinationFocused = it.isFocused },
                    shape = RoundedCornerShape(10.dp)
                )

                IconButton(onClick = { viewModel.swapOriginDestination() }) {
                    Icon(Icons.Default.SwapVert, "Swap")
                }
            }

            // Suggestions
            if (activeSuggestions.isNotEmpty()) {
                Spacer(modifier = Modifier.height(4.dp))
                LazyColumn(modifier = Modifier.heightIn(max = 200.dp)) {
                    items(activeSuggestions) { suggestion ->
                        SuggestionRow(
                            suggestion = suggestion,
                            onClick = {
                                if (originFocused) {
                                    viewModel.selectOriginSuggestion(suggestion)
                                    originFocused = false
                                } else {
                                    viewModel.selectDestinationSuggestion(suggestion)
                                    destinationFocused = false
                                }
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Search button
            Button(
                onClick = onSearch,
                enabled = viewModel.isSearchReady,
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.Search, null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Search Along Route", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
private fun SuggestionRow(suggestion: PlaceSuggestion, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 8.dp)
    ) {
        Text(suggestion.title, fontSize = 14.sp)
        if (suggestion.subtitle.isNotEmpty()) {
            Text(
                suggestion.subtitle,
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
    HorizontalDivider(modifier = Modifier.padding(start = 12.dp))
}
