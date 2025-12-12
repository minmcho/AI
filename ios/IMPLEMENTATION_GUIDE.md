# iOS Implementation Guide - Integrating Real AI Models

This guide shows you how to integrate production-ready AI models into the Health Rash AI iOS app.

## Overview

Current app uses mock implementations. This guide covers:
1. Vision AI (Rash Classification)
2. Speech Recognition (Whisper)
3. Medical LLM (Response Generation)

## Step 1: Vision AI with Core ML

### Option A: Custom Trained Model

1. **Prepare Training Data**
   ```python
   # Collect dermatology images dataset
   # Organize by condition type
   # Minimum 1000 images per class recommended
   ```

2. **Train Model with Create ML**
   ```swift
   // In Xcode: Open Create ML
   // Create Image Classifier
   // Train on dataset
   // Export as .mlmodel
   ```

3. **Integrate in Xcode**
   ```swift
   // Add .mlmodel to project
   // Xcode auto-generates Swift class

   // In AIAnalyzer.swift
   import CoreML
   import Vision

   private func performVisionAnalysis(image: UIImage) -> VisionAnalysisResult {
       guard let cgImage = image.cgImage else { return defaultResult }

       // Load Core ML model
       guard let model = try? VNCoreMLModel(for: RashClassifier_1().model) else {
           return defaultResult
       }

       // Create Vision request
       let request = VNCoreMLRequest(model: model) { request, error in
           guard let results = request.results as? [VNClassificationObservation],
                 let topResult = results.first else {
               return
           }

           // Map to severity
           let severity = self.mapToSeverity(classification: topResult.identifier)
           let confidence = Double(topResult.confidence)

           // Return result
           completion(VisionAnalysisResult(
               description: topResult.identifier,
               severity: severity,
               characteristics: self.extractCharacteristics(from: results),
               confidence: confidence
           ))
       }

       // Perform analysis
       let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
       try? handler.perform([request])

       return result
   }
   ```

### Option B: Transfer Learning with Pre-trained Model

```python
# Use TensorFlow/PyTorch
import coremltools as ct
import tensorflow as tf

# Load pre-trained model
base_model = tf.keras.applications.MobileNetV3Small(
    weights='imagenet',
    include_top=False
)

# Add classification head
model = tf.keras.Sequential([
    base_model,
    tf.keras.layers.GlobalAveragePooling2D(),
    tf.keras.layers.Dense(256, activation='relu'),
    tf.keras.layers.Dropout(0.5),
    tf.keras.layers.Dense(num_classes, activation='softmax')
])

# Train on dermatology data
model.fit(train_data, epochs=50)

# Convert to Core ML
coreml_model = ct.convert(
    model,
    inputs=[ct.ImageType(shape=(1, 224, 224, 3))],
    classifier_config=ct.ClassifierConfig(class_labels)
)

# Save
coreml_model.save("RashClassifier.mlmodel")
```

## Step 2: Speech Recognition with Whisper

### Option A: WhisperKit (Recommended)

1. **Install WhisperKit**
   ```swift
   // Add to your project via Swift Package Manager
   // https://github.com/argmaxinc/WhisperKit

   dependencies: [
       .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.5.0")
   ]
   ```

2. **Update VoiceRecorder.swift**
   ```swift
   import WhisperKit

   class VoiceRecorder: ObservableObject {
       private var whisper: WhisperKit?

       func initializeWhisper() async {
           whisper = try? await WhisperKit(
               model: "small",  // or "base" for smaller size
               language: "auto"  // auto-detect or specify "es"/"my"
           )
       }

       func transcribeAudio(fileURL: URL) async throws -> String {
           guard let whisper = whisper else {
               throw WhisperError.modelNotLoaded
           }

           let result = try await whisper.transcribe(audioPath: fileURL.path)
           return result.text
       }

       func stopRecording(completion: @escaping (String) -> Void) {
           // Save audio to file
           let audioURL = saveAudioToFile()

           isRecording = false
           isProcessing = true

           Task {
               do {
                   let transcript = try await transcribeAudio(fileURL: audioURL)
                   await MainActor.run {
                       isProcessing = false
                       completion(transcript)
                   }
               } catch {
                   print("Transcription error: \(error)")
                   await MainActor.run {
                       isProcessing = false
                       completion("Error transcribing audio")
                   }
               }
           }
       }
   }
   ```

