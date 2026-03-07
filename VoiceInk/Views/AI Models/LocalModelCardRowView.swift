import SwiftUI
import AppKit
// MARK: - Local Model Card View
struct LocalModelCardView: View {
    let model: LocalModel
    let isDownloaded: Bool
    let isCurrent: Bool
    let downloadProgress: [String: Double]
    let modelURL: URL?

    var deleteAction: () -> Void
    var setDefaultAction: () -> Void
    var downloadAction: () -> Void

    private var isDownloading: Bool {
        downloadProgress.keys.contains(model.name + "_main") ||
        downloadProgress.keys.contains(model.name + "_coreml")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isCurrent ? Color.green : Color.primary.opacity(0.35))
                    .frame(width: 14, alignment: .center)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.labelColor))
                        statusBadge
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
                DownloadProgressView(modelName: model.name, downloadProgress: downloadProgress)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }
        }
        .background(CardBackground(isSelected: isCurrent, useAccentGradientWhenSelected: isCurrent))
    }

    private var statusBadge: some View {
        Group {
            if isCurrent {
                Text("Default")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.07)))
            }
        }
    }

    private var actionSection: some View {
        HStack(spacing: 6) {
            if !isDownloaded {
                Button(action: downloadAction) {
                    Text(isDownloading ? "Downloading…" : "Download")
                        .font(.system(size: 12))
                        .frame(minWidth: 88)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isDownloading)
            } else if !isCurrent {
                Button(action: setDefaultAction) {
                    Text("Set Default")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if isDownloaded {
                Menu {
                    Button(action: deleteAction) {
                        Label("Delete Model", systemImage: "trash")
                    }
                    Button {
                        if let modelURL = modelURL {
                            NSWorkspace.shared.selectFile(modelURL.path, inFileViewerRootedAtPath: "")
                        }
                    } label: {
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

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.green.opacity(0.8))
            }
        }
    }
}

// MARK: - Imported Local Model
struct ImportedLocalModelCardView: View {
    let model: ImportedLocalModel
    let isDownloaded: Bool
    let isCurrent: Bool
    let modelURL: URL?

    var deleteAction: () -> Void
    var setDefaultAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isCurrent ? Color.green : Color.primary.opacity(0.35))
                .frame(width: 14, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.labelColor))
                    if isCurrent {
                        Text("Default")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 3).fill(Color.accentColor.opacity(0.1)))
                    }
                }
                Text("Imported")
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabelColor))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                if !isCurrent, isDownloaded {
                    Button(action: setDefaultAction) {
                        Text("Set Default")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if isDownloaded {
                    Menu {
                        Button(action: deleteAction) {
                            Label("Delete Model", systemImage: "trash")
                        }
                        Button {
                            if let modelURL = modelURL {
                                NSWorkspace.shared.selectFile(modelURL.path, inFileViewerRootedAtPath: "")
                            }
                        } label: {
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(CardBackground(isSelected: isCurrent, useAccentGradientWhenSelected: isCurrent))
    }
}
