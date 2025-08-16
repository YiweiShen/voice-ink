<div align="center">
  <img src="VoiceInk/Assets.xcassets/AppIcon.appiconset/256-mac.png" width="180" height="180" />
  <h1>VoiceInk Lite</h1>
  <p>Lightweight, opinionated voice-to-text app for macOS focused on core transcription functionality</p>

[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-brightgreen)

</div>

---

VoiceInk Light is a streamlined version of VoiceInk, focusing on essential voice-to-text functionality without the complexity of AI enhancements. This opinionated build prioritizes simplicity, performance, and privacy.

This lightweight version strips away non-essential features to provide a clean, fast transcription experience for users who want straightforward voice-to-text conversion without additional AI-powered features.

## Features

- 🎙️ **Core Transcription**: Local AI models for accurate voice-to-text conversion
- 🔒 **Privacy First**: 100% offline processing ensures your data never leaves your device
- 🎯 **Global Shortcuts**: Configurable keyboard shortcuts for quick recording and push-to-talk functionality
- 📝 **Personal Dictionary**: Custom words and text replacements for personalized transcription
- 🔧 **Simple Interface**: Clean, distraction-free UI focused on essential functionality
- ⚡ **Lightweight**: Minimal resource usage with fast startup and response times

## Get Started

### Build from Source

VoiceInk Light is designed to be built from source. Follow the instructions in [BUILDING.md](BUILDING.md) to compile and run the application on your macOS system.

## Requirements

- macOS 14.0 or later

## Documentation

- [Building from Source](BUILDING.md) - Detailed instructions for building the project
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute to VoiceInk
- [Code of Conduct](CODE_OF_CONDUCT.md) - Our community standards

## Contributing

We welcome contributions to VoiceInk Light! This project maintains a focused scope on core transcription functionality. Before contributing:

1. Read our [Contributing Guidelines](CONTRIBUTING.md)
2. Open an issue to discuss your proposed changes
3. Ensure contributions align with the lightweight, opinionated nature of this build

For build instructions, see our [Building Guide](BUILDING.md).

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please:

1. Check the existing issues in the GitHub repository
2. Create a new issue if your problem isn't already reported
3. Provide as much detail as possible about your environment and the problem

## Acknowledgments

### Core Technology

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) - High-performance inference of OpenAI's Whisper model
- [FluidAudio](https://github.com/FluidInference/FluidAudio) - Used for Parakeet model implementation

### Essential Dependencies

- [Sparkle](https://github.com/sparkle-project/Sparkle) - Keeping VoiceInk up to date
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - User-customizable keyboard shortcuts
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Launch at login functionality
- [MediaRemoteAdapter](https://github.com/ejbills/mediaremote-adapter) - Media playback control during recording
- [Zip](https://github.com/marmelroy/Zip) - File compression and decompression utilities

---

VoiceInk Light - A focused, lightweight approach to voice-to-text transcription on macOS.
