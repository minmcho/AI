package com.cargotrack.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cargotrack.data.models.*
import com.cargotrack.viewmodels.ShipmentViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShipmentDetailScreen(
    shipmentId: String,
    onBack: () -> Unit,
    viewModel: ShipmentViewModel = hiltViewModel(),
) {
    LaunchedEffect(shipmentId) { viewModel.loadShipment(shipmentId) }

    val shipment by viewModel.selectedShipment.collectAsState()
    val events by viewModel.events.collectAsState()
    val cargoItems by viewModel.cargoItems.collectAsState()
    var selectedTab by remember { mutableIntStateOf(0) }
    val tabs = listOf("Timeline", "Cargo Items")

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(shipment?.trackingNumber ?: "Loading…",
                        style = MaterialTheme.typography.titleMedium)
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = Color.White,
                    navigationIconContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding)) {
            shipment?.let { s ->
                // Status header
                ShipmentHeader(shipment = s)
                // Tabs
                TabRow(selectedTabIndex = selectedTab) {
                    tabs.forEachIndexed { index, title ->
                        Tab(selected = selectedTab == index,
                            onClick = { selectedTab = index },
                            text = { Text(title) })
                    }
                }
                when (selectedTab) {
                    0 -> TrackingTimeline(events)
                    1 -> CargoItemList(cargoItems)
                }
            } ?: Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        }
    }
}

@Composable
private fun ShipmentHeader(shipment: Shipment) {
    val statusColor = Color(shipment.status.color)
    Surface(
        color = MaterialTheme.colorScheme.primaryContainer,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("Status", style = MaterialTheme.typography.labelMedium)
                StatusBadge(shipment.status.label, statusColor)
            }
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                shipment.carrier?.let {
                    InfoChip(Icons.Default.Flight, "Carrier", it)
                }
                shipment.serviceType?.let {
                    InfoChip(Icons.Default.Category, "Service", it)
                }
            }
            shipment.estimatedArrival?.let {
                InfoChip(Icons.Default.Schedule, "ETA", it.take(10))
            }
        }
    }
}

@Composable
private fun InfoChip(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, value: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(icon, null, modifier = Modifier.size(14.dp),
            tint = MaterialTheme.colorScheme.onPrimaryContainer.copy(0.7f))
        Column {
            Text(label, style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(0.6f))
            Text(value, style = MaterialTheme.typography.bodySmall,
                fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
private fun TrackingTimeline(events: List<TrackingEvent>) {
    if (events.isEmpty()) {
        Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
            Text("No tracking events yet", color = MaterialTheme.colorScheme.onSurface.copy(0.5f))
        }
        return
    }
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        items(events) { event ->
            TimelineRow(event = event, isLast = event == events.last())
        }
    }
}

@Composable
private fun TimelineRow(event: TrackingEvent, isLast: Boolean) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        // Timeline indicator
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                Modifier.size(12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Surface(
                    shape = RoundedCornerShape(50),
                    color = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(10.dp),
                ) {}
            }
            if (!isLast) {
                Divider(
                    Modifier.width(2.dp).height(40.dp),
                    color = MaterialTheme.colorScheme.primary.copy(0.3f),
                    thickness = 2.dp,
                )
            }
        }
        Column(Modifier.weight(1f).padding(bottom = if (isLast) 0.dp else 8.dp)) {
            Text(
                event.eventType.replace("_", " ").replaceFirstChar { it.uppercase() },
                fontWeight = FontWeight.SemiBold,
                style = MaterialTheme.typography.bodyMedium,
            )
            event.locationName?.let {
                Text(it, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(0.7f))
            }
            event.description?.let {
                Text(it, style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(0.6f))
            }
            Text(
                event.occurredAt.take(16).replace("T", " "),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface.copy(0.45f),
            )
        }
    }
}

@Composable
private fun CargoItemList(items: List<CargoItem>) {
    if (items.isEmpty()) {
        Box(Modifier.fillMaxWidth().padding(32.dp), contentAlignment = Alignment.Center) {
            Text("No cargo items", color = MaterialTheme.colorScheme.onSurface.copy(0.5f))
        }
        return
    }
    LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items(items) { item ->
            CargoItemCard(item)
        }
    }
}

@Composable
private fun CargoItemCard(item: CargoItem) {
    val hasDefect = (item.defectScore ?: 0.0) > 0.5
    Card(
        shape = RoundedCornerShape(10.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (hasDefect)
                MaterialTheme.colorScheme.errorContainer.copy(0.3f)
            else MaterialTheme.colorScheme.surface,
        ),
    ) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(item.description, fontWeight = FontWeight.Medium,
                    style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                if (hasDefect) {
                    Icon(Icons.Default.Warning, "Defect",
                        tint = MaterialTheme.colorScheme.error, modifier = Modifier.size(18.dp))
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                item.sku?.let { Text("SKU: $it", style = MaterialTheme.typography.labelSmall) }
                Text("Qty: ${item.quantity}", style = MaterialTheme.typography.labelSmall)
                item.category?.let {
                    StatusBadge(it, MaterialTheme.colorScheme.secondary)
                }
            }
            item.defectScore?.let { score ->
                if (score > 0) {
                    LinearProgressIndicator(
                        progress = { score.toFloat() },
                        modifier = Modifier.fillMaxWidth().height(4.dp),
                        color = if (score > 0.5) MaterialTheme.colorScheme.error
                                else MaterialTheme.colorScheme.primary,
                        trackColor = MaterialTheme.colorScheme.surfaceVariant,
                    )
                    Text("Defect probability: ${(score * 100).toInt()}%",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (score > 0.5) MaterialTheme.colorScheme.error
                                else MaterialTheme.colorScheme.onSurface.copy(0.6f))
                }
            }
        }
    }
}
