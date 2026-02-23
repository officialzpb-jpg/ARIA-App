//
//  ARIA - AI Routing & Integration Assistant
//  iOS Main App Entry Point
//

import SwiftUI
import AVFoundation
import BackgroundTasks

@main
struct ARIAApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    requestPermissions()
                }
        }
    }
    
    private func requestPermissions() {
        // Microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("Microphone permission: \(granted)")
        }
        
        // Speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            print("Speech recognition status: \(status)")
        }
        
        // Notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("Notification permission: \(granted)")
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var currentTranscript = ""
    @Published var aiResponse = ""
    @Published var selectedPersona: Persona = .default
    @Published var routingRules: [RoutingRule] = []
    @Published var apiKeys: [String: String] = [:]
    
    // Services
    let audioService = AudioCaptureService()
    let sttService = SpeechToTextService()
    let aiService = AIService()
    let routingService = RoutingService()
}

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.aria.backgroundprocess", using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    func handleBackgroundTask(task: BGAppRefreshTask) {
        // Handle background processing
        task.setTaskCompleted(success: true)
    }
}

// MARK: - Models

enum Persona: String, CaseIterable {
    case `default` = "Default Assistant"
    case executive = "Executive Assistant"
    case creative = "Creative Partner"
    case technical = "Technical Advisor"
    case concise = "Concise Mode"
    
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

struct RoutingRule: Identifiable, Codable {
    let id: UUID
    var name: String
    var conditions: [Condition]
    var actions: [Action]
    var isEnabled: Bool
    
    struct Condition: Codable {
        var type: ConditionType
        var value: String
        
        enum ConditionType: String, Codable {
            case contains = "contains"
            case startsWith = "starts_with"
            case sentiment = "sentiment"
            case timeOfDay = "time_of_day"
            case keyword = "keyword"
        }
    }
    
    struct Action: Codable {
        var channel: Channel
        var destination: String
        
        enum Channel: String, Codable {
            case discord = "discord"
            case telegram = "telegram"
            case sms = "sms"
            case email = "email"
            case slack = "slack"
            case webhook = "webhook"
        }
    }
}

// MARK: - Services

// Audio Capture Service
class AudioCaptureService: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    
    func startRecording() async throws -> URL {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        // Configure format
        let recordingFormat = inputNode!.outputFormat(forBus: 0)
        
        // Install tap for audio level monitoring
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            let level = self.calculateAudioLevel(buffer: buffer)
            DispatchQueue.main.async {
                self.audioLevel = level
            }
        }
        
        // Start engine
        audioEngine?.prepare()
        try audioEngine?.start()
        
        isRecording = true
        
        // Return temporary file URL
        return FileManager.default.temporaryDirectory.appendingPathComponent("recording_\(UUID().uuidString).wav")
    }
    
    func stopRecording() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        isRecording = false
    }
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelData[$0] }
        
        let sum = channelDataValueArray.map { $0 * $0 }.reduce(0, +)
        let rms = sqrt(sum / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        
        return max(0, (avgPower + 50) / 50) // Normalize 0-1
    }
}

// Speech-to-Text Service
class SpeechToTextService {
    enum STTProvider {
        case whisperLocal
        case whisperAPI
        case appleSpeech
    }
    
    func transcribe(audioURL: URL, provider: STTProvider = .whisperLocal) async throws -> String {
        switch provider {
        case .whisperLocal:
            return try await transcribeWithWhisperLocal(audioURL: audioURL)
        case .whisperAPI:
            return try await transcribeWithWhisperAPI(audioURL: audioURL)
        case .appleSpeech:
            return try await transcribeWithAppleSpeech(audioURL: audioURL)
        }
    }
    
    private func transcribeWithWhisperLocal(audioURL: URL) async throws -> String {
        // Integrate with whisper.cpp via Swift bindings
        // This would use a compiled whisper.cpp library
        // For now, return placeholder
        return "Local transcription placeholder"
    }
    
    private func transcribeWithWhisperAPI(audioURL: URL) async throws -> String {
        let apiKey = KeychainManager.shared.get(key: "openai_api_key") ?? ""
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart form data
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        data.append(try Data(contentsOf: audioURL))
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        
        return json?["text"] as? String ?? ""
    }
    
    private func transcribeWithAppleSpeech(audioURL: URL) async throws -> String {
        // Use SFSpeechRecognizer for on-device recognition
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
    case transcriptionFailed
}

// AI Service
class AIService {
    enum AIProvider {
        case openAI(model: String)
        case anthropic(model: String)
        case local(endpoint: URL)
    }
    
    func generateResponse(prompt: String, persona: Persona, provider: AIProvider = .openAI(model: "gpt-4o-mini")) async throws -> String {
        let systemPrompt = persona.systemPrompt
        
        switch provider {
        case .openAI(let model):
            return try await callOpenAI(prompt: prompt, systemPrompt: systemPrompt, model: model)
        case .anthropic(let model):
            return try await callAnthropic(prompt: prompt, systemPrompt: systemPrompt, model: model)
        case .local(let endpoint):
            return try await callLocalLLM(prompt: prompt, systemPrompt: systemPrompt, endpoint: endpoint)
        }
    }
    
