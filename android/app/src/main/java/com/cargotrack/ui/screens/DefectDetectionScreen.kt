package com.cargotrack.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.cargotrack.data.models.DefectDetection
import com.cargotrack.viewmodels.DefectViewModel
import com.cargotrack.viewmodels.UiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DefectDetectionScreen(
    viewModel: DefectViewModel = hiltViewModel(),
) {
    var imageUrl by remember { mutableStateOf("") }
    val result by viewModel.result.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Defect Detection") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = Color.White,
                ),
            )
        },
    ) { padding ->
        Column(
            Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // Image URL input
            Card(shape = RoundedCornerShape(12.dp)) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("Image Analysis", style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold)
                    OutlinedTextField(
                        value = imageUrl,
                        onValueChange = { imageUrl = it },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Image URL") },
                        placeholder = { Text("https://example.com/cargo-image.jpg") },
                        leadingIcon = { Icon(Icons.Default.Link, null) },
                        singleLine = true,
                        shape = RoundedCornerShape(8.dp),
                    )

                    // Preview image
                    if (imageUrl.startsWith("http")) {
                        AsyncImage(
                            model = imageUrl,
                            contentDescription = "Cargo image",
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(200.dp)
                                .clip(RoundedCornerShape(8.dp)),
                            contentScale = ContentScale.Crop,
                        )
                    }

                    Button(
                        onClick = { viewModel.analyseImageUrl(imageUrl) },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = imageUrl.startsWith("http"),
                        shape = RoundedCornerShape(8.dp),
                    ) {
                        Icon(Icons.Default.Search, null, Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text("Analyse for Defects")
                    }
                }
            }

            // Result
            when (val r = result) {
                null             -> {}
                is UiState.Loading -> Box(
                    Modifier.fillMaxWidth().height(120.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        CircularProgressIndicator()
                        Text("Running Claude vision analysis…",
                            style = MaterialTheme.typography.bodySmall)
                    }
                }

                is UiState.Error -> Card(
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer,
                    ),
                ) {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(Icons.Default.Error, null, tint = MaterialTheme.colorScheme.error)
                        Text(r.message, color = MaterialTheme.colorScheme.onErrorContainer)
                    }
                }

                is UiState.Success -> DefectResultCard(r.data)
            }

            // How it works
            InfoCard(
                title = "How it works",
                items = listOf(
                    "Image is sent to Claude Vision (claude-opus-4-6)",
                    "Extended thinking analyses defect patterns",
                    "System prompt is cached for fast repeat calls",
                    "Results include bounding boxes + recommended action",
                ),
            )
        }
    }
}

@Composable
private fun DefectResultCard(defect: DefectDetection) {
    val severityColor = when (defect.severity.lowercase()) {
        "critical" -> Color(0xFFC62828)
        "high"     -> Color(0xFFE53935)
        "medium"   -> Color(0xFFF57C00)
        "low"      -> Color(0xFF558B2F)
        else       -> Color(0xFF9E9E9E)
    }

    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (defect.defectFound)
                severityColor.copy(alpha = 0.08f)
            else MaterialTheme.colorScheme.secondaryContainer.copy(0.5f),
        ),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(
                        if (defect.defectFound) Icons.Default.Warning else Icons.Default.CheckCircle,
                        null,
                        tint = if (defect.defectFound) severityColor
                               else Color(0xFF2E7D32),
                        modifier = Modifier.size(24.dp),
                    )
                    Text(
                        if (defect.defectFound) "Defect Detected" else "No Defects Found",
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleMedium,
                    )
                }
                if (defect.defectFound) {
                    StatusBadge(
                        defect.severity.replaceFirstChar { it.uppercase() },
                        severityColor,
                    )
                }
            }

            if (defect.defectFound) {
                ResultRow("Type", defect.defectType.replace("_", " ").replaceFirstChar { it.uppercase() })
                ResultRow("Confidence", "${(defect.confidence * 100).toInt()}%")
            }

            if (defect.description.isNotBlank()) {
                ResultRow("Analysis", defect.description)
            }

            if (defect.recommendedAction.isNotBlank()) {
                Divider()
                Row(
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(Icons.Default.Assignment, null,
                        tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(18.dp))
                    Column {
                        Text("Recommended Action", style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(0.6f))
                        Text(defect.recommendedAction, style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium)
                    }
                }
            }

            // Claude reasoning (collapsed)
            defect.reasoning?.let { thinking ->
                var expanded by remember { mutableStateOf(false) }
                Divider()
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        Icon(Icons.Default.Psychology, null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.secondary)
                        Text("Claude's Reasoning",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Medium)
                    }
                    TextButton(onClick = { expanded = !expanded }) {
                        Text(if (expanded) "Hide" else "Show",
                            style = MaterialTheme.typography.labelSmall)
                    }
                }
                if (expanded) {
                    Surface(
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        shape = RoundedCornerShape(8.dp),
                    ) {
                        Text(
                            thinking.take(2000),
                            modifier = Modifier.padding(12.dp),
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }

            // Performance info
            Text(
                "Model: ${defect.modelVersion} · ${defect.latencyMs}ms",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurface.copy(0.4f),
            )
        }
    }
}

@Composable
private fun ResultRow(label: String, value: String) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(0.6f))
        Text(value, style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun InfoCard(title: String, items: List<String>) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold)
            items.forEachIndexed { i, item ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("${i + 1}.", style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                    Text(item, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}
