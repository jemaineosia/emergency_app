# iOS Microphone Permission Troubleshooting Guide

## Issue: "Microphone Permission Denied" on iPhone

Your iOS permissions are **correctly configured** in `Info.plist`:
- ✅ NSMicrophoneUsageDescription: "This app needs microphone access to listen for emergency wake words."
- ✅ NSSpeechRecognitionUsageDescription: "This app needs speech recognition to detect emergency wake words."

## Why Permission Still Denied?

iOS permissions are **baked in at install time**. If the app was installed before these permission descriptions were added, iOS won't know to request them.

## Solution Steps

### Option 1: Complete Reinstallation (Recommended)

1. **Delete the app from your iPhone:**
   - Long press the app icon
   - Tap "Remove App" → "Delete App"
   - This completely removes the app and its permission settings

2. **Clean and rebuild:**
   ```bash
   flutter clean
   cd ios && rm -rf Pods Podfile.lock && cd ..
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

3. **When you open the app:**
   - You should see a permission prompt: "Emergency App would like to access the microphone"
   - **Tap "Allow"**
   - You may see a second prompt for speech recognition - also tap "Allow"

### Option 2: Manual Permission Check

If you already reinstalled but still see the error:

1. **Go to iPhone Settings:**
   - Settings → Privacy & Security → Microphone
   - Find "emergency_app" (or "Runner")
   - Toggle it **ON**

2. **Also check Speech Recognition:**
   - Settings → Privacy & Security → Speech Recognition
   - Find "emergency_app" (or "Runner")
   - Toggle it **ON**

3. **Restart the app**

### Option 3: Reset All Permissions (Last Resort)

1. Go to iPhone Settings → General → Transfer or Reset iPhone → Reset → Reset Location & Privacy
2. Your iPhone will restart
3. All apps will request permissions again on next use
4. Reinstall your app and allow permissions when prompted

## Verification Checklist

After reinstalling, verify these work:

- [ ] App launches without crashes
- [ ] When you tap "Start Listening" - no error appears
- [ ] You can see microphone activity (if app shows listening indicator)
- [ ] Say "Jarvis" - wake word should be detected
- [ ] Say "help emergency [wake word]" - should trigger countdown

## Technical Details

### What's Happening Under the Hood

1. **Info.plist** declares the permissions your app *might* need
2. **First launch**: iOS reads Info.plist and knows to show permission prompts
3. **Runtime request**: Your app calls `permission_handler` to request permission
4. **User response**: User taps "Allow" or "Don't Allow"
5. **Setting saved**: Permission choice is saved permanently for this app install

### Why Clean Reinstall is Necessary

- iOS caches the Info.plist from when the app was first installed
- Updating Info.plist in code doesn't update the cached version
- Only a fresh install reads the new Info.plist

## Quick Commands Reference

```bash
# Complete clean and reinstall workflow
flutter clean
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter pub get
cd ios && pod install && cd ..
flutter run

# Or use the simplified script:
cd ios && pod install && cd ..
flutter run
```

## Expected Permission Prompts

When you first open the app after clean install:

### Prompt 1: Microphone Access
```
"emergency_app" Would Like to 
Access the Microphone

This app needs microphone access to 
listen for emergency wake words.

[ Don't Allow ]  [ Allow ]
```
**Action: Tap "Allow"**

### Prompt 2: Speech Recognition
```
"emergency_app" Would Like to 
Use Speech Recognition

This app needs speech recognition to 
detect emergency wake words.

[ Don't Allow ]  [ Allow ]
```
**Action: Tap "Allow"**

## Still Not Working?

If permissions are allowed but Porcupine still fails:

1. **Check Porcupine Access Key:**
   - Go to Settings in app
   - Verify access key is: `CExlRfk8z/A47D8rP/Bz3ScHoDmiRaslMfLJjiYkdpf0S04QSt4wYQ==`
   - If blank, re-enter it and save

2. **Check logs:**
   ```bash
   flutter run
   ```
   Look for error messages in the console

3. **Test step by step:**
   - Test basic microphone: Tap "Start Listening" without Porcupine
   - If that works, the issue is Porcupine-specific
   - Check Porcupine initialization logs

## Common Mistakes

❌ **Updating Info.plist but not reinstalling**
- Fix: Delete app from device, then reinstall

❌ **Permission denied in iOS Settings**
- Fix: Settings → Privacy → Microphone → Toggle ON

❌ **Using iOS Simulator**
- Porcupine may not work properly in Simulator
- **Always test on physical device**

❌ **Wrong access key**
- Fix: Verify in Settings screen matches: `CExlRfk8z/A47D8rP/Bz3ScHoDmiRaslMfLJjiYkdpf0S04QSt4wYQ==`

## Success Indicators

✅ No "permission denied" errors in console
✅ App shows "Listening for wake word..." status
✅ Speaking "Jarvis" triggers wake word detection
✅ Speaking "help emergency police" starts countdown
✅ No crashes when using voice features

## Next Steps After Fixing Permissions

1. Test wake word detection: Say "Jarvis"
2. Test emergency command: Say "help emergency police"
3. Verify countdown starts with correct contact
4. Test cancel functionality
5. Test multiple contacts with different wake words
6. Test background listening (if auto-start is enabled)

---

**Note:** iOS is very strict about privacy permissions. This is by design to protect user privacy. The complete reinstall process ensures iOS properly recognizes your app's permission requirements.