    private func callOpenAI(prompt: String, systemPrompt: String, model: String) async throws -> String {
        let apiKey = KeychainManager.shared.get(key: "openai_api_key") ?? ""
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let choices = json?["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        throw AIError.invalidResponse
    }
    
    private func callAnthropic(prompt: String, systemPrompt: String, model: String) async throws -> String {
        // Anthropic API implementation
        return "Anthropic response placeholder"
    }
    
    private func callLocalLLM(prompt: String, systemPrompt: String, endpoint: URL) async throws -> String {
        // Local LLM (Ollama/LM Studio) implementation
        return "Local LLM response placeholder"
    }
}

enum AIError: Error {
    case invalidResponse
    case rateLimited
    case insufficientCredits
}

// Routing Service
class RoutingService {
    func routeResponse(_ response: String, rules: [RoutingRule]) async {
        for rule in rules where rule.isEnabled {
            if matchesRule(response, rule: rule) {
                for action in rule.actions {
                    await executeAction(action, content: response)
                }
            }
        }
    }
    
    private func matchesRule(_ content: String, rule: RoutingRule) -> Bool {
        for condition in rule.conditions {
            switch condition.type {
            case .contains:
                if !content.lowercased().contains(condition.value.lowercased()) {
                    return false
                }
            case .keyword:
                let keywords = condition.value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                if !keywords.contains(where: { content.lowercased().contains($0) }) {
                    return false
                }
            default:
                break
            }
        }
        return true
    }
    
    private func executeAction(_ action: RoutingRule.Action, content: String) async {
        switch action.channel {
        case .discord:
            await sendToDiscord(content, webhookURL: action.destination)
        case .telegram:
            await sendToTelegram(content, botToken: action.destination)
        case .sms:
            await sendSMS(content, phoneNumber: action.destination)
        case .email:
            await sendEmail(content, address: action.destination)
        case .slack:
            await sendToSlack(content, webhookURL: action.destination)
        case .webhook:
            await sendToWebhook(content, url: action.destination)
        }
    }
    
    private func sendToDiscord(_ content: String, webhookURL: String) async {
        guard let url = URL(string: webhookURL) else { return }
        
        let payload: [String: Any] = [
            "content": content,
            "username": "ARIA Assistant"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        _ = try? await URLSession.shared.data(for: request)
    }
    
    private func sendToTelegram(_ content: String, botToken: String) async {
        // Telegram Bot API implementation
    }
    
    private func sendSMS(_ content: String, phoneNumber: String) async {
        // Twilio SMS implementation
    }
    
    private func sendEmail(_ content: String, address: String) async {
        // Email implementation
    }
    
    private func sendToSlack(_ content: String, webhookURL: String) async {
        // Slack webhook implementation
    }
    
    private func sendToWebhook(_ content: String, url: String) async {
        // Generic webhook implementation
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    static let shared = KeychainManager()
    
    func set(value: String, key: String) {
        // Implement Keychain storage
        UserDefaults.standard.set(value, forKey: key) // Temporary, use Keychain in production
    }
    
    func get(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key) // Temporary
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            VoiceInterfaceView()
                .tabItem {
                    Label("Voice", systemImage: "mic.fill")
                }
            
            RoutingRulesView()
                .tabItem {
                    Label("Routes", systemImage: "arrow.branch")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Voice Interface View

struct VoiceInterfaceView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPersonaPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            HStack {
                Text("ARIA")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Button(action: { showingPersonaPicker = true }) {
                    Text(appState.selectedPersona.rawValue)
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
            
            // Recording Button
            RecordingButton()
                .environmentObject(appState)
            
            Spacer()
            
            // Status
            if appState.isRecording {
                Text("Listening...")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            
            // Recent conversations
            RecentConversationsList()
        }
        .sheet(isPresented: $showingPersonaPicker) {
            PersonaPickerView(selectedPersona: $appState.selectedPersona)
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
                    Circle()
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseAnimation ? 1.5 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulseAnimation)
                    
                    Circle()
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 2)
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseAnimation ? 1.8 : 1.2)
                        .opacity(pulseAnimation ? 0 : 0.5)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.3), value: pulseAnimation)
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
        .onAppear {
            if appState.isRecording {
                pulseAnimation = true
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
        appState.audioService.stopRecording()
        appState.isRecording = false
        
        // Process the recording
        Task {
            // TODO: Get actual recording URL and process
            // For now, simulate
            await processVoiceQuery()
        }
    }
    
    private func processVoiceQuery() async {
        // 1. Transcribe
        // 2. Send to AI
        // 3. Route response
        // 4. Show result
    }
}

struct RecentConversationsList: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // List of recent conversations
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<3) { i in
                        ConversationRow()
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(height: 200)
    }
}

struct ConversationRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Send message to team about meeting")
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                
                Text("2 min ago • Routed to Slack")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PersonaPickerView: View {
    @Binding var selectedPersona: Persona
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Persona.allCases, id: \.self) { persona in
                    Button(action: {
                        selectedPersona = persona
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(persona.rawValue)
                                    .font(.headline)
                                Text(persona.systemPrompt)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if selectedPersona == persona {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Persona")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Placeholder Views

struct RoutingRulesView: View {
    var body: some View {
        Text("Routing Rules")
    }
}

struct HistoryView: View {
    var body: some View {
        Text("History")
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}

// MARK: - Control Center Extension

// This would be implemented as a separate Control Center module target
// See ControlCenterModule.swift for implementation
