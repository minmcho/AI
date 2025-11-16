# NutriVision AI iOS App - Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Prerequisites
```bash
# Check your Xcode version
xcodebuild -version
# Requires: Xcode 15.0+

# Ensure backend is running
cd ../backend
uvicorn app.main:app --reload
# Backend should be running at http://localhost:8000
```

### Step 2: Configure API Endpoint

Edit `Utilities/Config.swift`:
```swift
// For simulator (localhost)
static let baseURL = "http://localhost:8000"

// For device (use your computer's IP)
static let baseURL = "http://192.168.1.XXX:8000"

// For production
static let baseURL = "https://api.nutrivision.ai"
```

### Step 3: Create Xcode Project

1. **Open Xcode**
2. **Create New Project**:
   - Choose "App" template
   - Product Name: `NutriVisionAI`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 16.0

3. **Add Files**:
   - Drag all source files into the project
   - Make sure "Copy items if needed" is checked
   - Add to target: NutriVisionAI

### Step 4: Configure Info.plist

Add these keys for permissions:
- **NSCameraUsageDescription**: "We need camera access to analyze your food images"
- **NSPhotoLibraryUsageDescription**: "We need photo library access to select food images"
- **NSMicrophoneUsageDescription**: "We need microphone access for voice commands"
- **NSSpeechRecognitionUsageDescription**: "We use speech recognition for voice commands"

### Step 5: Run the App

1. Select a simulator or connected device
2. Press **Cmd+R** or click the Play button
3. The app will build and launch

## 📝 First Time Use

### Register a New Account

1. Launch the app
2. Tap "Create Account"
3. Fill in your details:
   - Email
   - Username
   - Password
   - Age, height, weight (optional)
   - Dietary restrictions (optional)
   - Health goals (optional)

4. Tap "Register"
5. You'll be logged in automatically

### Explore Features

#### 1. Scan Food
- Tap camera icon in top right
- Take a photo or choose from library
- Get instant analysis with BLIP

#### 2. Voice Commands
- Navigate to Profile tab
- Tap "Voice Commands"
- Select your language
- Tap and hold to record
- Say: "Find recipe for pasta carbonara"

#### 3. Browse Recipes
- Go to Recipes tab
- Search or browse categories
- Tap a recipe for details
- Save to favorites

#### 4. Create Meal Plan
- Go to Meals tab
- Tap "Generate Meal Plan"
- AI will create a personalized plan
- View calendar of meals

## 🎯 API Endpoints Test

Test your backend connection:

```swift
// In Xcode console, add this to ContentView.onAppear:
Task {
    do {
        let response: [String: Any] = try await APIClient.shared.request(
            endpoint: "/",
            method: "GET",
            requiresAuth: false
        )
        print("✅ Backend connected:", response)
    } catch {
        print("❌ Backend error:", error)
    }
}
```

## 🔧 Troubleshooting

### "Could not connect to server"
- Check backend is running
- Verify `Config.baseURL` is correct
- For device: use your computer's IP address
- Ensure firewall allows connections

### "Unauthorized" errors
- Token might be expired
- Try logging out and back in
- Check TokenManager is saving tokens

### Camera not working
- Check Info.plist has camera permissions
- Grant permission when prompted
- Restart app after granting

### Build errors
- Clean build folder: Cmd+Shift+K
- Delete Derived Data
- Restart Xcode
- Update to latest Xcode

## 📱 Testing Features

### Test Image Analysis

```swift
// Use sample food images
let testImages = [
    "https://example.com/pasta.jpg",
    "https://example.com/salad.jpg"
]

// Test BLIP caption generation
await aiViewModel.generateCaption(image: testImage)
print(aiViewModel.caption)

// Test BLIP VQA
await aiViewModel.answerQuestion(
    image: testImage,
    question: "What type of food is this?"
)
```

### Test Voice Commands

Supported voice commands in English:
- "Find recipe for [food]"
- "Create a meal plan for 7 days"
- "How many calories in [food]?"
- "Add [item] to shopping list"
- "Log my breakfast"

### Test Multi-language

Change language:
```swift
// In app
Profile > Settings > Language > 中文 (Chinese)

// Voice commands now work in Chinese:
"找鸡肉食谱" → "Find chicken recipe"
"一周饮食计划" → "Create weekly meal plan"
```

## 🎨 Customization

### Change Theme Colors

Edit colors in `Utilities/Extensions.swift`:
```swift
extension Color {
    static let primary = Color.blue
    static let secondary = Color.purple
    static let accent = Color.orange
}
```

### Modify UI Layout

Edit `Utilities/Config.swift`:
```swift
struct UI {
    static let cornerRadius: CGFloat = 16  // Rounded corners
    static let padding: CGFloat = 20       // Spacing
    static let iconSize: CGFloat = 28      // Icon sizes
}
```

## 📊 Sample Data

Create test users with different profiles:

```
User 1: Weight Loss
- Email: test1@example.com
- Goal: Lose 10 kg
- Restrictions: Vegetarian
- Target: 1500 cal/day

User 2: Muscle Gain
- Email: test2@example.com
- Goal: Build muscle
- Restrictions: High protein
- Target: 2500 cal/day

User 3: General Health
- Email: test3@example.com
- Goal: Maintain weight
- Restrictions: Gluten-free
- Target: 2000 cal/day
```

## 🚀 Next Steps

1. **Complete Profile**
   - Add your health metrics
   - Set dietary preferences
   - Choose health goals

2. **Try AI Features**
   - Scan a food image
   - Ask questions about food
   - Generate captions

3. **Create Meal Plan**
   - Use AI to generate personalized plan
   - View weekly calendar
   - Add custom meals

4. **Enable Voice**
   - Set up voice commands
   - Try different languages
   - Use hands-free cooking mode

5. **Social Features**
   - Share your meals
   - Browse community posts
   - Save favorite recipes

## 📖 Additional Resources

- **Full Documentation**: See `README.md`
- **API Reference**: `../API_ENDPOINTS.md`
- **Backend Setup**: `../SETUP.md`
- **Architecture**: `../ARCHITECTURE.md`

## 🆘 Getting Help

**Common Issues:**
- [Backend not starting](#troubleshooting)
- [Camera permission denied](#troubleshooting)
- [Login not working](#troubleshooting)

**Support Channels:**
- GitHub Issues: Report bugs
- Discord: Community support
- Email: support@nutrivision.ai

---

**🎉 You're all set! Start exploring NutriVision AI and enjoy your AI-powered nutrition journey!**
