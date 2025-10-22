# Emergency App

A Flutter application that uses voice-activated emergency calling with configurable countdown timer.

## Features

- **Voice-Activated Emergency Calls**: Say "help emergency [wake word]" to trigger an emergency call
- **Custom Emergency Contacts**: Add contacts with specific wake words (police, ambulance, fire station, etc.)
- **Configurable Countdown**: Choose between 30 or 60-second countdown before the call is placed
- **Cancel Option**: Cancel the emergency call during the countdown period
- **Contact Management**: Add, edit, and delete emergency contacts
- **Persistent Storage**: All contacts and settings are saved locally

## How It Works

1. **Add Emergency Contacts**
   - Tap the `+` button to add a new contact
   - Fill in the details:
     - Name: Contact name (e.g., "City Police Department")
     - Type: Choose from police, ambulance, or fire station
     - Wake Word: The word to trigger this contact (e.g., "police", "ambulance")
     - Address: Physical address of the emergency service
     - Contact Number: Phone number to call

2. **Activate Voice Listening**
   - Tap the microphone button on the home screen
   - The app will start listening for the wake word phrase

3. **Trigger Emergency Call**
   - Say: "help emergency [wake word]"
   - Example: "help emergency police" or "help emergency ambulance"
   - The app will detect the wake word and start the countdown

4. **Countdown Screen**
   - A countdown timer will display (30 or 60 seconds based on settings)
   - You can see the contact details that will be called
   - Tap "CANCEL CALL" to stop the emergency call

5. **Configure Settings**
   - Tap the settings icon in the top-right corner
   - Choose countdown duration: 30 seconds or 60 seconds
   - Read the usage instructions

## Permissions Required

### Android
- `RECORD_AUDIO`: For voice recognition
- `CALL_PHONE`: To place emergency calls
- `INTERNET`: For app functionality

### iOS
- Microphone access for voice recognition
- Speech recognition for detecting wake words

## Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Connect your device or start an emulator
4. Run `flutter run`

## Dependencies

- `speech_to_text`: Voice recognition
- `permission_handler`: Manage app permissions
- `url_launcher`: Make phone calls
- `shared_preferences`: Local data storage
- `provider`: State management

## Important Notes

- **Test Mode**: Test the app with non-emergency numbers first
- **Permissions**: Grant microphone and phone permissions when prompted
- **Network**: Some features may require internet connectivity
- **Voice Recognition**: Works best in quiet environments
- **Emergency Services**: Always ensure you have the correct emergency numbers for your region

## Safety Tips

1. Always add the correct emergency contact numbers for your area
2. Test the voice recognition with non-emergency contacts first
3. Make sure to configure the countdown timer to give you enough time to cancel accidental triggers
4. Keep your emergency contacts up to date
5. Familiarize yourself with the app interface before an emergency

## Platform Support

- ✅ Android
- ✅ iOS
- ⚠️ Web (limited - phone calling may not work)
- ⚠️ Desktop (limited - phone calling may not work)

## License

This project is open source and available for emergency preparedness purposes.