### Option B: Manual Whisper Core ML Integration

1. **Convert Whisper to Core ML**
   ```python
   import whisper
   import coremltools as ct
   from transformers import WhisperForConditionalGeneration

   # Load Whisper model
   model = WhisperForConditionalGeneration.from_pretrained("openai/whisper-small")

   # Export to ONNX then Core ML
   # (Simplified - actual process is complex)
   # See: https://github.com/openai/whisper/discussions/categories/core-ml
   ```

2. **Download Pre-converted Models**
   ```bash
   # Download from Hugging Face
   # https://huggingface.co/models?library=coreml&search=whisper

   # Add .mlpackage to Xcode project
   ```

## Step 3: Medical LLM Integration

### Option A: Phi-3 Mini with Core ML

1. **Convert Phi-3 to Core ML**
   ```python
   # Use Apple MLX or similar tools
   from transformers import AutoModelForCausalLM, AutoTokenizer
   import coremltools as ct

   model_name = "microsoft/Phi-3-mini-4k-instruct"
   model = AutoModelForCausalLM.from_pretrained(model_name)
   tokenizer = AutoTokenizer.from_pretrained(model_name)

   # Export to Core ML (requires Apple Silicon Mac)
   # Using mlx-lm or similar tools
   # This is a simplified example - actual process is complex
   ```

2. **Integrate in Swift**
   ```swift
   import CoreML

   class MedicalLLM {
       private var model: MLModel?

       init() {
           // Load Core ML LLM
           guard let modelURL = Bundle.main.url(forResource: "Phi3Mini", withExtension: "mlmodelc"),
                 let model = try? MLModel(contentsOf: modelURL) else {
               print("Failed to load LLM")
               return
           }
           self.model = model
       }

       func generate(prompt: String) async -> String {
           guard let model = model else { return "Model not loaded" }

           // Tokenize input
           let tokens = tokenize(prompt)

           // Create input
           let input = /* MLMultiArray from tokens */

           // Run inference
           guard let output = try? model.prediction(from: input) else {
               return "Inference failed"
           }

           // Decode output
           return decodeTokens(output)
       }
   }
   ```

### Option B: GGML/llama.cpp Integration

1. **Build llama.cpp for iOS**
   ```bash
   git clone https://github.com/ggerganov/llama.cpp
   cd llama.cpp

   # Build iOS framework
   mkdir build-ios
   cd build-ios
   cmake .. -DCMAKE_SYSTEM_NAME=iOS \
            -DCMAKE_OSX_ARCHITECTURES=arm64 \
            -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0
   make
   ```

2. **Create Swift Bridge**
   ```swift
   // Create bridging header
   #import "llama.h"

   // Swift wrapper
   class LlamaCPP {
       private var context: OpaquePointer?

       func loadModel(path: String) {
           let params = llama_context_default_params()
           context = llama_init_from_file(path, params)
       }

       func generate(prompt: String) -> String {
           // Tokenize and generate
           // Return decoded output
       }
   }
   ```

3. **Download Quantized Models**
   ```bash
   # Download GGUF models
   # Phi-3 Mini Q4_K_M (~2.5GB)
   # Llama 3.2 3B Q4_K_M (~2GB)

   # Add to Xcode as resource
   ```

### Option C: MLC LLM (Recommended for Production)

1. **Install MLC LLM**
   ```bash
   pip install mlc-llm mlc-ai-nightly
   ```

2. **Compile Model for iOS**
   ```bash
   mlc_llm compile \
       microsoft/Phi-3-mini-4k-instruct \
       --device iphone \
       --quantization q4f16_1 \
       -o Phi3-iOS
   ```

