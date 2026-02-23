//
//  ARIA iOS App - Complete Implementation
//  Project Structure for Xcode
//

/*
PROJECT: ARIA.xcodeproj
TARGETS:
  - ARIA (Main App)
  - ARIAControlCenter (Control Center Extension)
  - ARIAWidget (Widget Extension)
  - ARIAIntents (Siri Shortcuts)

DEPENDENCIES (Package.swift or SPM):
  - Alamofire (HTTP client)
  - KeychainAccess (Secure storage)
  - Starscream (WebSocket)
  - SwiftUI-Introspect
  - whisper.cpp (C++ bindings)
*/

import SwiftUI
import AVFoundation
import Speech
import Combine
import WidgetKit
import ActivityKit

// MARK: - App Entry Point

@main
struct ARIAApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState.shared)
        }
    }
}

// MARK: - App State (Singleton)

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isRecording = false
    @Published var currentTranscript = ""
    @Published var aiResponse = ""
    @Published var selectedPersona: Persona = .default
    @Published var isProcessing = false
    @Published var audioLevel: Float = 0.0
    @Published var showIntro = true
    
    let audioService = AudioCaptureService()
    let sttService = SpeechToTextService()
    let aiService = AIService()
    let routingService = RoutingService()
    let apiClient = APIClient()
}

// MARK: - Models

enum Persona: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case executive = "Executive"
    case creative = "Creative"
    case technical = "Technical"
    case concise = "Concise"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .default: return "person.fill"
        case .executive: return "briefcase.fill"
        case .creative: return "paintbrush.fill"
        case .technical: return "cpu.fill"
        case .concise: return "text.bubble.fill"
        }
    }
    
    var systemPrompt: String {
        switch self {
        case .default:
            return "You are a helpful AI assistant."
        case .executive:
            return "You are an executive assistant. Be concise, professional, and action-oriented. Focus on deliverables and next steps."
        case .creative:
            return "You are a creative writing partner. Be imaginative, inspiring, and help brainstorm ideas."
        case .technical:
            return "You are a technical advisor. Provide detailed, accurate information with code examples when relevant."
        case .concise:
            return "Respond in 1-2 sentences maximum. Be extremely brief."
        }
    }
}

struct Conversation: Identifiable, Codable {
    let id: String
    let transcript: String
    let aiResponse: String
    let timestamp: Date
    let modelUsed: String
    let routedTo: [String]
}

struct RoutingRule: Identifiable, Codable {
    let id: String
    var name: String
    var isEnabled: Bool
    var conditions: [Condition]
    var actions: [Action]
    
    struct Condition: Codable {
        let type: String
        let value: String
    }
    
    struct Action: Codable {
        let channel: String
        let destination: String
    }
}

// MARK: - API Client

class APIClient {
    private let baseURL = "https://api.aria.ai"
    private var token: String? {
        get { KeychainManager.shared.get(key: "auth_token") }
        set { KeychainManager.shared.set(value: newValue ?? "", key: "auth_token") }
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let request = try createRequest(path: "/api/v1/auth/login", method: "POST", body: [
            "email": email,
            "password": password
        ])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)
        self.token = response.token
        return response
    }
    
    func generateAIResponse(prompt: String, persona: Persona) async throws -> AIResponse {
        let request = try createRequest(path: "/api/v1/ai/generate", method: "POST", body: [
            "prompt": prompt,
            "systemPrompt": persona.systemPrompt,
            "provider": "openai",
            "model": "gpt-4o-mini"
        ])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AIResponse.self, from: data)
    }
    
    func transcribeAudio(audioData: Data) async throws -> TranscriptionResponse {
        let base64Audio = audioData.base64EncodedString()
        let request = try createRequest(path: "/api/v1/ai/transcribe", method: "POST", body: [
            "audioBase64": base64Audio,
            "provider": "whisper"
        ])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TranscriptionResponse.self, from: data)
    }
    
    func sendToDiscord(content: String, webhookURL: String) async throws {
        let request = try createRequest(path: "/api/v1/webhooks/discord", method: "POST", body: [
            "content": content,
            "webhookUrl": webhookURL
        ])
        
        _ = try await URLSession.shared.data(for: request)
    }
    
    private func createRequest(path: String, method: String, body: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
}

struct AuthResponse: Codable {
    let user: UserData
    let token: String
}

struct UserData: Codable {
    let id: String
    let email: String
    let name: String?
    let subscriptionTier: String
}

struct AIResponse: Codable {
    let response: String
    let model: String
    let latencyMs: Int
    let provider: String
}

