# NutriVision AI - iOS Swift Mobile App

A comprehensive iOS mobile application for NutriVision AI, featuring food image analysis, BLIP-powered visual question answering, speech recognition, multi-language support, meal planning, and personalized nutrition tracking.

## 📱 Features

### Core Features
- ✅ **User Authentication** - Secure login/register with JWT tokens
- ✅ **Health Profile** - Track weight, height, age, allergies, dietary restrictions
- ✅ **Food Image Analysis** - Vision AI and BLIP for food recognition
- ✅ **Image Captioning** - Natural language descriptions of food using BLIP
- ✅ **Visual Q&A** - Ask questions about food images with BLIP-VQA
- ✅ **Recipe Discovery** - Search and browse recipes with semantic similarity
- ✅ **Meal Planning** - AI-generated personalized meal plans
- ✅ **Nutrition Tracking** - Daily calorie and macro tracking
- ✅ **Shopping Lists** - Smart shopping list generation with MCP
- ✅ **Voice Commands** - Hands-free control with speech recognition
- ✅ **Multi-language** - Support for 6 languages (EN, ZH, JA, KO, TH, MY)
- ✅ **Text-to-Speech** - Recipe narration and voice guidance
- ✅ **Social Sharing** - Share meals and recipes with community
- ✅ **Video Recommendations** - Cooking videos from YouTube and social media

## 🏗️ Project Structure

