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
            if isExpanded {
                ExpandedMicClarityView(onClose: collapseMicClarity, karaokeEngine: karaokeEngine)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Collapsed Mic Clarity Bar
            MicClarityBarCollapsed(isExpanded: isExpanded)
                .onTapGesture {
                    toggleExpansion()
                }
        }
        .modifier(GlassEffectModifier(tintColor: Color(hex: "fff7fd").opacity(0.2), shape: .rect(cornerRadius: isExpanded ? 20 : 25)))
    }
    
    private func toggleExpansion() {
        if isExpanded {
            collapseMicClarity()
        } else {
            expandMicClarity()
        }
    }
    
    private func expandMicClarity() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
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
                Text("Microphone Clarity")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Arrow icon changes based on expansion state
            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
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
        .frame(maxHeight: 300) // Limit the maximum height
    }
}

// MARK: - Mic Clarity Content View
struct MicClarityContentView: View {
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 16) {
            if karaokeEngine.isMicrophoneInitialized {
                // Show echo reduction controls when microphone is initialized
                EchoReductionView(karaokeEngine: karaokeEngine, isVisible: $isVisible)
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

// MARK: - Echo Reduction View
struct EchoReductionView: View {
    @ObservedObject var karaokeEngine: KaraokeAudioEngine
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Echo Reduction")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .opacity(isVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.1), value: isVisible)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Off")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("Max")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Slider(value: $karaokeEngine.echoReduction, in: 0...1)
                    .accentColor(.white)
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


