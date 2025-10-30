//
//  PlaylistBar.swift
//  Carry-oke
//
//  Created by Jayanth Annabhimoju on 10/27/25.
//

import SwiftUI

// MARK: - Playlist Bar (Liquid Glass)
struct PlaylistBar: View {
    @State private var isShowingQueue = false
    @State private var isYouTubePlayer = true
    
    var body: some View {
        // Collapsed Playlist Bar
        PlaylistBarCollapsed(isYouTubePlayer: isYouTubePlayer)
            .onTapGesture {
                isShowingQueue = true
            }
            .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.2), shape: .rect(cornerRadius: 25)))
            .sheet(isPresented: $isShowingQueue) {
                QueueSheetView(isYouTubePlayer: $isYouTubePlayer)
                    .presentationDetents(isYouTubePlayer ? [.fraction(0.5)] : [.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(isYouTubePlayer ? .enabled : .automatic)
            }
    }
}

// MARK: - Collapsed Playlist Bar
struct PlaylistBarCollapsed: View {
    let isYouTubePlayer: Bool
    
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

// MARK: - Queue Sheet View (Full Screen)
struct QueueSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var queueItems: [QueueItem] = []
    @Binding var isYouTubePlayer: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background matching app theme
                Color(hex: "412234")
                    .ignoresSafeArea()
                
                // Background gradient effect
                VStack {
                    Spacer()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "B49FCC").opacity(0.6),
                            Color(hex: "C49FCC").opacity(0)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 400)
                    .blur(radius: 30)
                    
                    
                }
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Only show "Currently Playing" section in Local Player mode
                    if !isYouTubePlayer {
                        HStack {
                            Text("Currently Playing:")
                                .font(.system(size: 18, weight: .medium))
                                .padding(.bottom, 10)
                                .padding(.horizontal, 20)
                            Spacer()
                        }
                        // Mini player bar at top
                        MiniPlayerBar()
                            .padding(.horizontal, 20)
                            .padding(.top, 0)
                    }
                    
                    HStack {
                        Text("Queue")
                            .font(Font.largeTitle.bold())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 40)
                        Spacer()
                    }
                    
                    // Content based on player mode
                    if isYouTubePlayer {
                        // YouTube Player Content
                        YouTubePlayerPlaceholder()
                    } else {
                        // Queue content (existing)
                        if queueItems.isEmpty {
                            Spacer()
                            EmptyQueueView()
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(queueItems) { item in
                                        QueueItemRow(item: item)
                                            .padding(.horizontal, 20)
                                        
    //                                    This hidden code is supposed to be for the song
    //                                    HStack(spacing: 20) {
    //                                        PlayButton(systemName: "backward.end.fill", size: 20)
    //                                        PlayButton(systemName: "play.fill", size: 24)
    //                                        PlayButton(systemName: "forward.end.fill", size: 20)
    //                                    }
                                    }
                                }
                                .padding(.top, 20)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .medium))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // YouTube/Local Player Toggle Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isYouTubePlayer.toggle()
                            }
                        }) {
                            Text(isYouTubePlayer ? "YouTube Player" : "Local Player")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                        
                        // Plus Button - only show when NOT in YouTube Player mode
                        if !isYouTubePlayer {
                            Button(action: {
                                // Add song action (dummy for now)
                                print("Add song tapped")
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Mini Player Bar
struct MiniPlayerBar: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("No song playing")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("Select a song to play")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.2), shape: .rect(cornerRadius: 16)))
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
            
            Text("Hit the '+' button at the top \nto add songs")
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



// MARK: - YouTube Player Placeholder
struct YouTubePlayerPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // YouTube icon placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(height: 200)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("[YouTube Placeholder]")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("YouTube player interface will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
            
            Spacer()
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