```
NutriVisionAI/
├── NutriVisionAIApp.swift          # Main app entry point
├── Info.plist                       # App configuration
│
├── Models/                          # Data models
│   ├── User.swift                   # User model with enums
│   ├── Recipe.swift                 # Recipe, Meal, Ingredient models
│   ├── Speech.swift                 # Speech and language models
│   └── Video.swift                  # Video models
│
├── Services/                        # Business logic and API
│   ├── APIClient.swift              # Network layer
│   ├── TokenManager.swift           # Secure token storage
│   ├── AuthService.swift            # Authentication service
│   ├── RecipeService.swift          # Recipe operations
│   ├── AIService.swift              # AI features (BLIP, Vision)
│   ├── SpeechService.swift          # Speech recognition & TTS
│   ├── MealPlanService.swift        # Meal planning
│   └── ImagePickerService.swift     # Camera/gallery access
│
├── ViewModels/                      # MVVM ViewModels
│   ├── AuthenticationViewModel.swift
│   ├── HomeViewModel.swift
│   ├── RecipeViewModel.swift
│   ├── MealPlanViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── AIFeaturesViewModel.swift
│   ├── SpeechViewModel.swift
│   └── ShoppingViewModel.swift
│
├── Views/                           # SwiftUI Views
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   ├── RegisterView.swift
│   │   ├── OnboardingView.swift
│   │   └── HealthProfileSetupView.swift
│   │
│   ├── Home/
│   │   ├── MainTabView.swift
│   │   ├── HomeView.swift
│   │   ├── DashboardView.swift
│   │   └── StatsCardView.swift
│   │
│   ├── Features/
│   │   ├── Recipes/
│   │   │   ├── RecipeListView.swift
│   │   │   ├── RecipeDetailView.swift
│   │   │   ├── RecipeSearchView.swift
│   │   │   └── RecipeFilterView.swift
│   │   │
│   │   ├── AI/
│   │   │   ├── FoodScannerView.swift
│   │   │   ├── BLIPCaptionView.swift
│   │   │   ├── BLIPVQAView.swift
│   │   │   ├── ChatAssistantView.swift
│   │   │   └── AIAnalysisResultView.swift
│   │   │
│   │   ├── MealPlan/
│   │   │   ├── MealPlanView.swift
│   │   │   ├── MealPlanGeneratorView.swift
│   │   │   ├── MealCalendarView.swift
│   │   │   └── MealDetailView.swift
│   │   │
│   │   ├── Speech/
│   │   │   ├── VoiceCommandView.swift
│   │   │   ├── LanguageSelectionView.swift
│   │   │   ├── RecipeNarrationView.swift
│   │   │   └── TranslationView.swift
│   │   │
│   │   ├── Shopping/
│   │   │   ├── ShoppingListView.swift
│   │   │   ├── ShoppingListDetailView.swift
│   │   │   └── ShoppingListGeneratorView.swift
│   │   │
│   │   ├── Journal/
│   │   │   ├── JournalView.swift
│   │   │   ├── JournalEntryView.swift
│   │   │   └── MoodTrackerView.swift
│   │   │
│   │   ├── Social/
│   │   │   ├── SocialFeedView.swift
│   │   │   ├── PostDetailView.swift
│   │   │   └── CreatePostView.swift
│   │   │
│   │   └── Videos/
│   │       ├── VideoListView.swift
│   │       ├── VideoPlayerView.swift
│   │       └── TrendingVideosView.swift
│   │
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── EditProfileView.swift
│   │   ├── HealthMetricsView.swift
│   │   ├── SettingsView.swift
│   │   └── AboutView.swift
│   │
│   └── Components/                  # Reusable UI components
│       ├── LoadingView.swift
│       ├── ErrorView.swift
│       ├── ImagePicker.swift
│       ├── CameraView.swift
│       ├── RecordingButton.swift
│       ├── LanguagePicker.swift
│       ├── DietaryBadge.swift
│       ├── NutritionCard.swift
│       ├── RecipeCard.swift
│       └── CustomButton.swift
│
├── Utilities/                       # Helper functions
│   ├── Config.swift                 # Configuration constants
│   ├── Extensions.swift             # Swift extensions
│   ├── ImageUtils.swift             # Image processing
│   ├── DateUtils.swift              # Date formatting
│   └── ValidationUtils.swift        # Input validation
│
└── Resources/                       # Assets
    ├── Colors.xcassets
    ├── Images.xcassets
    └── Localizable.strings
```

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
- Active backend server (see backend setup)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/nutrivision-ai.git
   cd nutrivision-ai/ios-app/NutriVisionAI
   ```

2. **Configure API endpoint**

   Edit `Utilities/Config.swift`:
   ```swift
   static let baseURL = "http://your-backend-url:8000"
   ```

3. **Open in Xcode**
   ```bash
   open NutriVisionAI.xcodeproj
   ```

4. **Install dependencies** (if using SPM)
   - In Xcode: File > Add Packages
   - Add any required packages

5. **Run the app**
   - Select a simulator or device
   - Press Cmd+R to build and run

## 📦 Dependencies

### Swift Package Manager

Add these packages to your project:

```swift
// Optional: Enhanced UI components
dependencies: [
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.0"),
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
]
```

## 🎨 UI Components

### Main Tab View Structure

```swift
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }

            FoodScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }

            MealPlanView()
                .tabItem {
                    Label("Meals", systemImage: "calendar")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
```

### Food Scanner View (Camera + BLIP)

```swift
struct FoodScannerView: View {
    @StateObject private var viewModel = AIFeaturesViewModel()
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var showResults = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Camera/Gallery buttons
                HStack(spacing: 20) {
                    Button(action: { showCamera = true }) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                            Text("Take Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button(action: { /* Show photo picker */ }) {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.largeTitle)
                            Text("Choose Photo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()

                // Selected image preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding()

                    // Analysis buttons
                    VStack(spacing: 12) {
                        Button("Generate Caption") {
                            Task {
                                await viewModel.generateCaption(image: image)
                                showResults = true
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Comprehensive Analysis") {
                            Task {
                                await viewModel.analyzeFoodWithBLIP(image: image)
                                showResults = true
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Spacer()
            }
            .navigationTitle("Food Scanner")
            .sheet(isPresented: $showCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showResults) {
                AIAnalysisResultView(viewModel: viewModel)
            }
        }
    }
}
```

### Voice Command View

```swift
struct VoiceCommandView: View {
    @StateObject private var speechViewModel = SpeechViewModel()
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 30) {
            // Language selector
            Picker("Language", selection: $speechViewModel.selectedLanguage) {
                ForEach(Language.allCases, id: \.self) { language in
                    Text("\(language.flag) \(language.displayName)")
                        .tag(language)
                }
            }
            .pickerStyle(.menu)
            .padding()

            // Recording button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)

                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }

            // Transcription result
            if let transcription = speechViewModel.transcription {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transcription:")
                        .font(.headline)

                    Text(transcription.text)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    if let intent = transcription.intent {
                        HStack {
                            Text("Intent:")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text(intent)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Voice Commands")
        .padding()
    }

    private func toggleRecording() {
        if isRecording {
            speechViewModel.stopRecording()
        } else {
            speechViewModel.startRecording()
        }
        isRecording.toggle()
    }
}
```

## 📡 API Integration Examples

### Recipe Service

```swift
class RecipeService {
    private let apiClient = APIClient.shared

    func searchRecipes(query: String) async throws -> [Recipe] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.searchRecipes)?query=\(query)",
            method: "GET"
        )
    }

    func getRecipeDetails(id: Int) async throws -> Recipe {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.recipes)/\(id)",
            method: "GET"
        )
    }

    func findSimilarRecipes(recipeId: Int) async throws -> [Recipe] {
        return try await apiClient.request(
            endpoint: "\(Config.Endpoints.similarRecipes)/\(recipeId)",
            method: "GET"
        )
    }
}
```

### AI Service (BLIP Integration)

```swift
class AIService {
    private let apiClient = APIClient.shared

    func generateCaption(imageData: Data) async throws -> BlipCaptionResponse {
        let base64Image = imageData.base64EncodedString()
        let request = ["image_data": "data:image/jpeg;base64,\(base64Image)"]

        return try await apiClient.request(
            endpoint: Config.Endpoints.blipCaption,
            method: "POST",
            body: request
        )
    }

    func answerVisualQuestion(
        imageData: Data,
        question: String
    ) async throws -> BlipVQAResponse {
        let base64Image = imageData.base64EncodedString()
        let request = [
            "image_data": "data:image/jpeg;base64,\(base64Image)",
            "question": question
        ]

        return try await apiClient.request(
            endpoint: Config.Endpoints.blipVQA,
            method: "POST",
            body: request
        )
    }

    func analyzeFoodWithBLIP(imageData: Data) async throws -> BlipFoodAnalysisResponse {
        return try await apiClient.uploadImage(
            endpoint: Config.Endpoints.blipAnalyze,
            image: imageData
        )
    }
}
```

### Speech Service

```swift
class SpeechService {
    private let apiClient = APIClient.shared

    func transcribeAudio(audioData: Data, language: String?) async throws -> TranscriptionResponse {
        let base64Audio = audioData.base64EncodedString()
        let request = [
            "audio_base64": base64Audio,
            "language": language ?? "en"
        ]

        return try await apiClient.request(
            endpoint: Config.Endpoints.transcribe,
            method: "POST",
            body: request
        )
    }

    func synthesizeSpeech(text: String, language: String) async throws -> Data {
        let request = [
            "text": text,
            "language": language
        ]

        let response: SynthesisResponse = try await apiClient.request(
            endpoint: Config.Endpoints.synthesize,
            method: "POST",
            body: request
        )

        // Decode base64 audio
        guard let audioData = Data(base64Encoded: response.audioBase64) else {
            throw APIError.decodingFailed(NSError(domain: "", code: -1))
        }

        return audioData
    }

    func processVoiceCommand(audioData: Data, language: String) async throws -> VoiceCommandResponse {
        let base64Audio = audioData.base64EncodedString()
        let request = [
            "audio_base64": base64Audio,
            "user_language": language
        ]

        return try await apiClient.request(
            endpoint: Config.Endpoints.voiceCommand,
            method: "POST",
            body: request
        )
    }
}
```

## 🎯 Key Features Implementation

### 1. BLIP Image Captioning

**ViewModel:**
```swift
@MainActor
class AIFeaturesViewModel: ObservableObject {
    @Published var caption: String?
    @Published var isAnalyzing = false
    @Published var error: String?

    private let aiService = AIService()

    func generateCaption(image: UIImage) async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            error = "Failed to process image"
            return
        }

        do {
            let response = try await aiService.generateCaption(imageData: imageData)
            caption = response.caption
        } catch {
            self.error = error.localizedDescription
        }
    }
}
```

### 2. Voice Commands with Intent Detection

**ViewModel:**
```swift
@MainActor
class SpeechViewModel: ObservableObject {
    @Published var transcription: VoiceCommandResponse?
    @Published var selectedLanguage: Language = .en
    @Published var isRecording = false

