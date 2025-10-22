# 🚀 Quick Start Guide - Emergency App Refactor# Emergency App - Quick Start Guide



## ✅ What's Already Done## 📱 App Overview



Phase 1 (Foundation) is complete:The Emergency App is a voice-activated emergency calling system that helps you quickly contact emergency services by simply saying a wake word.

- ✅ New dependencies added (`supabase_flutter`, `geolocator`, `flutter_contacts`, `workmanager`)

- ✅ Database schema designed (see `SUPABASE_SETUP.md`)## 🎯 Main Features

- ✅ Data models created (EmergencyContact, UserProfile, UserSettings, UpdateHistory)

- ✅ Configuration files created (need your API keys)### 1. Home Screen

- ✅ Dependencies installed- **Voice Control Button**: Large circular microphone button

  - Blue when idle

## 🎯 What You Need to Do Next  - Red and pulsing when listening

- **Contact List**: Shows all your emergency contacts

### Step 1: Set Up Supabase (15 minutes)- **Add Button**: Floating action button (+) to add new contacts

- **Settings Button**: Top-right corner for app settings

1. Go to [https://supabase.com](https://supabase.com) and create a new project

2. Once created, go to **SQL Editor** and run the schema from `SUPABASE_SETUP.md` (copy the entire SQL block)### 2. Add/Edit Contact Screen

3. Go to **Settings → API** and copy:Fields to fill:

   - Project URL- **Name**: e.g., "City Hospital Emergency"

   - Anon Public Key- **Type**: Police, Ambulance, or Fire Station

4. Open `lib/core/constants/supabase_config.dart` and paste your credentials:- **Wake Word**: e.g., "ambulance", "police", "fire"

   ```dart- **Address**: Physical location

   static const String supabaseUrl = 'https://xxxxx.supabase.co';- **Contact Number**: Phone number to call

   static const String supabaseAnonKey = 'eyJ...'; // Your anon key

   ```### 3. Countdown Screen

Displays when wake word is detected:

5. Enable authentication providers:- **Timer**: Large circular countdown (30 or 60 seconds)

   - Go to **Authentication → Providers**- **Contact Details**: Shows who will be called

   - Enable **Google** (add OAuth credentials from Google Cloud Console)- **Cancel Button**: Large orange button to cancel the call

   - Enable **Facebook** (add OAuth credentials from Facebook Developers)

   - Enable **Anonymous Sign-ins** (just toggle it on)### 4. Settings Screen

- **Countdown Timer**: Choose 30 or 60 seconds

### Step 2: Set Up Google Places API (15 minutes)- **Instructions**: How to use the app



1. Go to [https://console.cloud.google.com](https://console.cloud.google.com)## 🗣️ Voice Commands

2. Create a new project (or use existing)

3. Enable APIs:**Format**: "help emergency [wake word]"

   - **Places API** (New)

   - **Geocoding API****Examples**:

4. Create API Key:- "help emergency police" → Calls police contact

   - Go to **Credentials → Create Credentials → API Key**- "help emergency ambulance" → Calls ambulance contact

   - Click **Restrict Key**:- "help emergency fire" → Calls fire station contact

     - **iOS**: Add bundle ID `com.skilla.emergencyApp`

     - **Android**: Add package name `com.skilla.emergency_app` + your SHA-1 certificate## 📋 Setup Steps

5. Copy API key to `lib/core/constants/google_config.dart`:

   ```dart1. **First Time Setup**

   static const String placesApiKey = 'AIza...'; // Your API key   ```

   ```   ✓ Allow microphone permission

   ✓ Allow phone permission (when calling)

### Step 3: Configure Platform Permissions   ✓ Add at least one emergency contact

   ```

#### iOS (`ios/Runner/Info.plist`)

Add these entries (or update existing file):2. **Add Your First Contact**

```xml   ```

<!-- Location -->   → Tap the + button

<key>NSLocationWhenInUseUsageDescription</key>   → Fill in all fields

<string>We need your location to find nearby emergency services</string>   → Use simple wake words

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>   → Save the contact

<string>We update emergency contacts based on your location</string>   ```



<!-- Contacts -->3. **Test the App** (with non-emergency number!)

<key>NSContactsUsageDescription</key>   ```

<string>We save emergency contacts (POLICE, HOSPITAL, FIRE STATION) to your phone</string>   → Tap the microphone button

   → Say "help emergency [your wake word]"

<!-- Background Modes -->   → Test the countdown and cancel

<key>UIBackgroundModes</key>   → Verify the contact is correct

<array>   ```

  <string>fetch</string>

  <string>processing</string>4. **Configure Settings**

</array>   ```

   → Tap settings icon

<!-- OAuth Deep Linking -->   → Choose countdown duration

<key>CFBundleURLTypes</key>   → Review the instructions

<array>   → Save settings

  <dict>   ```

    <key>CFBundleURLSchemes</key>

    <array>## ⚠️ Important Warnings

      <string>com.skilla.emergencyApp</string>

    </array>🚨 **Before Real Use**:

  </dict>- Test with non-emergency numbers first

</array>- Verify all contact numbers are correct

```- Practice the voice commands

- Test in different noise environments

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add these permissions inside `<manifest>`:🚨 **During Emergency**:

```xml- Speak clearly and calmly

<uses-permission android:name="android.permission.INTERNET"/>- Use the exact wake word you configured

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>- Don't panic if first attempt fails

<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>- You can manually call if voice fails

<uses-permission android:name="android.permission.READ_CONTACTS"/>

<uses-permission android:name="android.permission.WRITE_CONTACTS"/>🚨 **Safety**:

<uses-permission android:name="android.permission.CALL_PHONE"/>- Keep emergency numbers updated

```- Regularly test the app

- Don't rely solely on this app

Add deep linking intent filter inside `<activity>`:- Always have backup calling method

```xml

<intent-filter>## 🔧 Troubleshooting

  <action android:name="android.intent.action.VIEW" />

  <category android:name="android.intent.category.DEFAULT" />**Voice Not Recognized?**

  <category android:name="android.intent.category.BROWSABLE" />- Check microphone permission

  <data- Speak clearly and loudly

    android:scheme="com.skilla.emergencyApp"- Reduce background noise

    android:host="login-callback" />- Make sure listening is active (red button)

</intent-filter>

```**Can't Make Calls?**

- Check phone permission

### Step 4: Install iOS Dependencies- Verify contact number format

- Test with manual call first

```bash- Check SIM card is active

cd ios && pod install && cd ..

```**App Not Saving?**

- Fill all required fields

## 📚 Implementation Order- Check internet connection

- Restart the app

Now that setup is done, here's the recommended implementation order:- Clear app data (will delete contacts)



### Phase 2: Core Services (Start Here!)## 💡 Best Practices



1. **Supabase Service** (`lib/services/supabase_service.dart`)1. **Wake Words**: Use simple, clear words

   - Initialize client   - ✅ "police", "ambulance", "fire"

   - CRUD operations for all tables   - ❌ "law enforcement", "medical emergency"

   

2. **Auth Service** (`lib/services/auth_service.dart`)2. **Countdown Timer**:

   - Google/Facebook/Anonymous sign-in   - 60 seconds: Better for accidental triggers

   - Session management   - 30 seconds: Faster for real emergencies

   

3. **Location Service** (`lib/services/location_service.dart`)3. **Contact Organization**:

   - Get current position   - Add primary emergency services first

   - Request permissions   - Include secondary contacts

      - Keep addresses updated

4. **Places Service** (`lib/services/places_service.dart`)

   - Find nearest POLICE, HOSPITAL, FIRE STATION4. **Regular Testing**:

   - Parse place details   - Test monthly with non-emergency numbers

      - Update contacts when moving

5. **Contact Sync Service** (`lib/services/contact_sync_service.dart`)   - Practice voice commands

   - Create/update phone contacts

   - Sync 3 fixed contacts## 📞 Example Contact Setup

   

6. **Background Service** (`lib/services/background_service.dart`)**Police Department**

   - Periodic location check- Name: City Police Emergency

   - Auto-update contacts- Type: Police

- Wake Word: police

### Phase 3: UI Screens- Address: 123 Main St, City

- Number: [Your local police number]

1. Auth screens (login/signup)

2. Onboarding flow**Ambulance Service**

3. Dashboard (new home screen)- Name: City Ambulance

4. Settings- Type: Ambulance

5. Contact management- Wake Word: ambulance

- Address: 456 Hospital Rd

### Phase 4: Cleanup- Number: [Your local ambulance]



1. Remove old voice detection code**Fire Department**

2. Test everything- Name: City Fire Station

3. Deploy- Type: Fire Station

- Wake Word: fire

## 📖 Documentation- Address: 789 Fire St

- Number: [Your local fire dept]

- **Full Plan**: See `REFACTOR_PLAN.md` for detailed checklist

- **Database**: See `SUPABASE_SETUP.md` for SQL schema## 🎓 Usage Scenario

- **Old Guides**: `QUICK_START_OLD.md` (previous version)

**Example Emergency Situation**:

## 🔑 Why This Approach is Better1. You need police assistance

2. Tap microphone button (turns red)

**Old Approach**:3. Say clearly: "help emergency police"

- ❌ Wake word detection (battery drain, iOS limitations)4. Countdown screen appears

- ❌ Speech recognition (errors, false positives)5. Verify correct contact

- ❌ Doesn't work reliably on lock screen6. Wait for automatic call OR cancel if wrong



**New Approach**:---

- ✅ Native Siri/Google Assistant (works on lock screen!)

- ✅ Location-aware (auto-updates when traveling)**Remember**: This app is a tool to assist in emergencies. Always prioritize your safety and use traditional methods if the app fails.

- ✅ Battery efficient (no always-on microphone)
- ✅ Simple UX ("Hey Siri, call POLICE")

## ⚠️ Important Notes

1. **API Keys**: Never commit `supabase_config.dart` or `google_config.dart` (already in `.gitignore`)
2. **Google Places Pricing**: Free tier covers 28,000 requests/month, then ~$17 per 1000 requests
3. **iOS Background Fetch**: Frequency is controlled by iOS, not guaranteed every hour
4. **Testing**: Test on real devices for location/contacts/background tasks

## 🆘 Need Help?

If you get stuck or need help implementing a specific service, just ask! I can help you:
- Implement any of the services listed above
- Debug Supabase or Google Places API issues
- Create UI screens
- Configure OAuth providers
- Test on devices

## 🎉 Ready to Start?

Once you complete Steps 1-4 above, you're ready to start implementing the services!

**Recommended first task**: Implement the Supabase service and test the connection.

```bash
# Test that everything compiles
flutter run
```

Good luck! 🚀
