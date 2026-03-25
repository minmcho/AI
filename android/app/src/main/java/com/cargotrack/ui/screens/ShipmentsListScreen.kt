package com.cargotrack.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cargotrack.data.models.ShipmentStatus
import com.cargotrack.viewmodels.ShipmentViewModel
import com.cargotrack.viewmodels.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShipmentsListScreen(
    onNavigateToShipment: (String) -> Unit,
    viewModel: ShipmentViewModel = hiltViewModel(),
) {
    LaunchedEffect(Unit) { viewModel.loadShipments() }

    val shipments by viewModel.shipments.collectAsState()
    var selectedStatus by remember { mutableStateOf<ShipmentStatus?>(null) }
    var trackingQuery by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Shipments") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding)) {
            // Track by number
            OutlinedTextField(
                value = trackingQuery,
                onValueChange = { trackingQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Enter tracking number…") },
                leadingIcon = { Icon(Icons.Default.Search, null) },
                singleLine = true,
                shape = RoundedCornerShape(24.dp),
                trailingIcon = {
                    if (trackingQuery.isNotBlank()) {
                        TextButton(onClick = { viewModel.trackByNumber(trackingQuery) }) {
                            Text("Track")
                        }
                    }
                },
            )

            // Status filter chips
            LazyRow(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                item {
                    FilterChip(
                        selected  = selectedStatus == null,
                        onClick   = { selectedStatus = null; viewModel.loadShipments() },
                        label     = { Text("All") },
                    )
                }
                items(ShipmentStatus.entries) { status ->
                    FilterChip(
                        selected  = selectedStatus == status,
                        onClick   = {
                            selectedStatus = status
                            viewModel.loadShipments(status = status.name.lowercase())
                        },
                        label     = { Text(status.label) },
                    )
                }
            }

            when (val s = shipments) {
                is UiState.Loading -> Box(
                    Modifier.fillMaxSize(), contentAlignment = Alignment.Center,
                ) { CircularProgressIndicator() }

                is UiState.Error -> Box(
                    Modifier.fillMaxSize().padding(16.dp),
                    contentAlignment = Alignment.Center,
                ) { Text("Error: ${s.message}", color = MaterialTheme.colorScheme.error) }

                is UiState.Success -> {
                    val list = s.data
                    if (list.isEmpty()) {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text("No shipments found",
                                color = MaterialTheme.colorScheme.onSurface.copy(0.5f))
                        }
                    } else {
                        LazyColumn(
                            contentPadding = PaddingValues(16.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                        ) {
                            item {
                                Text(
                                    "${list.size} shipment${if (list.size != 1) "s" else ""}",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = MaterialTheme.colorScheme.onSurface.copy(0.6f),
                                )
                            }
                            items(list) { shipment ->
                                ShipmentCard(
                                    shipment = shipment,
                                    onClick = { onNavigateToShipment(shipment.id) },
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
