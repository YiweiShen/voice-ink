import SwiftUI
import CoreAudio

struct AudioInputSettingsView: View {
    @ObservedObject var audioDeviceManager = AudioDeviceManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                heroSection
                deviceSelectionSection
            }
            .padding(24)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            // Initialize with system default if no mode is selected
            if audioDeviceManager.inputMode == .custom && audioDeviceManager.selectedDeviceID == nil {
                audioDeviceManager.selectInputMode(.systemDefault)
            }
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .padding(20)
                .background(Circle()
                    .fill(Color(.windowBackgroundColor).opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5))
            
            VStack(spacing: 8) {
                Text("Microphone Settings")
                    .font(.system(size: 28, weight: .bold))
                Text("Select which microphone VoiceInk should use to record your voice")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    private var deviceSelectionSection: some View {
        VStack(spacing: 16) {
            // System Default Device Option
            AudioDeviceCard(
                device: (id: 0, uid: "system-default", name: "System Default"),
                isSelected: audioDeviceManager.inputMode == .systemDefault,
                action: { audioDeviceManager.selectInputMode(.systemDefault) }
            )
            
            ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                AudioDeviceCard(
                    device: device,
                    isSelected: audioDeviceManager.inputMode == .custom && audioDeviceManager.selectedDeviceID == device.id,
                    action: { 
                        audioDeviceManager.selectInputMode(.custom)
                        audioDeviceManager.selectDevice(id: device.id) 
                    }
                )
            }
        }
    }
    
    
}

struct AudioDeviceCard: View {
    let device: (id: AudioDeviceID, uid: String, name: String)
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: isSelected ? "mic.circle.fill" : "mic.circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? .blue : .secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Microphone")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 12) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .symbolRenderingMode(.hierarchical)
                        } else {
                            Image(systemName: "circle")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
                
            }
            .padding()
            .background(CardBackground(isSelected: false))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
} 
