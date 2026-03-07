import SwiftUI
import CoreAudio

struct AudioInputSettingsView: View {
    @ObservedObject var audioDeviceManager = AudioDeviceManager.shared
    @State private var systemDefaultDeviceID: AudioDeviceID?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(audioDeviceManager.availableDevices, id: \.id) { device in
                AudioDeviceCard(
                    device: device,
                    isSystemDefault: device.id == systemDefaultDeviceID,
                    isSelected: (audioDeviceManager.inputMode == .systemDefault && device.id == systemDefaultDeviceID) ||
                                (audioDeviceManager.inputMode == .custom && audioDeviceManager.selectedDeviceID == device.id),
                    action: {
                        if device.id == systemDefaultDeviceID {
                            audioDeviceManager.selectInputMode(.systemDefault)
                        } else {
                            audioDeviceManager.selectInputMode(.custom)
                            audioDeviceManager.selectDevice(id: device.id)
                        }
                    }
                )
            }
        }
        .onAppear {
            updateSystemDefaultDevice()
            if audioDeviceManager.inputMode == .custom && audioDeviceManager.selectedDeviceID == nil {
                audioDeviceManager.selectInputMode(.systemDefault)
            }
        }
    }

    private func updateSystemDefaultDevice() {
        systemDefaultDeviceID = AudioDeviceConfiguration.getDefaultInputDevice()
    }
}

struct AudioDeviceCard: View {
    let device: (id: AudioDeviceID, uid: String, name: String)
    let isSystemDefault: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "mic.fill" : "mic")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : Color.primary.opacity(0.45))
                    .frame(width: 18, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(device.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        if isSystemDefault {
                            Text("System Default")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .foregroundColor(.secondary)
                                .cornerRadius(4)
                        }
                    }
                    Text("Microphone")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .accentColor : Color.primary.opacity(0.2))
            }
            .padding(14)
            .background(CardBackground(isSelected: isSelected, useAccentGradientWhenSelected: true))
        }
        .buttonStyle(.plain)
    }
}
