# Implementation Guide: Integrating Real AI Models

This guide walks you through replacing the mock AI implementations with real open-source models.

## Overview

The current implementation uses mock/placeholder functions. To make this production-ready, you need to integrate actual AI models for:

1. **Vision AI** - Analyzing rash images
2. **Speech-to-Text** - Converting voice to text (Whisper)
3. **LLM** - Generating medical responses

## Step 1: Vision AI Integration

### Option A: Using Transformers.js (Recommended for Web-first)

1. **Install dependencies**
   ```bash
   npm install @xenova/transformers
   ```

2. **Update `src/services/visionService.ts`**
   ```typescript
   import { pipeline } from '@xenova/transformers';

   let classifier: any = null;

   async function initModel() {
     if (!classifier) {
       classifier = await pipeline(
         'image-classification',
         'openai/clip-vit-base-patch32'
       );
     }
     return classifier;
   }

   export async function analyzeRashImage(imageUri: string): Promise<VisionAnalysisResult> {
     const model = await initModel();
     const result = await model(imageUri);

     // Process results into your format
     return {
       description: result[0].label,
       severity: calculateSeverity(result),
       characteristics: extractCharacteristics(result),
       confidence: result[0].score,
     };
   }
   ```

### Option B: Using ONNX Runtime (Better Performance)

1. **Install dependencies**
   ```bash
   npm install onnxruntime-react-native
   npm install react-native-fs
   ```

2. **Download models**
   ```bash
   mkdir -p assets/models
   # Download from Hugging Face or train your own
   wget https://huggingface.co/your-model/resolve/main/model.onnx
   ```

3. **Update service**
   ```typescript
   import * as ort from 'onnxruntime-react-native';
   import RNFS from 'react-native-fs';

   let session: ort.InferenceSession | null = null;

   async function initModel() {
     if (!session) {
       const modelPath = `${RNFS.DocumentDirectoryPath}/models/vision.onnx`;
       session = await ort.InferenceSession.create(modelPath);
     }
     return session;
   }

   export async function analyzeRashImage(imageUri: string) {
     const model = await initModel();
     const imageData = await preprocessImage(imageUri);
     const feeds = { input: imageData };
     const results = await model.run(feeds);
     return parseResults(results);
   }
   ```

### Option C: Medical-Specific Models

For best results with medical images, use specialized models:

