//
//  ARIA - AI Routing & Integration Assistant
//  iOS Control Center Module
//  Requires separate target: ControlCenterModule
//

import CoreFoundation
import CoreFoundation.CFNotificationCenter

// This is a Control Center module that allows triggering ARIA from Control Center
// Requires creating a separate target in Xcode with the Control Center Module template

import Foundation
import CoreFoundation

class ARIAControlCenterModule: NSObject {
    
    // Called when the user taps the Control Center toggle
    static func handleToggle() {
        // Wake the main app
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            notificationCenter,
            CFNotificationName("com.aria.triggerRecording" as CFString),
            nil,
            nil,
            true
        )
        
        // Haptic feedback
        AudioServicesPlaySystemSound(1519) // Standard haptic
    }
}

// MARK: - Siri Shortcuts Integration

import Intents

class ARIAShortcuts {
    
    // Define custom intents for Siri Shortcuts
    
    static func donateTriggerIntent() {
        let intent = ARIATriggerIntent()
        intent.suggestedInvocationPhrase = "Ask ARIA"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Failed to donate intent: \(error)")
            }
        }
    }
    
    static func donateSendMessageIntent(to recipient: String) {
        let intent = ARIASendMessageIntent()
        intent.recipient = recipient
        intent.suggestedInvocationPhrase = "Send message to \(recipient) via ARIA"
        
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Failed to donate intent: \(error)")
            }
        }
    }
}

// Custom Intent Handler
class ARIAIntentHandler: NSObject, ARIATriggerIntentHandling, ARIASendMessageIntentHandling {
    
    func handle(intent: ARIATriggerIntent, completion: @escaping (ARIATriggerIntentResponse) -> Void) {
        // Trigger recording in main app
        ARIAControlCenterModule.handleToggle()
        completion(ARIATriggerIntentResponse(code: .success, userActivity: nil))
    }
    
    func handle(intent: ARIASendMessageIntent, completion: @escaping (ARIASendMessageIntentResponse) -> Void) {
        // Handle send message intent
        let recipient = intent.recipient ?? ""
        
        // Open main app with parameters
        let url = URL(string: "aria://send?to=\(recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
        UIApplication.shared.open(url, options: [:]) { _ in
            completion(ARIASendMessageIntentResponse(code: .success, userActivity: nil))
        }
    }
}

// MARK: - Back Tap Integration

import UIKit

class ARIABackTapManager {
    
    // Note: Back Tap is configured by the user in Settings > Accessibility > Touch > Back Tap
    // We register for the notification when it triggers
    
    static func setupBackTapListener() {
        // Listen for the back tap notification
        // This is handled by the system calling our app via URL scheme or notification
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Check if we were opened via Back Tap
            if let launchOptions = UIApplication.shared.launchOptions,
               let source = launchOptions[.sourceApplication] as? String,
               source == "com.apple.accessibility.BackTap" {
                // Trigger recording
                NotificationCenter.default.post(name: .init("ARIAStartRecording"), object: nil)
            }
        }
    }
}

// MARK: - Lock Screen Widget

import WidgetKit
import SwiftUI

struct ARIALockScreenWidget: Widget {
    let kind: String = "ARIALockScreenWidget"
    
    var body: some WidgetConfiguration {
        AccessoryInlineConfiguration(
            kind: kind,
            provider: ARIAProvider()
        ) { entry in
            ARIALockScreenView(entry: entry)
        }
        .configurationDisplayName("ARIA")
        .description("Quick access to ARIA voice assistant")
    }
}

struct ARIAEntry: TimelineEntry {
    let date: Date
    let isRecording: Bool
}

