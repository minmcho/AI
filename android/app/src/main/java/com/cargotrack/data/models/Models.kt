package com.cargotrack.data.models

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

// ── Shipment ──────────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class Shipment(
    val id: String,
    @Json(name = "tracking_number") val trackingNumber: String,
    val status: ShipmentStatus,
    val priority: Priority,
    @Json(name = "origin_id") val originId: String,
    @Json(name = "destination_id") val destinationId: String,
    @Json(name = "department_id") val departmentId: String?,
    val carrier: String?,
    @Json(name = "service_type") val serviceType: String?,
    @Json(name = "estimated_arrival") val estimatedArrival: String?,
    @Json(name = "actual_arrival") val actualArrival: String?,
    @Json(name = "total_weight_kg") val totalWeightKg: Double?,
    @Json(name = "total_volume_m3") val totalVolumeM3: Double?,
    val notes: String?,
    @Json(name = "created_at") val createdAt: String,
    @Json(name = "updated_at") val updatedAt: String,
)

enum class ShipmentStatus(val label: String, val color: Long) {
    PENDING("Pending", 0xFFFFA726),
    IN_TRANSIT("In Transit", 0xFF42A5F5),
    AT_CUSTOMS("At Customs", 0xFFEF5350),
    ARRIVED("Arrived", 0xFF66BB6A),
    DELIVERED("Delivered", 0xFF26A69A),
    EXCEPTION("Exception", 0xFFEF5350),
    CANCELLED("Cancelled", 0xFF9E9E9E);

    companion object {
        fun fromString(s: String): ShipmentStatus =
            entries.firstOrNull { it.name.equals(s, ignoreCase = true) } ?: PENDING
    }
}

enum class Priority { LOW, STANDARD, HIGH, CRITICAL }

// ── Cargo Item ────────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class CargoItem(
    val id: String,
    @Json(name = "shipment_id") val shipmentId: String,
    val sku: String?,
    val description: String,
    val quantity: Int,
    @Json(name = "weight_kg") val weightKg: Double?,
    @Json(name = "volume_m3") val volumeM3: Double?,
    @Json(name = "value_usd") val valueUsd: Double?,
    val category: String?,
    @Json(name = "sub_category") val subCategory: String?,
    @Json(name = "cluster_id") val clusterId: Int?,
    @Json(name = "defect_score") val defectScore: Double?,
    @Json(name = "created_at") val createdAt: String,
)

// ── Tracking Event ────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class TrackingEvent(
    val id: String,
    @Json(name = "shipment_id") val shipmentId: String,
    @Json(name = "event_type") val eventType: String,
    @Json(name = "location_id") val locationId: String?,
    @Json(name = "location_name") val locationName: String?,
    val latitude: Double?,
    val longitude: Double?,
    val description: String?,
    @Json(name = "occurred_at") val occurredAt: String,
)

// ── Inventory ─────────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class InventoryItem(
    val id: String,
    @Json(name = "location_id") val locationId: String,
    @Json(name = "department_id") val departmentId: String?,
    val sku: String,
    val description: String?,
    val quantity: Int,
    @Json(name = "reorder_point") val reorderPoint: Int?,
    @Json(name = "max_stock") val maxStock: Int?,
    @Json(name = "bin_location") val binLocation: String?,
    val category: String?,
    @Json(name = "sub_category") val subCategory: String?,
    @Json(name = "cluster_id") val clusterId: Int?,
    @Json(name = "updated_at") val updatedAt: String,
) {
    val isLowStock: Boolean
        get() = reorderPoint != null && quantity <= reorderPoint
}

// ── Defect ────────────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class DefectDetection(
    val id: String?,
    @Json(name = "defect_found") val defectFound: Boolean,
    @Json(name = "defect_type") val defectType: String,
    val severity: String,
    val confidence: Double,
    @Json(name = "bounding_boxes") val boundingBoxes: List<BoundingBox>,
    val description: String,
    @Json(name = "recommended_action") val recommendedAction: String,
    val reasoning: String?,
    @Json(name = "model_version") val modelVersion: String,
    @Json(name = "latency_ms") val latencyMs: Int,
)

@JsonClass(generateAdapter = true)
data class BoundingBox(
    val x: Float, val y: Float,
    val w: Float, val h: Float,
    val label: String,
    val score: Float,
)

// ── Alert ─────────────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class Alert(
    val id: String,
    @Json(name = "alert_type") val alertType: String,
    val severity: AlertSeverity,
    val title: String,
    val message: String,
    @Json(name = "entity_type") val entityType: String?,
    @Json(name = "entity_id") val entityId: String?,
    @Json(name = "location_id") val locationId: String?,
    @Json(name = "department_id") val departmentId: String?,
    val acknowledged: Boolean,
    @Json(name = "created_at") val createdAt: String,
)

enum class AlertSeverity(val color: Long) {
    INFO(0xFF42A5F5),
    WARNING(0xFFFFA726),
    ERROR(0xFFEF5350),
    CRITICAL(0xFFB71C1C);
    companion object {
        fun fromString(s: String) = entries.firstOrNull { it.name.equals(s, ignoreCase = true) } ?: INFO
    }
}

// ── Dashboard stats ───────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class DashboardStats(
    @Json(name = "active_shipments") val activeShipments: Int,
    @Json(name = "delivered_today") val deliveredToday: Int,
    @Json(name = "pending_alerts") val pendingAlerts: Int,
    @Json(name = "defects_detected") val defectsDetected: Int,
    @Json(name = "low_stock_items") val lowStockItems: Int,
)

// ── Org structure ─────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class Location(
    val id: String,
    val name: String,
    val code: String,
    @Json(name = "region_id") val regionId: String,
    @Json(name = "location_type") val locationType: String,
    val latitude: Double?,
    val longitude: Double?,
    val address: String?,
)

// ── ML Results ────────────────────────────────────────────────

@JsonClass(generateAdapter = true)
data class ClassificationResult(
    val category: String,
    @Json(name = "sub_category") val subCategory: String,
    val confidence: Double,
    val method: String,
    @Json(name = "hs_code_suggestion") val hsCodeSuggestion: String?,
)

@JsonClass(generateAdapter = true)
data class ClusteringResult(
    @Json(name = "run_id") val runId: String,
    @Json(name = "run_type") val runType: String,
    val algorithm: String,
    @Json(name = "num_clusters") val numClusters: Int,
    @Json(name = "num_items") val numItems: Int,
    @Json(name = "silhouette_score") val silhouetteScore: Double?,
    val clusters: List<ClusterLabel>,
)

@JsonClass(generateAdapter = true)
data class ClusterLabel(
    @Json(name = "cluster_id") val clusterId: Int,
    val name: String,
    val size: Int,
)

// ── API response wrappers ─────────────────────────────────────

@JsonClass(generateAdapter = true)
data class ShipmentsResponse(val shipments: List<Shipment>, val count: Int)

@JsonClass(generateAdapter = true)
data class InventoryResponse(val inventory: List<InventoryItem>, val count: Int)

@JsonClass(generateAdapter = true)
data class AlertsResponse(val alerts: List<Alert>, val count: Int)

@JsonClass(generateAdapter = true)
data class CargoItemsResponse(val items: List<CargoItem>)

@JsonClass(generateAdapter = true)
data class EventsResponse(val events: List<TrackingEvent>)
