# Emergency App - Refactor Implementation Plan

## 🎯 Overview

**Date**: October 22, 2025  
**Status**: In Progress (Phase 1 - Foundation Complete)  
**Goal**: Refactor from wake-word detection to location-based emergency contact management with Siri/Google Assistant integration

## 📊 Progress Status

### ✅ Completed (Phase 1 - Foundation)
- [x] Updated `pubspec.yaml` with new dependencies
- [x] Created Supabase database schema (see `SUPABASE_SETUP.md`)
- [x] Created configuration files (`supabase_config.dart`, `google_config.dart`)
- [x] Updated `.gitignore` to protect sensitive keys
- [x] Created new data models:
  - `EmergencyContact` (with ContactType enum)
  - `UserProfile`
  - `UserSettings`
  - `UpdateHistory`

### 🚧 In Progress (Phase 2 - Core Services)
- [ ] Supabase service (database operations)
- [ ] Authentication service (Google/Facebook/Anonymous)
- [ ] Location service (get current position)
- [ ] Google Places service (find emergency services)
- [ ] Phone contact sync service (create/update device contacts)
- [ ] Background task service (periodic updates)

### ⏳ Not Started (Phase 3 - UI & Integration)
- [ ] Authentication screens (login/signup)
- [ ] Dashboard (show 3 emergency contacts)
- [ ] Settings screen (update interval, radius)
- [ ] User contacts management
- [ ] Onboarding flow
- [ ] Remove old voice detection code
- [ ] Platform-specific configurations

## 🏗️ New Architecture

### **User Flow:**
```
1. User downloads app
2. User registers (Google/Facebook/Anonymous)
3. App requests location & contacts permissions
4. App finds nearest POLICE, HOSPITAL, FIRE STATION via Google Places API
5. App creates 3 fixed contacts in phone:
   - "POLICE" → nearest police station number
   - "HOSPITAL" → nearest hospital number
   - "FIRE STATION" → nearest fire station number
6. Every hour (configurable), app checks location and updates contacts
7. User can say: "Hey Siri, call POLICE" or "OK Google, call HOSPITAL"
```

### **Tech Stack:**
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)
- **Location**: `geolocator` + `geocoding`
- **Emergency Data**: Google Places API
- **Contacts**: `flutter_contacts`
- **Background Tasks**: `workmanager`
- **State Management**: `provider`

### **Database Tables:**
1. `users` - User profiles (extends Supabase auth)
2. `emergency_contacts` - User's emergency contacts (AI + manual)
3. `update_history` - Track contact changes over time
4. `user_settings` - Update interval, radius, auto-update settings

## 📋 Implementation Checklist

### Phase 2: Core Services (CURRENT)

#### 2.1 Supabase Service
- [ ] Create `lib/services/supabase_service.dart`
- [ ] Initialize Supabase client
- [ ] Implement CRUD operations for all tables
- [ ] Handle real-time subscriptions
- [ ] Error handling and retry logic

#### 2.2 Authentication Service
- [ ] Create `lib/services/auth_service.dart`
- [ ] Implement Google Sign-In
- [ ] Implement Facebook Sign-In
- [ ] Implement Anonymous Sign-In
- [ ] Session management
- [ ] Create/update user profile on sign-in
- [ ] Initialize default user settings

#### 2.3 Location Service
- [ ] Create `lib/services/location_service.dart`
- [ ] Request location permissions
- [ ] Get current position
- [ ] Monitor location changes
- [ ] Calculate distance between coordinates
- [ ] Geocode (address ↔ coordinates)

#### 2.4 Google Places Service
- [ ] Create `lib/services/places_service.dart`
- [ ] Find nearest police station
- [ ] Find nearest hospital
- [ ] Find nearest fire station
- [ ] Parse place details (name, phone, address)
- [ ] Handle API errors and rate limits

#### 2.5 Phone Contact Sync Service
- [ ] Create `lib/services/contact_sync_service.dart`
- [ ] Request contacts permissions
- [ ] Check if contact exists (by name)
- [ ] Create new contact in phone
- [ ] Update existing contact in phone
- [ ] Sync 3 fixed contacts: POLICE, HOSPITAL, FIRE STATION
- [ ] Handle iOS/Android differences

