# New Features Configuration Guide

This document describes how to configure the newly added advanced features in the NutriVision AI iOS app.

## Overview of New Features

1. **Apple Health (HealthKit) Integration** - Sync nutrition data with Apple Health
2. **Push Notifications** - Meal and water reminders
3. **Barcode Scanner** - Scan packaged foods for instant nutrition info
4. **AR Portion Estimator** - Use AR to estimate food portions
5. **Widgets** - Home screen widgets for quick nutrition stats
6. **Siri Shortcuts** - Voice control for common actions

---

## 1. Info.plist Configuration

Add the following keys to your `Info.plist` file:

### Camera Permission (for Barcode Scanner & AR)
```xml
<key>NSCameraUsageDescription</key>
<string>NutriVision AI needs camera access to scan barcodes and estimate food portions using AR</string>
```

### Microphone Permission (for Voice Commands)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>NutriVision AI needs microphone access for voice commands and speech-to-text features</string>
```

### Speech Recognition Permission
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>NutriVision AI uses speech recognition to process your voice commands</string>
```

### HealthKit Permission
```xml
<key>NSHealthShareUsageDescription</key>
<string>NutriVision AI reads your nutrition data from Apple Health to provide personalized recommendations</string>

<key>NSHealthUpdateUsageDescription</key>
<string>NutriVision AI writes nutrition data to Apple Health to keep your health data in sync</string>
```

### Face ID (Optional for Biometric Authentication)
```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to securely access your nutrition data</string>
```

---

## 2. Capabilities Configuration

### In Xcode, enable the following capabilities:

#### HealthKit
1. Go to your project target
2. Select "Signing & Capabilities"
3. Click "+ Capability"
4. Add "HealthKit"

#### Push Notifications
1. Click "+ Capability"
2. Add "Push Notifications"

#### App Groups (for Widgets)
1. Click "+ Capability"
2. Add "App Groups"
3. Create app group: `group.com.nutrivision.ai`

#### Siri
1. Click "+ Capability"
2. Add "Siri"

---

## 3. Widget Extension Setup

### Create Widget Extension:
```bash
File → New → Target → Widget Extension
Name: NutriVisionWidget
```

### Add to App Group:
1. Select NutriVisionWidget target
2. Add "App Groups" capability
3. Enable `group.com.nutrivision.ai`

### Share HealthKit Manager:
Make sure `HealthKitManager.swift` is included in both the main app and widget targets.

---

## 4. Intent Definition (for Siri Shortcuts)

### Create Intents Definition File:
```bash
File → New → File → SiriKit Intent Definition File
Name: Intents.intentdefinition
```

### Add Custom Intents:

#### LogMealIntent
- **Name**: LogMealIntent
- **Category**: Log
- **Title**: Log Meal
- **Description**: Log a meal with nutrition information
- **Parameters**:
  - `mealType` (String): breakfast, lunch, dinner, snack
  - `calories` (Integer): Calories consumed
  - `protein` (Double, optional): Protein in grams
  - `carbs` (Double, optional): Carbs in grams
  - `fat` (Double, optional): Fat in grams
- **Suggested Phrase**: "Log my ${mealType}"

#### GetNutritionIntent
- **Name**: GetNutritionIntent
- **Category**: Information
- **Title**: Get Nutrition Stats
- **Description**: Get today's nutrition statistics
- **Suggested Phrase**: "Show my nutrition"

#### LogWaterIntent
- **Name**: LogWaterIntent
- **Category**: Log
- **Title**: Log Water
- **Description**: Log water intake
- **Parameters**:
  - `amount` (Double): Amount in milliliters
- **Suggested Phrase**: "Log water"

#### FindRecipeIntent
- **Name**: FindRecipeIntent
- **Category**: Search
- **Title**: Find Recipe
- **Description**: Search for recipes
- **Parameters**:
  - `query` (String): Search query
- **Suggested Phrase**: "Find ${query} recipe"

---

## 5. Intents Extension Setup (Optional)

### Create Intents Extension:
```bash
File → New → Target → Intents Extension
Name: NutriVisionIntents
```

This allows Siri to execute intents in the background.

---

## 6. App Transport Security (for API calls)

If your backend doesn't use HTTPS, add to Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note**: For production, use HTTPS only!

---

## 7. ARKit Configuration

ARKit requires:
- iOS 11.0 or later
- A device with an A9 processor or later
- Camera permission (already added above)

### Add to Info.plist:
```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arkit</string>
</array>
```

---

## 8. Background Modes (for Notifications)

Enable background modes:
1. Select your target
2. Signing & Capabilities
3. "+ Capability" → Background Modes
4. Check: "Remote notifications"

---

## 9. Notification Categories

The `NotificationManager` automatically registers these categories:
- **MEAL_REMINDER**: Breakfast, lunch, dinner reminders
  - Actions: Log Meal, Snooze, Dismiss
- **WATER_REMINDER**: Hydration reminders
  - Actions: Log Water, Dismiss

---

## 10. File Structure

Ensure these files are in your project:

