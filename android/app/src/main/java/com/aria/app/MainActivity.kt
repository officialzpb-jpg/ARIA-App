// ARIA Android App - MainActivity.kt
// Complete Jetpack Compose Implementation

package com.aria.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.aria.app.ui.theme.ARIATheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// Color Palette - Military Terminal Theme
val Cyan = Color(0xFF00F0FF)
val DarkBackground = Color(0xFF0A0A0F)
val DarkSurface = Color(0xFF12121A)
val TextPrimary = Color(0xFFFFFFFF)
val TextSecondary = Color(0xFFA0A0B0)

class MainActivity : ComponentActivity() {
    
    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        // Handle permission results
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Request permissions
        requestPermissions()
        
        setContent {
            ARIATheme {
                ARIAApp()
            }
        }
    }
    
    private fun requestPermissions() {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.INTERNET
        )
        
        permissionLauncher.launch(permissions)
    }
}

@Composable
fun ARIAApp() {
    val navController = rememberNavController()
    val viewModel: ARIAViewModel = viewModel()
    
    Scaffold(
        bottomBar = { BottomNavigationBar(navController) },
        containerColor = DarkBackground
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = "voice",
            modifier = Modifier.padding(padding)
        ) {
            composable("voice") { VoiceScreen(viewModel) }
            composable("history") { HistoryScreen() }
            composable("routes") { RoutesScreen() }
            composable("settings") { SettingsScreen() }
        }
    }
}

@Composable
fun BottomNavigationBar(navController: NavHostController) {
    val items = listOf(
        NavigationItem("Voice", Icons.Default.Mic, "voice"),
        NavigationItem("History", Icons.Default.History, "history"),
        NavigationItem("Routes", Icons.Default.AccountTree, "routes"),
        NavigationItem("Settings", Icons.Default.Settings, "settings")
    )
    
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    
    NavigationBar(
        containerColor = DarkSurface,
        tonalElevation = 0.dp
    ) {
        items.forEach { item ->
            NavigationBarItem(
                icon = { Icon(item.icon, contentDescription = item.label) },
                label = { Text(item.label) },
                selected = currentRoute == item.route,
                onClick = {
                    navController.navigate(item.route) {
                        popUpTo(navController.graph.startDestinationId)
                        launchSingleTop = true
                    }
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = Cyan,
                    selectedTextColor = Cyan,
                    unselectedIconColor = TextSecondary,
                    unselectedTextColor = TextSecondary,
                    indicatorColor = Cyan.copy(alpha = 0.1f)
                )
            )
        }
    }
}

data class NavigationItem(
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val route: String
)

@Composable
fun VoiceScreen(viewModel: ARIAViewModel) {
    val uiState by viewModel.uiState.collectAsState()
    var showPersonaDialog by remember { mutableStateOf(false) }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "ARIA",
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace,
                    color = Cyan
                )
                
                Button(
                    onClick = { showPersonaDialog = true },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Cyan.copy(alpha = 0.2f),
                        contentColor = Cyan
                    ),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Text(uiState.selectedPersona.name)
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Recording Button
            RecordingButton(
                isRecording = uiState.isRecording,
                audioLevel = uiState.audioLevel,
                onClick = { viewModel.toggleRecording() }
            )
            
            // Audio Waveform
            AnimatedVisibility(
                visible = uiState.isRecording,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                AudioWaveform(
                    level = uiState.audioLevel,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(60.dp)
                        .padding(horizontal = 32.dp, vertical = 16.dp)
                )
            }
            
            // Transcript
            AnimatedVisibility(
                visible = uiState.transcript.isNotEmpty(),
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .heightIn(max = 150.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = Color.White.copy(alpha = 0.1f)
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(
                        text = uiState.transcript,
                        modifier = Modifier.padding(16.dp),
                        color = TextPrimary
                    )
                }
            }
            
            // AI Response
            AnimatedVisibility(
                visible = uiState.aiResponse.isNotEmpty(),
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .heightIn(max = 200.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = Cyan.copy(alpha = 0.1f)
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Text(
                        text = uiState.aiResponse,
                        modifier = Modifier.padding(16.dp),
                        color = Cyan
                    )
                }
            }
            
            Spacer(modifier = Modifier.weight(1f))
        }
    }
    
    if (showPersonaDialog) {
        PersonaDialog(
            selectedPersona = uiState.selectedPersona,
            onPersonaSelected = { viewModel.selectPersona(it) },
            onDismiss = { showPersonaDialog = false }
        )
    }
}

@Composable
fun RecordingButton(
    isRecording: Boolean,
    audioLevel: Float,
    onClick: () -> Unit
) {
    val scope = rememberCoroutineScope()
    var pulseAnimation by remember { mutableStateOf(false) }
    
    LaunchedEffect(isRecording) {
        pulseAnimation = isRecording
    }
    
    Box(
        modifier = Modifier.size(200.dp),
        contentAlignment = Alignment.Center
    ) {
        // Pulse rings
        if (isRecording) {
            repeat(2) { index ->
                val delay = index * 300
                Box(
                    modifier = Modifier
                        .size(200.dp)
                        .scale(if (pulseAnimation) 1.5f else 1f)
                        .alpha(if (pulseAnimation) 0f else 0.5f)
                        .background(
                            color = Cyan.copy(alpha = 0.3f),
                            shape = CircleShape
                        )
                )
                
                LaunchedEffect(pulseAnimation) {
                    if (pulseAnimation) {
                        while (true) {
                            delay(delay.toLong())
                            // Animation handled by scale/alpha above
                        }
                    }
                }
            }
        }
        
        // Main button
        Button(
            onClick = onClick,
            modifier = Modifier
                .size(120.dp)
                .shadow(
                    elevation = 20.dp,
                    shape = CircleShape,
                    spotColor = if (isRecording) Color.Red else Cyan
                ),
            shape = CircleShape,
            colors = ButtonDefaults.buttonColors(
                containerColor = if (isRecording) Color.Red else Cyan,
                contentColor = if (isRecording) Color.White else Color.Black
            )
        ) {
            Icon(
                imageVector = if (isRecording) Icons.Default.Stop else Icons.Default.Mic,
                contentDescription = if (isRecording) "Stop" else "Record",
                modifier = Modifier.size(40.dp)
            )
        }
    }
}

