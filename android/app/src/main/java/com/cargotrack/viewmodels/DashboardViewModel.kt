package com.cargotrack.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cargotrack.data.api.CargoApiService
import com.cargotrack.data.api.WebSocketManager
import com.cargotrack.data.models.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class DashboardViewModel @Inject constructor(
    private val api: CargoApiService,
    private val wsManager: WebSocketManager,
) : ViewModel() {

    private val _stats = MutableStateFlow<UiState<DashboardStats>>(UiState.Loading)
    val stats: StateFlow<UiState<DashboardStats>> = _stats.asStateFlow()

    private val _recentShipments = MutableStateFlow<List<Shipment>>(emptyList())
    val recentShipments: StateFlow<List<Shipment>> = _recentShipments.asStateFlow()

    private val _alerts = MutableStateFlow<List<Alert>>(emptyList())
    val alerts: StateFlow<List<Alert>> = _alerts.asStateFlow()

    private val _realtimeEvents = MutableSharedFlow<WebSocketManager.RealtimeEvent>(replay = 5)
    val realtimeEvents: SharedFlow<WebSocketManager.RealtimeEvent> = _realtimeEvents.asSharedFlow()

    var selectedDepartmentId: String? = null
        private set

    init {
        loadDashboard()
        subscribeRealtime()
    }

    fun loadDashboard(departmentId: String? = selectedDepartmentId) {
        selectedDepartmentId = departmentId
        viewModelScope.launch {
            _stats.value = UiState.Loading
            try {
                val statsResp = api.getDashboardStats(departmentId)
                if (statsResp.isSuccessful) {
                    _stats.value = UiState.Success(statsResp.body()!!)
                } else {
                    _stats.value = UiState.Error("HTTP ${statsResp.code()}")
                }

                val shipmentsResp = api.listShipments(departmentId = departmentId, limit = 10)
                if (shipmentsResp.isSuccessful) {
                    _recentShipments.value = shipmentsResp.body()?.shipments ?: emptyList()
                }

                val alertsResp = api.listAlerts(departmentId = departmentId, unacknowledgedOnly = true)
                if (alertsResp.isSuccessful) {
                    _alerts.value = alertsResp.body()?.alerts ?: emptyList()
                }
            } catch (e: Exception) {
                _stats.value = UiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    fun acknowledgeAlert(alertId: String) {
        viewModelScope.launch {
            try {
                api.acknowledgeAlert(alertId)
                _alerts.value = _alerts.value.filter { it.id != alertId }
            } catch (_: Exception) {}
        }
    }

    private fun subscribeRealtime() {
        viewModelScope.launch {
            wsManager.events(departmentId = selectedDepartmentId)
                .catch { /* reconnect logic would go here */ }
                .collect { event ->
                    _realtimeEvents.emit(event)
                    when (event.type) {
                        "new_alert"           -> loadDashboard()
                        "shipment_updated"    -> loadDashboard()
                        "inventory_changed"   -> loadDashboard()
                    }
                }
        }
    }
}

@HiltViewModel
class ShipmentViewModel @Inject constructor(
    private val api: CargoApiService,
) : ViewModel() {

    private val _shipments = MutableStateFlow<UiState<List<Shipment>>>(UiState.Loading)
    val shipments: StateFlow<UiState<List<Shipment>>> = _shipments.asStateFlow()

    private val _selectedShipment = MutableStateFlow<Shipment?>(null)
    val selectedShipment: StateFlow<Shipment?> = _selectedShipment.asStateFlow()

    private val _events = MutableStateFlow<List<TrackingEvent>>(emptyList())
    val events: StateFlow<List<TrackingEvent>> = _events.asStateFlow()

    private val _cargoItems = MutableStateFlow<List<CargoItem>>(emptyList())
    val cargoItems: StateFlow<List<CargoItem>> = _cargoItems.asStateFlow()

    fun loadShipments(status: String? = null, departmentId: String? = null) {
        viewModelScope.launch {
            _shipments.value = UiState.Loading
            try {
                val resp = api.listShipments(status = status, departmentId = departmentId)
                _shipments.value = if (resp.isSuccessful)
                    UiState.Success(resp.body()?.shipments ?: emptyList())
                else UiState.Error("HTTP ${resp.code()}")
            } catch (e: Exception) {
                _shipments.value = UiState.Error(e.message ?: "Error")
            }
        }
    }

    fun loadShipment(id: String) {
        viewModelScope.launch {
            val resp = api.getShipment(id)
            if (resp.isSuccessful) _selectedShipment.value = resp.body()

            val evtResp = api.listEvents(id)
            if (evtResp.isSuccessful) _events.value = evtResp.body()?.events ?: emptyList()

            val itemsResp = api.listCargoItems(id)
            if (itemsResp.isSuccessful) _cargoItems.value = itemsResp.body()?.items ?: emptyList()
        }
    }

    fun trackByNumber(trackingNumber: String) {
        viewModelScope.launch {
            try {
                val resp = api.getShipmentByTracking(trackingNumber)
                if (resp.isSuccessful) {
                    _selectedShipment.value = resp.body()
                    resp.body()?.id?.let { loadShipment(it) }
                }
            } catch (_: Exception) {}
        }
    }
}

@HiltViewModel
class InventoryViewModel @Inject constructor(
    private val api: CargoApiService,
) : ViewModel() {

    private val _inventory = MutableStateFlow<UiState<List<InventoryItem>>>(UiState.Loading)
    val inventory: StateFlow<UiState<List<InventoryItem>>> = _inventory.asStateFlow()

    private val _clusteringResult = MutableStateFlow<ClusteringResult?>(null)
    val clusteringResult: StateFlow<ClusteringResult?> = _clusteringResult.asStateFlow()

    fun loadInventory(locationId: String? = null, belowReorder: Boolean = false) {
        viewModelScope.launch {
            _inventory.value = UiState.Loading
            try {
                val resp = api.listInventory(locationId = locationId, belowReorder = belowReorder)
                _inventory.value = if (resp.isSuccessful)
                    UiState.Success(resp.body()?.inventory ?: emptyList())
                else UiState.Error("HTTP ${resp.code()}")
            } catch (e: Exception) {
                _inventory.value = UiState.Error(e.message ?: "Error")
            }
        }
    }

    fun loadClustering() {
        viewModelScope.launch {
            try {
                val resp = api.getLatestClustering("inventory")
                if (resp.isSuccessful) _clusteringResult.value = resp.body()
            } catch (_: Exception) {}
        }
    }
}

@HiltViewModel
class DefectViewModel @Inject constructor(
    private val api: CargoApiService,
) : ViewModel() {

    private val _result = MutableStateFlow<UiState<DefectDetection>?>(null)
    val result: StateFlow<UiState<DefectDetection>?> = _result.asStateFlow()

    fun analyseImageUrl(imageUrl: String, itemContext: Map<String, Any> = emptyMap()) {
        viewModelScope.launch {
            _result.value = UiState.Loading
            try {
                val body = buildMap<String, Any> {
                    put("image_url", imageUrl)
                    put("persist", false)
                    if (itemContext.isNotEmpty()) put("item_context", itemContext)
                }
                val resp = api.detectDefect(body)
                _result.value = if (resp.isSuccessful) UiState.Success(resp.body()!!)
                else UiState.Error("HTTP ${resp.code()}")
            } catch (e: Exception) {
                _result.value = UiState.Error(e.message ?: "Error")
            }
        }
    }
}

// ── UI state wrapper ──────────────────────────────────────────

sealed class UiState<out T> {
    data object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}
