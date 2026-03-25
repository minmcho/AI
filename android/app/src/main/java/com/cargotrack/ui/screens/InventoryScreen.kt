package com.cargotrack.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cargotrack.data.models.*
import com.cargotrack.viewmodels.InventoryViewModel
import com.cargotrack.viewmodels.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InventoryScreen(
    viewModel: InventoryViewModel = hiltViewModel(),
) {
    LaunchedEffect(Unit) {
        viewModel.loadInventory()
        viewModel.loadClustering()
    }

    val inventory by viewModel.inventory.collectAsState()
    val clustering by viewModel.clusteringResult.collectAsState()
    var showLowStock by remember { mutableStateOf(false) }
    var searchQuery by remember { mutableStateOf("") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Inventory") },
                actions = {
                    FilterChip(
                        selected = showLowStock,
                        onClick = {
                            showLowStock = !showLowStock
                            viewModel.loadInventory(belowReorder = showLowStock)
                        },
                        label = { Text("Low Stock") },
                        leadingIcon = { Icon(Icons.Default.Warning, null, Modifier.size(16.dp)) },
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = Color.White,
                    actionIconContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        Column(Modifier.padding(padding)) {
            // Search bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                placeholder = { Text("Search SKU or description…") },
                leadingIcon = { Icon(Icons.Default.Search, null) },
                singleLine = true,
                shape = RoundedCornerShape(24.dp),
            )

            // Clustering summary
            clustering?.let { cl ->
                ClusteringSummaryCard(result = cl)
            }

            when (val inv = inventory) {
                is UiState.Loading -> Box(
                    Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center,
                ) { CircularProgressIndicator() }

                is UiState.Error -> Box(
                    Modifier.fillMaxSize().padding(16.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text("Error: ${inv.message}", color = MaterialTheme.colorScheme.error)
                }

                is UiState.Success -> {
                    val filtered = inv.data.filter { item ->
                        searchQuery.isBlank() ||
                            item.sku.contains(searchQuery, ignoreCase = true) ||
                            item.description?.contains(searchQuery, ignoreCase = true) == true
                    }
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        item {
                            Text(
                                "${filtered.size} item${if (filtered.size != 1) "s" else ""}",
                                style = MaterialTheme.typography.labelMedium,
                                color = MaterialTheme.colorScheme.onSurface.copy(0.6f),
                            )
                        }
                        items(filtered) { item ->
                            InventoryItemCard(item)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ClusteringSummaryCard(result: ClusteringResult) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer,
        ),
        shape = RoundedCornerShape(10.dp),
    ) {
        Row(
            Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(Icons.Default.Hub, null,
                tint = MaterialTheme.colorScheme.onSecondaryContainer,
                modifier = Modifier.size(20.dp))
            Column {
                Text(
                    "${result.numClusters} clusters · ${result.numItems} items · ${result.algorithm.uppercase()}",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                )
                result.silhouetteScore?.let {
                    Text("Silhouette: ${"%.3f".format(it)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSecondaryContainer.copy(0.7f))
                }
            }
        }
    }
}

@Composable
private fun InventoryItemCard(item: InventoryItem) {
    val stockRatio = if (item.maxStock != null && item.maxStock > 0)
        item.quantity.toFloat() / item.maxStock
    else null

    Card(
        shape = RoundedCornerShape(10.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (item.isLowStock)
                MaterialTheme.colorScheme.errorContainer.copy(0.25f)
            else MaterialTheme.colorScheme.surface,
        ),
    ) {
        Column(Modifier.padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column(Modifier.weight(1f)) {
                    Text(item.sku, fontWeight = FontWeight.SemiBold,
                        style = MaterialTheme.typography.bodyMedium)
                    item.description?.let {
                        Text(it, style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(0.6f),
                            maxLines = 1)
                    }
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(item.quantity.toString(),
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = if (item.isLowStock) MaterialTheme.colorScheme.error
                                else MaterialTheme.colorScheme.primary)
                    Text("units", style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(0.5f))
                }
            }

            // Stock level bar
            stockRatio?.let {
                LinearProgressIndicator(
                    progress = { it.coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth().height(5.dp),
                    color = when {
                        item.isLowStock -> MaterialTheme.colorScheme.error
                        it < 0.3f       -> MaterialTheme.colorScheme.tertiary
                        else            -> MaterialTheme.colorScheme.primary
                    },
                    trackColor = MaterialTheme.colorScheme.surfaceVariant,
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                item.category?.let { StatusBadge(it, MaterialTheme.colorScheme.primary) }
                item.binLocation?.let {
                    StatusBadge("Bin: $it", MaterialTheme.colorScheme.secondary)
                }
                item.clusterId?.let {
                    StatusBadge("C$it", Color(0xFF7B1FA2))
                }
                if (item.isLowStock) {
                    StatusBadge("LOW STOCK", MaterialTheme.colorScheme.error)
                }
            }
        }
    }
}
