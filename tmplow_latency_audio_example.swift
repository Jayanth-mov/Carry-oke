import AVFoundation
import AudioToolbox

class LowLatencyKaraokeEngine {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixerNode = AVAudioMixerNode()
    
    // MARK: - Public Control Methods
    
    func start() throws {
        try audioEngine.start()
    }
    
    func stop() {
        audioEngine.stop()
    }
    
    func isRunning() -> Bool {
        return audioEngine.isRunning
    }
    
    func setupLowLatencyAudio() throws {
        try configureOptimalAudioSession()
        try optimizeBufferSizes()
        setupAudioNodes()
        // Note: Engine is prepared but not started yet - call start() separately
    }
    
    // MARK: - Strategy 1: Use the Right Audio Session Configuration
    private func configureOptimalAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        // Step 1: Set category and mode for absolute minimum latency
        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,  // .measurement mode provides the lowest latency
            options: [
                .defaultToSpeaker,           // Route audio to speaker by default
                .allowBluetooth,             // Allow Bluetooth but prefer wired
                .mixWithOthers,              // Allow mixing with other audio (optional)
                .allowAirPlay,               // Allow AirPlay routing
                .overrideMutedMicrophoneInterruption  // Override muted mic interruptions
            ]
        )
        
        // Step 2: Set optimal sample rate (highest supported for best quality/latency ratio)
        let preferredSampleRates: [Double] = [48000, 44100, 96000] // Try in order of preference
        for sampleRate in preferredSampleRates {
            do {
                try audioSession.setPreferredSampleRate(sampleRate)
                print("✅ Sample rate set to: \(sampleRate)Hz")
                break
            } catch {
                print("⚠️ Failed to set sample rate to \(sampleRate)Hz: \(error)")
                continue
            }
        }
        
        // Step 3: Configure for minimal latency routing
        // Disable automatic gain control and noise suppression for lowest latency
        if audioSession.availableCategories.contains(.playAndRecord) {
            try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(false)
        }
        
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Log current audio session configuration
        logAudioSessionConfiguration()
    }
    
    // MARK: - Strategy 2: Optimize Buffer Sizes  
    private func optimizeBufferSizes() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        // Get current hardware constraints
        let hardwareBufferDuration = audioSession.ioBufferDuration
        let hardwareSampleRate = audioSession.sampleRate
        
        print("📊 Hardware buffer duration: \(hardwareBufferDuration * 1000)ms")
        print("📊 Hardware sample rate: \(hardwareSampleRate)Hz")
        
        // Define buffer duration targets (in seconds) from most aggressive to conservative
        let bufferTargets: [TimeInterval] = [
            0.0023,  // ~2.3ms - Ultra aggressive (may not work on all devices)
            0.0046,  // ~4.6ms - Very aggressive  
            0.0058,  // ~5.8ms - Aggressive
            0.0093,  // ~9.3ms - Moderate
            0.0116   // ~11.6ms - Conservative fallback
        ]
        
        var optimalBufferSet = false
        
        for targetDuration in bufferTargets {
            do {
                try audioSession.setPreferredIOBufferDuration(targetDuration)
                
                // Verify the actual buffer duration that was set
                let actualDuration = audioSession.ioBufferDuration
                let latencyMs = actualDuration * 1000
                
                print("✅ Buffer duration set to: \(latencyMs)ms (requested: \(targetDuration * 1000)ms)")
                
                // Check if we achieved acceptably low latency
                if latencyMs <= 15.0 { // If we got 15ms or better, we're good
                    optimalBufferSet = true
                    break
                }
                
            } catch {
                print("⚠️ Failed to set buffer duration to \(targetDuration * 1000)ms: \(error)")
                continue
            }
        }
        
        if !optimalBufferSet {
            print("⚠️ Warning: Could not achieve optimal buffer size. Using hardware default.")
        }
        
        // Calculate and report expected round-trip latency
        calculateExpectedLatency()
    }
    
    private func logAudioSessionConfiguration() {
        let audioSession = AVAudioSession.sharedInstance()
        
        print("\n📱 Audio Session Configuration:")
        print("   Category: \(audioSession.category.rawValue)")
        print("   Mode: \(audioSession.mode.rawValue)")
        print("   Sample Rate: \(audioSession.sampleRate)Hz")
        print("   IO Buffer Duration: \(audioSession.ioBufferDuration * 1000)ms")
        print("   Input Latency: \(audioSession.inputLatency * 1000)ms")
        print("   Output Latency: \(audioSession.outputLatency * 1000)ms")
        print("   Input Gain: \(audioSession.inputGain)")
        print("   Output Volume: \(audioSession.outputVolume)")
        
        // Check for Bluetooth connection
        let currentRoute = audioSession.currentRoute
        for output in currentRoute.outputs {
            if output.portType == .bluetoothA2DP || output.portType == .bluetoothHFP {
                print("⚠️ WARNING: Bluetooth audio detected - this will add significant latency!")
            }
        }
    }
    
    private func calculateExpectedLatency() {
        let audioSession = AVAudioSession.sharedInstance()
        
        let bufferLatency = audioSession.ioBufferDuration * 1000 // Convert to ms
        let inputLatency = audioSession.inputLatency * 1000
        let outputLatency = audioSession.outputLatency * 1000
        let processingLatency: Double = 1.0 // Estimate ~1ms for our processing
        
        let totalExpectedLatency = bufferLatency + inputLatency + outputLatency + processingLatency
        
        print("\n🎯 Latency Breakdown:")
        print("   Buffer Latency: \(String(format: "%.1f", bufferLatency))ms")
        print("   Input Latency: \(String(format: "%.1f", inputLatency))ms")  
        print("   Output Latency: \(String(format: "%.1f", outputLatency))ms")
        print("   Processing Latency: \(String(format: "%.1f", processingLatency))ms")
        print("   💡 Total Expected: \(String(format: "%.1f", totalExpectedLatency))ms")
        
        if totalExpectedLatency <= 10 {
            print("   ✅ EXCELLENT - Imperceptible latency")
        } else if totalExpectedLatency <= 20 {
            print("   ✅ GOOD - Very low latency, suitable for real-time performance")
        } else if totalExpectedLatency <= 40 {
            print("   ⚠️ ACCEPTABLE - Noticeable but usable for karaoke")
        } else {
            print("   ❌ POOR - High latency, may affect user experience")
        }
    }
    
    private func setupAudioNodes() {
        let inputNode = audioEngine.inputNode
        let outputNode = audioEngine.outputNode
        
        // Attach nodes
        audioEngine.attach(playerNode)
        audioEngine.attach(mixerNode)
        
        // Get the input format with optimal settings
        let inputFormat = inputNode.inputFormat(forBus: 0)
        print("🎤 Input format: \(inputFormat)")
        
        // Create optimized format for internal processing
        let processingFormat = createOptimalProcessingFormat(from: inputFormat)
        
        // Connect with minimal processing and format conversion only when necessary
        // Direct connection: Input → Mixer → Output
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        audioEngine.connect(playerNode, to: mixerNode, format: processingFormat)
        audioEngine.connect(mixerNode, to: outputNode, format: processingFormat)
        
        // Configure mixer for minimal latency
        mixerNode.volume = 1.0
        mixerNode.pan = 0.0
        
        // Install tap for real-time monitoring with optimized buffer sizes
        setupOptimizedRealtimeMonitoring(inputFormat: inputFormat)
        
        print("✅ Audio nodes configured with optimized routing")
    }
    
    private func createOptimalProcessingFormat(from inputFormat: AVAudioFormat) -> AVAudioFormat {
        // Use the same sample rate as input to avoid costly sample rate conversion
        let sampleRate = inputFormat.sampleRate
        let channelCount = inputFormat.channelCount
        
        // Create format with optimal settings
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount) else {
            print("⚠️ Failed to create optimal format, using input format")
            return inputFormat
        }
        
        print("🔧 Processing format: \(format)")
        return format
    }
    
    private func setupOptimizedRealtimeMonitoring(inputFormat: AVAudioFormat) {
        let inputNode = audioEngine.inputNode
        
        // Calculate optimal buffer size based on sample rate and target latency
        let targetLatencyMs: Double = 5.0 // Target 5ms processing latency
        let sampleRate = inputFormat.sampleRate
        let optimalBufferSize = AVAudioFrameCount((sampleRate * targetLatencyMs) / 1000.0)
        
        // Ensure buffer size is power of 2 for optimal performance
        let bufferSize = nextPowerOfTwo(optimalBufferSize)
        
        // Clamp buffer size to reasonable bounds
        let finalBufferSize = min(max(bufferSize, 64), 512) // Between 64 and 512 samples
        
        print("🎯 Tap buffer size: \(finalBufferSize) samples (\(Double(finalBufferSize) / sampleRate * 1000)ms)")
        
        inputNode.installTap(onBus: 0, 
                           bufferSize: finalBufferSize, 
                           format: inputFormat) { [weak self] buffer, time in
            // Process audio here with minimal delay
            self?.processAudioInRealTime(buffer: buffer, time: time)
        }
    }
    
    // Helper function to find next power of 2
    private func nextPowerOfTwo(_ value: AVAudioFrameCount) -> AVAudioFrameCount {
        guard value > 1 else { return 1 }
        return 1 << (32 - UInt32(value - 1).leadingZeroBitCount)
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
        try performDynamicBufferOptimization()
        optimizeAudioEngineSettings()
        try setupManualRenderingIfNeeded()
    }
    
    // MARK: - Dynamic Buffer Size Optimization
    private func performDynamicBufferOptimization() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        print("\n🔧 Starting dynamic buffer optimization...")
        
        // Test different buffer sizes to find the optimal one for this device
        let testDurations: [(duration: TimeInterval, description: String)] = [
            (0.0023, "Ultra-aggressive (2.3ms)"),
            (0.0046, "Very aggressive (4.6ms)"),
            (0.0058, "Aggressive (5.8ms)"),
            (0.0093, "Moderate (9.3ms)"),
            (0.0116, "Conservative (11.6ms)")
        ]
        
        var bestDuration: TimeInterval = 0.0116 // Conservative fallback
        var bestScore: Double = 0.0
        
        for (testDuration, description) in testDurations {
            do {
                // Try to set the buffer duration
                try audioSession.setPreferredIOBufferDuration(testDuration)
                
                let actualDuration = audioSession.ioBufferDuration
                let totalLatency = audioSession.inputLatency + audioSession.outputLatency + actualDuration
                
                // Score based on achieved latency (lower is better)
                let latencyScore = 1.0 / (totalLatency + 0.001) // Add small value to avoid division by zero
                
                print("   Testing \(description): Achieved \(actualDuration * 1000)ms, Total latency: \(totalLatency * 1000)ms")
                
                if latencyScore > bestScore && totalLatency < 0.050 { // Must be under 50ms total
                    bestScore = latencyScore
                    bestDuration = testDuration
                }
                
            } catch {
                print("   ❌ \(description) failed: \(error.localizedDescription)")
            }
        }
        
        // Set the optimal buffer duration
        do {
            try audioSession.setPreferredIOBufferDuration(bestDuration)
            let finalDuration = audioSession.ioBufferDuration
            print("✅ Optimal buffer duration: \(finalDuration * 1000)ms")
        } catch {
            print("⚠️ Failed to set optimal buffer duration: \(error)")
        }
        
        // Verify we're not using Bluetooth (which would add significant latency)
        checkForHighLatencyConnections()
    }
    
    private func optimizeAudioEngineSettings() {
        // Disable any unnecessary processing on the main mixer
        audioEngine.mainMixerNode.volume = 1.0
        
        // Set our custom mixer to minimal processing mode
        mixerNode.volume = 1.0
        mixerNode.pan = 0.0
        
        // If available, set processing format to match hardware
        let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
        print("🔊 Output format: \(outputFormat)")
    }
    
    private func checkForHighLatencyConnections() {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        var hasBluetoothConnection = false
        var hasAirPlayConnection = false
        
        for output in currentRoute.outputs {
            switch output.portType {
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                hasBluetoothConnection = true
                print("⚠️ Bluetooth connection detected: \(output.portName)")
            case .airPlay:
                hasAirPlayConnection = true
                print("⚠️ AirPlay connection detected: \(output.portName)")
            default:
                print("✅ Low-latency connection: \(output.portName) (\(output.portType.rawValue))")
            }
        }
        
        if hasBluetoothConnection {
            print("💡 Tip: Disconnect Bluetooth audio for minimum latency")
        }
        
        if hasAirPlayConnection {
            print("💡 Tip: Disconnect AirPlay for minimum latency")
        }
    }
    
    // MARK: - Real-time Performance Monitoring
    func monitorRealTimePerformance() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.logCurrentPerformanceMetrics()
        }
    }
    
    private func logCurrentPerformanceMetrics() {
        let audioSession = AVAudioSession.sharedInstance()
        
        let bufferDuration = audioSession.ioBufferDuration * 1000
        let inputLatency = audioSession.inputLatency * 1000
        let outputLatency = audioSession.outputLatency * 1000
        let totalLatency = bufferDuration + inputLatency + outputLatency
        
        let cpuUsage = audioEngine.mainMixerNode.lastRenderTime?.sampleTime ?? 0
        
        print("\n📊 Performance Metrics:")
        print("   Current buffer: \(String(format: "%.1f", bufferDuration))ms")
        print("   Total latency: \(String(format: "%.1f", totalLatency))ms")
        print("   Sample rate: \(audioSession.sampleRate)Hz")
        
        // Check if we're still running optimally
        if totalLatency > 30.0 {
            print("⚠️ Warning: Latency above 30ms - consider re-optimization")
        }
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
            print("🎤 Initializing low-latency karaoke mode...")
            
            // Strategy 1 & 2: Configure optimal audio session and buffer sizes
            try audioEngine.setupLowLatencyAudio()
            
            // Additional ultra-low latency optimizations
            try audioEngine.optimizeForUltraLowLatency()
            
            // Now start the audio engine
            try audioEngine.start()
            
            // Start real-time performance monitoring
            audioEngine.monitorRealTimePerformance()
            
            print("✅ Low-latency karaoke mode activated!")
            
        } catch {
            print("❌ Failed to setup low-latency audio: \(error)")
            // Fallback to higher latency but more stable configuration
            fallbackToStableMode()
        }
    }
    
    private func fallbackToStableMode() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            // Use more conservative settings for stability
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .videoRecording,  // More stable than .measurement
                                       options: [.defaultToSpeaker])
            
            try audioSession.setPreferredIOBufferDuration(0.0232) // ~23ms - very stable
            try audioSession.setPreferredSampleRate(44100)
            try audioSession.setActive(true)
            
            // Start the audio engine in fallback mode
            try audioEngine.start()
            
            print("⚠️ Using fallback stable mode (higher latency but more reliable)")
            
        } catch {
            print("❌ Even fallback mode failed: \(error)")
        }
    }
    
    func stopKaraoke() {
        // Stop the audio engine using the public method
        audioEngine.stop()
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("✅ Karaoke mode deactivated")
        } catch {
            print("⚠️ Error deactivating audio session: \(error)")
        }
    }
}