#### 2.6 Background Task Service
- [ ] Create `lib/services/background_service.dart`
- [ ] Configure WorkManager
- [ ] Register periodic task (default: 1 hour)
- [ ] Task logic: Check location → Find emergency services → Update contacts
- [ ] Log updates to `update_history` table
- [ ] Handle task failures

### Phase 3: UI & Integration

#### 3.1 Authentication Screens
- [ ] Create `lib/screens/auth/login_screen.dart`
- [ ] Create `lib/screens/auth/signup_screen.dart`
- [ ] Google Sign-In button
- [ ] Facebook Sign-In button
- [ ] Anonymous Sign-In button
- [ ] Loading states
- [ ] Error handling

#### 3.2 Onboarding Flow
- [ ] Create `lib/screens/onboarding/welcome_screen.dart`
- [ ] Create `lib/screens/onboarding/permissions_screen.dart`
- [ ] Explain app purpose
- [ ] Request location permission
- [ ] Request contacts permission
- [ ] Initial emergency contact scan

#### 3.3 Dashboard
- [ ] Create `lib/screens/dashboard/home_screen.dart` (replace old one)
- [ ] Display 3 AI-generated contacts (POLICE, HOSPITAL, FIRE STATION)
- [ ] Display user's custom contacts
- [ ] Call button for each contact
- [ ] Last update timestamp
- [ ] Manual refresh button
- [ ] Settings button

#### 3.4 Settings Screen
- [ ] Create `lib/screens/settings/settings_screen.dart`
- [ ] Update interval slider (15 min - 24 hours)
- [ ] Search radius slider (1 km - 50 km)
- [ ] Auto-update toggle
- [ ] Account settings (logout, delete account)
- [ ] About/Help

#### 3.5 Contact Management
- [ ] Create `lib/screens/contacts/contact_list_screen.dart`
- [ ] Create `lib/screens/contacts/add_contact_screen.dart`
- [ ] Create `lib/screens/contacts/edit_contact_screen.dart`
- [ ] View update history
- [ ] Add custom emergency contact
- [ ] Edit custom contact
- [ ] Delete custom contact

#### 3.6 Remove Old Code
- [ ] Delete `lib/services/porcupine_service.dart`
- [ ] Delete `lib/services/speech_service.dart`
- [ ] Delete `lib/services/android_voice_service.dart`
- [ ] Delete `lib/screens/countdown_screen.dart`
- [ ] Delete `android/app/src/main/kotlin/.../VoiceListenerService.kt`
- [ ] Remove Porcupine/speech dependencies from `pubspec.yaml`
- [ ] Remove Android voice service permissions from `AndroidManifest.xml`
- [ ] Clean up `lib/providers/emergency_provider.dart`

### Phase 4: Platform Configuration

#### 4.1 iOS Configuration
- [ ] Update `ios/Runner/Info.plist`:
  - NSLocationWhenInUseUsageDescription
  - NSLocationAlwaysAndWhenInUseUsageDescription
  - NSContactsUsageDescription
  - UIBackgroundModes (fetch, processing)
  - CFBundleURLTypes (for OAuth)
- [ ] Configure Google Places API key (iOS)
- [ ] Test on physical iOS device
- [ ] Submit for App Store review with background justification

#### 4.2 Android Configuration
- [ ] Update `android/app/src/main/AndroidManifest.xml`:
  - ACCESS_FINE_LOCATION
  - ACCESS_COARSE_LOCATION
  - READ_CONTACTS
  - WRITE_CONTACTS
  - CALL_PHONE
  - INTERNET
- [ ] Configure Google Places API key (Android)
- [ ] Configure OAuth deep linking
- [ ] Test on physical Android device

### Phase 5: Testing & Deployment

#### 5.1 Testing
- [ ] Unit tests for services
- [ ] Integration tests for background tasks
- [ ] Test auth flow (all 3 providers)
- [ ] Test location updates
- [ ] Test contact sync (create & update)
- [ ] Test background fetch (iOS & Android)
- [ ] Test on different locations
- [ ] Test with airplane mode / offline
- [ ] Test permission denial scenarios

#### 5.2 Documentation
- [ ] User guide (how to use Siri/Google Assistant)
- [ ] Setup guide (Supabase + Google Places API)
- [ ] Privacy policy
- [ ] Terms of service
- [ ] App Store description
- [ ] Google Play description

