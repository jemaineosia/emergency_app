#!/bin/bash

# Emergency App - Complete Reinstall Script
# This script completely removes and reinstalls the app to reset permissions

echo "🚨 Emergency App - Permission Reset Script"
echo "=========================================="
echo ""

# Step 1: Uninstall from device
echo "📱 Step 1: Uninstalling app from iPhone..."
flutter install --uninstall-only
if [ $? -ne 0 ]; then
    echo "❌ Uninstall failed. Please delete the app manually from your iPhone:"
    echo "   1. Find 'Emergency App' on your iPhone"
    echo "   2. Long press the icon"
    echo "   3. Tap 'Remove App' → 'Delete App'"
    echo ""
    echo "After deleting manually, run this script again."
    exit 1
fi
echo "✅ App uninstalled"
echo ""

# Step 2: Clean Flutter build
echo "🧹 Step 2: Cleaning Flutter build cache..."
flutter clean
echo "✅ Build cache cleaned"
echo ""

# Step 3: Remove iOS pods
echo "🧹 Step 3: Cleaning iOS dependencies..."
cd ios
rm -rf Pods Podfile.lock
cd ..
echo "✅ iOS dependencies cleaned"
echo ""

# Step 4: Get dependencies
echo "📦 Step 4: Getting Flutter dependencies..."
flutter pub get
echo "✅ Dependencies retrieved"
echo ""

# Step 5: Install iOS pods with permission flags
echo "📦 Step 5: Installing iOS CocoaPods with permissions..."
cd ios
pod install
cd ..
echo "✅ CocoaPods installed with PERMISSION_MICROPHONE and PERMISSION_SPEECH_RECOGNIZER"
echo ""

# Step 6: Build and install
echo "📱 Step 6: Building and installing app..."
echo ""
echo "⚠️  IMPORTANT: When the app launches, you will see TWO permission prompts:"
echo "   1. 'Allow Microphone Access?' → TAP ALLOW ✅"
echo "   2. 'Allow Speech Recognition?' → TAP ALLOW ✅"
echo ""
echo "Building and installing now..."
echo ""

flutter run

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next Steps:"
echo "   1. The app should now be running on your iPhone"
echo "   2. You should see the Permission Screen"
echo "   3. Tap 'Grant Permissions' button"
echo "   4. When iOS prompts appear, tap 'Allow' for both"
echo "   5. Verify app appears in: Settings → Privacy → Microphone"
echo ""
