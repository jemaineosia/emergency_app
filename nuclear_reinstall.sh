#!/bin/bash

echo "🚨 NUCLEAR REINSTALL SCRIPT FOR iOS PERMISSIONS"
echo "================================================"
echo ""

# Make sure we're in the right directory
cd /Users/skilla/Development/Apps/emergency_app || exit 1

echo "⚠️  IMPORTANT INSTRUCTIONS:"
echo ""
echo "1. CLOSE the app on your iPhone (swipe up from app switcher)"
echo "2. DELETE the app from iPhone:"
echo "   - Go to Settings → General → iPhone Storage"
echo "   - Find 'Emergency App' or 'emergency_app'"
echo "   - Tap it → Delete App"
echo "   - OR: Long press app icon → Remove App → Delete App"
echo ""
echo "3. REBOOT your iPhone:"
echo "   - Hold Power button + Volume Up"
echo "   - Slide to power off"
echo "   - Wait 10 seconds"
echo "   - Power back on"
echo ""
read -p "Press Enter AFTER you've done steps 1-3 above..."

echo ""
echo "🧹 Step 1: Nuclear clean of Flutter project..."
flutter clean

echo ""
echo "🧹 Step 2: Removing ALL iOS build artifacts..."
cd ios
rm -rf Pods Podfile.lock build DerivedData .symlinks
cd ..
rm -rf build/
rm -rf .dart_tool/

echo ""
echo "🧹 Step 3: Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo ""
echo "🧹 Step 4: Cleaning CocoaPods cache..."
rm -rf ~/Library/Caches/CocoaPods
cd ios
pod cache clean --all 2>/dev/null || true
pod deintegrate 2>/dev/null || true
cd ..

echo ""
echo "📦 Step 5: Getting fresh Flutter dependencies..."
flutter pub get

echo ""
echo "📦 Step 6: Installing fresh CocoaPods..."
cd ios
pod install
cd ..

echo ""
echo "🔨 Step 7: Building and installing app..."
echo ""
echo "⚠️  WATCH FOR PERMISSION POPUPS ON YOUR iPHONE!"
echo ""
echo "When the app launches, you should see:"
echo "  1. 'Emergency App Would Like to Access the Microphone' → TAP ALLOW"
echo "  2. 'Emergency App Would Like to Use Speech Recognition' → TAP ALLOW"
echo ""
echo "If you DON'T see popups, the issue is deeper (see troubleshooting guide)"
echo ""
echo "Building now..."
echo ""

flutter run

echo ""
echo "✅ Installation complete!"
echo ""
echo "DID YOU SEE THE PERMISSION POPUPS?"
echo "  - YES → Great! Grant permissions and test the app"
echo "  - NO  → Read STILL_DENIED_AFTER_DELETE.md for advanced troubleshooting"
echo ""
