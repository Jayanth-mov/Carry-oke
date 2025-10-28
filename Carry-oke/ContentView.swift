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
    @StateObject private var karaokeEngine = KaraokeAudioEngine()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                BackgroundView()
                
                // Main Content
                VStack(spacing: 0) {
                    // Header
                    HeaderView(showingSettings: $showingSettings, isKaraokeActive: karaokeEngine.isRecording)
                        .padding(.top, 60)
                    
                    Spacer()
                    
                    // Main Microphone Button
                    MicrophoneButton(karaokeEngine: karaokeEngine)
                    
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
            SettingsView(karaokeEngine: karaokeEngine)
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
    let isKaraokeActive: Bool
    
    var body: some View {
        HStack {
            Text("Carry-oke")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Settings Button - hidden when karaoke is active
            if !isKaraokeActive {
                SettingsButton(showingSettings: $showingSettings)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isKaraokeActive)
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
        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.3)))
    }
}

// MARK: - Microphone Button (Liquid Glass)
struct MicrophoneButton: View {
    @State private var isPressed = false
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await karaokeEngine.toggleKaraoke()
                } catch {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: karaokeEngine.isRecording ? "mic.fill" : "mic.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(karaokeEngine.isRecording ? .red : .white)
                
                if !karaokeEngine.hasExternalOutput && !karaokeEngine.isRecording {
                    Text("Connect AirPods or\nBluetooth Speaker")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 200, height: 200)
        }
        .scaleEffect(isPressed ? 0.90 : 1.0)
        .modifier(GlassEffectModifier(
            tintColor: Color(hex: karaokeEngine.isRecording ? "FF4444" : 
                            (karaokeEngine.hasExternalOutput ? "F87060" : "666666")).opacity(0.25), 
            shape: .circle
        ))
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .task {
            await karaokeEngine.requestMicrophonePermission()
            karaokeEngine.refreshExternalOutputStatus()
        }
        .alert("External Audio Device Required", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
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
        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.2), shape: .capsule))
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

// MARK: - Glass Effect Modifier with Fallback
struct GlassEffectModifier: ViewModifier {
    let tintColor: Color
    let shape: GlassShape
    
    init(tintColor: Color, shape: GlassShape = .capsule) {
        self.tintColor = tintColor
        self.shape = shape
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            switch shape {
            case .capsule:
                content
                    .glassEffect(.regular.tint(tintColor).interactive())
            case .circle:
                content
                    .glassEffect(.regular.tint(tintColor).interactive(), in: .circle)
            case .rect(let cornerRadius):
                content
                    .glassEffect(.regular.tint(tintColor).interactive(), in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            // Fallback for iOS 17 and earlier
            content
                .background {
                    switch shape {
                    case .capsule:
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(Capsule().fill(tintColor))
                    case .circle:
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(tintColor))
                    case .rect(let cornerRadius):
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .overlay(RoundedRectangle(cornerRadius: cornerRadius).fill(tintColor))
                    }
                }
        }
    }
}

enum GlassShape {
    case capsule
    case circle
    case rect(cornerRadius: CGFloat)
}

// MARK: - Karaoke Audio Engine
@MainActor
class KaraokeAudioEngine: ObservableObject {
    @Published var isRecording = false
    @Published var hasPermission = false
    @Published var hasExternalOutput = false
    @Published var isMicrophoneInitialized = false
    
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioSession = AVAudioSession.sharedInstance()
    
    init() {
        // Delay audio engine setup to avoid initialization issues
        Task {
            // Small delay to ensure the app is fully loaded
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await setupAudioEngineAsync()
        }
    }
    
