//
//  ContentView.swift
//  Carry-oke
//
//  Created by Jayanth Annabhimoju on 10/26/25.
//

import SwiftUI
import AVFoundation
import Combine

struct ContentView: View {
    @State private var showingSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                BackgroundView()
                
                // Main Content
                VStack(spacing: 0) {
                    // Header
                    HeaderView(showingSettings: $showingSettings)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    // Main Microphone Button
                    MicrophoneButton()
                    
                    Spacer()
                    
                    // Playlist Bar
                    PlaylistBar()
                        .padding(.bottom, 34) // Account for safe area
                }
                .padding(.horizontal, 20)
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Background View
struct BackgroundView: View {
    var body: some View {
        ZStack {
            // Main background color
            Color(hex: "412234")
                .ignoresSafeArea()
            
            // Top glow effect
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "C49FCC").opacity(0.9),
                        Color(hex: "B49FCC").opacity(0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 350)
                .blur(radius: 50)
                
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        HStack {
            Text("Carry-oke")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Settings Button
            SettingsButton(showingSettings: $showingSettings)
        }
    }
}

// MARK: - Settings Button (Liquid Glass)
struct SettingsButton: View {
    @Binding var showingSettings: Bool
    
    var body: some View {
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
        .glassEffect(.regular.tint(Color(hex: "F87060").opacity(0.3)).interactive())
    }
}

// MARK: - Microphone Button (Liquid Glass)
struct MicrophoneButton: View {
    @State private var isPressed = false
    @StateObject private var karaokeEngine = KaraokeAudioEngine()
    
    var body: some View {
        Button(action: {
            Task {
                await karaokeEngine.toggleKaraoke()
            }
        }) {
            Image(systemName: karaokeEngine.isRecording ? "mic.fill" : "mic.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(karaokeEngine.isRecording ? .red : .white)
                .frame(width: 200, height: 200)
        }
        .scaleEffect(isPressed ? 0.90 : 1.0)
        .glassEffect(.regular.tint(Color(hex: karaokeEngine.isRecording ? "FF4444" : "F87060").opacity(0.25)).interactive(), in: .circle)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .task {
            await karaokeEngine.requestMicrophonePermission()
        }
    }
}

// MARK: - Playlist Bar (Liquid Glass)
struct PlaylistBar: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Playlist is empty.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                PlayButton(systemName: "play.fill")
                PlayButton(systemName: "forward.end.fill")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .glassEffect(.regular.tint(Color(hex: "F87060").opacity(0.2)).interactive(), in: .capsule)
    }
}

// MARK: - Play Button Component
struct PlayButton: View {
    let systemName: String
    
    var body: some View {
        Button(action: {
            // Play button action
        }) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - Color Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Karaoke Audio Engine
@MainActor
class KaraokeAudioEngine: ObservableObject {
    @Published var isRecording = false
    @Published var hasPermission = false
    
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioSession = AVAudioSession.sharedInstance()
    
    init() {
        setupAudioEngine()
    }
    
    deinit {
        // Clean up audio engine directly without calling main actor method
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session in deinit: \(error)")
        }
    }
    
    // Request microphone permission
    func requestMicrophonePermission() async {
        switch audioSession.recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
            print("Microphone permission denied. Please enable in Settings > Privacy & Security > Microphone")
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            hasPermission = granted
        @unknown default:
            hasPermission = false
        }
    }
    
    private func setupAudioEngine() {
        // Setup audio session with comprehensive Bluetooth support
        do {
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .default,
                                       options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try audioSession.setActive(true)
            print("Karaoke audio session setup with Bluetooth support")
        } catch {
            print("Failed to setup karaoke audio session: \(error)")
        }
        
        // Get the input node (microphone)
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Get the main mixer node (output)
        let mainMixer = audioEngine.mainMixerNode
        
        // Connect input directly to output (pass-through)
        audioEngine.connect(inputNode, to: mainMixer, format: inputFormat)
    }
    
    func toggleKaraoke() async {
        // Check if we have permission, request it if we don't
        if !hasPermission {
            await requestMicrophonePermission()
            guard hasPermission else {
                print("Microphone permission denied")
                return
            }
        }
        
        if isRecording {
            stopKaraoke()
        } else {
            startKaraoke()
        }
    }
    
