package com.cargotrack

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.navigation.NavHostController
import androidx.navigation.compose.*
import com.cargotrack.ui.screens.*
import com.cargotrack.ui.theme.CargoTrackTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CargoTrackTheme {
                CargoTrackApp()
            }
        }
    }
}

sealed class Screen(val route: String, val label: String, val icon: ImageVector) {
    data object Dashboard : Screen("dashboard", "Dashboard", Icons.Default.Dashboard)
    data object Shipments : Screen("shipments", "Shipments", Icons.Default.LocalShipping)
    data object Inventory : Screen("inventory", "Inventory", Icons.Default.Inventory)
    data object Defects   : Screen("defects",   "Defects",   Icons.Default.BugReport)
}

@Composable
fun CargoTrackApp() {
    val navController = rememberNavController()
    val bottomScreens = listOf(Screen.Dashboard, Screen.Shipments, Screen.Inventory, Screen.Defects)
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        bottomBar = {
            if (currentRoute in bottomScreens.map { it.route }) {
                NavigationBar {
                    bottomScreens.forEach { screen ->
                        NavigationBarItem(
                            selected  = currentRoute == screen.route,
                            onClick   = {
                                navController.navigate(screen.route) {
                                    popUpTo(navController.graph.startDestinationId) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon      = { Icon(screen.icon, screen.label) },
                            label     = { Text(screen.label) },
                        )
                    }
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Dashboard.route,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable(Screen.Dashboard.route) {
                DashboardScreen(
                    onNavigateToShipments = { navController.navigate(Screen.Shipments.route) },
                    onNavigateToInventory = { navController.navigate(Screen.Inventory.route) },
                    onNavigateToDefects   = { navController.navigate(Screen.Defects.route) },
                    onNavigateToShipment  = { id ->
                        navController.navigate("shipment_detail/$id")
                    },
                )
            }
            composable(Screen.Shipments.route) {
                ShipmentsListScreen(
                    onNavigateToShipment = { id -> navController.navigate("shipment_detail/$id") },
                )
            }
            composable("shipment_detail/{id}") { back ->
                val id = back.arguments?.getString("id") ?: return@composable
                ShipmentDetailScreen(shipmentId = id, onBack = { navController.popBackStack() })
            }
            composable(Screen.Inventory.route) { InventoryScreen() }
            composable(Screen.Defects.route)   { DefectDetectionScreen() }
        }
    }
}
