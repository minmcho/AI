package com.cargotrack.data.api

import android.util.Log
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import okhttp3.*

private const val TAG = "WebSocketManager"

/**
 * Manages the persistent WebSocket connection to the Go gateway.
 *
 * Usage:
 * ```
 * webSocketManager.events(departmentId = "xxx").collect { event ->
 *     when (event.type) {
 *         "shipment_updated"   -> ...
 *         "tracking_event"     -> ...
 *         "new_alert"          -> ...
 *         "defect_detected"    -> ...
 *         "inventory_changed"  -> ...
 *     }
 * }
 * ```
 */
class WebSocketManager(
    private val baseUrl: String,
    private val client: OkHttpClient,
) {
    private val moshi = Moshi.Builder()
        .addLast(KotlinJsonAdapterFactory())
        .build()

    @JsonClass(generateAdapter = true)
    data class RealtimeEvent(
        val type: String,
        val payload: Map<String, Any?>,
        val timestamp: String,
    )

    fun events(
        departmentId: String? = null,
        locationId: String? = null,
        shipmentId: String? = null,
    ): Flow<RealtimeEvent> = callbackFlow {
        val wsUrl = buildString {
            append(baseUrl.replace("http", "ws").replace("https", "wss"))
            append("/ws")
            val params = mutableListOf<String>()
            if (!departmentId.isNullOrBlank()) params += "department_id=$departmentId"
            if (!locationId.isNullOrBlank()) params += "location_id=$locationId"
            if (!shipmentId.isNullOrBlank()) params += "shipment_id=$shipmentId"
            if (params.isNotEmpty()) append("?${params.joinToString("&")}")
        }

        val request = Request.Builder().url(wsUrl).build()
        val adapter = moshi.adapter(RealtimeEvent::class.java)

        val ws = client.newWebSocket(request, object : WebSocketListener() {
            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val event = adapter.fromJson(text) ?: return
                    trySend(event)
                } catch (e: Exception) {
                    Log.w(TAG, "parse error: $e")
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                Log.e(TAG, "ws failure: $t")
                close(t)
            }

            override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                Log.d(TAG, "ws closed: $code $reason")
                close()
            }
        })

        awaitClose { ws.close(1000, "flow cancelled") }
    }
}
