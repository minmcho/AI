# Health Rash AI - Mobile Application

![Health Rash AI](https://img.shields.io/badge/platform-iOS%20%7C%20Android-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![AI](https://img.shields.io/badge/AI-Open%20Source-purple)

A compassionate, privacy-preserving mobile application that helps healthcare workers in underserved communities analyze skin rashes using open-source AI. The app supports multilingual voice input (Spanish and Burmese) and provides evidence-based medical guidance with care instructions.

## 🌟 Features

### Core Capabilities
- 📸 **Photo Capture**: Take clear photos of skin rashes using the device camera
- 🎤 **Voice Input**: Speak questions in Spanish or Burmese
- 🤖 **AI Analysis**: Get instant, evidence-based analysis using open-source vision AI
- 💬 **Compassionate Responses**: Receive clear, culturally sensitive medical guidance
- 📋 **Care Instructions**: Step-by-step treatment recommendations
- 🔊 **Audio Playback**: Listen to responses in the selected language
- 🔒 **100% Privacy**: All processing happens on-device, no data leaves your phone

### Privacy & Security
- ✅ All AI processing performed locally on device
- ✅ No internet connection required after initial setup
- ✅ Encrypted local storage
- ✅ Auto-delete old analyses
- ✅ No external servers or cloud services
- ✅ HIPAA-ready architecture

## 🏗️ Architecture

### Tech Stack
- **Framework**: React Native with Expo
- **Language**: TypeScript
- **Navigation**: React Navigation
- **Storage**: AsyncStorage + SecureStore (encrypted)

### Open-Source AI Components

#### 1. Vision AI (Rash Analysis)
**Current**: Mock implementation for demonstration
**Production Options**:
- **Transformers.js** - Run vision models in JavaScript
  ```bash
  npm install @xenova/transformers
  ```
- **ONNX Runtime** - Optimized mobile inference
  ```bash
  npm install onnxruntime-react-native
  ```
- **TensorFlow Lite** - Native mobile ML
  ```bash
  npm install @tensorflow/tfjs-react-native
  ```

**Recommended Models**:
- CLIP (general vision understanding)
- Medical-specific models from Hugging Face
- Custom-trained dermatology models

#### 2. Speech-to-Text (Whisper)
**Current**: Mock implementation
**Production Options**:
- **whisper.cpp** - C++ implementation for mobile
  ```bash
  # React Native Whisper
  npm install @react-native-whisper/react-native-whisper
  ```
- **Transformers.js** - JavaScript Whisper
  ```bash
  npm install @xenova/transformers
  ```

**Model Sizes**:
- `whisper-tiny`: ~75MB, fast
- `whisper-base`: ~150MB, balanced
- `whisper-small`: ~500MB, recommended
- `whisper-medium`: ~1.5GB, highest accuracy

**Languages Supported**: Spanish (es), Burmese (my), and 97+ other languages

#### 3. Medical LLM (Response Generation)
**Current**: Mock implementation
**Production Options**:
- **Phi-3 Mini** (3.8B params, Microsoft)
  - Optimized for mobile
  - 2-4GB quantized
  - Medical knowledge
- **Llama 3.2** (3B params, Meta)
  - Mobile-optimized
  - Multilingual
  - 2-3GB quantized
- **Mistral 7B** (4-bit quantized)
  - High quality
  - ~4GB storage

**Integration Options**:
- **llama.cpp** - Best performance
  ```bash
  npm install @react-native-llama/llama
  ```
- **ONNX Runtime** - Cross-platform
- **MLC LLM** - Mobile-optimized runtime

## 📱 Installation & Setup

### Prerequisites
- Node.js 18+ and npm
- Expo CLI
- iOS Simulator (Mac) or Android Studio (for testing)

### Quick Start

1. **Clone the repository**
   ```bash
   cd mobile
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start the development server**
   ```bash
   npm start
   ```

4. **Run on device/simulator**
   ```bash
   # iOS
   npm run ios

   # Android
   npm run android
   ```

### Setting Up AI Models (Production)

#### Option 1: Transformers.js (Easiest)
```typescript
// Install
npm install @xenova/transformers

// In visionService.ts
import { pipeline } from '@xenova/transformers';

export async function analyzeRashImage(imageUri: string) {
  const classifier = await pipeline(
    'image-classification',
    'openai/clip-vit-base-patch32'
  );
  const result = await classifier(imageUri);
  return result;
}

// In whisperService.ts
const transcriber = await pipeline(
  'automatic-speech-recognition',
  'openai/whisper-small'
);
const result = await transcriber(audioUri, { language: 'es' });
```

#### Option 2: ONNX Runtime (Best Performance)
```bash
npm install onnxruntime-react-native

# Download models
mkdir -p assets/models
wget https://huggingface.co/onnx/whisper-small/resolve/main/model.onnx
```

```typescript
import * as ort from 'onnxruntime-react-native';

const session = await ort.InferenceSession.create('assets/models/model.onnx');
const results = await session.run(inputs);
```

#### Option 3: Native Integration (Maximum Performance)
For production apps, integrate native bindings:
- iOS: Use Core ML with whisper.cpp
- Android: Use TensorFlow Lite with NNAPI

## 🎨 Project Structure

```
mobile/
├── App.tsx                 # Main app entry with navigation
├── src/
│   ├── screens/
│   │   ├── HomeScreen.tsx          # Landing page with language selection
│   │   ├── CameraScreen.tsx        # Photo capture & voice input
│   │   ├── AnalysisScreen.tsx      # AI results display
│   │   └── SettingsScreen.tsx      # App settings & privacy controls
│   ├── components/
│   │   └── VoiceInput.tsx          # Voice recording component
│   └── services/
│       ├── visionService.ts        # Vision AI integration
│       ├── medicalLLMService.ts    # Medical response LLM
│       ├── whisperService.ts       # Speech-to-text
│       └── storageService.ts       # Encrypted local storage
├── assets/                 # Icons, images, models
├── package.json
└── app.json               # Expo configuration
```

## 🔧 Configuration

### App Settings (`app.json`)
- Camera and microphone permissions configured
- iOS and Android specific settings
- Bundle identifiers set

### Privacy Settings
Edit `src/services/storageService.ts` to configure:
- Auto-delete time period (7, 14, 30, 60 days)
- Storage encryption keys
- Data retention policies

## 🌍 Localization

Currently supported languages:
- 🇪🇸 Spanish (Español)
- 🇲🇲 Burmese (မြန်မာဘာသာ)

To add more languages:
1. Update `VoiceInput.tsx` with new language options
2. Add translations in `medicalLLMService.ts`
3. Configure Whisper model for the language

## 🔒 Privacy & Compliance

### HIPAA Compliance Checklist
- ✅ End-to-end encryption
- ✅ Local-only processing
- ✅ Secure storage (iOS Keychain, Android Keystore)
- ✅ Automatic data deletion
- ✅ No cloud transmission
- ✅ Audit logging capability
- ✅ User data control

### Data Flow
```
1. User takes photo → Stored in memory only
2. User records voice → Processed immediately, then deleted
3. AI analysis → Performed on-device
4. Results → Encrypted local storage (optional)
5. Auto-delete → After configured period (default: 30 days)
```

## 🚀 Deployment

### iOS App Store
```bash
# Build for iOS
eas build --platform ios

# Submit to App Store
eas submit --platform ios
```

### Android Play Store
```bash
# Build for Android
eas build --platform android

# Submit to Play Store
eas submit --platform android
```

### Pre-deployment Checklist
- [ ] Replace mock AI services with real models
- [ ] Download and bundle AI models
- [ ] Test on physical devices (not just simulators)
- [ ] Verify all languages work correctly
- [ ] Test camera on various devices
- [ ] Measure app size and optimize
- [ ] Add error tracking (Sentry, Bugsnag)
- [ ] Implement analytics (privacy-preserving only)
- [ ] Get medical/legal review
- [ ] Prepare App Store descriptions

## 🧪 Testing

### Manual Testing
1. Test camera on different devices
2. Test voice input in both languages
3. Verify AI responses are appropriate
4. Test offline functionality
5. Test privacy features (data deletion)

### Automated Testing
```bash
npm test
```

## 📊 Performance Optimization

### App Size Optimization
- Use quantized AI models (4-bit or 8-bit)
- Enable Hermes JavaScript engine
- Use ProGuard (Android) and bitcode (iOS)
- Lazy-load AI models

### Runtime Performance
- Cache AI models in memory
- Use native modules for intensive tasks
- Implement request batching
- Monitor memory usage

### Recommended Model Sizes
- Vision AI: 100-300 MB
- Whisper: 150-500 MB (small model)
- LLM: 2-4 GB (quantized Phi-3 or Llama 3.2)
- **Total app size**: ~3-5 GB

## 🤝 Contributing

Contributions are welcome! This is an open-source project aimed at improving healthcare access.

### Areas for Contribution
- Additional language support
- Improved AI models
- UI/UX enhancements
- Medical accuracy improvements
- Documentation
- Testing

## 📄 License

MIT License - See LICENSE file for details

## ⚠️ Medical Disclaimer

**IMPORTANT**: This application is intended as a support tool for trained healthcare workers. It does NOT replace professional medical diagnosis or treatment. All AI-generated responses are for informational purposes only.

- Always follow established medical protocols
- Seek professional medical attention for serious conditions
- Do not rely solely on AI analysis for critical decisions
- This app is not FDA-approved or certified medical software

## 🆘 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: [your-email@example.com]
- Documentation: [link to docs]

## 🙏 Acknowledgments

This project uses the following open-source technologies:
- **Whisper** by OpenAI - Speech recognition
- **CLIP** by OpenAI - Vision understanding
- **Phi-3** by Microsoft - Language model
- **React Native** by Meta - Mobile framework
- **Expo** - Development platform

Built with ❤️ for healthcare workers serving underserved communities.

---

**Version**: 1.0.0
**Last Updated**: December 2024
**Status**: Beta - Demo with mock AI (production requires real model integration)
