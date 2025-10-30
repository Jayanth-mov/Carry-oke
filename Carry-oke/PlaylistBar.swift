//
//  PlaylistBar.swift
//  Carry-oke
//
//  Created by Jayanth Annabhimoju on 10/27/25.
//

import SwiftUI
import Combine
import AVFoundation

// MARK: - Playlist Bar (Liquid Glass)
struct PlaylistBar: View {
    @State private var isShowingQueue = false
    @State private var isYouTubePlayer = false
    @ObservedObject var queueManager: QueueManager
    
    var body: some View {
        // Collapsed Playlist Bar
        PlaylistBarCollapsed(isYouTubePlayer: isYouTubePlayer, queueManager: queueManager)
            .onTapGesture {
                isShowingQueue = true
            }
            .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.2), shape: .rect(cornerRadius: 25)))
            .sheet(isPresented: $isShowingQueue) {
                QueueSheetView(isYouTubePlayer: $isYouTubePlayer, queueManager: queueManager)
                    .presentationDetents(isYouTubePlayer ? [.fraction(0.5)] : [.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(isYouTubePlayer ? .enabled : .automatic)
            }
    }
}

// MARK: - Collapsed Playlist Bar
struct PlaylistBarCollapsed: View {
    let isYouTubePlayer: Bool
    @ObservedObject var queueManager: QueueManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if queueManager.queueItems.isEmpty {
                    Text("Playlist is empty.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                } else if let currentSong = queueManager.currentSong {
                    Text(currentSong.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(queueManager.isPlaying ? "Now Playing" : "Paused")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("Select a song")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Play button - disabled when queue is empty
                Button(action: {
                    if !queueManager.queueItems.isEmpty {
                        queueManager.togglePlayPause()
                    }
                }) {
                    Image(systemName: queueManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(queueManager.queueItems.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(width: 32, height: 32)
                }
                .disabled(queueManager.queueItems.isEmpty)
                .allowsHitTesting(!queueManager.queueItems.isEmpty)
                
                // Next button - disabled when queue is empty
                Button(action: {
                    if !queueManager.queueItems.isEmpty {
                        queueManager.nextSong()
                    }
                }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(queueManager.queueItems.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(width: 32, height: 32)
                }
                .disabled(queueManager.queueItems.isEmpty)
                .allowsHitTesting(!queueManager.queueItems.isEmpty)
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
    @Binding var isYouTubePlayer: Bool
    @State private var showingFilePicker = false
    @ObservedObject var queueManager: QueueManager
    
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
                
                // Main Content
                VStack(spacing: 0) {
                    // Only show "Currently Playing" section in Local Player mode
                    if !isYouTubePlayer {
                        HStack {
                            Text("Queue")
                                .font(Font.largeTitle.bold())
                                .padding(.horizontal, 20)
                                .padding(.vertical, 0)
                            Spacer()
                        }
                    }
                    
                    // Content based on player mode
                    if isYouTubePlayer {
                        // YouTube Player Content
                        YouTubePlayerPlaceholder()
                    } else {
                        // Queue content (existing)
                        if queueManager.queueItems.isEmpty {
                            Spacer()
                            EmptyQueueView()
                            Spacer()
                        } else {
                            List {
                                ForEach(queueManager.queueItems.indices, id: \.self) { index in
                                    let item = queueManager.queueItems[index]
                                    QueueItemRow(
                                        item: item, 
                                        onRemove: {
                                            queueManager.removeFromQueue(item: item)
                                        },
                                        onTap: {
                                            queueManager.playSong(at: index)
                                        },
                                        queueManager: queueManager
                                    )
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                }
                                .onMove(perform: queueManager.moveQueueItems)
                                .onDelete(perform: queueManager.deleteQueueItems)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .padding(.top, 20)
                        }
                    }
                    
                    // Playback Controls at the bottom when there are songs and NOT in YouTube mode
                    if !isYouTubePlayer {
                        PlaybackControlsView(queueManager: queueManager)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
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
                            Text(isYouTubePlayer ? "Switch to Local Player" : "Switch to YouTube Player")
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
                                showingFilePicker = true
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
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(onFilesSelected: { urls in
                queueManager.addAudioFilesToQueue(urls: urls)
            })
        }
    }
}

// MARK: - Playback Controls View
struct PlaybackControlsView: View {
    @ObservedObject var queueManager: QueueManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Current song info
            if let currentSong = queueManager.currentSong {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentSong.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Now Playing")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
            }
            
            // Seek bar
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { queueManager.currentTime },
                        set: { newValue in
                            queueManager.seekTo(time: newValue)
                        }
                    ),
                    in: 0...max(queueManager.duration, 1)
                )
                .accentColor(.white)
                
                // Time labels
                HStack {
                    Text(formatTime(queueManager.currentTime))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(formatTime(queueManager.duration))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Control buttons
            HStack(spacing: 30) {
                // Previous button
                Button(action: {
                    print("🎵 Previous button tapped - Current index: \(queueManager.currentIndex)")
                    queueManager.previousSong()
                }) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 18))
                        .foregroundColor(queueManager.queueItems.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(width: 60, height: 50)
                        .contentShape(Rectangle())
                }
                .disabled(queueManager.queueItems.isEmpty)
                
                // Play/Pause button
                Button(action: {
                    print("🎵 Play/Pause button tapped - isPlaying: \(queueManager.isPlaying)")
                    queueManager.togglePlayPause()
                }) {
                    Image(systemName: queueManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22))
                        .foregroundColor(queueManager.queueItems.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(width: 60, height: 50)
                        .contentShape(Rectangle())
                }
                .disabled(queueManager.queueItems.isEmpty)
                
                // Next button
                Button(action: {
                    print("🎵 Next button tapped - Current index: \(queueManager.currentIndex)")
                    queueManager.nextSong()
                }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 18))
                        .foregroundColor(queueManager.queueItems.isEmpty ? .white.opacity(0.3) : .white)
                        .frame(width: 60, height: 50)
                        .contentShape(Rectangle())
                }
                .disabled(queueManager.queueItems.isEmpty)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .modifier(GlassEffectModifier(tintColor: Color(hex: "F87060").opacity(0.3), shape: .rect(cornerRadius: 16)))
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
    let onRemove: () -> Void
    let onTap: () -> Void
    @ObservedObject var queueManager: QueueManager
    
    var isCurrentSong: Bool {
        queueManager.currentSong?.id == item.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Album artwork placeholder with play indicator
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    if isCurrentSong && queueManager.isPlaying {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isCurrentSong ? .white : .white)
                    .lineLimit(1)
                
                Text(formatDuration(item.duration))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentSong ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration <= 0 {
            return "Unknown duration"
        }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
struct QueueItem: Identifiable, Codable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: TimeInterval
    let fileURL: URL?
    
    init(title: String, artist: String, duration: TimeInterval, fileURL: URL? = nil) {
        self.title = title
        self.artist = artist
        self.duration = duration
        self.fileURL = fileURL
    }
}

// MARK: - Document Picker
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let onFilesSelected: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        var contentTypes: [UTType] = []
        
        // Add standard audio types
        contentTypes.append(UTType.audio)
        contentTypes.append(UTType.mp3)
        contentTypes.append(UTType.wav)
        contentTypes.append(UTType.aiff)
        
        // Add additional audio types if available
        if let mp3Type = UTType("public.mp3") {
            contentTypes.append(mp3Type)
        }
        if let mp4AudioType = UTType("public.mpeg-4-audio") {
            contentTypes.append(mp4AudioType)
        }
        if let flacType = UTType("public.flac") {
            contentTypes.append(flacType)
        }
        if let m4aType = UTType("com.apple.m4a-audio") {
            contentTypes.append(m4aType)
        }
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
        
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFilesSelected: onFilesSelected)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFilesSelected: ([URL]) -> Void
        
        init(onFilesSelected: @escaping ([URL]) -> Void) {
            self.onFilesSelected = onFilesSelected
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Files are copied to app sandbox, no need for security-scoped resource access
            onFilesSelected(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Handle cancellation if needed
        }
    }
}

// MARK: - Queue Manager for Persistence
class QueueManager: NSObject, ObservableObject {
    static let shared = QueueManager()
    private let userDefaults = UserDefaults.standard
    private let queueKey = "SavedQueue"
    private let volumeKey = "MusicVolume"
    
    @Published var queueItems: [QueueItem] = []
    @Published var currentIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var musicVolume: Float = 1.0 {
        didSet {
            updateAudioPlayerVolume()
            saveMusicVolume()
        }
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    var currentSong: QueueItem? {
        guard currentIndex >= 0 && currentIndex < queueItems.count else { return nil }
        return queueItems[currentIndex]
    }
    
    override private init() {
        super.init()
        loadQueueItems()
        loadMusicVolume()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func loadMusicVolume() {
        musicVolume = userDefaults.float(forKey: volumeKey)
        if musicVolume == 0.0 && userDefaults.object(forKey: volumeKey) == nil {
            // If no saved volume, default to 1.0 (full volume)
            musicVolume = 1.0
        }
    }
    
    private func saveMusicVolume() {
        userDefaults.set(musicVolume, forKey: volumeKey)
        userDefaults.synchronize()
    }
    
    private func updateAudioPlayerVolume() {
        audioPlayer?.volume = musicVolume
    }
    
    func saveQueue(_ queue: [QueueItem]) {
        do {
            let data = try JSONEncoder().encode(queue)
            userDefaults.set(data, forKey: queueKey)
            userDefaults.synchronize() // Force immediate save
            print("✅ Queue saved successfully with \(queue.count) items")
            print("✅ Queue items: \(queue.map { $0.title })")
        } catch {
            print("❌ Failed to save queue: \(error)")
        }
    }
    
    private func saveCurrentQueue() {
        saveQueue(queueItems)
    }
    
    private func loadQueueItems() {
        DispatchQueue.main.async {
            self.queueItems = self.loadQueue()
        }
    }
    
    private func loadQueue() -> [QueueItem] {
        print("🔄 Loading queue from UserDefaults...")
        guard let data = userDefaults.data(forKey: queueKey) else {
            print("📁 No saved queue found")
            return []
        }
        
        do {
            let queue = try JSONDecoder().decode([QueueItem].self, from: data)
            print("✅ Queue loaded successfully with \(queue.count) items")
            print("✅ Queue items: \(queue.map { $0.title })")
            
            // Debug: Print all file URLs before validation
            for item in queue {
                if let url = item.fileURL {
                    print("🔍 Checking file: \(url.absoluteString)")
                    print("🔍 File path: \(url.path)")
                    print("🔍 File exists: \(FileManager.default.fileExists(atPath: url.path))")
                } else {
                    print("🔍 No file URL for item: \(item.title)")
                }
            }
            
            // Verify file URLs are still accessible
            let validItems = queue.filter { item in
                guard let url = item.fileURL else { 
                    print("❌ Item \(item.title) has no file URL")
                    return false 
                }
                let exists = FileManager.default.fileExists(atPath: url.path)
                print("📁 File \(url.lastPathComponent) exists: \(exists)")
                if !exists {
                    print("❌ File not found at path: \(url.path)")
                }
                return exists
            }
            
            print("🔍 Valid items after filtering: \(validItems.count)")
            
            if validItems.count != queue.count {
                print("⚠️ Some files were removed or moved. Loaded \(validItems.count) of \(queue.count) items")
                // Save the filtered queue
                DispatchQueue.main.async {
                    self.saveQueue(validItems)
                }
            }
            
            return validItems
        } catch {
            print("❌ Failed to load queue: \(error)")
            return []
        }
    }
    
    func addAudioFilesToQueue(urls: [URL]) {
        for url in urls {
            // Extract file name without extension for title
            let fileName = url.deletingPathExtension().lastPathComponent
            
            // Get audio duration
            let asset = AVAsset(url: url)
            let duration = asset.duration.seconds
            
            // Create a new queue item
            let newItem = QueueItem(
                title: fileName,
                artist: "Unknown Artist",
                duration: duration.isNaN ? 0 : duration,
                fileURL: url
            )
            
            // Add to queue
            queueItems.append(newItem)
        }
        
        // Save the updated queue
        saveCurrentQueue()
        print("Added \(urls.count) audio files to queue and saved")
    }
    
    func moveQueueItems(from source: IndexSet, to destination: Int) {
        let currentSongId = currentSong?.id
        
        queueItems.move(fromOffsets: source, toOffset: destination)
        
        // Update currentIndex to track the moved current song
        if let songId = currentSongId {
            currentIndex = queueItems.firstIndex { $0.id == songId } ?? 0
        }
        
        // Save the updated queue
        saveCurrentQueue()
        print("Moved queue items to position \(destination) and saved")
    }
    
    func deleteQueueItems(offsets: IndexSet) {
        let currentSongId = currentSong?.id
        let wasCurrentDeleted = offsets.contains(currentIndex)
        
        queueItems.remove(atOffsets: offsets)
        
        if wasCurrentDeleted {
            // If current song was deleted, stop playback and reset
            stop()
            currentIndex = min(currentIndex, queueItems.count - 1)
            if currentIndex >= 0 && currentIndex < queueItems.count {
                // Optionally auto-play the next song
                // playSong(at: currentIndex)
            }
        } else if let songId = currentSongId {
            // Update currentIndex to track the current song after deletion
            currentIndex = queueItems.firstIndex { $0.id == songId } ?? 0
        }
        
        // Save the updated queue
        saveCurrentQueue()
        print("Deleted queue items and saved")
    }
    
    func removeFromQueue(item: QueueItem) {
        if let index = queueItems.firstIndex(where: { $0.id == item.id }) {
            let wasCurrentSong = index == currentIndex
            
            queueItems.remove(at: index)
            
            if wasCurrentSong {
                // If current song was removed, stop playback
                stop()
                currentIndex = min(currentIndex, queueItems.count - 1)
            } else if index < currentIndex {
                // If a song before current was removed, adjust index
                currentIndex -= 1
            }
            
            // Save the updated queue
            saveCurrentQueue()
            print("Removed \(item.title) from queue and saved")
        }
    }
    
    func clearQueue() {
        queueItems.removeAll()
        userDefaults.removeObject(forKey: queueKey)
        stop()
        print("🗑️ Queue cleared")
    }
    
    // MARK: - Playback Control Methods
    
    func playSong(at index: Int) {
        guard index >= 0 && index < queueItems.count else { return }
        
        // Get the song info BEFORE updating currentIndex to avoid confusion
        let songToPlay = queueItems[index]
        guard let url = songToPlay.fileURL else { 
            print("❌ No file URL for song: \(songToPlay.title)")
            return 
        }
        
        // Stop current playback completely before starting new song
        stop()
        
        // Now update the current index
        currentIndex = index
        
        print("🎵 Starting playback of: \(songToPlay.title)")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = musicVolume // Apply the current volume setting
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            
            play()
            print("✅ Successfully started playing: \(songToPlay.title)")
        } catch {
            print("❌ Error playing song \(songToPlay.title): \(error)")
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            if audioPlayer == nil, let currentSong = currentSong {
                playSong(at: currentIndex)
            } else {
                play()
            }
        }
    }
    
    func nextSong() {
        guard !queueItems.isEmpty else { 
            print("No songs in queue")
            return 
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < queueItems.count {
            playSong(at: nextIndex)
            print("Playing next song: \(queueItems[nextIndex].title)")
        } else {
            // Reached end of queue, loop to beginning
            playSong(at: 0)
            print("End of queue reached, looping to first song: \(queueItems[0].title)")
        }
    }
    
    func previousSong() {
        guard !queueItems.isEmpty else { 
            print("No songs in queue")
            return 
        }
        
        let prevIndex = currentIndex - 1
        if prevIndex >= 0 {
            playSong(at: prevIndex)
            print("Playing previous song: \(queueItems[prevIndex].title)")
        } else {
            // At beginning of queue, loop to end
            let lastIndex = queueItems.count - 1
            playSong(at: lastIndex)
            print("Beginning of queue reached, looping to last song: \(queueItems[lastIndex].title)")
        }
    }
    
    func seekTo(time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    private func startTimer() {
        stopTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentTime = self.audioPlayer?.currentTime ?? 0
            }
        }
    }
    
    private func stopTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension QueueManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            // Auto-advance to next song (with looping)
            nextSong()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
        isPlaying = false
        stopTimer()
    }
}


