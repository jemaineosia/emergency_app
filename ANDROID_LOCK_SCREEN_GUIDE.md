# Android Lock Screen Emergency Detection

## 🎉 What's Now Possible on Android

Your Emergency App now has **TRUE hands-free capability on Android**:

✅ **Works on lock screen** - Detects voice commands even when phone is locked  
✅ **Background service** - Keeps listening even when app is in background  
✅ **Auto wake screen** - Automatically turns screen on when emergency is detected  
✅ **Persistent notification** - Shows "🎤 Listening for voice commands..."  
✅ **No "Hey Google" needed** - Just say "help emergency police" directly  

## 📱 How It Works

### Initial Setup
1. Install the app on Android
2. Grant microphone permission (automatic prompt)
3. Grant phone call permission (automatic prompt)
4. Add emergency contacts with wake words

### Always-On Detection
The app automatically:
- Starts a **foreground service** with persistent notification
- Keeps **wake lock** to prevent CPU sleep
- Listens for wake words **continuously**
- Works even when:
  - Phone screen is OFF
  - Phone is LOCKED
  - App is in BACKGROUND
  - Other apps are open

### Emergency Flow
1. **Lock your phone** and put it in your pocket
2. Say: **"help emergency police"** (or your custom wake word)
3. **Screen automatically turns on**
4. **Countdown appears** (5 seconds)
5. **Auto-dials** the emergency number
6. **Resumes listening** after call ends

## 🔋 Battery & Performance

### Battery Impact
- **Minimal**: Uses Android's optimized wake lock
- **Efficient**: Porcupine wake word detection uses ~1-2% CPU
- **Smart**: Only active audio processing when detecting speech

### Optimization Tips
- The foreground service notification prevents Android from killing the app
- Wake lock only keeps CPU active, not screen
- Speech recognition only activates after wake word detected

## 🔔 Notification Bar

You'll see a persistent notification:
```
Emergency App Active
🎤 Listening for voice commands...
```

**Why it's there:**
- Required by Android for foreground services
- Lets you quickly open the app
- Shows the service is active and protecting you
- Prevents Android from killing the app

**To hide it:**
- Long-press notification → Settings → Turn off "Emergency Voice Listener"
- Note: Hiding it may cause Android to kill the service eventually

## 🆚 Android vs iOS Comparison

| Feature | Android | iOS |
|---------|---------|-----|
| **Lock screen detection** | ✅ YES | ❌ NO |
| **App in background** | ✅ YES | ⚠️ Limited (few minutes) |
| **Screen off detection** | ✅ YES | ⚠️ Only if app is active |
| **Persistent notification** | ✅ YES (shows status) | ❌ NO |
| **Auto wake screen** | ✅ YES | ❌ NO |
| **True hands-free** | ✅ YES | ⚠️ Partial |

## 🧪 Testing on Android

### Test Lock Screen Detection
1. Open app → Add a test contact (wake word: "test")
2. Lock your phone
3. Wait 2 seconds
4. Say: **"help emergency test"**
5. Screen should turn on and countdown should appear

### Test Background Detection
1. Open app → It starts listening
2. Press Home button (app goes to background)
3. Open another app (Chrome, etc.)
4. Say: **"help emergency police"**
5. Emergency App should come to foreground with countdown

### Test Screen Off Detection
1. Open app
2. Lock phone (screen turns off)
3. Don't touch phone
4. Say: **"help emergency fire"**
5. Screen should turn on automatically

## ⚙️ Permissions Required

The app requests these Android permissions:
- ✅ `RECORD_AUDIO` - Listen for voice commands
- ✅ `CALL_PHONE` - Make emergency calls
- ✅ `FOREGROUND_SERVICE` - Keep listening in background
- ✅ `FOREGROUND_SERVICE_MICROPHONE` - Specify microphone use
- ✅ `WAKE_LOCK` - Keep CPU active when screen is off
- ✅ `USE_FULL_SCREEN_INTENT` - Turn screen on for emergencies
- ✅ `SYSTEM_ALERT_WINDOW` - Show countdown on lock screen
- ✅ `DISABLE_KEYGUARD` - Unlock screen during emergency

## 🚨 Important Notes

### When Service Stops
The foreground service will stop if:
- You manually stop it via notification
- Battery saver/optimization kills it (disable for this app)
- Android runs out of memory (rare)
- You force-stop the app

### To Ensure It Stays Active
1. Settings → Apps → Emergency App
2. Battery → Unrestricted
3. Permissions → Allow all the time
4. Auto-start → Enable (if available on your device)

### Privacy
- All voice processing happens **on-device**
- No audio is sent to the cloud
- Porcupine wake word detection is **offline**
- Speech-to-text uses device speech recognition

## 💡 Best Practices

### Daily Use
- Keep the app running when you might need it
- Check the notification is showing (service is active)
- Test your wake words occasionally
- Keep phone charged or on charger

### Emergency Situations
- Practice saying wake words clearly
- Speak at normal volume
- Phone can be in pocket/purse
- Works even in noisy environments (within reason)

### Adding Contacts
- Use simple, distinct wake words
- Test each wake word after adding
- Avoid similar-sounding wake words
- Update emergency numbers regularly

## 🔧 Troubleshooting

**Service not starting?**
- Check if app has all permissions
- Disable battery optimization for the app
- Restart the app

**Not detecting on lock screen?**
- Make sure notification is showing
- Check if battery saver is on
- Verify wake word is configured

**Screen not turning on?**
- Grant "Display over other apps" permission
- Check "Turn screen on" permission
- Some devices restrict this (manufacturer limitation)

## 📊 Technical Details

**Architecture:**
- Foreground Service: `VoiceListenerService.kt`
- Wake Lock: Partial wake lock (CPU only, not screen)
- Method Channel: `com.skilla.emergencyApp/voice_service`
- Notification Channel: `emergency_voice_listener`
- Service Type: `foreground_service_microphone`

**Background Audio Processing:**
- Uses Porcupine for efficient wake word detection
- Activates speech recognition only after wake word
- Automatically restarts listening after each use

---

**You now have the most advanced hands-free emergency app on Android!** 🚀

Your phone is always listening and ready to help, even when locked and in your pocket.
