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
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    
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
                        Spacer()
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
                            Text("Audio Settings")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 12) {
                                // iPhone Microphone Status
                                MicrophoneStatusView(
                                    isInitialized: karaokeEngine.isMicrophoneInitialized,
                                    hasPermission: karaokeEngine.hasPermission
                                )
                                
                                // Output Device Info (read-only)
                                OutputDeviceInfoView(karaokeEngine: karaokeEngine)
                            }
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Refresh Button
                        Button {
                            Task {
                                await karaokeEngine.requestMicrophonePermission()
                                karaokeEngine.refreshExternalOutputStatus()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Refresh Status")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                        }
                        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.3), shape: .capsule))
                        
                        Spacer()
                        
                        VStack {
                            HStack {
                                Text("Version:")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(.white))
                                Text("1.0")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(Color(hex: "#ffa59c"))
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await karaokeEngine.requestMicrophonePermission()
            karaokeEngine.refreshExternalOutputStatus()
        }
    }
}

// MARK: - Microphone Status View
struct MicrophoneStatusView: View {
    let isInitialized: Bool
    let hasPermission: Bool
    
    var statusColor: Color {
        if !hasPermission {
            return .red
        } else if isInitialized {
            return .green
        } else {
            return .orange
        }
    }
    
    var statusText: String {
        if !hasPermission {
            return "Permission Denied"
        } else if isInitialized {
            return "Initialized"
        } else {
            return "Not Initialized"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iPhone Microphone")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 24)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Built-in Microphone")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                if !hasPermission {
                    Button("Settings") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .modifier(GlassEffectModifier(tintColor: statusColor.opacity(0.1), shape: .rect(cornerRadius: 16)))
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Output Device Info View
struct OutputDeviceInfoView: View {
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    
    var outputDeviceInfo: String {
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        let outputs = currentRoute.outputs
        
        // Filter for external outputs
        let externalOutputs = outputs.filter { output in
            return output.portType == .bluetoothA2DP ||
                   output.portType == .bluetoothHFP ||
                   output.portType == .bluetoothLE ||
                   output.portType == .airPlay ||
                   output.portType == .headphones ||
                   output.portType == .lineOut ||
                   output.portType == .HDMI ||
                   output.portType == .usbAudio
        }
        
        if externalOutputs.isEmpty {
            return "No external devices connected\n(External speakers required for karaoke)"
        } else {
            let deviceNames = externalOutputs.map { $0.portName }.joined(separator: ", ")
            return "Connected: \(deviceNames)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output Devices")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 24)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outputDeviceInfo)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(karaokeEngine.hasExternalOutput ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(karaokeEngine.hasExternalOutput ? "External Device Connected" : "No External Device")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(karaokeEngine.hasExternalOutput ? .green : .red)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.1), shape: .rect(cornerRadius: 16)))
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    SettingsView(karaokeEngine: KaraokeAudioEngine())
}
