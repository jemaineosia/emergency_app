# 🚨 Quick Fix: iOS Microphone Permission Denied

## The Problem
Your app says "Microphone Permission Denied" even though permissions are in Info.plist.

## Why?
iOS only reads Info.plist **when the app is first installed**. If you installed before adding permissions, iOS doesn't know to ask for them.

## The Solution (3 Simple Steps)

### Step 1: Delete the App from iPhone
- Long press the app icon
- Tap **Remove App** → **Delete App**

### Step 2: Rebuild & Install
```bash
cd /Users/skilla/Development/Apps/emergency_app
flutter run
```

### Step 3: Allow Permissions
When you open the app, you'll see 2 prompts:
1. **"Access the Microphone"** → Tap **Allow**
2. **"Use Speech Recognition"** → Tap **Allow**

---

## Alternative: Check Settings Manually

If you already reinstalled:

**iPhone Settings → Privacy & Security → Microphone**
- Find "emergency_app" or "Runner"
- Toggle **ON**

**iPhone Settings → Privacy & Security → Speech Recognition**
- Find "emergency_app" or "Runner"  
- Toggle **ON**

---

## What I've Already Done ✅

✅ Cleaned Flutter project
✅ Removed iOS pods
✅ Reinstalled dependencies
✅ Verified Info.plist has correct permissions:
  - NSMicrophoneUsageDescription ✓
  - NSSpeechRecognitionUsageDescription ✓
✅ Installed all CocoaPods (Porcupine, permissions, etc.)

---

## Test After Fixing

1. Say **"Jarvis"** → Should detect wake word
2. Say **"help emergency police"** → Should start countdown
3. Verify countdown shows correct contact
4. Test cancel button

---

## Still Having Issues?

Check `TROUBLESHOOTING_iOS_PERMISSIONS.md` for detailed debugging steps.

---

**TIP:** Always test Porcupine on a **physical iPhone**, not the simulator. Wake word detection requires real microphone hardware.
