package com.cargotrack.data.api

import com.cargotrack.data.models.*
import retrofit2.Response
import retrofit2.http.*

interface CargoApiService {

    // ── Dashboard ─────────────────────────────────────────────
    @GET("api/v1/dashboard/stats")
    suspend fun getDashboardStats(
        @Query("department_id") departmentId: String? = null,
    ): Response<DashboardStats>

    // ── Shipments ─────────────────────────────────────────────
    @GET("api/v1/shipments")
    suspend fun listShipments(
        @Query("status") status: String? = null,
        @Query("department_id") departmentId: String? = null,
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0,
    ): Response<ShipmentsResponse>

    @GET("api/v1/shipments/{id}")
    suspend fun getShipment(@Path("id") id: String): Response<Shipment>

    @GET("api/v1/shipments/track/{trackingNumber}")
    suspend fun getShipmentByTracking(
        @Path("trackingNumber") trackingNumber: String,
    ): Response<Shipment>

    @POST("api/v1/shipments")
    suspend fun createShipment(@Body body: Map<String, @JvmSuppressWildcards Any>): Response<Shipment>

    @PATCH("api/v1/shipments/{id}/status")
    suspend fun updateStatus(
        @Path("id") id: String,
        @Body body: Map<String, @JvmSuppressWildcards Any>,
    ): Response<TrackingEvent>

    @GET("api/v1/shipments/{id}/items")
    suspend fun listCargoItems(@Path("id") shipmentId: String): Response<CargoItemsResponse>

    @POST("api/v1/shipments/{id}/items")
    suspend fun addCargoItem(
        @Path("id") shipmentId: String,
        @Body body: Map<String, @JvmSuppressWildcards Any>,
    ): Response<CargoItem>

    @GET("api/v1/shipments/{id}/events")
    suspend fun listEvents(@Path("id") shipmentId: String): Response<EventsResponse>

    // ── Inventory ─────────────────────────────────────────────
    @GET("api/v1/inventory")
    suspend fun listInventory(
        @Query("location_id") locationId: String? = null,
        @Query("department_id") departmentId: String? = null,
        @Query("below_reorder") belowReorder: Boolean = false,
        @Query("limit") limit: Int = 100,
    ): Response<InventoryResponse>

    @POST("api/v1/inventory/adjust")
    suspend fun adjustInventory(
        @Body body: Map<String, @JvmSuppressWildcards Any>,
    ): Response<InventoryItem>

    // ── Alerts ────────────────────────────────────────────────
    @GET("api/v1/alerts")
    suspend fun listAlerts(
        @Query("department_id") departmentId: String? = null,
        @Query("severity") severity: String? = null,
        @Query("unacknowledged_only") unacknowledgedOnly: Boolean = false,
    ): Response<AlertsResponse>

    @POST("api/v1/alerts/{id}/acknowledge")
    suspend fun acknowledgeAlert(@Path("id") alertId: String): Response<Map<String, Boolean>>

    // ── Locations ─────────────────────────────────────────────
    @GET("api/v1/locations")
    suspend fun listLocations(
        @Query("region_id") regionId: String? = null,
    ): Response<Map<String, List<Location>>>

    // ── ML / AI ───────────────────────────────────────────────
    @POST("api/v1/ml/defect-detect")
    suspend fun detectDefect(
        @Body body: Map<String, @JvmSuppressWildcards Any>,
    ): Response<DefectDetection>

    @POST("api/v1/ml/classify")
    suspend fun classifyItem(
        @Body body: Map<String, @JvmSuppressWildcards Any>,
    ): Response<ClassificationResult>

    @POST("api/v1/ml/cluster")
    suspend fun runClustering(
        @Body body: Map<String, @JvmSuppressWildcards Any>,
    ): Response<ClusteringResult>

    @GET("api/v1/ml/cluster/{runType}/latest")
    suspend fun getLatestClustering(
        @Path("runType") runType: String,
    ): Response<ClusteringResult>

    @POST("api/v1/ml/reason")
    suspend fun reason(
        @Body body: Map<String, @JvmSuppressWildcards Any>,
    ): Response<Map<String, Any>>
}
