import SwiftUI
import Combine
import AppKit

struct ParakeetModelCardRowView: View {
    let model: ParakeetModel
    @ObservedObject var whisperState: WhisperState

    var isCurrent: Bool {
        whisperState.currentTranscriptionModel?.name == model.name
    }

    var isDownloaded: Bool {
        whisperState.isParakeetModelDownloaded
    }

    var isDownloading: Bool {
        whisperState.isDownloadingParakeet
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.labelColor))
                        Text("Experimental")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color.orange.opacity(0.1)))
                        if isCurrent {
                            Text("Default")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Color.accentColor.opacity(0.1)))
                        }
                    }
                    Text("\(model.size) · \(model.language)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(.tertiaryLabelColor))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                actionSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if isDownloading {
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }
        }
        .background(CardBackground(isSelected: isCurrent, useAccentGradientWhenSelected: isCurrent))
    }

    private var actionSection: some View {
        HStack(spacing: 6) {
            if !isDownloaded {
                Button(action: { Task { await whisperState.downloadParakeetModel() } }) {
                    Label(isDownloading ? "Downloading…" : "Download", systemImage: "arrow.down.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isDownloading)
            } else if !isCurrent {
                Button(action: { Task { whisperState.setDefaultTranscriptionModel(model) } }) {
                    Text("Set Default")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if isDownloaded {
                Menu {
                    Button(action: { whisperState.deleteParakeetModel() }) {
                        Label("Delete Model", systemImage: "trash")
                    }
                    Button { whisperState.showParakeetModelInFinder() } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Color.primary.opacity(0.4))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 20, height: 20)
            }
        }
    }
}
