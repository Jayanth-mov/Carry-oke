//
//  SettingsView.swift
//  Carry-oke
//
//  Created by Jayanth Annabhimoju on 10/27/25.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioManager = AudioDeviceManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 350)
                        .blur(radius: 50)
                        
                        Spacer()
                    }
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Settings Content
                    VStack(spacing: 24) {
                        // Audio Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Audio Devices")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                // Input Device Picker
                                DevicePickerView(
                                    title: "Input Device",
                                    devices: audioManager.inputDevices,
                                    selectedDevice: Binding(
                                        get: { audioManager.selectedInputDevice },
                                        set: { audioManager.setPreferredInput($0) }
                                    )
                                )
                                
                                // Output Device Picker
                                DevicePickerView(
                                    title: "Output Device",
                                    devices: audioManager.outputDevices,
                                    selectedDevice: Binding(
                                        get: { audioManager.selectedOutputDevice },
                                        set: { audioManager.setPreferredOutput($0) }
                                    )
                                )
                            }
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Refresh Button
                        Button {
                            Task {
                                await audioManager.refreshDevices()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Refresh Devices")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                        .glassEffect(.regular.tint(Color(hex: "F87060").opacity(0.3)).interactive(), in: .capsule)
                        
                        Spacer()
                        
                        VStack {
                            HStack {
                                Text("Version:")
                                    .font(.system(size:16, weight: .medium))
                                    .foregroundColor(Color(.white))
                                Text("1.0")
                                    .font(.system(size:16, weight: .medium))
                                    .foregroundColor(Color(hex: "E57891"))
                            }
                            .font(.system(size:16, weight: .medium))
                            .foregroundColor(Color(.white))
                            
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
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



// MARK: - Device Picker View
struct DevicePickerView: View {
    let title: String
    let devices: [AudioDevice]
    @Binding var selectedDevice: AudioDevice?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 24)
            
            Menu {
                ForEach(devices) { device in
                    Button {
                        selectedDevice = device
                    } label: {
                        HStack {
                            Text(device.name)
                            if selectedDevice?.id == device.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                if devices.isEmpty {
                    Text("No devices available")
                        .foregroundColor(.secondary)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let selected = selectedDevice {
                            Text(selected.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Select Device")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .glassEffect(.regular.tint(Color(hex: "F87060").opacity(0.2)).interactive(), in: .rect(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    SettingsView()
}
