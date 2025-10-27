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
        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.3)))
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
        .modifier(GlassEffectModifier(tintColor: Color(hex: karaokeEngine.isRecording ? "FF4444" : "F87060").opacity(0.25), shape: .circle))
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

#Preview {
    ContentView()
}
