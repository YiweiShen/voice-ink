import SwiftUI

struct MiniRecorderView: View {
    @ObservedObject var whisperState: WhisperState
    @ObservedObject var recorder: Recorder
    @EnvironmentObject var windowManager: MiniWindowManager
    @EnvironmentObject private var enhancementService: AIEnhancementService
    
    @State private var showEnhancementPromptPopover = false
    
    private var backgroundView: some View {
        Capsule()
            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
    }
    
    private var statusView: some View {
        RecorderStatusDisplay(
            currentState: whisperState.recordingState,
            audioMeter: recorder.audioMeter
        )
    }
    
    private var contentLayout: some View {
        HStack(spacing: 0) {
            // Left button zone - always visible
            RecorderPromptButton(showPopover: $showEnhancementPromptPopover)
                .padding(.leading, 7)
            
            Spacer()
            
            // Fixed visualizer zone
            statusView
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(.vertical, 9)
    }
    
    private var recorderCapsule: some View {
        backgroundView
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            }
            .overlay {
                contentLayout
            }
    }
    
    var body: some View {
        Group {
            if windowManager.isVisible {
                recorderCapsule
            }
        }
    }
}