```
NutriVisionAI/
├── Services/
│   ├── HealthKitManager.swift          ✓ Created
│   ├── NotificationManager.swift       ✓ Created
│   └── ShortcutsManager.swift          ✓ Created
├── Views/
│   ├── Barcode/
│   │   └── BarcodeScannerView.swift    ✓ Created
│   ├── AR/
│   │   └── ARPortionEstimatorView.swift ✓ Created
│   └── Home/
│       └── HomeView.swift              ✓ Updated
├── Intents/
│   └── IntentHandler.swift             ✓ Created
└── Info.plist                          ⚠ Needs configuration

NutriVisionWidget/
└── NutriVisionWidget.swift             ✓ Created
```

---

## 11. Testing

### HealthKit Testing:
1. Run on a real device (HealthKit doesn't work in simulator)
2. Go to Settings → Enable Apple Health Sync
3. Grant permissions in Health app

### Notifications Testing:
1. Enable meal/water reminders in Settings
2. Wait for scheduled times or trigger manually
3. Test notification actions

### Barcode Scanner Testing:
1. Use real products with barcodes
2. Ensure camera permission granted
3. Test with various barcode formats (EAN-13, UPC, Code128)

### AR Portion Estimator Testing:
1. Requires A9+ device
2. Good lighting conditions
3. Horizontal surfaces for plane detection

### Widgets Testing:
1. Long press on home screen
2. Tap "+" button
3. Search for "NutriVision"
4. Add widget

### Siri Shortcuts Testing:
1. Say "Hey Siri, log my breakfast"
2. Or go to Settings → Siri & Search → NutriVision AI
3. Add shortcuts manually

---

## 12. Required Frameworks

Make sure these frameworks are linked:

- **HealthKit.framework**
- **UserNotifications.framework**
- **Intents.framework**
- **IntentsUI.framework** (for Shortcuts UI)
- **AVFoundation.framework** (for camera/barcode)
- **Vision.framework** (for barcode detection)
- **ARKit.framework** (for AR features)
- **WidgetKit.framework** (for widgets)
- **Speech.framework** (for speech recognition)

These are automatically linked when you import them in Swift.

---

## 13. Minimum iOS Version

Update minimum deployment target to **iOS 14.0** for:
- Widgets (requires iOS 14+)
- Modern Intents API

In Xcode:
1. Select project
2. Select target
3. General → Deployment Info → iOS 14.0

---

## 14. Backend API Requirements

### New Endpoints Needed:

```
POST /ai/barcode
Body: { "barcode": "012345678901" }
Response: {
    "name": "Product Name",
    "brand": "Brand Name",
    "servingSize": "100g",
    "calories": 250,
    "protein": 10.5,
    "carbs": 30.0,
    "fat": 8.5,
    "fiber": 2.0,
    "sugar": 5.0,
    "sodium": 200.0,
    "imageUrl": "https://..."
}
```

You can integrate with Open Food Facts API or similar barcode databases.

---

## 15. Privacy & App Store Requirements

### Privacy Manifest (PrivacyInfo.xcprivacy):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeHealthAndFitness</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

---

## 16. Quick Start Commands

After configuration, build and run:

```bash
# Clean build folder
⌘ + Shift + K

# Build
⌘ + B

# Run on device
⌘ + R
```

---

## 17. Troubleshooting

### HealthKit not working:
- ✓ Check real device (not simulator)
- ✓ Verify capabilities enabled
- ✓ Check Info.plist permissions
- ✓ Request authorization in app

### Notifications not appearing:
- ✓ Check notification permissions
- ✓ Verify background modes enabled
- ✓ Test on real device
- ✓ Check Do Not Disturb status

### Barcode scanner not working:
- ✓ Camera permission granted
- ✓ Good lighting
- ✓ Supported barcode format
- ✓ Backend API implemented

### AR not working:
- ✓ A9+ processor device
- ✓ Good lighting
- ✓ Horizontal surface visible
- ✓ ARKit capability enabled

### Widgets not updating:
- ✓ App Groups configured
- ✓ Widget timeline policy correct
- ✓ Shared frameworks linked
- ✓ Force refresh widget

### Siri shortcuts not working:
- ✓ Siri capability enabled
- ✓ Intents definition file created
- ✓ Shortcuts donated in app
- ✓ Test with "Hey Siri"

---

## 18. Feature Flags (Optional)

You can disable features if not needed:

```swift
struct FeatureFlags {
    static let healthKitEnabled = true
    static let notificationsEnabled = true
    static let barcodeEnabled = true
    static let arEnabled = true
    static let widgetsEnabled = true
    static let siriShortcutsEnabled = true
}
```

---

## Summary

All new features are now integrated and ready to use! Follow this guide to:

1. Configure Info.plist permissions
2. Enable capabilities in Xcode
3. Set up widget and intents extensions
4. Implement backend barcode API
5. Test on real devices
6. Submit to App Store

For questions or issues, refer to Apple's documentation:
- [HealthKit](https://developer.apple.com/healthkit/)
- [UserNotifications](https://developer.apple.com/notifications/)
- [ARKit](https://developer.apple.com/arkit/)
- [WidgetKit](https://developer.apple.com/widgetkit/)
- [SiriKit](https://developer.apple.com/siri/)
