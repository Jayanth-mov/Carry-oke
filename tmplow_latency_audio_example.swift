import AVFoundation
import AudioToolbox

class LowLatencyKaraokeEngine {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixerNode = AVAudioMixerNode()
    
    func setupLowLatencyAudio() throws {
        // 1. Configure audio session for lowest possible latency
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.playAndRecord,
                                   mode: .measurement,  // Use measurement mode for lowest latency
                                   options: [.defaultToSpeaker, .allowBluetooth])
        
        // 2. Set the smallest possible buffer size
        // This is crucial for reducing latency
        try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer (very aggressive)
        
        // 3. Use highest sample rate supported
        try audioSession.setPreferredSampleRate(48000)
        
        try audioSession.setActive(true)
        
        // 4. Configure audio engine nodes
        setupAudioNodes()
        
        // 5. Start the engine
        try audioEngine.start()
    }
    
    private func setupAudioNodes() {
        let inputNode = audioEngine.inputNode
        let outputNode = audioEngine.outputNode
        
        // Attach nodes
        audioEngine.attach(playerNode)
        audioEngine.attach(mixerNode)
        
        // Get the input format
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Connect with minimal processing
        // Direct connection: Input → Mixer → Output
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        audioEngine.connect(playerNode, to: mixerNode, format: nil)
        audioEngine.connect(mixerNode, to: outputNode, format: nil)
        
        // Install tap for real-time monitoring (optional)
        setupRealtimeMonitoring()
    }
    
    private func setupRealtimeMonitoring() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Use smallest possible buffer size for tap
        let bufferSize: AVAudioFrameCount = 128 // Very small buffer
        
        inputNode.installTap(onBus: 0, 
                           bufferSize: bufferSize, 
                           format: inputFormat) { [weak self] buffer, time in
            // Process audio here with minimal delay
            self?.processAudioInRealTime(buffer: buffer, time: time)
        }
    }
    
    private func processAudioInRealTime(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // Keep processing minimal to reduce latency
        // Apply any effects or processing here, but keep it lightweight
        
        // Example: Simple volume adjustment
        guard let channelData = buffer.floatChannelData else { return }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameCount {
                data[frame] *= 0.8 // Simple volume reduction to prevent feedback
            }
        }
    }
}

// MARK: - Additional Optimization Techniques

extension LowLatencyKaraokeEngine {
    
    func optimizeForUltraLowLatency() throws {
        // Additional optimizations for extreme low latency scenarios
        
        let audioSession = AVAudioSession.sharedInstance()
        
        // Try even smaller buffer if device supports it
        if audioSession.inputLatency + audioSession.outputLatency < 0.020 { // If total latency < 20ms
            try audioSession.setPreferredIOBufferDuration(0.0023) // ~2.3ms buffer
        }
        
        // Disable any unnecessary processing
        audioEngine.mainMixerNode.volume = 1.0
        
        // Use manual rendering for ultimate control (advanced)
        setupManualRenderingIfNeeded()
    }
    
    private func setupManualRenderingIfNeeded() {
        // For ultimate latency control, you might need manual rendering
        // This is advanced and usually not necessary for most karaoke apps
        
        let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
        
        audioEngine.outputNode.installTap(onBus: 0, 
                                        bufferSize: 64, // Ultra-small buffer
                                        format: outputFormat) { buffer, time in
            // Manual processing here
        }
    }
}

// MARK: - Usage Example

class KaraokeViewController {
    private let audioEngine = LowLatencyKaraokeEngine()
    
    func startKaraoke() {
        do {
            try audioEngine.setupLowLatencyAudio()
            try audioEngine.optimizeForUltraLowLatency()
            print("Low-latency karaoke mode activated!")
        } catch {
            print("Failed to setup low-latency audio: \(error)")
        }
    }
}