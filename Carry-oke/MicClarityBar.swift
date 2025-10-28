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
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                ExpandedMicClarityView(onClose: collapseMicClarity)
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            ExpandedMicClarityHeader(onClose: onClose)
            
            // Empty content area (for future additions)
            MicClarityContentView()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxHeight: 300) // Limit the maximum height
    }
}

// MARK: - Expanded Mic Clarity Header
struct ExpandedMicClarityHeader: View {
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            
            Spacer()
            
            Text("Microphone Clarity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for future action button
            Rectangle()
                .fill(Color.clear)
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.1))
        )
    }
}

// MARK: - Mic Clarity Content View
struct MicClarityContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Coming Soon")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Microphone clarity features will be added here")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}


