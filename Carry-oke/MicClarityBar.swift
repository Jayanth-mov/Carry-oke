//
//  PlaylistBar.swift
//  Carry-oke
//
//  Created by Jayanth Annabhimoju on 10/27/25.
//

import SwiftUI

// MARK: - Playlist Bar (Liquid Glass)
struct PlaylistBar: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                ExpandedPlaylistView(onClose: collapsePlaylist)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Collapsed Playlist Bar
            PlaylistBarCollapsed()
                .onTapGesture {
                    expandPlaylist()
                }
        }
        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.2), shape: .rect(cornerRadius: isExpanded ? 20 : 25)))
    }
    
    private func expandPlaylist() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = true
        }
    }
    
    private func collapsePlaylist() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
}

// MARK: - Collapsed Playlist Bar
struct PlaylistBarCollapsed: View {
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
                    .allowsHitTesting(false) // Disable hit testing so taps pass through
                PlayButton(systemName: "forward.end.fill")
                    .allowsHitTesting(false) // Disable hit testing so taps pass through
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle()) // Make the entire area tappable
    }
}

// MARK: - Expanded Playlist View
struct ExpandedPlaylistView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button and add button
            ExpandedPlaylistHeader(onClose: onClose)
            
            // Queue section
            PlaylistQueueView()
                .padding(.horizontal, 20)
            
            // Current playing section (if needed)
            CurrentPlayingSection()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxHeight: 400) // Limit the maximum height
    }
}

// MARK: - Expanded Playlist Header
struct ExpandedPlaylistHeader: View {
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
            
            Text("Queue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                // Add song action (dummy for now)
                print("Add song tapped")
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.1))
        )
    }
}

// MARK: - Playlist Queue View
struct PlaylistQueueView: View {
    @State private var queueItems: [QueueItem] = []
    
    var body: some View {
        VStack(spacing: 12) {
            if queueItems.isEmpty {
                EmptyQueueView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(queueItems) { item in
                            QueueItemRow(item: item)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 250)
    }
}

// MARK: - Empty Queue View
struct EmptyQueueView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Queue is Empty")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Add songs to see them here")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Queue Item Row
struct QueueItemRow: View {
    let item: QueueItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Album artwork placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(item.artist)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                // Remove from queue action
                print("Remove \(item.title) from queue")
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Current Playing Section
struct CurrentPlayingSection: View {
    var body: some View {
        VStack(spacing: 16) {            
            // Progress bar (optional)
            HStack {
                Text("0:00")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("0:00")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Queue Item Model
struct QueueItem: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: TimeInterval
}


