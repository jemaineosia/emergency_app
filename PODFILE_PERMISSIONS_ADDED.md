# ✅ Added Permission Flags to Podfile

## What Changed

Added permission environment variables to `ios/Podfile`:

```ruby
# Permission handler configuration
ENV['PERMISSION_MICROPHONE'] = '1'
ENV['PERMISSION_SPEECH_RECOGNIZER'] = '1'
```

## Why This Helps

### What These Flags Do:

1. **`PERMISSION_MICROPHONE=1`**
   - Tells CocoaPods to include microphone permission handling code
   - Ensures `permission_handler_apple` pod properly links microphone APIs
   - Required for Porcupine wake word detection

2. **`PERMISSION_SPEECH_RECOGNIZER=1`**
   - Enables speech recognition permission handling
   - Required for `speech_to_text` functionality
   - Ensures iOS speech recognition APIs are properly linked

### How It Works:

The `permission_handler` package uses these environment variables to:
- Conditionally compile only the permissions you need
- Reduce app size by excluding unused permission code
- Ensure proper linking of iOS permission frameworks

## Impact on Your App

### Before (Without Flags):
- CocoaPods installs all permission handlers (bloat)
- Some permissions might not be properly configured
- Potential linking issues with permission APIs

### After (With Flags):
- ✅ Only microphone and speech permissions compiled
- ✅ Smaller app size
- ✅ Explicit permission configuration
- ✅ Better linking with iOS permission frameworks
- ✅ Clear declaration of required permissions

## Does This Fix the "permanentlyDenied" Issue?

**No.** These flags improve the build configuration but don't change the runtime permission state.

**You still need to DELETE and REINSTALL the app** to reset the `permanentlyDenied` status.

However, this ensures:
- Better permission handling in the new installation
- Proper framework linking for microphone/speech
- Cleaner build configuration

## What's Been Done

1. ✅ Updated `ios/Podfile` with permission flags
2. ✅ Reinstalled CocoaPods with new configuration
3. ✅ Updated `reinstall.sh` script to use new configuration
4. ✅ Verified pods installed successfully

## Next Steps

**You MUST still:**

1. **DELETE the app from iPhone:**
   - Long press icon → Remove App → Delete App

2. **Reinstall with updated configuration:**
   ```bash
   cd /Users/skilla/Development/Apps/emergency_app
   ./reinstall.sh
   ```

3. **Grant permissions when prompted:**
   - Allow Microphone ✅
   - Allow Speech Recognition ✅

## Additional Permission Flags (For Reference)

If you need other permissions in the future, here are common flags:

```ruby
ENV['PERMISSION_CAMERA'] = '1'                    # Camera access
ENV['PERMISSION_LOCATION_ALWAYS'] = '1'           # Location (always)
ENV['PERMISSION_LOCATION_WHEN_IN_USE'] = '1'      # Location (when in use)
ENV['PERMISSION_NOTIFICATIONS'] = '1'             # Push notifications
ENV['PERMISSION_CONTACTS'] = '1'                  # Contacts
ENV['PERMISSION_PHOTOS'] = '1'                    # Photo library
ENV['PERMISSION_CALENDAR'] = '1'                  # Calendar
ENV['PERMISSION_BLUETOOTH'] = '1'                 # Bluetooth
```

**For your emergency app, we only need:**
- ✅ `PERMISSION_MICROPHONE` (for Porcupine and speech)
- ✅ `PERMISSION_SPEECH_RECOGNIZER` (for speech-to-text)

## Verification

Check that pods installed correctly:
```bash
cd ios
cat Podfile.lock | grep permission_handler_apple
```

Should show: `permission_handler_apple (9.3.0)`

## Summary

✅ **Added:** Permission flags to Podfile  
✅ **Reinstalled:** CocoaPods with new config  
✅ **Updated:** Reinstall script  
⚠️ **Still Required:** Delete app from iPhone and reinstall  

**The permission flags improve the build, but you still need to delete/reinstall to reset the `permanentlyDenied` state!**

---

**Ready to fix the permission issue? Run:**
```bash
# 1. Delete app from iPhone (manually)
# 2. Then run:
cd /Users/skilla/Development/Apps/emergency_app
./reinstall.sh
```
