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
    
    var body: some View {
        Button(action: {
            // Microphone action
        }) {
            Image(systemName: "mic.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 200, height: 200)
        }
        .scaleEffect(isPressed ? 0.90 : 1.0)
        .glassEffect(.regular.tint(Color(hex: "F87060").opacity(0.25)).interactive(), in: .circle)
        .buttonStyle(.glassProminent).tint(Color(hex: "F87060").opacity(0.25))
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
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
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .default, 
                                       options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.updateDeviceLists()
            }
        }
    }
    
    private func updateDeviceLists() {
        // Get available inputs
        let availableInputs = audioSession.availableInputs ?? []
        inputDevices = availableInputs.map { AudioDevice(from: $0, type: .input) }
        
        // Get current route for outputs
        let currentRoute = audioSession.currentRoute
        var outputs: [AudioDevice] = []
        
        // Add built-in outputs
        outputs.append(AudioDevice(id: "builtin-speaker", 
                                 name: "iPhone Speaker", 
                                 type: .output))
        outputs.append(AudioDevice(id: "builtin-receiver", 
                                 name: "iPhone Earpiece", 
                                 type: .output))
        
        // Add route-based outputs
        for output in currentRoute.outputs {
            let device = AudioDevice(from: output, type: .output)
            if !outputs.contains(where: { $0.id == device.id }) {
                outputs.append(device)
            }
        }
        
        outputDevices = outputs
        
        // Set default selections if none are set
        if selectedInputDevice == nil {
            selectedInputDevice = inputDevices.first { $0.name.contains("Microphone") } ?? inputDevices.first
        }
        
        if selectedOutputDevice == nil {
            selectedOutputDevice = outputDevices.first { $0.name.contains("Speaker") } ?? outputDevices.first
        }
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
        // Output routing is handled by the system and user preferences
        // For karaoke apps, we mainly control this through audio session category options
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