    private let speechService = SpeechService()
    private var audioRecorder: AVAudioRecorder?

    func startRecording() {
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .default)
        try? audioSession.setActive(true)

        // Start recording
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
        audioRecorder = try? AVAudioRecorder(url: tempURL, settings: settings)
        audioRecorder?.record()
        isRecording = true
    }

    func stopRecording() async {
        audioRecorder?.stop()
        isRecording = false

        guard let url = audioRecorder?.url,
              let audioData = try? Data(contentsOf: url) else {
            return
        }

        do {
            transcription = try await speechService.processVoiceCommand(
                audioData: audioData,
                language: selectedLanguage.rawValue
            )

            // Handle intent
            handleIntent(transcription!)
        } catch {
            print("Transcription failed: \(error)")
        }
    }

    private func handleIntent(_ response: VoiceCommandResponse) {
        switch response.intent {
        case "search_recipe":
            if let query = response.parameters["query"] as? String {
                // Navigate to recipe search with query
            }
        case "create_meal_plan":
            // Navigate to meal plan generator
            break
        case "get_nutrition_info":
            // Show nutrition info
            break
        default:
            break
        }
    }
}
```

### 3. Multi-language Support

**Extensions:**
```swift
extension View {
    func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

// Localizable.strings files for each language
// en.lproj/Localizable.strings
"welcome" = "Welcome to NutriVision AI";
"scan_food" = "Scan Food";

// zh.lproj/Localizable.strings
"welcome" = "欢迎来到NutriVision AI";
"scan_food" = "扫描食物";
```

## 🔐 Security Best Practices

1. **Token Storage**
   - Tokens stored in iOS Keychain (encrypted)
   - Automatic token refresh on expiration
   - Secure deletion on logout

2. **API Communication**
   - HTTPS only in production
   - Certificate pinning (optional)
   - Request/response validation

3. **Data Privacy**
   - User data encrypted at rest
   - Secure photo storage
   - GDPR compliance ready

## 🧪 Testing

### Unit Tests

```swift
import XCTest
@testable import NutriVisionAI

class APIClientTests: XCTestCase {
    func testLoginRequest() async throws {
        let client = APIClient.shared
        // Mock request
        let response: LoginResponse = try await client.request(
            endpoint: Config.Endpoints.login,
            method: "POST",
            body: LoginRequest(username: "test", password: "test")
        )

        XCTAssertNotNil(response.accessToken)
    }
}
```

## 📱 Screenshots & Demo

### Main Features
- Home Dashboard with nutrition stats
- Recipe browser with semantic search
- Food scanner with BLIP analysis
- Voice commands in 6 languages
- Meal planning calendar
- Shopping list generator
- Social feed for sharing

## 🚧 Future Enhancements

- [ ] Offline mode with CoreData
- [ ] Apple Watch companion app
- [ ] Widgets for quick stats
- [ ] Siri Shortcuts integration
- [ ] AR food portion estimation
- [ ] Barcode scanner for packaged foods
- [ ] Integration with Apple Health
- [ ] Push notifications for meal reminders
- [ ] Dark mode customization
- [ ] iPad optimization

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- GitHub Issues: [https://github.com/yourusername/nutrivision-ai/issues](https://github.com/yourusername/nutrivision-ai/issues)
- Email: support@nutrivision.ai

## 🙏 Acknowledgments

- **OpenAI Whisper** - Speech recognition
- **Salesforce BLIP** - Image captioning and VQA
- **FastAPI** - Backend framework
- **SwiftUI** - Modern iOS UI framework

---

**Built with ❤️ for healthier living through AI**
