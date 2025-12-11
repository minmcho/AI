# Health Rash AI - Complete Project

A comprehensive open-source AI-powered healthcare solution for analyzing skin rashes in underserved communities. This project includes both a web-based image processing tool and a mobile application with multilingual voice support.

## 📱 Project Structure

This repository contains two applications:

### 1. Web Application (Root Directory)
A modern image processing web app built with React, TypeScript, and Vite.

**Location**: `/` (root directory)
**Features**:
- Image upload and processing
- Real-time filter adjustments
- Canvas-based editing
- Responsive design

**Tech Stack**:
- React 18
- TypeScript
- Vite
- Tailwind CSS

**Quick Start**:
```bash
npm install
npm run dev
```

### 2. Mobile Application (./mobile)
A privacy-preserving mobile app for health workers to analyze skin rashes using AI.

**Location**: `/mobile`
**Features**:
- 📸 Camera capture of skin rashes
- 🎤 Voice input in Spanish and Burmese
- 🤖 Local AI analysis (vision + LLM)
- 🔒 100% privacy-preserving (all on-device)
- 📋 Evidence-based care instructions
- 🔊 Audio playback of responses

**Tech Stack**:
- React Native + Expo
- TypeScript
- Open-source AI models (Whisper, CLIP, Phi-3)
- Encrypted local storage

**Quick Start**:
```bash
cd mobile
npm install
npm start
```

**See**: [mobile/README.md](./mobile/README.md) for detailed mobile app documentation

## 🎯 Main Focus: Mobile Health App

The **Health Rash AI mobile application** is the primary deliverable of this project. It addresses a critical need: providing AI-powered medical assistance to healthcare workers in underserved communities where access to specialists is limited.

### Key Use Case

**Scenario**: A community health worker in a rural area encounters a child with a skin rash.

**Workflow**:
1. Worker opens the app and selects their language (Spanish or Burmese)
2. Takes a photo of the rash using the camera
3. Speaks their question: "¿Es esto peligroso?" (Is this dangerous?)
4. AI analyzes the image locally on the device
5. Worker receives:
   - Severity assessment (low/medium/high)
   - Compassionate explanation in their language
   - Step-by-step care instructions
   - Whether to seek immediate medical attention
6. Can listen to the response via text-to-speech
7. All data stays on device, ensuring patient privacy

### Privacy-First Architecture

**Why On-Device Processing?**
- ✅ Works in areas with poor/no internet
- ✅ Protects patient privacy (HIPAA-ready)
- ✅ No data breaches possible
- ✅ No ongoing server costs
- ✅ Cultural sensitivity (data never leaves community)

## 🤖 Open-Source AI Components

All AI models are open-source and can run locally:

### Vision AI
- **CLIP** - OpenAI's vision-language model
- **MedCLIP** - Medical-specific variant
- **Custom dermatology models** from academic research

### Speech-to-Text
- **Whisper** - OpenAI's multilingual speech recognition
- Supports 99+ languages including Spanish and Burmese
- Multiple model sizes (tiny to large)

### Language Model
- **Phi-3 Mini** (3.8B) - Microsoft's efficient LLM
- **Llama 3.2** (3B) - Meta's mobile-optimized model
- **Mistral 7B** - Quantized for mobile devices

## 📚 Documentation

- **Mobile App**: [mobile/README.md](./mobile/README.md)
- **Implementation Guide**: [mobile/IMPLEMENTATION_GUIDE.md](./mobile/IMPLEMENTATION_GUIDE.md)
- **Web App**: [README.md](./README.md)

## 🚀 Getting Started

### For Mobile App Development

1. **Setup environment**
   ```bash
   cd mobile
   npm install
   ```

2. **Run in development**
   ```bash
   npm start
   # Then press 'i' for iOS or 'a' for Android
   ```

3. **Current Status**
   - ✅ Full UI/UX implemented
   - ✅ App structure complete
   - ✅ Navigation working
   - ✅ Privacy features implemented
   - ⏳ AI models use mock implementations
   - ⏳ Need real model integration (see IMPLEMENTATION_GUIDE.md)

4. **Next Steps to Production**
   - Integrate real Whisper model for speech-to-text
   - Add vision model for rash analysis
   - Integrate Phi-3 or Llama for medical responses
   - Test with medical professionals
   - Legal/medical compliance review

### For Web App Development

```bash
npm install
npm run dev
```

## 🌍 Impact

This application is designed to:

- **Expand Healthcare Access**: Bring AI-powered medical guidance to remote areas
- **Support Healthcare Workers**: Empower community health workers with decision support
- **Preserve Privacy**: Keep sensitive medical data completely private
- **Break Language Barriers**: Support local languages (Spanish, Burmese, expandable)
- **Enable Offline Use**: Work without internet connectivity
- **Reduce Costs**: No cloud infrastructure needed

## 🔒 Privacy & Ethics

**Privacy Commitments**:
- No data collection
- No analytics tracking
- No cloud services
- No external API calls
- All processing on-device
- User controls all data

**Ethical Considerations**:
- Clear AI limitations stated
- Not a replacement for doctors
- Culturally sensitive responses
- Evidence-based guidance
- Support for vulnerable populations

## 📄 License

MIT License - see [LICENSE](./LICENSE) file

This project is open-source to enable:
- Community contributions
- Adaptation for different regions
- Academic research
- Non-profit healthcare initiatives

## ⚠️ Medical Disclaimer

**CRITICAL**: This application is NOT medical software and does NOT provide medical diagnoses.

- For use by trained healthcare workers only
- AI responses are informational, not diagnostic
- Always follow established medical protocols
- Seek professional medical attention for serious conditions
- Not FDA-approved or medically certified
- Users assume all responsibility

## 🤝 Contributing

We welcome contributions! Areas where you can help:

- **Medical**: Validate AI responses, provide medical expertise
- **AI/ML**: Improve models, optimize for mobile, add new capabilities
- **Localization**: Add support for more languages
- **Testing**: Test in real-world scenarios
- **Documentation**: Improve guides and tutorials
- **Design**: Enhance UI/UX

See individual README files for contribution guidelines.

## 🙏 Acknowledgments

This project builds on incredible open-source work:

- **OpenAI** - Whisper, CLIP
- **Microsoft** - Phi-3
- **Meta** - Llama, React Native
- **Expo** - Mobile development platform
- **Hugging Face** - Model hosting and tools
- **Medical AI researchers** - Dermatology models

## 📞 Contact

- **Issues**: Open a GitHub issue
- **Email**: [your-email@example.com]
- **Website**: [project-website.com]

---

**Built with ❤️ for healthcare workers serving the world's most vulnerable communities.**

**Version**: 1.0.0 (Beta)
**Status**: Mobile app complete (mock AI), ready for model integration
**Platform**: iOS & Android