#### 5.3 Deployment
- [ ] Configure production Supabase instance
- [ ] Set up production Google Places API key
- [ ] Configure OAuth (production redirect URIs)
- [ ] Build release APK (Android)
- [ ] Build IPA (iOS)
- [ ] Submit to App Store (with background mode justification)
- [ ] Submit to Google Play

## 🔑 Required API Keys & Setup

### 1. Supabase
- [ ] Create project at https://supabase.com
- [ ] Run SQL schema from `SUPABASE_SETUP.md`
- [ ] Enable Google OAuth provider
- [ ] Enable Facebook OAuth provider
- [ ] Enable Anonymous sign-ins
- [ ] Copy Project URL and Anon Key to `supabase_config.dart`

### 2. Google Places API
- [ ] Create project at https://console.cloud.google.com
- [ ] Enable Places API
- [ ] Enable Geocoding API
- [ ] Create API key
- [ ] Restrict key (iOS: bundle ID, Android: package + SHA-1)
- [ ] Copy API key to `google_config.dart`

### 3. Google OAuth (for Sign-In)
- [ ] Create OAuth credentials in Google Cloud Console
- [ ] Configure consent screen
- [ ] Add Supabase redirect URI
- [ ] Copy Client ID to Supabase

### 4. Facebook OAuth (for Sign-In)
- [ ] Create app at https://developers.facebook.com
- [ ] Configure Facebook Login product
- [ ] Add Supabase redirect URI
- [ ] Copy App ID and App Secret to Supabase

## 📝 Key Decisions Made

### Contact Naming Convention
- **Fixed 3 contacts**: "POLICE", "HOSPITAL", "FIRE STATION"
- **Reasoning**: Single contact per type for easy Siri/Google Assistant commands
- **Update behavior**: Replace phone number when location changes (not create new contact)

### Background Update Strategy
- **Default frequency**: 1 hour (configurable 15 min - 24 hours)
- **Method**: WorkManager (cross-platform)
- **iOS limitation**: Background fetch frequency controlled by iOS (not guaranteed)
- **Justification for review**: Explain safety-critical nature for travelers

### Data Storage
- **Primary**: Supabase (cloud sync across devices)
- **Local cache**: SharedPreferences for offline access
- **Phone contacts**: Only 3 AI-generated contacts (POLICE, HOSPITAL, FIRE STATION)
- **Custom contacts**: Stored in app only (not in phone contacts)

## 🚨 Known Issues & Limitations

### iOS Background Limitations
- iOS controls background fetch frequency (not guaranteed every hour)
- User can disable background refresh in iOS Settings
- App Store review may request justification for background modes

### Google Places API Limitations
- API has rate limits (be careful with frequent requests)
- Costs money after free tier (~$17 per 1000 requests)
- Some areas may not have complete emergency service data

### Contact Sync Limitations
- Android may require contacts app restart to show changes
- iOS contact photo/ringtone cannot be set via flutter_contacts
- Cannot verify if user manually deleted contacts

## 📚 Resources

- [Supabase Setup Guide](./SUPABASE_SETUP.md)
- [Google Places API Docs](https://developers.google.com/maps/documentation/places/web-service)
- [flutter_contacts Package](https://pub.dev/packages/flutter_contacts)
- [WorkManager Package](https://pub.dev/packages/workmanager)
- [Geolocator Package](https://pub.dev/packages/geolocator)

## 🎯 Next Steps

**IMMEDIATE ACTION REQUIRED:**

1. **Set up Supabase project** (15 minutes)
   - Go to https://supabase.com and create project
   - Run SQL from `SUPABASE_SETUP.md`
   - Copy URL and Anon Key to `lib/core/constants/supabase_config.dart`

2. **Set up Google Places API** (15 minutes)
   - Go to https://console.cloud.google.com
   - Enable Places API and Geocoding API
   - Create restricted API key
   - Copy key to `lib/core/constants/google_config.dart`

3. **Install dependencies** (2 minutes)
   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   ```

4. **Start Phase 2 implementation**
   - Begin with Supabase service
   - Then authentication service
   - Then location service
   - Continue in order...

**ESTIMATED REMAINING TIME**: 20-30 hours of development work

---

**Last Updated**: October 22, 2025  
**Current Phase**: Phase 1 Complete, Starting Phase 2
