//
//  MicClarityBar.swift
//  Carry-oke
//
//  Created by Jayanth Annabhimoju on 10/27/25.
//

import SwiftUI

// MARK: - Microphone Clarity Bar (Liquid Glass)
struct MicClarityBar: View {
    @State private var isExpanded = false
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed Mic Clarity Bar - now at top
            MicClarityBarCollapsed(isExpanded: isExpanded)
                .onTapGesture {
                    toggleExpansion()
                }
            
            if isExpanded {
                ExpandedMicClarityView(onClose: collapseMicClarity, karaokeEngine: karaokeEngine)
                    .offset(y: isExpanded ? 0 : -10) // Start from 50 points above
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.8, anchor: .top).combined(with: .opacity)
                    ))
            }
        }
        .modifier(GlassEffectModifier(tintColor: Color(hex: "000000").opacity(0.6), shape: .rect(cornerRadius: isExpanded ? 20 : 25)))
    }
    
    private func toggleExpansion() {
        if isExpanded {
            collapseMicClarity()
        } else {
            expandMicClarity()
        }
    }
    
    private func expandMicClarity() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.1)) {
            isExpanded = true
        }
    }
    
    private func collapseMicClarity() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
}

// MARK: - Collapsed Mic Clarity Bar
struct MicClarityBarCollapsed: View {
    let isExpanded: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Audio Mixer")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Arrow icon changes based on expansion state - flipped for downward expansion
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle()) // Make the entire area tappable
    }
}

// MARK: - Expanded Mic Clarity View
struct ExpandedMicClarityView: View {
    let onClose: () -> Void
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area - shows different content based on mic initialization
            MicClarityContentView(karaokeEngine: karaokeEngine)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxHeight: 275) // Limit the maximum height
    }
}

// MARK: - Mic Clarity Content View
struct MicClarityContentView: View {
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            if karaokeEngine.isMicrophoneInitialized {
                // Show audio controls when microphone is initialized
                AudioControlsView(karaokeEngine: karaokeEngine, isVisible: $isVisible)
            } else {
                // Show unavailable message when microphone is not initialized
                UnavailableView(isVisible: $isVisible)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - Audio Controls View
struct AudioControlsView: View {
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                // Microphone Volume Slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Microphone Volume")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                    
                    HStack {
                        Text("Low")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("High")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Slider(value: $karaokeEngine.microphoneVolume, in: 0...2)
                        .accentColor(.white)
                }
                
                // Background Noise Reduction Slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Background Noise Reduction")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                    
                    HStack {
                        Text("Off")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("Max")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Slider(value: $karaokeEngine.backgroundNoiseReduction, in: 0...2)
                        .accentColor(.white)
                }
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.1), value: isVisible)
        }
    }
}

// MARK: - Unavailable View
struct UnavailableView: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.4))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.1), value: isVisible)
            
            Text("Clarity Settings Unavailable")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.1), value: isVisible)
            
            Text("Microphone is not initialized")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.1), value: isVisible)
        }
    }
}


