#!/bin/bash

# Health Rash AI - Xcode Project Setup Script
# This script creates a proper Xcode project structure

set -e  # Exit on error

echo "🏥 Health Rash AI - Xcode Project Setup"
echo "========================================"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_NAME="HealthRashAI"
BUNDLE_ID="com.healthrash.HealthRashAI"

cd "$SCRIPT_DIR"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed"
    echo "Please install Xcode from the Mac App Store"
    exit 1
fi

echo "✅ Xcode found"
echo ""

# Check if xcodeproj already exists
if [ -d "${PROJECT_NAME}.xcodeproj" ]; then
    echo "⚠️  Warning: ${PROJECT_NAME}.xcodeproj already exists"
    read -p "Do you want to delete it and create a new one? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing project..."
        rm -rf "${PROJECT_NAME}.xcodeproj"
    else
        echo "Aborting..."
        exit 1
    fi
fi

echo "📁 Creating Xcode project structure..."

# Create a temporary directory for the template
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Create the Xcode project using xcodebuild
# We'll create a minimal project and then add our files

cat > "$TEMP_DIR/project.yml" << EOF
name: $PROJECT_NAME
options:
  bundleIdPrefix: com.healthrash
  deploymentTarget:
    iOS: 16.0
settings:
  PRODUCT_NAME: $PROJECT_NAME
  PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
  SWIFT_VERSION: 5.9
  IPHONEOS_DEPLOYMENT_TARGET: 16.0
targets:
  $PROJECT_NAME:
    type: application
    platform: iOS
    deploymentTarget: "16.0"
    sources:
      - $PROJECT_NAME
    settings:
      INFOPLIST_FILE: $PROJECT_NAME/Info.plist
      PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
    scheme:
      testTargets: []
EOF

# Check if xcodegen is installed
if command -v xcodegen &> /dev/null; then
    echo "✅ Using xcodegen to create project..."
    xcodegen generate
    echo "✅ Xcode project created successfully!"
else
    echo "⚠️  xcodegen not found. Using manual method..."
    echo ""
    echo "📝 Please follow these manual steps:"
    echo ""
    echo "1. Open Xcode"
    echo "2. File → New → Project"
    echo "3. Select: iOS → App"
    echo "4. Configure:"
    echo "   - Product Name: HealthRashAI"
    echo "   - Bundle Identifier: com.healthrash.HealthRashAI"
    echo "   - Interface: SwiftUI"
    echo "   - Language: Swift"
    echo "5. Save to: $SCRIPT_DIR"
    echo "6. Delete default ContentView.swift and HealthRashAIApp.swift"
    echo "7. Add all files from HealthRashAI folder to project"
    echo ""
    echo "📖 See SETUP_GUIDE.md for detailed instructions"
    echo ""
    read -p "Press Enter once you've created the project in Xcode..."
fi

# Open in Xcode if project exists
if [ -d "${PROJECT_NAME}.xcodeproj" ]; then
    echo ""
    echo "🚀 Opening project in Xcode..."
    open "${PROJECT_NAME}.xcodeproj"
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "📝 Next steps:"
    echo "1. Select a simulator or device"
    echo "2. Press Cmd+R to build and run"
    echo "3. Grant camera and microphone permissions when prompted"
    echo ""
    echo "📖 For more information, see:"
    echo "   - README.md for app documentation"
    echo "   - IMPLEMENTATION_GUIDE.md for AI integration"
    echo ""
else
    echo ""
    echo "⚠️  Project file not found."
    echo "Please create the project manually following SETUP_GUIDE.md"
    echo ""
fi

# Clean up
rm -rf "$TEMP_DIR"

echo "Done! 🎉"