struct TranscriptionResponse: Codable {
    let transcript: String
    let provider: String
}

enum APIError: Error {
    case invalidURL
    case unauthorized
    case serverError
}

// MARK: - Services

class AudioCaptureService: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    
    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("recording_\(UUID().uuidString).wav")
    }
    
    func startRecording() async throws -> URL {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let format = inputNode!.outputFormat(forBus: 0)
        
        // Create audio file
        audioFile = try AVAudioFile(forWriting: recordingURL, settings: format.settings)
        
        // Install tap
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // Write to file
            try? self.audioFile?.write(from: buffer)
            
            // Calculate audio level
            let level = self.calculateAudioLevel(buffer: buffer)
            DispatchQueue.main.async {
                self.audioLevel = level
            }
        }
        
        audioEngine?.prepare()
        try audioEngine?.start()
        
        isRecording = true
        
        // Start Live Activity
        if #available(iOS 16.1, *) {
            ARIALiveActivityManager.shared.startRecording()
        }
        
        return recordingURL
    }
    
    func stopRecording() -> URL? {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        
        let url = audioFile?.url
        audioFile = nil
        audioEngine = nil
        
        isRecording = false
        audioLevel = 0
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            ARIALiveActivityManager.shared.stopRecording()
        }
        
        return url
    }
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in stride(from: 0, to: frameLength, by: buffer.stride) {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameLength)
        return min(1.0, average * 10)
    }
}

class SpeechToTextService {
    enum Provider {
        case whisperLocal
        case whisperAPI
        case appleSpeech
    }
    
    func transcribe(audioURL: URL, provider: Provider = .whisperAPI) async throws -> String {
        switch provider {
        case .whisperAPI:
            let audioData = try Data(contentsOf: audioURL)
            let response = try await AppState.shared.apiClient.transcribeAudio(audioData: audioData)
            return response.transcript
            
        case .appleSpeech:
            return try await transcribeWithAppleSpeech(audioURL: audioURL)
            
        case .whisperLocal:
            // Would integrate with whisper.cpp
            return "Local transcription not implemented"
        }
    }
    
    private func transcribeWithAppleSpeech(audioURL: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw STTError.recognizerUnavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.requiresOnDeviceRecognition = true
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}

enum STTError: Error {
    case recognizerUnavailable
}

class AIService {
    func generateResponse(prompt: String, persona: Persona) async throws -> String {
        let response = try await AppState.shared.apiClient.generateAIResponse(
            prompt: prompt,
            persona: persona
        )
        return response.response
    }
}

class RoutingService {
    func routeResponse(_ response: String, to channels: [String]) async {
        for channel in channels {
            switch channel {
            case "discord":
                // Route to Discord
                break
            case "telegram":
                // Route to Telegram
                break
            default:
                break
            }
        }
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    
    func set(value: String, key: String) {
        // In production, use KeychainAccess library
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func get(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
    
    func delete(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - Views

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if appState.showIntro {
                IntroView()
                    .transition(.opacity)
            } else {
                MainTabView()
            }
        }
    }
}

struct IntroView: View {
    @EnvironmentObject var appState: AppState
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(animate ? 1.2 : 0.8)
                        .opacity(animate ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: animate)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundColor(.cyan)
                        .rotationEffect(.degrees(animate ? 0 : -180))
                        .scaleEffect(animate ? 1 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.5), value: animate)
                }
                
                // Title
                Text("ARIA")
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 50)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: animate)
                
                Text("AI Voice Assistant")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.7), value: animate)
                
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                    .scaleEffect(1.5)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.9), value: animate)
                
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            animate = true
            
            // Hide intro after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    appState.showIntro = false
                }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            VoiceInterfaceView()
                .tabItem {
                    Label("Voice", systemImage: "mic.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            
            RoutingView()
                .tabItem {
                    Label("Routes", systemImage: "arrow.branch")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.cyan)
    }
}

struct VoiceInterfaceView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPersonaPicker = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("ARIA")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    Button(action: { showingPersonaPicker = true }) {
                        HStack {
                            Image(systemName: appState.selectedPersona.icon)
                            Text(appState.selectedPersona.rawValue)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.cyan.opacity(0.2))
                        .foregroundColor(.cyan)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Recording button
                RecordingButton()
                
                // Audio waveform
                if appState.isRecording {
                    AudioWaveformView(level: appState.audioLevel)
                        .frame(height: 60)
                        .padding(.horizontal)
                }
                
