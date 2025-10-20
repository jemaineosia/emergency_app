# 🚨 Emergency App - Quick Reference Card

## 🎯 READY TO USE NOW!

### ✅ What Works Immediately:
- **Auto-Start Listening** - No button tap needed!
- **Keep Screen On** - Phone stays awake
- **Voice Commands** - "help emergency [wake word]"
- **Countdown & Cancel** - 30s or 60s before call

---

## 🚀 Quick Start (2 Minutes)

### 1. Run the App
```bash
flutter run
```

### 2. First Time Setup
1. Grant microphone permission
2. Tap ⚙️ Settings
3. Enable ✅ "Auto-Start Listening"
4. Enable ✅ "Keep Screen On"
5. Choose countdown: 30s or 60s
6. Save

### 3. Add Emergency Contact
1. Tap ➕ button
2. Fill in:
   - Name: "City Police"
   - Type: Police
   - Wake Word: "police"
   - Address: [their address]
   - Phone: [emergency number]
3. Save

### 4. Test It!
1. App is now listening (red microphone)
2. Say: **"help emergency police"**
3. Countdown screen appears
4. Cancel or wait for call

---

## 🗣️ Voice Commands

### Format:
```
"help emergency [wake word]"
```

### Examples:
- "help emergency police" → Calls police
- "help emergency ambulance" → Calls ambulance
- "help emergency fire" → Calls fire station

### Tips:
- Speak clearly and loudly
- Use simple wake words
- Reduce background noise
- App must be open and listening

---

## ⚙️ Settings Explained

### Countdown Timer
- **30 seconds**: Faster emergency response
- **60 seconds**: More time to cancel accidents

### Auto-Start Listening
- **ON**: App listens immediately when opened
- **OFF**: Must tap microphone button to start

### Keep Screen On
- **ON**: Screen won't sleep while listening
- **OFF**: Normal phone behavior (saves battery)

### Porcupine Access Key (Optional)
- For always-on wake word detection
- Get free key: https://console.picovoice.ai/
- See PORCUPINE_SETUP.md for details

---

## 🔴 Using the App

### When Listening:
- ✅ Microphone icon is RED and pulsing
- ✅ Shows "Listening..." text
- ✅ Displays recognized speech
- ✅ Detects "help emergency [wake word]"

### When NOT Listening:
- ⚪ Microphone icon is BLUE
- ⚪ Shows "Tap to activate" text
- ⚪ Tap microphone to start

### Auto-Start Mode:
- App starts listening automatically
- No need to tap microphone
- Restarts when app reopens
- Red pulsing microphone always visible

---

## 🆘 Emergency Flow

```
1. 🎤 App is listening (red microphone)
      ↓
2. 🗣️ Say "help emergency police"
      ↓
3. ⏱️ Countdown screen appears (30s/60s)
      ↓
4. ℹ️ Shows contact details
      ↓
5. ❌ CANCEL or ⏳ WAIT
      ↓
6. 📞 Phone dials emergency number
```

---

## ⚠️ Important Notes

### DO:
- ✅ Test with non-emergency numbers first
- ✅ Keep phone nearby and accessible
- ✅ Use simple, clear wake words
- ✅ Keep app open for best results
- ✅ Verify contact numbers regularly

### DON'T:
- ❌ Rely solely on this app
- ❌ Use with inaccurate emergency numbers
- ❌ Forget to test regularly
- ❌ Use complex wake words
- ❌ Expect it to work when app is closed

---

## 🔋 Battery Tips

### To Save Battery:
- Turn OFF "Keep Screen On"
- Don't use "Auto-Start Listening"
- Manually start listening when needed
- Close app when not in use

### For Maximum Availability:
- Turn ON "Keep Screen On"
- Turn ON "Auto-Start Listening"
- Keep phone plugged in
- Place phone in accessible location

---

## 🐛 Troubleshooting

### Voice Not Recognized?
- ✅ Check microphone permission
- ✅ Speak louder and clearer
- ✅ Reduce background noise
- ✅ Verify red microphone is pulsing
- ✅ Check wake word matches contact

### App Not Listening?
- ✅ Tap microphone button (if auto-start OFF)
- ✅ Check "Auto-Start Listening" in settings
- ✅ Reopen the app
- ✅ Grant microphone permission again

### Countdown Not Starting?
- ✅ Must say exact phrase: "help emergency [wake word]"
- ✅ Wake word must match a contact
- ✅ Add contacts if list is empty
- ✅ Check contact wake word spelling

### Phone Not Calling?
- ✅ Grant phone permission when prompted
- ✅ Verify contact number is correct
- ✅ Check phone has signal/SIM card
- ✅ Test manual call first

---

## 📞 Sample Contacts

### Police
```
Name: City Police Department
Type: Police
Wake Word: police
Address: 123 Main St, City
Phone: [your local police]
```

### Ambulance
```
Name: City Ambulance
Type: Ambulance
Wake Word: ambulance
Address: 456 Hospital Rd
Phone: [your local ambulance]
```

### Fire
```
Name: City Fire Station
Type: Fire Station
Wake Word: fire
Address: 789 Fire Lane
Phone: [your local fire dept]
```

---

## 🎓 Best Practices

1. **Practice First**: Test with your own number
2. **Keep Current**: Update contacts regularly
3. **Multiple Contacts**: Add backup services
4. **Clear Speech**: Practice voice commands
5. **Easy Access**: Keep phone within reach
6. **Regular Tests**: Monthly verification

---

## 🔮 Future: Always-On Wake Word

Want "Hey Siri" style always-on detection?

### Option: Porcupine Wake Word
1. Get free key: https://console.picovoice.ai/
2. Enter in Settings → Porcupine Access Key
3. See PORCUPINE_SETUP.md for full guide
4. Works offline, low battery usage
5. More reliable wake word detection

**Note**: Still requires app to be running in background. OS limits full "Hey Siri" functionality to system services only.

---

## 📱 Platform Status

- ✅ **Android**: Fully supported
- ✅ **iOS**: Fully supported
- ⚠️ **Web**: Limited (no phone calls)
- ⚠️ **Desktop**: Limited (no phone calls)

---

## 🆘 Emergency Support

**If app fails during real emergency:**
1. Use phone's native dialer
2. Call emergency services directly
3. This app is supplementary tool only

**Always have backup calling methods!**

---

## 📚 More Info

- Full docs: `README.md`
- User guide: `QUICK_START.md`
- Setup guide: `PORCUPINE_SETUP.md`
- Dev notes: `DEVELOPMENT.md`

---

**Version**: 1.0.0
**Last Updated**: October 2025
**Status**: ✅ Production Ready (with auto-start listening)

---

**Your safety is the priority. This app assists but doesn't replace traditional emergency calling methods.**