@Composable
fun AudioWaveform(
    level: Float,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(20) { index ->
            val normalizedIndex = kotlin.math.abs(index - 10)
            val barHeight = 20.dp + (80.dp * level * (1f - normalizedIndex / 10f))
            
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height(barHeight)
                    .background(
                        color = Cyan,
                        shape = RoundedCornerShape(2.dp)
                    )
            )
        }
    }
}

@Composable
fun PersonaDialog(
    selectedPersona: Persona,
    onPersonaSelected: (Persona) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Select Persona", color = TextPrimary) },
        text = {
            Column {
                Persona.values().forEach { persona ->
                    ListItem(
                        headlineContent = { Text(persona.displayName, color = TextPrimary) },
                        supportingContent = { Text(persona.description, color = TextSecondary) },
                        leadingContent = {
                            Icon(
                                imageVector = persona.icon,
                                contentDescription = null,
                                tint = Cyan
                            )
                        },
                        trailingContent = if (persona == selectedPersona) {
                            { Icon(Icons.Default.Check, contentDescription = "Selected", tint = Cyan) }
                        } else null,
                        modifier = Modifier.clickable { onPersonaSelected(persona) }
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Close", color = Cyan)
            }
        },
        containerColor = DarkSurface
    )
}

@Composable
fun HistoryScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .padding(16.dp)
    ) {
        Text(
            text = "History",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Placeholder history items
        repeat(5) { index ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                colors = CardDefaults.cardColors(
                    containerColor = DarkSurface
                ),
                shape = RoundedCornerShape(12.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Voice query about project status",
                        color = TextPrimary,
                        maxLines = 1
                    )
                    Text(
                        text = "2 hours ago • Routed to Slack",
                        color = TextSecondary,
                        fontSize = 12.sp
                    )
                }
            }
        }
    }
}

@Composable
fun RoutesScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .padding(16.dp)
    ) {
        Text(
            text = "Routing Rules",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Add rule button
        Button(
            onClick = { },
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = Cyan),
            shape = RoundedCornerShape(8.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = null)
            Spacer(modifier = Modifier.width(8.dp))
            Text("Add Rule", color = Color.Black)
        }
    }
}

@Composable
fun SettingsScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(DarkBackground)
            .padding(16.dp)
    ) {
        Text(
            text = "Settings",
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Settings items
        SettingsItem("Account", Icons.Default.Person)
        SettingsItem("API Keys", Icons.Default.Key)
        SettingsItem("Voice Settings", Icons.Default.Mic)
        SettingsItem("Notifications", Icons.Default.Notifications)
        SettingsItem("About", Icons.Default.Info)
    }
}

@Composable
fun SettingsItem(title: String, icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .clickable { },
        colors = CardDefaults.cardColors(containerColor = DarkSurface),
        shape = RoundedCornerShape(8.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, tint = Cyan)
            Spacer(modifier = Modifier.width(16.dp))
            Text(title, color = TextPrimary)
            Spacer(modifier = Modifier.weight(1f))
            Icon(Icons.Default.ChevronRight, contentDescription = null, tint = TextSecondary)
        }
    }
}

// Data Classes
enum class Persona(val displayName: String, val description: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    DEFAULT("Default", "General purpose assistant", Icons.Default.Person),
    EXECUTIVE("Executive", "Professional and concise", Icons.Default.Business),
    CREATIVE("Creative", "Imaginative and inspiring", Icons.Default.Palette),
    TECHNICAL("Technical", "Detailed with code examples", Icons.Default.Code),
    CONCISE("Concise", "Brief 1-2 sentence responses", Icons.Default.ShortText)
}

// ViewModel
class ARIAViewModel : androidx.lifecycle.ViewModel() {
    private val _uiState = mutableStateOf(ARIAUIState())
    val uiState: State<ARIAUIState> = _uiState
    
    fun toggleRecording() {
        _uiState.value = _uiState.value.copy(
            isRecording = !_uiState.value.isRecording
        )
        
        if (!_uiState.value.isRecording) {
            // Process recording
            processRecording()
        }
    }
    
    fun selectPersona(persona: Persona) {
        _uiState.value = _uiState.value.copy(selectedPersona = persona)
    }
    
    private fun processRecording() {
        viewModelScope.launch {
            // Simulate processing
            delay(1000)
            _uiState.value = _uiState.value.copy(
                transcript = "What's the weather like today?"
            )
            
            delay(1500)
            _uiState.value = _uiState.value.copy(
                aiResponse = "I don't have access to real-time weather data, but I can help you find a weather app or website to check the current conditions in your area."
            )
        }
    }
}

data class ARIAUIState(
    val isRecording: Boolean = false,
    val audioLevel: Float = 0f,
    val transcript: String = "",
    val aiResponse: String = "",
    val selectedPersona: Persona = Persona.DEFAULT
)
