package com.cargotrack.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// ── Brand colours ─────────────────────────────────────────────
val CargoBlue     = Color(0xFF1565C0)
val CargoLightBlue= Color(0xFF42A5F5)
val CargoCyan     = Color(0xFF00ACC1)
val CargoGreen    = Color(0xFF2E7D32)
val CargoAmber    = Color(0xFFF57C00)
val CargoRed      = Color(0xFFC62828)
val CargoPurple   = Color(0xFF6A1B9A)
val CargoGray     = Color(0xFF37474F)
val CargoSurface  = Color(0xFFF5F7FA)
val CargoDarkBg   = Color(0xFF0D1B2A)
val CargoDarkSurface = Color(0xFF1A2840)

private val DarkColorScheme = darkColorScheme(
    primary        = CargoLightBlue,
    onPrimary      = Color.White,
    primaryContainer    = Color(0xFF0D47A1),
    onPrimaryContainer  = Color(0xFFBBDEFB),
    secondary      = CargoCyan,
    tertiary       = CargoGreen,
    background     = CargoDarkBg,
    surface        = CargoDarkSurface,
    onBackground   = Color.White,
    onSurface      = Color(0xFFECEFF1),
    error          = Color(0xFFEF9A9A),
)

private val LightColorScheme = lightColorScheme(
    primary        = CargoBlue,
    onPrimary      = Color.White,
    primaryContainer    = Color(0xFFBBDEFB),
    onPrimaryContainer  = Color(0xFF0D47A1),
    secondary      = CargoCyan,
    tertiary       = CargoGreen,
    background     = CargoSurface,
    surface        = Color.White,
    onBackground   = Color(0xFF1A2840),
    onSurface      = Color(0xFF263238),
    error          = CargoRed,
)

@Composable
fun CargoTrackTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        typography  = Typography(),
        content     = content,
    )
}
