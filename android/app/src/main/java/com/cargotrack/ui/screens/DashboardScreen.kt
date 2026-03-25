package com.cargotrack.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cargotrack.data.models.*
import com.cargotrack.viewmodels.DashboardViewModel
import com.cargotrack.viewmodels.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    onNavigateToShipments: () -> Unit,
    onNavigateToInventory: () -> Unit,
    onNavigateToDefects: () -> Unit,
    onNavigateToShipment: (String) -> Unit,
    viewModel: DashboardViewModel = hiltViewModel(),
) {
    val stats by viewModel.stats.collectAsState()
    val recentShipments by viewModel.recentShipments.collectAsState()
    val alerts by viewModel.alerts.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text("CargoTrack", style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold)
                        Text("Live dashboard", style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.loadDashboard() }) {
                        Icon(Icons.Default.Refresh, "Refresh")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = Color.White,
                    actionIconContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(16.dp),
        ) {
            // Stats cards
            item {
                when (val s = stats) {
                    is UiState.Loading -> CircularProgressIndicator(Modifier.padding(16.dp))
                    is UiState.Error   -> Text("Error: ${s.message}", color = MaterialTheme.colorScheme.error)
                    is UiState.Success -> StatsGrid(
                        stats = s.data,
                        onShipmentsClick = onNavigateToShipments,
                        onInventoryClick = onNavigateToInventory,
                        onDefectsClick   = onNavigateToDefects,
                    )
                }
            }

            // Unacknowledged alerts
            if (alerts.isNotEmpty()) {
                item {
                    Text("Active Alerts", style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(vertical = 4.dp))
                }
                items(alerts.take(3)) { alert ->
                    AlertCard(alert = alert, onAcknowledge = { viewModel.acknowledgeAlert(it) })
                }
            }

            // Recent shipments
            item {
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Recent Shipments", style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold)
                    TextButton(onClick = onNavigateToShipments) { Text("View all") }
                }
            }
            if (recentShipments.isEmpty()) {
                item { Text("No shipments", color = MaterialTheme.colorScheme.onSurface.copy(0.5f)) }
            }
            items(recentShipments) { shipment ->
                ShipmentCard(shipment = shipment, onClick = { onNavigateToShipment(shipment.id) })
            }
        }
    }
}

@Composable
private fun StatsGrid(
    stats: DashboardStats,
    onShipmentsClick: () -> Unit,
    onInventoryClick: () -> Unit,
    onDefectsClick: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.LocalShipping,
                label = "Active Shipments",
                value = stats.activeShipments.toString(),
                color = MaterialTheme.colorScheme.primary,
                onClick = onShipmentsClick,
            )
            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.CheckCircle,
                label = "Delivered Today",
                value = stats.deliveredToday.toString(),
                color = Color(0xFF2E7D32),
            )
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Warning,
                label = "Pending Alerts",
                value = stats.pendingAlerts.toString(),
                color = if (stats.pendingAlerts > 0) Color(0xFFF57C00) else Color(0xFF9E9E9E),
            )
            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.BugReport,
                label = "Defects",
                value = stats.defectsDetected.toString(),
                color = if (stats.defectsDetected > 0) Color(0xFFC62828) else Color(0xFF9E9E9E),
                onClick = onDefectsClick,
            )
        }
        StatCard(
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Default.Inventory,
            label = "Low Stock Items",
            value = stats.lowStockItems.toString(),
            color = if (stats.lowStockItems > 0) Color(0xFF6A1B9A) else Color(0xFF9E9E9E),
            onClick = onInventoryClick,
        )
    }
}

@Composable
private fun StatCard(
    modifier: Modifier,
    icon: ImageVector,
    label: String,
    value: String,
    color: Color,
    onClick: (() -> Unit)? = null,
) {
    Card(
        modifier = modifier
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(2.dp),
        shape = RoundedCornerShape(12.dp),
    ) {
        Row(
            Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Box(
                Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(color.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(icon, null, tint = color, modifier = Modifier.size(22.dp))
            }
            Column {
                Text(value, style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold, color = color)
                Text(label, style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(0.6f))
            }
        }
    }
}

@Composable
fun ShipmentCard(shipment: Shipment, onClick: () -> Unit) {
    val statusColor = Color(shipment.status.color)
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        shape = RoundedCornerShape(10.dp),
        elevation = CardDefaults.cardElevation(1.dp),
    ) {
        Row(
            Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(Modifier.weight(1f)) {
                Text(shipment.trackingNumber, fontWeight = FontWeight.SemiBold,
                    style = MaterialTheme.typography.bodyMedium)
                Text(
                    "${shipment.carrier ?: "—"} · ${shipment.priority.name.lowercase().replaceFirstChar { it.uppercase() }}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(0.6f),
                )
            }
            StatusBadge(label = shipment.status.label, color = statusColor)
        }
    }
}

@Composable
fun AlertCard(alert: Alert, onAcknowledge: (String) -> Unit) {
    val color = Color(alert.severity.color)
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.08f)),
        shape = RoundedCornerShape(10.dp),
        border = CardDefaults.outlinedCardBorder().copy(
            // subtle tinted border
        ),
    ) {
        Row(
            Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(
                Modifier.weight(1f),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Icon(Icons.Default.Warning, null, tint = color, modifier = Modifier.size(20.dp))
                Column {
                    Text(alert.title, fontWeight = FontWeight.Medium,
                        style = MaterialTheme.typography.bodySmall)
                    Text(alert.message, style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(0.6f),
                        maxLines = 1)
                }
            }
            TextButton(onClick = { onAcknowledge(alert.id) }) {
                Text("Ack", style = MaterialTheme.typography.labelSmall)
            }
        }
    }
}

@Composable
fun StatusBadge(label: String, color: Color) {
    Box(
        Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(color.copy(alpha = 0.15f))
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(label, style = MaterialTheme.typography.labelSmall,
            color = color, fontWeight = FontWeight.SemiBold)
    }
}