    private func startKaraoke() {
        guard !audioEngine.isRunning else { return }
        
        do {
            // Activate audio session
            try audioSession.setActive(true)
            
            // Start the audio engine
            try audioEngine.start()
            
            isRecording = true
            print("Karaoke mode started - audio pass-through active")
            
        } catch {
            print("Failed to start karaoke: \(error)")
            isRecording = false
        }
    }
    
    private func stopKaraoke() {
        guard audioEngine.isRunning else { return }
        
        // Stop the audio engine
        audioEngine.stop()
        
        do {
            // Deactivate audio session
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        isRecording = false
        print("Karaoke mode stopped")
    }
}

// MARK: - Audio Device Manager
@MainActor
class AudioDeviceManager: ObservableObject {
    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []
    @Published var selectedInputDevice: AudioDevice?
    @Published var selectedOutputDevice: AudioDevice?
    
    private var audioSession = AVAudioSession.sharedInstance()
    
    init() {
        setupAudioSession()
        updateDeviceLists()
        setupNotifications()
    }
    
    // Force refresh device lists (useful for debugging)
    func refreshDevices() async {
        print("Manual device refresh triggered")
        
        // Try to refresh the audio session to detect newly connected devices
        do {
            // Temporarily deactivate and reactivate to force route discovery
            try audioSession.setActive(false, options: [])
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            try audioSession.setActive(true, options: [])
        } catch {
            print("Error refreshing audio session: \(error)")
        }
        
        updateDeviceLists()
    }
    
    private func setupAudioSession() {
        do {
            // First, set the category with all necessary options
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .default, 
                                       options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker, .allowAirPlay])
            
            // Activate the session to make Bluetooth devices discoverable
            try audioSession.setActive(true, options: [])
            
            print("Audio session setup completed with Bluetooth support")
            
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupNotifications() {
        // Listen for route changes (device connect/disconnect)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            Task { @MainActor in
                print("Audio route changed - refreshing device list")
                
                // Add a small delay to ensure the route change is complete
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                self.updateDeviceLists()
            }
        }
        