struct ARIAProvider: TimelineProvider {
    func placeholder(in context: Context) -> ARIAEntry {
        ARIAEntry(date: Date(), isRecording: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ARIAEntry) -> Void) {
        completion(ARIAEntry(date: Date(), isRecording: false))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ARIAEntry>) -> Void) {
        let entry = ARIAEntry(date: Date(), isRecording: false)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct ARIALockScreenView: View {
    var entry: ARIAProvider.Entry
    
    var body: some View {
        Image(systemName: entry.isRecording ? "mic.circle.fill" : "mic.circle")
            .foregroundColor(.cyan)
    }
}

// MARK: - Dynamic Island / Live Activity

import ActivityKit

@available(iOS 16.1, *)
struct ARIALiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var audioLevel: Double
        var elapsedTime: TimeInterval
    }
    
    var sessionId: String
}

@available(iOS 16.1, *)
class ARIALiveActivityManager {
    static let shared = ARIALiveActivityManager()
    
    var currentActivity: Activity<ARIALiveActivityAttributes>?
    
    func startRecording() {
        let attributes = ARIALiveActivityAttributes(sessionId: UUID().uuidString)
        let contentState = ARIALiveActivityAttributes.ContentState(
            status: "Listening...",
            audioLevel: 0.0,
            elapsedTime: 0
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
    
    func updateAudioLevel(_ level: Double) {
        guard let activity = currentActivity else { return }
        
        let updatedState = ARIALiveActivityAttributes.ContentState(
            status: "Listening...",
            audioLevel: level,
            elapsedTime: Date().timeIntervalSince(activity.attributes.creationDate)
        )
        
        Task {
            await activity.update(using: updatedState)
        }
    }
    
    func stopRecording() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(using: nil, dismissalPolicy: .immediate)
        }
        
        currentActivity = nil
    }
}

// MARK: - URL Scheme Handling

// aria://trigger - Start recording
// aria://send?to=CONTACT&message=TEXT - Send specific message
// aria://settings - Open settings

extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard url.scheme == "aria" else { return false }
        
        switch url.host {
        case "trigger":
            NotificationCenter.default.post(name: .init("ARIAStartRecording"), object: nil)
            return true
            
        case "send":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let recipient = components?.queryItems?.first(where: { $0.name == "to" })?.value
            let message = components?.queryItems?.first(where: { $0.name == "message" })?.value
            
            // Handle send intent
            print("Send to: \(recipient ?? "unknown"), message: \(message ?? "none")")
            return true
            
        case "settings":
            // Open settings tab
            return true
            
        default:
            return false
        }
    }
}

// MARK: - Background Audio Processing

import BackgroundTasks

class ARIABackgroundTaskManager {
    
    static let shared = ARIABackgroundTaskManager()
    
    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.aria.audioProcessing",
            using: nil
        ) { task in
            self.handleAudioProcessingTask(task as! BGProcessingTask)
        }
    }
    
    func scheduleAudioProcessing() {
        let request = BGProcessingTaskRequest(identifier: "com.aria.audioProcessing")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background task: \(error)")
        }
    }
    
    private func handleAudioProcessingTask(_ task: BGProcessingTask) {
        // Perform background audio processing
        // This could be used for batch transcription or model updates
        
        task.expirationHandler = {
            // Clean up if task expires
        }
        
        // Complete the task
        task.setTaskCompleted(success: true)
    }
}

// MARK: - Push Notification Handling

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Push token: \(token)")
        
        // Send token to backend
        // This enables server-initiated triggers (e.g., "ARIA, remind me...")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for push: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle push notification triggers
        if let action = userInfo["action"] as? String {
            switch action {
            case "startRecording":
                NotificationCenter.default.post(name: .init("ARIAStartRecording"), object: nil)
            default:
                break
            }
        }
        
        completionHandler(.newData)
    }
}

// MARK: - Watch Connectivity (Apple Watch)

import WatchConnectivity

class ARIAWatchManager: NSObject, WCSessionDelegate {
    static let shared = ARIAWatchManager()
    
    func setup() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch session activated: \(activationState)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let action = message["action"] as? String, action == "trigger" {
            NotificationCenter.default.post(name: .init("ARIAStartRecording"), object: nil)
        }
    }
}