                // Transcript
                if !appState.currentTranscript.isEmpty {
                    ScrollView {
                        Text(appState.currentTranscript)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .frame(maxHeight: 150)
                }
                
                // AI Response
                if !appState.aiResponse.isEmpty {
                    ScrollView {
                        Text(appState.aiResponse)
                            .font(.body)
                            .foregroundColor(.cyan)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .frame(maxHeight: 200)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingPersonaPicker) {
            PersonaPickerView()
        }
    }
}

struct RecordingButton: View {
    @EnvironmentObject var appState: AppState
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: toggleRecording) {
            ZStack {
                // Pulse rings
                if appState.isRecording {
                    ForEach(0..<2) { i in
                        Circle()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                            .opacity(pulseAnimation ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.3),
                                value: pulseAnimation
                            )
                    }
                }
                
                // Main button
                Circle()
                    .fill(appState.isRecording ? Color.red : Color.cyan)
                    .frame(width: 120, height: 120)
                    .shadow(color: (appState.isRecording ? Color.red : Color.cyan).opacity(0.5), radius: 20)
                
                Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(appState.isRecording ? .white : .black)
            }
        }
        .onChange(of: appState.isRecording) { isRecording in
            pulseAnimation = isRecording
        }
    }
    
    private func toggleRecording() {
        if appState.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        Task {
            do {
                _ = try await appState.audioService.startRecording()
                await MainActor.run {
                    appState.isRecording = true
                }
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    private func stopRecording() {
        guard let audioURL = appState.audioService.stopRecording() else { return }
        
        appState.isRecording = false
        appState.isProcessing = true
        
        Task {
            do {
                // Transcribe
                let transcript = try await appState.sttService.transcribe(audioURL: audioURL)
                await MainActor.run {
                    appState.currentTranscript = transcript
                }
                
                // Generate AI response
                let response = try await appState.aiService.generateResponse(
                    prompt: transcript,
                    persona: appState.selectedPersona
                )
                await MainActor.run {
                    appState.aiResponse = response
                    appState.isProcessing = false
                }
                
            } catch {
                await MainActor.run {
                    appState.aiResponse = "Error: \(error.localizedDescription)"
                    appState.isProcessing = false
                }
            }
        }
    }
}

struct AudioWaveformView: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<30) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.cyan)
                        .frame(width: 4)
                        .frame(height: barHeight(for: index, in: geometry.size.height))
                        .animation(.easeInOut(duration: 0.1), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        let normalizedIndex = abs(index - 15)
        let baseHeight = maxHeight * 0.3
        let variableHeight = maxHeight * 0.7 * CGFloat(level)
        let positionFactor = 1.0 - (CGFloat(normalizedIndex) / 15.0)
        
        return baseHeight + (variableHeight * positionFactor)
    }
}

struct PersonaPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Persona.allCases) { persona in
                    Button(action: {
                        appState.selectedPersona = persona
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: persona.icon)
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading) {
                                Text(persona.rawValue)
                                    .font(.headline)
                                Text(persona.systemPrompt)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if appState.selectedPersona == persona {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Persona")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HistoryView: View {
    @State private var conversations: [Conversation] = []
    
    var body: some View {
        List {
            ForEach(conversations) { conversation in
                VStack(alignment: .leading, spacing: 8) {
                    Text(conversation.transcript)
                        .font(.body)
                        .lineLimit(2)
                    
                    Text(conversation.aiResponse)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("History")
    }
}

struct RoutingView: View {
    var body: some View {
        Text("Routing Rules")
            .navigationTitle("Routes")
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                NavigationLink("Profile") {
                    Text("Profile Settings")
                }
                NavigationLink("API Keys") {
                    Text("API Key Management")
                }
            }
            
            Section("Preferences") {
                Toggle("Dark Mode", isOn: .constant(true))
                Toggle("Haptic Feedback", isOn: .constant(true))
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Live Activity (iOS 16.1+)

@available(iOS 16.1, *)
class ARIALiveActivityManager {
    static let shared = ARIALiveActivityManager()
    
    var currentActivity: Activity<ARIAWidgetAttributes>?
    
    func startRecording() {
        let attributes = ARIAWidgetAttributes()
        let contentState = ARIAWidgetAttributes.ContentState(
            status: "Listening...",
            audioLevel: 0.0
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateAudioLevel(_ level: Float) {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.update(using: ARIAWidgetAttributes.ContentState(
                status: "Listening...",
                audioLevel: level
            ))
        }
    }
    
    func stopRecording() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        
        currentActivity = nil
    }
}

@available(iOS 16.1, *)
struct ARIAWidgetAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
        var audioLevel: Double
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        return true
    }
}
