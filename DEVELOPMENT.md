# Development Notes

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── emergency_contact.dart         # Contact data model
│   └── app_settings.dart              # Settings data model
├── providers/
│   └── emergency_provider.dart        # State management
├── services/
│   ├── speech_service.dart            # Voice recognition
│   └── phone_service.dart             # Phone calling
└── screens/
    ├── home_screen.dart               # Main screen
    ├── add_edit_contact_screen.dart   # Contact form
    ├── settings_screen.dart           # Settings
    └── countdown_screen.dart          # Emergency countdown
```

## Key Components

### Models
- **EmergencyContact**: Stores contact information with wake word
- **AppSettings**: Stores app configuration (countdown duration)

### Provider (State Management)
- **EmergencyProvider**: Manages contacts, settings, and app state
  - CRUD operations for contacts
  - Settings persistence
  - Wake word matching logic

### Services
- **SpeechService**: Handles speech recognition
  - Initialize speech recognition
  - Start/stop listening
  - Detect wake words
  
- **PhoneService**: Handles phone calls
  - Launch phone dialer with number

### Screens
- **HomeScreen**: Voice control and contact list
- **AddEditContactScreen**: Form for adding/editing contacts
- **SettingsScreen**: App configuration
- **CountdownScreen**: Emergency call countdown with cancel option

## Data Persistence

Uses `shared_preferences` to store:
- List of emergency contacts (JSON)
- App settings (JSON)

Data is automatically loaded on app start and saved after each change.

## Voice Recognition Flow

1. User taps microphone button
2. Request microphone permission
3. Initialize speech recognition
4. Start listening for speech
5. Process recognized text
6. Check for "help emergency" + wake word pattern
7. If match found, trigger countdown
8. If no match, continue listening

## Wake Word Detection Logic

Pattern: `"help emergency [wake word]"`

Example matches:
- "help emergency police" → Matches wake word "police"
- "help emergency ambulance" → Matches wake word "ambulance"
- "I need help emergency fire" → Matches wake word "fire"

Case insensitive matching.

## Testing Checklist

### Unit Testing
- [ ] Contact CRUD operations
- [ ] Settings persistence
- [ ] Wake word matching
- [ ] Data serialization

### Integration Testing
- [ ] Voice recognition flow
- [ ] Contact management flow
- [ ] Countdown and cancel flow
- [ ] Settings update flow

### UI Testing
- [ ] All screens navigate correctly
- [ ] Forms validate input
- [ ] Buttons respond properly
- [ ] Lists update in real-time

### Platform Testing
- [ ] Android microphone permission
- [ ] Android phone calling
- [ ] iOS microphone permission
- [ ] iOS speech recognition
- [ ] iOS phone calling

### Edge Cases
- [ ] Empty contact list
- [ ] No internet connection
- [ ] Permission denied
- [ ] Invalid phone numbers
- [ ] Speech recognition timeout
- [ ] Background app state

## Future Enhancements

### Potential Features
1. **Multiple Languages**: Support for different languages
2. **Contact Groups**: Organize contacts by priority
3. **Emergency Message**: Send SMS with location
4. **GPS Location**: Share location with emergency contact
5. **Contact Photos**: Add photos to contacts
6. **Call History**: Track emergency calls made
7. **Backup/Restore**: Cloud backup of contacts
8. **Widget**: Quick access widget
9. **Background Listening**: Always-on wake word detection
10. **Custom Countdown**: Any duration between 10-120 seconds

### Technical Improvements
1. **Unit Tests**: Add comprehensive test coverage
2. **Integration Tests**: Test complete user flows
3. **Error Handling**: Better error messages
4. **Offline Support**: Work without internet
5. **Performance**: Optimize speech recognition
6. **Accessibility**: Screen reader support
7. **Localization**: Multi-language support
8. **Analytics**: Track usage patterns (privacy-focused)

## Known Limitations

1. **Voice Recognition**:
   - Requires internet on some platforms
   - May struggle with accents
   - Background noise affects accuracy
   - Limited to supported languages

2. **Phone Calling**:
   - Requires phone app installed
   - May not work on tablets without SIM
   - Web/desktop support limited

3. **Permissions**:
   - User can deny permissions
   - Must handle permission edge cases

4. **Platform Differences**:
   - iOS requires more privacy strings
   - Android may have different speech engines
   - Web has limited phone capabilities

## Debugging Tips

### Voice Recognition Not Working
```dart
// Enable speech-to-text debug logging
print(_speech.isAvailable);
print(_speech.isListening);
print(_speech.lastStatus);
print(_speech.lastError);
```

### Contacts Not Saving
```dart
// Check SharedPreferences
final prefs = await SharedPreferences.getInstance();
print(prefs.getString('contacts'));
print(prefs.getString('settings'));
```

### Wake Word Not Detected
```dart
// Log recognized text
print('Recognized: $text');
print('Looking for: ${contact.wakeWord}');
print('Match found: ${text.contains(contact.wakeWord)}');
```

## Build Commands

```bash
# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Build APK for Android
flutter build apk

# Build app bundle for Play Store
flutter build appbundle

# Build iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

## Dependencies Version Info

Current dependencies (as of project creation):
- speech_to_text: ^7.0.0
- permission_handler: ^11.0.1
- url_launcher: ^6.2.1
- shared_preferences: ^2.2.2
- provider: ^6.1.1

Check for updates:
```bash
flutter pub outdated
```

## Contributing Guidelines

1. Follow Flutter style guide
2. Add comments for complex logic
3. Update README for new features
4. Test on both iOS and Android
5. Handle errors gracefully
6. Maintain backwards compatibility