**Sources**:
- [MedCLIP](https://github.com/RyanWangZf/MedCLIP) - Medical vision-language model
- [DermNet](https://github.com/jeonsworld/ViT-pytorch) - Dermatology classifier
- Custom models trained on dermatology datasets

## Step 2: Speech-to-Text (Whisper) Integration

### Option A: React Native Whisper (Native Performance)

1. **Install**
   ```bash
   npm install @react-native-whisper/react-native-whisper
   cd ios && pod install && cd ..
   ```

2. **Download Whisper models**
   ```bash
   # Download GGML models from whisper.cpp
   curl -LO https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin
   mv ggml-small.bin assets/models/
   ```

3. **Update `src/services/whisperService.ts`**
   ```typescript
   import Whisper from '@react-native-whisper/react-native-whisper';

   let whisper: any = null;

   async function initWhisper() {
     if (!whisper) {
       whisper = await Whisper.initialize({
         modelPath: 'assets/models/ggml-small.bin',
       });
     }
     return whisper;
   }

   export async function transcribeAudio(
     audioUri: string,
     language: string
   ): Promise<string> {
     const model = await initWhisper();

     const result = await model.transcribe({
       audioPath: audioUri,
       language: language, // 'es' or 'my'
       task: 'transcribe',
     });

     return result.text;
   }
   ```

### Option B: Transformers.js Whisper

1. **Install**
   ```bash
   npm install @xenova/transformers
   ```

2. **Update service**
   ```typescript
   import { pipeline } from '@xenova/transformers';

   let transcriber: any = null;

   async function initTranscriber() {
     if (!transcriber) {
       transcriber = await pipeline(
         'automatic-speech-recognition',
         'openai/whisper-small',
         { quantized: true } // Smaller model size
       );
     }
     return transcriber;
   }

   export async function transcribeAudio(audioUri: string, language: string) {
     const model = await initTranscriber();
     const result = await model(audioUri, {
       language: language,
       task: 'transcribe',
     });
     return result.text;
   }
   ```

## Step 3: Medical LLM Integration

### Option A: Phi-3 Mini (Recommended)

1. **Install llama.cpp for React Native**
   ```bash
   npm install @react-native-llama/llama
   cd ios && pod install && cd ..
   ```

2. **Download Phi-3 Mini GGUF**
   ```bash
   # Download quantized model (~2GB)
   wget https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf
   mv Phi-3-mini-4k-instruct-q4.gguf assets/models/
   ```

3. **Update `src/services/medicalLLMService.ts`**
   ```typescript
   import { initLlama, LlamaContext } from '@react-native-llama/llama';

   let llama: LlamaContext | null = null;

   async function initLLM() {
     if (!llama) {
       llama = await initLlama({
         model: 'assets/models/Phi-3-mini-4k-instruct-q4.gguf',
         n_ctx: 2048,
         n_threads: 4,
       });
     }
     return llama;
   }

   export async function generateMedicalResponse(
     visualAnalysis: VisualAnalysis,
     question: string,
     language: string
   ): Promise<MedicalResponse> {
     const model = await initLLM();
     const prompt = buildMedicalPrompt(visualAnalysis, question, language);

     const response = await model.completion({
       prompt: prompt,
       max_tokens: 512,
       temperature: 0.7,
       top_p: 0.9,
     });

     return parseResponse(response.text, language);
   }
   ```

### Option B: MLC LLM (Mobile-Optimized)

MLC LLM provides highly optimized models for mobile:

```bash
npm install @mlc-ai/web-llm
```

Models available:
- Phi-3-mini
- Llama-3.2-3B
- Mistral-7B (quantized)

## Step 4: Model Download Strategy

For production apps, you need to handle model downloads:

### Approach 1: Bundle with App
- Include models in app bundle
- Increases app size significantly
- No download required
- Best for smaller models (<500MB)

### Approach 2: On-Demand Download
```typescript
// In App.tsx or a setup screen
import * as FileSystem from 'expo-file-system';

async function downloadModels() {
  const models = [
    {
      name: 'whisper-small',
      url: 'https://your-cdn.com/whisper-small.bin',
      path: `${FileSystem.documentDirectory}models/whisper.bin`,
      size: 500 * 1024 * 1024, // 500MB
    },
    {
      name: 'phi3-mini',
      url: 'https://your-cdn.com/phi3-mini-q4.gguf',
      path: `${FileSystem.documentDirectory}models/llm.gguf`,
      size: 2 * 1024 * 1024 * 1024, // 2GB
    },
  ];

  for (const model of models) {
    const info = await FileSystem.getInfoAsync(model.path);

    if (!info.exists) {
      console.log(`Downloading ${model.name}...`);

      const downloadResumable = FileSystem.createDownloadResumable(
        model.url,
        model.path,
        {},
        (progress) => {
          const percent = (progress.totalBytesWritten / model.size) * 100;
          console.log(`${model.name}: ${percent.toFixed(1)}%`);
        }
      );

      await downloadResumable.downloadAsync();
      console.log(`${model.name} downloaded!`);
    }
  }
}
```

### Approach 3: Hybrid
- Bundle smallest models (tiny Whisper)
- Download larger models on first run
- Provide offline mode with basic models

## Step 5: Testing Real Models

1. **Test Vision AI**
   ```typescript
   // Test with sample rash images
   const testImages = [
     'path/to/mild-rash.jpg',
     'path/to/moderate-rash.jpg',
     'path/to/severe-rash.jpg',
   ];

   for (const img of testImages) {
     const result = await analyzeRashImage(img);
     console.log('Analysis:', result);
   }
   ```

2. **Test Speech-to-Text**
   ```typescript
   // Record sample audio in Spanish and Burmese
   const testAudio = [
     { uri: 'spanish-question.m4a', lang: 'es' },
     { uri: 'burmese-question.m4a', lang: 'my' },
   ];

   for (const audio of testAudio) {
     const text = await transcribeAudio(audio.uri, audio.lang);
     console.log(`Transcribed (${audio.lang}):`, text);
   }
   ```

3. **Test LLM**
   ```typescript
   const testCase = {
     visualAnalysis: {
       description: 'Small red bumps',
       severity: 'low',
       characteristics: ['localized', 'mild redness'],
     },
     question: '¿Es esto peligroso?',
     language: 'es',
   };

   const response = await generateMedicalResponse(
     testCase.visualAnalysis,
     testCase.question,
     testCase.language
   );
   console.log('Response:', response);
   ```

## Step 6: Performance Optimization

### Model Quantization
Use quantized models to reduce size and improve speed:
- **4-bit quantization**: 4x smaller, minimal accuracy loss
- **8-bit quantization**: 2x smaller, negligible accuracy loss

### Caching Strategy
```typescript
// Cache models in memory
const modelCache = new Map();

async function getModel(type: string) {
  if (!modelCache.has(type)) {
    const model = await loadModel(type);
    modelCache.set(type, model);
  }
  return modelCache.get(type);
}
```

### Background Loading
```typescript
// Load models in background on app start
useEffect(() => {
  const loadModels = async () => {
    await Promise.all([
      initWhisper(),
      initLLM(),
      initVisionModel(),
    ]);
    console.log('All models ready!');
  };

  loadModels();
}, []);
```

## Step 7: Deployment Considerations

### App Size
- iOS App Store limit: 4GB over-the-air, unlimited via WiFi
- Android Play Store limit: 150MB APK + 2GB expansion files

**Strategies**:
1. Use on-demand downloads for models
2. Offer "lite" version with smaller models
3. Implement progressive model downloading

### Legal Compliance
- [ ] Medical disclaimer prominently displayed
- [ ] User accepts terms before use
- [ ] Clear about AI limitations
- [ ] Privacy policy for data handling
- [ ] Consult legal team for medical app regulations

### Medical Validation
- [ ] Test with real medical professionals
- [ ] Validate responses against medical literature
- [ ] Implement feedback mechanism
- [ ] Track accuracy metrics
- [ ] Regular model updates

## Resources

### Model Sources
- **Hugging Face**: https://huggingface.co/models
- **ONNX Model Zoo**: https://github.com/onnx/models
- **TensorFlow Hub**: https://tfhub.dev/
- **Whisper Models**: https://github.com/openai/whisper

### Libraries
- **Transformers.js**: https://github.com/xenova/transformers.js
- **ONNX Runtime**: https://onnxruntime.ai/
- **llama.cpp**: https://github.com/ggerganov/llama.cpp
- **whisper.cpp**: https://github.com/ggerganov/whisper.cpp

### Communities
- React Native AI Discord
- Hugging Face Forums
- r/MachineLearning Reddit
- Medical AI research groups

## Support

If you need help with implementation:
1. Check the README.md troubleshooting section
2. Open an issue on GitHub
3. Join our Discord community
4. Email: support@healthrashai.org

Good luck with your implementation! 🚀