    @MainActor
    private func setupAudioEngineAsync() async {
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
            // Check if microphone is initialized
            do {
                try forceBuiltInMicrophoneOnly()
            } catch {
                print("Failed to initialize built-in microphone: \(error)")
                isMicrophoneInitialized = false
            }
        case .denied:
            hasPermission = false
            isMicrophoneInitialized = false
            print("Microphone permission denied. Please enable in Settings > Privacy & Security > Microphone")
        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            hasPermission = granted
            if granted {
                // Try to initialize microphone
                do {
                    try forceBuiltInMicrophoneOnly()
                } catch {
                    print("Failed to initialize built-in microphone: \(error)")
                    isMicrophoneInitialized = false
                }
            } else {
                isMicrophoneInitialized = false
            }
        @unknown default:
            hasPermission = false
            isMicrophoneInitialized = false
        }
    }
    
    private func setupAudioEngine() {
        // Setup audio session - FORCE external output only, built-in microphone only
        do {
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .default,
                                       options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            
            // Set preferred sample rate to avoid format issues
            try audioSession.setPreferredSampleRate(44100.0)
            
            // Force built-in microphone only
            try forceBuiltInMicrophoneOnly()
            
            try audioSession.setActive(true)
            
            // Force external output devices only
            try forceExternalOutputOnly()
            
            print("Karaoke audio session setup - built-in microphone, external speakers only")
        } catch {
            print("Failed to setup karaoke audio session: \(error)")
            return
        }
        
        // Setup audio engine with proper format handling
        setupAudioEngineConnections()
    }
    
    private func setupAudioEngineConnections() {
        // Stop and reset the audio engine first
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()
        
        // Get the input node (microphone)
        let inputNode = audioEngine.inputNode
        
        // Get the main mixer node (output)
        let mainMixer = audioEngine.mainMixerNode
        
        // Create a compatible format for the connection
        // Use the input node's output format, but ensure it's valid
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        print("Input format: \(inputFormat)")
        print("Sample rate: \(inputFormat.sampleRate), channels: \(inputFormat.channelCount)")
        
        // Validate the format before connecting
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            print("ERROR: Invalid input format detected")
            return
        }
        
        do {
            // Connect input directly to output (pass-through)
            audioEngine.connect(inputNode, to: mainMixer, format: inputFormat)
            print("Successfully connected audio nodes with format: \(inputFormat)")
        } catch {
            print("Failed to connect audio nodes: \(error)")
            
            // Fallback: try with a standard format
            let standardFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)
            if let standardFormat = standardFormat {
                do {
                    audioEngine.connect(inputNode, to: mainMixer, format: standardFormat)
                    print("Successfully connected audio nodes with standard format: \(standardFormat)")
                } catch {
                    print("Failed to connect with standard format: \(error)")
                }
            }
        }
    }
    
    private func forceBuiltInMicrophoneOnly() throws {
        // Get available inputs and find the built-in microphone
        let availableInputs = audioSession.availableInputs ?? []
        
        print("Available input devices: \(availableInputs.map { "\($0.portName) (\($0.portType.rawValue))" })")
        
        // Find the built-in microphone
        let builtInMic = availableInputs.first { input in
            return input.portType == .builtInMic
        }
        
        if let builtInMic = builtInMic {
            try audioSession.setPreferredInput(builtInMic)
            isMicrophoneInitialized = true
            print("Successfully set preferred input to built-in microphone: \(builtInMic.portName)")
        } else {
            print("Warning: Built-in microphone not found in available inputs")
            // Still try to set the first available input as fallback
            if let firstInput = availableInputs.first {
                try audioSession.setPreferredInput(firstInput)
                isMicrophoneInitialized = true
                print("Fallback: Set preferred input to: \(firstInput.portName)")
            } else {
                isMicrophoneInitialized = false
                print("Error: No input devices available")
            }
        }
    }
    
    private func forceExternalOutputOnly() throws {
        let currentRoute = audioSession.currentRoute
        
        print("Current audio route outputs: \(currentRoute.outputs.map { $0.portType.rawValue })")
        
        // Check if we have any external outputs available
        let externalOutputs = currentRoute.outputs.filter { output in
            return output.portType == .bluetoothA2DP || 
                   output.portType == .bluetoothHFP ||
                   output.portType == .bluetoothLE ||
                   output.portType == .airPlay ||
                   output.portType == .headphones ||
                   output.portType == .lineOut ||
                   output.portType == .HDMI ||
                   output.portType == .usbAudio
        }
        
        hasExternalOutput = !externalOutputs.isEmpty
        
        if externalOutputs.isEmpty {
            // No external outputs available - throw an error to prevent built-in speaker usage
            print("ERROR: No external output devices detected. Please connect AirPods, headphones, or a Bluetooth speaker.")
            throw NSError(domain: "KaraokeError", code: 1, userInfo: [NSLocalizedDescriptionKey: "External audio device required. Please connect an external bluetooth speaker."])
        } else {
            print("External output devices detected: \(externalOutputs.map { $0.portName })")
        }
        
        // Override the route to prefer external outputs
        try audioSession.overrideOutputAudioPort(.none) // This removes built-in speaker preference
    }
    
    func refreshExternalOutputStatus() {
        let currentRoute = audioSession.currentRoute
        
        // Check if we have any external outputs available
        let externalOutputs = currentRoute.outputs.filter { output in
            return output.portType == .bluetoothA2DP || 
                   output.portType == .bluetoothHFP ||
                   output.portType == .bluetoothLE ||
                   output.portType == .airPlay ||
                   output.portType == .headphones ||
                   output.portType == .lineOut ||
                   output.portType == .HDMI ||
                   output.portType == .usbAudio
        }
        
        hasExternalOutput = !externalOutputs.isEmpty
        
        if !externalOutputs.isEmpty {
            print("External output devices detected: \(externalOutputs.map { $0.portName })")
        } else {
            print("No external output devices detected")
        }
    }
    
    func toggleKaraoke() async throws {
        // Check if we have permission, request it if we don't
        if !hasPermission {
            await requestMicrophonePermission()
            guard hasPermission else {
                throw NSError(domain: "KaraokeError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])
            }
        }
        
        if isRecording {
            stopKaraoke()
        } else {
            try startKaraoke()
        }
    }
    
    private func startKaraoke() throws {
        guard !audioEngine.isRunning else { return }
        
        do {
            // Activate audio session
            try audioSession.setActive(true)
            
            // Ensure built-in microphone is selected
            try forceBuiltInMicrophoneOnly()
            
            // Ensure we're still forcing external output
            try forceExternalOutputOnly()
            
            // Re-setup audio engine connections to ensure they're valid
            setupAudioEngineConnections()
            
            // Prepare the audio engine before starting
            audioEngine.prepare()
            
            // Start the audio engine
            try audioEngine.start()
            
            isRecording = true
            print("Karaoke mode started - built-in microphone, external speakers only")
            
        } catch {
            print("Failed to start karaoke: \(error)")
            isRecording = false
            throw error
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

#Preview {
    ContentView()
}
