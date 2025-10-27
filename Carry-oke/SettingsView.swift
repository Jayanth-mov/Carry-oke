// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioManager = AudioDeviceManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                BackgroundView()
                
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
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}