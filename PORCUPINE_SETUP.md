# Implementing Always-On Wake Word Detection with Porcupine

## Overview

Porcupine by Picovoice provides **offline, always-on wake word detection** similar to "Hey Siri" or "Ok Google".

## Important Information

### ⚠️ Requirements

1. **Access Key Required**: You need to sign up at [Picovoice Console](https://console.picovoice.ai/) to get a free access key
2. **Free Tier Limits**: 
   - Free for development/testing
   - Paid license for production
   - 3 custom wake words on free tier

### 📱 Platform Support

- ✅ Android: Full support
- ✅ iOS: Full support  
- ❌ Web: Not supported
- ⚠️ Background: Limited by OS restrictions

## Setup Steps

### Step 1: Get Porcupine Access Key

1. Go to [https://console.picovoice.ai/](https://console.picovoice.ai/)
2. Sign up for a free account
3. Copy your Access Key from the dashboard
4. The access key looks like: `YOUR_ACCESS_KEY_HERE`

### Step 2: Choose Wake Words

#### Option A: Built-in Wake Words (Free)
Porcupine provides several built-in wake words:
- `jarvis`
- `alexa`
- `ok google`
- `hey siri`
- `terminator`
- `porcupine`
- `picovoice`
- `bumblebee`
- `grapefruit`
- `grasshopper`

#### Option B: Custom Wake Words (Requires Training)
You can create custom wake words like "help emergency" through Picovoice Console:
1. Go to Picovoice Console
2. Navigate to "Wake Word" section
3. Train your custom wake word phrase
4. Download the `.ppn` file
5. Add to your Flutter project

### Step 3: Update Android Permissions

The permissions are already added, but verify in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Step 4: Update iOS Permissions

Already configured in `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to detect emergency wake words.</string>
```

## Implementation Options

### Option 1: Foreground Only (Recommended for Start)

**Pros:**
- Simpler implementation
- No background service complexity
- Works immediately
- Lower battery usage

**Cons:**
- App must be open
- Phone must be unlocked

**Use Case:** Keep app open on home screen, always listening for "help emergency"

### Option 2: Background Service (More Complex)

**Pros:**
- Works when app is minimized
- Always listening (within OS limits)
- Persistent notification shows it's active

**Cons:**
- OS can kill service to save battery
- Requires foreground service notification
- More complex implementation
- Higher battery usage

**Use Case:** Running in background with notification, can detect wake word even when screen is off (for short periods)

### Option 3: Hybrid Approach (Best Balance)

- Foreground always-on listening when app is open
- Background service for up to 30 minutes after app is minimized
- User can manually restart if needed
- Clear notification showing service is active

## Current Implementation Status

I've added `porcupine_flutter` to dependencies. Here's what you need to do:

### 1. Get Your Access Key
```
Sign up at: https://console.picovoice.ai/
Copy your access key
```

### 2. Choose Your Implementation Path

**Path A: Quick Start (Built-in Wake Words)**
- Use built-in wake words like "jarvis" or "alexa"
- Fastest to implement
- Limited customization

**Path B: Custom Wake Words**
- Create "help emergency" as custom wake word
- More relevant to your use case
- Requires wake word training

## Alternative: Simpler Approach

If Porcupine seems too complex, I can implement:

### Auto-Start Listening Mode
- App automatically starts listening when opened
- No button tap required
- Uses speech_to_text (already installed)
- Continuous listening while app is active
- Shows "Always Listening" indicator
- Lower battery usage than Porcupine

**This works well if:**
- User keeps app open during activities
- Phone is easily accessible
- Don't need background detection

## My Recommendation

For your use case (emergency app), I recommend:

### Phase 1: Start Simple
1. **Implement auto-start listening** with speech_to_text
2. **Keep app in foreground** with screen always on
3. **Add quick launch shortcut** to home screen
4. **Test thoroughly** with real usage

### Phase 2: Add Wake Word (Optional)
1. Get Porcupine access key
2. Train custom "help emergency" wake word
3. Implement foreground wake word detection
4. Test battery usage and reliability

### Phase 3: Background (Advanced)
1. Add background service
2. Implement persistent notification
3. Handle OS battery optimization
4. Extensive testing

## What Would You Like?

Please choose one option:

**Option A: Simple Implementation** ⭐ RECOMMENDED
- I'll implement auto-start listening (no button tap needed)
- App continuously listens while open
- "Keep screen on" option
- Quick emergency access
- ✅ Can implement NOW

**Option B: Porcupine Wake Word**
- You need to get Porcupine access key first
- I'll implement after you provide the key
- Always-on wake word detection
- More complex setup
- ⏳ Requires your access key

**Option C: Hybrid Approach**
- Start with Option A (simple)
- Add Porcupine later when you have access key
- Best of both worlds
- ✅ Can start NOW, upgrade later

Let me know which option you prefer, and I'll implement it right away! 🚀

## Quick Command Reference

```bash
# Install Porcupine (already added to pubspec.yaml)
flutter pub get

# Get Porcupine console access
open https://console.picovoice.ai/

# Run the app
flutter run
```

## Resources

- [Porcupine Documentation](https://picovoice.ai/docs/porcupine/)
- [Flutter Package](https://pub.dev/packages/porcupine_flutter)
- [Console Dashboard](https://console.picovoice.ai/)
- [Custom Wake Word Training](https://picovoice.ai/platform/porcupine/)
