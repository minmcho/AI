# Privacy Permissions Setup

## Required iOS Privacy Permissions

Since we're using a modern iOS app structure, you need to add privacy permission descriptions directly in Xcode.

---

## 📋 How to Add Privacy Permissions in Xcode

### Step 1: Open Your Project
1. Open your Xcode project
2. Click on the **project name** in the Project Navigator (left sidebar)
3. Select the **HealthRashAI** target (under TARGETS)

### Step 2: Go to Info Tab
1. Click the **Info** tab at the top
2. You'll see a list called **Custom iOS Target Properties**

### Step 3: Add Privacy Keys

Click the **+** button next to any existing key to add new keys.

Add these **4 privacy permission keys**:

---

### 1. Camera Permission

**Key Name:** `Privacy - Camera Usage Description`
**Type:** `String`
**Value:**
```
We need camera access to capture photos of skin rashes for AI-powered medical analysis. All processing is done locally on your device for complete privacy.
```

**OR use the raw key:** `NSCameraUsageDescription`

---

### 2. Microphone Permission

**Key Name:** `Privacy - Microphone Usage Description`
**Type:** `String`
**Value:**
```
We need microphone access to record your questions about the skin rash. Voice recordings are processed locally and never sent to external servers.
```

**OR use the raw key:** `NSMicrophoneUsageDescription`

---

### 3. Speech Recognition Permission

**Key Name:** `Privacy - Speech Recognition Usage Description`
**Type:** `String`
**Value:**
```
We need speech recognition to convert your spoken questions into text. All processing happens on your device to maintain your privacy.
```

**OR use the raw key:** `NSSpeechRecognitionUsageDescription`

---

### 4. Photo Library Permission (Optional)

**Key Name:** `Privacy - Photo Library Additions Usage Description`
**Type:** `String`
**Value:**
```
We need permission to save analysis results to your photo library if you choose to export them.
```

**OR use the raw key:** `NSPhotoLibraryAddUsageDescription`

---

## 🎯 Visual Guide

In Xcode's Info tab, it should look like this:

```
Custom iOS Target Properties
├─ Privacy - Camera Usage Description               (String) We need camera access to...
├─ Privacy - Microphone Usage Description           (String) We need microphone access to...
├─ Privacy - Speech Recognition Usage Description   (String) We need speech recognition to...
└─ Privacy - Photo Library Additions Usage Description (String) We need permission to save...
```

---

## ✅ Verification

After adding all 4 keys:

1. **Build** your project (⌘+B)
2. **Run** the app (⌘+R)
3. When you first use camera/microphone, iOS will show your permission dialog with the descriptions

---

## 🔍 Troubleshooting

### Can't find "Privacy - Camera Usage Description"?

If Xcode doesn't auto-complete the key name:
1. Type the raw key instead: `NSCameraUsageDescription`
2. Set Type to `String`
3. Add your description

### Keys not showing up?

1. Make sure you're in the **Info** tab (not Build Settings)
2. Look for **Custom iOS Target Properties** section
3. Click the **+** button to add new entries

---

## 📱 What Happens When You Run

When your app first tries to access:

- **Camera**: iOS shows alert: "HealthRashAI Would Like to Access the Camera" + your description
- **Microphone**: iOS shows alert: "HealthRashAI Would Like to Access the Microphone" + your description
- **Speech Recognition**: iOS shows alert: "HealthRashAI Would Like to Use Speech Recognition" + your description

Users can Allow or Don't Allow. Your app handles permissions via the CameraManager and VoiceRecorder classes.

---

## 🚀 After Setup

Once you've added all 4 privacy keys:

✅ Build will succeed
✅ App will run without permission errors
✅ Camera and microphone will work properly
✅ Users will see clear permission dialogs

**Total time: ~2 minutes**
