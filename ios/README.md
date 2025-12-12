# Health Rash AI - iOS Native App

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green)
![License](https://img.shields.io/badge/license-MIT-green)

A native iOS application built with SwiftUI for analyzing skin rashes using on-device AI. Designed for healthcare workers in underserved communities with multilingual support (Spanish and Burmese).

## 🌟 Features

### Core Functionality
- 📸 **Native Camera Integration** - High-quality photo capture using AVFoundation
- 🎤 **Speech Recognition** - Voice input in Spanish and Burmese using iOS Speech framework
- 🤖 **On-Device AI** - Privacy-preserving analysis using Core ML
- 🔊 **Text-to-Speech** - Audio playback of medical responses using AVSpeechSynthesizer
- 💾 **Secure Storage** - Encrypted local storage with auto-delete
- ⚙️ **Comprehensive Settings** - Full privacy and preference controls

### Privacy & Security
- ✅ 100% on-device processing (no internet required)
- ✅ No external API calls or cloud services
- ✅ Encrypted local data storage using UserDefaults
- ✅ Camera and microphone permissions clearly explained
- ✅ Auto-delete old analyses (configurable)
- ✅ HIPAA-ready architecture

## 🏗️ Architecture

### Technology Stack
- **Swift 5.9+**
- **SwiftUI 4.0** - Modern declarative UI framework
- **AVFoundation** - Camera and audio capture
- **Speech Framework** - Speech-to-text recognition
- **AVSpeechSynthesizer** - Text-to-speech output
- **Core ML** - On-device machine learning (ready for integration)
- **Vision Framework** - Image analysis capabilities
- **UserDefaults** - Secure local storage

### Project Structure

```
HealthRashAI/
├── HealthRashAIApp.swift          # App entry point & configuration
├── ContentView.swift               # Root view
├── Views/
│   ├── HomeView.swift             # Language selection & introduction
│   ├── CameraView.swift           # Camera capture & photo preview
│   ├── VoiceInputView.swift       # Voice recording component
│   ├── AnalysisView.swift         # AI results display
│   └── SettingsView.swift         # App settings & privacy controls
├── Services/
│   ├── CameraManager.swift        # AVFoundation camera handling
│   ├── VoiceRecorder.swift        # Speech recognition
│   ├── AIAnalyzer.swift           # Vision & LLM integration
│   ├── SpeechSynthesizer.swift    # Text-to-speech
│   └── StorageService.swift       # Secure local storage
├── Info.plist                     # App configuration & permissions
└── Assets.xcassets/               # App icons and images
```

## 🚀 Getting Started

### Prerequisites
- **Xcode 15.0+**
- **iOS 16.0+** (deployment target)
- **macOS Ventura+** for development
- **Apple Developer Account** (for device testing)

### Installation

1. **Open in Xcode**
   ```bash
   cd ios
   open HealthRashAI.xcodeproj
   ```

2. **Configure Signing**
   - Select your development team in Xcode
   - Update Bundle Identifier if needed
   - Xcode → Signing & Capabilities

3. **Build and Run**
   - Select target device or simulator
   - Press `Cmd + R` to build and run
   - Grant camera and microphone permissions when prompted

### Required Permissions

The app requires these permissions (automatically requested):

| Permission | Purpose |
|------------|---------|
| Camera | Capture photos of skin rashes |
| Microphone | Record voice questions |
| Speech Recognition | Convert speech to text |
| Photo Library (optional) | Save analysis results |

All permissions have clear descriptions in `Info.plist`.

## 🤖 AI Integration

### Current Status
The app uses **mock AI implementations** for demonstration. To make it production-ready, integrate real AI models:

### 1. Vision AI (Rash Analysis)

**Option A: Core ML with Custom Model**

```swift
// Train or download a dermatology classification model
// Convert to Core ML format (.mlmodel)

import CoreML
import Vision

guard let model = try? VNCoreMLModel(for: RashClassifier().model) else {
    return
}

let request = VNCoreMLRequest(model: model) { request, error in
    guard let results = request.results as? [VNClassificationObservation] else {
        return
    }

    // Process classification results
    let topResult = results.first
    print("Classification: \(topResult?.identifier ?? "unknown")")
    print("Confidence: \(topResult?.confidence ?? 0)")
}

let handler = VNImageRequestHandler(cgImage: image.cgImage!)
try? handler.perform([request])
```

**Model Sources:**
- Train custom model with dermatology dataset
- Use transfer learning with MobileNetV3/EfficientNet
- Convert existing ONNX models to Core ML

### 2. Speech Recognition (Whisper Integration)

**Current:** Uses iOS Speech framework with Spanish/Burmese support

**Upgrade to Whisper:**

```swift
// Option 1: Use WhisperKit (Core ML Whisper)
// https://github.com/argmaxinc/WhisperKit

import WhisperKit

let whisper = try await WhisperKit()
let result = try await whisper.transcribe(audioPath: audioURL)
print(result.text)

// Option 2: Convert Whisper to Core ML yourself
// 1. Export Whisper model to Core ML using coremltools
// 2. Add .mlmodel to Xcode project
// 3. Use Vision/Sound Analysis framework
```

### 3. Medical LLM (Response Generation)

**Option A: Core ML LLM**

```swift
// Convert Phi-3 Mini or Llama 3.2 to Core ML
// Use Apple's LLM tools or mlx-lm

import CoreML

guard let model = try? MLModel(contentsOf: phi3ModelURL) else {
    return
}

let input = /* tokenized input */
let output = try model.prediction(from: input)
```

**Option B: GGML on iOS**

```swift
// Use llama.cpp iOS port
// https://github.com/ggerganov/llama.cpp

// Build llama.cpp for iOS
// Link library in Xcode
// Call C++ functions from Swift
```

**Recommended Models:**
- **Phi-3 Mini** (3.8B) - Best for mobile
- **Llama 3.2** (3B) - Good quality
- **Gemma 2B** - Smallest option

### Model Size Considerations

| Component | Model | Size | RAM Required |
|-----------|-------|------|--------------|
| Vision | MobileNetV3 | 10-30 MB | 200 MB |
| Speech | Whisper Small | 500 MB | 1 GB |
| LLM | Phi-3 Mini (Q4) | 2.5 GB | 3 GB |
| **Total** | | **~3 GB** | **~4 GB** |

**Recommendation:** iPhone 12 or newer with 6GB+ RAM

## 📱 App Features

### Home Screen
- Language selection (Spanish 🇪🇸 / Burmese 🇲🇲)
- How it works guide
- Privacy notice
- Start new analysis button

### Camera Screen
- Live camera preview
- Guidance overlay for optimal photo capture
- Photo retake option
- Integrated voice input

### Voice Input
- Visual recording indicator
- Language-specific example questions
- Real-time processing feedback
- Spanish and Burmese support

### Analysis Screen
- Severity badge (Low/Medium/High color-coded)
- Medical analysis explanation
- Numbered care instructions
- Medical attention warning (if needed)
- Audio playback of results
- Privacy confirmation

### Settings Screen
- Default language selection
- Privacy mode toggle
- Auto-save analyses option
- Auto-delete period (7/14/30/60 days)
- Storage usage statistics
- Clear all data option
- About section with app info

## 🔒 Privacy Features

### Data Protection
```swift
// All data stored using UserDefaults with encryption option
// Can be enhanced with Keychain for sensitive data

import Security

// Save to Keychain
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "analysisData",
    kSecValueData as String: data
]
SecItemAdd(query as CFDictionary, nil)
```

### Auto-Delete
```swift
// Automatically delete analyses older than configured days
StorageService.shared.deleteOldAnalyses(olderThan: 30)
```

### No Network Access
- App works 100% offline
- No network permissions requested
- All processing on-device

## 🎨 UI/UX Design

### Color Scheme
- **Primary Blue**: `#2563EB` - Actions and emphasis
- **Success Green**: `#16A34A` - Positive feedback
- **Warning Yellow**: `#F59E0B` - Caution
- **Error Red**: `#EF4444` - Alerts

### Typography
- **System Font** - Native iOS feel
- **Dynamic Type Support** - Accessibility
- **Localized Text** - Spanish & Burmese

### Accessibility
- VoiceOver support
- Dynamic font sizes
- High contrast mode
- Reduced motion option

## 📊 Performance Optimization

### Image Processing
```swift
// Resize images before processing to save memory
func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
}
```

### Memory Management
```swift
// Use @Published sparingly
// Weak references in closures
// Release camera session when not in use
```

### Battery Optimization
- Camera session stops when not active
- No background processing
- Efficient Core ML inference

## 🧪 Testing

### Unit Tests
```swift
import XCTest
@testable import HealthRashAI

class StorageServiceTests: XCTestCase {
    func testSaveAnalysis() {
        let service = StorageService.shared
        service.clearAllData()

        let result = AnalysisResult(...)
        service.saveAnalysis(question: "Test", language: "es", result: result)

        let analyses = service.getAnalyses()
        XCTAssertEqual(analyses.count, 1)
    }
}
```

### UI Tests
```swift
import XCTestCase

class HealthRashAIUITests: XCTestCase {
    func testNavigationFlow() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Start New Analysis"].tap()
        XCTAssertTrue(app.staticTexts["Capture Rash Photo"].exists)
    }
}
```

## 📦 Distribution

### App Store Preparation

1. **Set up App Store Connect**
   - Create app record
   - Add screenshots (6.7", 6.5", 5.5")
   - Write description

2. **App Store Assets**
   - App Icon (1024x1024)
   - Screenshots for all sizes
   - Privacy policy URL
   - Support URL

3. **Build and Archive**
   ```bash
   # In Xcode
   Product → Archive
   # Upload to App Store Connect
   ```

4. **Submit for Review**
   - Medical app disclaimer
   - Privacy explanation
   - Demo video/account

### TestFlight Beta

```bash
# Distribute to beta testers
# Xcode → Window → Organizer → Distribute App → TestFlight
```

## ⚠️ Medical Disclaimer

**CRITICAL**: This application is NOT a medical device and does NOT provide medical diagnoses.

- For use by trained healthcare workers only
- AI responses are informational, not diagnostic
- Always follow established medical protocols
- Seek professional medical attention for serious conditions
- Not FDA-approved or medically certified

## 🐛 Known Issues

1. **Speech Recognition** - Burmese support may be limited on some iOS versions
2. **Core ML Models** - Not included (need to be integrated)
3. **Landscape Mode** - UI optimized for portrait only

## 🔄 Future Enhancements

- [ ] iPad optimization with split-view
- [ ] Apple Watch companion app
- [ ] HealthKit integration
- [ ] Export analysis as PDF
- [ ] More language support (French, Arabic, Hindi)
- [ ] Offline model download manager
- [ ] Dark mode optimization

## 🤝 Contributing

Contributions welcome! Areas of focus:

- Core ML model optimization
- Additional language support
- UI/UX improvements
- Medical accuracy validation
- Accessibility enhancements

## 📄 License

MIT License - See LICENSE file

## 🙏 Acknowledgments

Built with:
- **SwiftUI** - Apple's modern UI framework
- **AVFoundation** - Apple's media framework
- **Speech Framework** - Apple's speech recognition
- **Core ML** - Apple's machine learning framework

Inspired by the need to improve healthcare access in underserved communities.

---

**Version**: 1.0.0
**Min iOS**: 16.0
**Swift**: 5.9
**Xcode**: 15.0+
**Status**: UI Complete, Ready for AI Model Integration

**Built with ❤️ for healthcare workers worldwide** 🌍