        // Also listen for interruptions
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            Task { @MainActor in
                print("Audio session interrupted - refreshing device list")
                self.updateDeviceLists()
            }
        }
    }
    
    private func updateDeviceLists() {
        print("=== Updating Device Lists ===")
        
        // Get available inputs
        let availableInputs = audioSession.availableInputs ?? []
        inputDevices = availableInputs.map { AudioDevice(from: $0, type: .input) }
        print("Found \(inputDevices.count) input devices")
        
        // Get current route for outputs
        let currentRoute = audioSession.currentRoute
        var outputs: [AudioDevice] = []
        
        print("Current audio route has \(currentRoute.outputs.count) outputs:")
        
        // Add current route outputs first (these are actively connected)
        for output in currentRoute.outputs {
            let device = AudioDevice(from: output, type: .output)
            outputs.append(device)
            print("  - Current route output: \(device.name) (\(output.portType.rawValue))")
        }
        
        // Add built-in outputs if they're not already detected
        let builtInSpeaker = AudioDevice(id: "builtin-speaker", 
                                       name: "iPhone Speaker", 
                                       type: .output)
        let builtInReceiver = AudioDevice(id: "builtin-receiver", 
                                        name: "iPhone Earpiece", 
                                        type: .output)
        
        // Only add built-in devices if similar ones aren't already detected
        let hasBuiltInSpeaker = outputs.contains { output in
            output.name.localizedCaseInsensitiveContains("speaker") || 
            output.name.localizedCaseInsensitiveContains("built-in")
        }
        
        let hasBuiltInReceiver = outputs.contains { output in
            output.name.localizedCaseInsensitiveContains("receiver") || 
            output.name.localizedCaseInsensitiveContains("earpiece")
        }
        
        if !hasBuiltInSpeaker {
            outputs.append(builtInSpeaker)
            print("  - Added fallback: iPhone Speaker")
        }
        
        if !hasBuiltInReceiver {
            outputs.append(builtInReceiver)
            print("  - Added fallback: iPhone Earpiece")
        }
        
        outputDevices = outputs
        
        // Set default selections if none are set
        if selectedInputDevice == nil {
            selectedInputDevice = inputDevices.first { $0.name.localizedCaseInsensitiveContains("microphone") } ?? inputDevices.first
            print("Selected default input: \(selectedInputDevice?.name ?? "None")")
        }
        
        if selectedOutputDevice == nil {
            // Prefer external devices (Bluetooth, wired) over built-in
            selectedOutputDevice = outputDevices.first { device in
                !device.name.localizedCaseInsensitiveContains("iphone") && 
                !device.name.localizedCaseInsensitiveContains("receiver") &&
                !device.name.localizedCaseInsensitiveContains("built-in")
            } ?? outputDevices.first { device in
                device.name.localizedCaseInsensitiveContains("speaker")
            } ?? outputDevices.first
            
            print("Selected default output: \(selectedOutputDevice?.name ?? "None")")
        }
        
        print("=== Final Device Lists ===")
        print("Input devices (\(inputDevices.count)):")
        for device in inputDevices {
            print("  - \(device.name) (ID: \(device.id))")
        }
        
        print("Output devices (\(outputDevices.count)):")
        for device in outputDevices {
            print("  - \(device.name) (ID: \(device.id))")
        }
        print("=========================")
    }
    
    func setPreferredInput(_ device: AudioDevice?) {
        selectedInputDevice = device
        guard let device = device,
              let input = audioSession.availableInputs?.first(where: { $0.uid == device.id }) else {
            return
        }
        
        do {
            try audioSession.setPreferredInput(input)
        } catch {
            print("Failed to set preferred input: \(error)")
        }
    }
    
    func setPreferredOutput(_ device: AudioDevice?) {
        selectedOutputDevice = device
        
        // For output devices, we need to work with the audio session's routing
        // iOS handles most output routing automatically, but we can influence it
        if let device = device {
            do {
                // If it's a built-in device, we can set specific options
                if device.id == "builtin-speaker" {
                    // Force to speaker
                    try audioSession.overrideOutputAudioPort(.speaker)
                } else if device.id == "builtin-receiver" {
                    // Use default routing (earpiece)
                    try audioSession.overrideOutputAudioPort(.none)
                } else {
                    // For external devices (Bluetooth, wired headphones), 
                    // iOS typically routes to them automatically when connected
                    try audioSession.overrideOutputAudioPort(.none)
                }
                
                print("Output preference set to: \(device.name)")
                
            } catch {
                print("Failed to set output preference: \(error)")
            }
        }
    }
}

// MARK: - Audio Device Model
struct AudioDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let type: DeviceType
    
    enum DeviceType {
        case input, output
    }
    
    init(id: String, name: String, type: DeviceType) {
        self.id = id
        self.name = name
        self.type = type
    }
    
    init(from portDescription: AVAudioSessionPortDescription, type: DeviceType) {
        self.id = portDescription.uid
        self.name = portDescription.portName
        self.type = type
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioManager = AudioDeviceManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                BackgroundView()
                
                VStack(spacing: 24) {
                    // Header with close button
                    HStack {
                        Button("Refresh") {
                            Task {
                                await audioManager.refreshDevices()
                            }
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                    
                    VStack(spacing: 20) {
                        // Input Device Dropdown
                        DeviceDropdownView(
                            title: "Input Device",
                            devices: audioManager.inputDevices,
                            selectedDevice: audioManager.selectedInputDevice
                        ) { device in
                            audioManager.setPreferredInput(device)
                        }
                        
                        // Output Device Dropdown
                        DeviceDropdownView(
                            title: "Output Device",
                            devices: audioManager.outputDevices,
                            selectedDevice: audioManager.selectedOutputDevice
                        ) { device in
                            audioManager.setPreferredOutput(device)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Device Dropdown View
struct DeviceDropdownView: View {
    let title: String
    let devices: [AudioDevice]
    let selectedDevice: AudioDevice?
    let onSelection: (AudioDevice) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main dropdown button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    
                    Spacer()
                    
                    VStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if let selected = selectedDevice {
                            Text(selected.name)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "F87060").opacity(0.6))
                )
            }
            
            // Expanded device list
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(devices) { device in
                        Button(action: {
                            onSelection(device)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                Text(device.name)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                if selectedDevice?.id == device.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "F87060").opacity(0.3))
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "F87060").opacity(0.2))
                        .padding(.top, -16)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    ContentView()
}