3. **Integrate in Xcode**
   ```swift
   // Add MLC LLM framework to project
   import MLCChat

   class MedicalLLMService {
       private var llm: MLCEngine?

       func initialize() async {
           llm = try? await MLCEngine(
               modelPath: "Phi3-iOS",
               modelLib: "phi-3-mini"
           )
       }

       func generateResponse(prompt: String) async -> String {
           guard let llm = llm else { return "Not initialized" }

           let messages = [
               Message(role: "system", content: "You are a medical AI assistant..."),
               Message(role: "user", content: prompt)
           ]

           let response = try? await llm.chat(messages: messages)
           return response?.content ?? "Error"
       }
   }
   ```

## Step 4: Optimize for iOS

### Model Quantization
```python
# Quantize models to reduce size
# 16-bit → 4-bit = 75% size reduction

import coremltools as ct

# Quantize Core ML model
spec = ct.utils.load_spec("model.mlmodel")
quantized = ct.models.neural_network.quantization_utils.quantize_weights(
    spec,
    nbits=4,  # 4-bit quantization
    quantization_mode="linear"
)
ct.utils.save_spec(quantized, "model_quantized.mlmodel")
```

### Memory Management
```swift
// Unload models when not in use
class AIModelManager {
    private var visionModel: VNCoreMLModel?
    private var llmModel: MLModel?

    func loadModels() async {
        // Load on demand
        visionModel = try? await loadVisionModel()
        llmModel = try? await loadLLMModel()
    }

    func unloadModels() {
        visionModel = nil
        llmModel = nil
        // Force memory cleanup
        autoreleasepool {}
    }
}
```

### Background Processing
```swift
// Use background tasks for model loading
import BackgroundTasks

func scheduleModelDownload() {
    let request = BGProcessingTaskRequest(identifier: "com.app.modeldownload")
    request.requiresNetworkConnectivity = true

    try? BGTaskScheduler.shared.submit(request)
}
```

## Step 5: Testing & Validation

### Unit Tests
```swift
class AIAnalyzerTests: XCTestCase {
    func testVisionAnalysis() async {
        let analyzer = AIAnalyzer()
        let testImage = UIImage(named: "test_rash")!

        let result = analyzer.performVisionAnalysis(image: testImage)

        XCTAssertNotNil(result)
        XCTAssertTrue(["low", "medium", "high"].contains(result.severity))
        XCTAssertGreaterThan(result.confidence, 0.5)
    }
}
```

### Performance Testing
```swift
import XCTest

class PerformanceTests: XCTestCase {
    func testInferenceSpeed() {
        let analyzer = AIAnalyzer()

        measure {
            let result = analyzer.analyzeRash(...)
            // Should complete in < 5 seconds
        }
    }
}
```

## Step 6: App Store Preparation

### Privacy Manifest
```xml
<!-- Add to Info.plist -->
<key>NSPrivacyTracking</key>
<false/>

<key>NSPrivacyTrackingDomains</key>
<array/>

<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>C617.1</string>
        </array>
    </dict>
</array>
```

### Medical Disclaimer
```swift
struct DisclaimerView: View {
    @Binding var accepted: Bool

    var body: some View {
        VStack {
            Text("Medical Disclaimer")
                .font(.title)

            Text("This app is for informational purposes only...")

            Button("I Understand") {
                accepted = true
            }
        }
    }
}
```

## Resources

### Model Sources
- **Hugging Face**: https://huggingface.co/models?library=coreml
- **Apple ML Gallery**: https://developer.apple.com/machine-learning/models/
- **MLC LLM Models**: https://mlc.ai/models

### Tools
- **Core ML Tools**: `pip install coremltools`
- **WhisperKit**: https://github.com/argmaxinc/WhisperKit
- **MLC LLM**: https://github.com/mlc-ai/mlc-llm
- **llama.cpp**: https://github.com/ggerganov/llama.cpp

### Documentation
- **Core ML**: https://developer.apple.com/documentation/coreml
- **Vision**: https://developer.apple.com/documentation/vision
- **Speech**: https://developer.apple.com/documentation/speech
- **AVFoundation**: https://developer.apple.com/av-foundation/

## Next Steps

1. Choose AI models based on device constraints
2. Convert models to Core ML format
3. Integrate models following guides above
4. Test extensively on physical devices
5. Validate medical accuracy with professionals
6. Submit to App Store

Good luck with your implementation! 🚀
