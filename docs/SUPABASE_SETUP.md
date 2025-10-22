# Supabase Setup Guide

## 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign up/login
2. Create a new project
3. Note down:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon Public Key**: Found in Settings → API

## 2. Database Schema

Run the following SQL in the Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Emergency contacts table
CREATE TABLE public.emergency_contacts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  contact_type TEXT NOT NULL CHECK (contact_type IN ('POLICE', 'HOSPITAL', 'FIRE_STATION', 'CUSTOM')),
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  place_id TEXT, -- Google Places ID
  is_ai_generated BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, contact_type, is_ai_generated) -- Only one AI-generated contact per type per user
);

-- Update history table (track contact changes)
CREATE TABLE public.update_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES public.emergency_contacts(id) ON DELETE CASCADE,
  old_phone_number TEXT,
  new_phone_number TEXT,
  old_address TEXT,
  new_address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  update_reason TEXT, -- 'location_change', 'manual_update', 'scheduled_update'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User settings table
CREATE TABLE public.user_settings (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  update_interval_minutes INTEGER DEFAULT 60, -- Background update frequency
  auto_update_enabled BOOLEAN DEFAULT true,
  location_radius_km DOUBLE PRECISION DEFAULT 10.0, -- Search radius for emergency services
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.update_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data

-- Users table policies
CREATE POLICY "Users can view own profile" 
  ON public.users FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON public.users FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
  ON public.users FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Emergency contacts policies
CREATE POLICY "Users can view own contacts" 
  ON public.emergency_contacts FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own contacts" 
  ON public.emergency_contacts FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own contacts" 
  ON public.emergency_contacts FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own contacts" 
  ON public.emergency_contacts FOR DELETE 
  USING (auth.uid() = user_id);

-- Update history policies
CREATE POLICY "Users can view own history" 
  ON public.update_history FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own history" 
  ON public.update_history FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- User settings policies
CREATE POLICY "Users can view own settings" 
  ON public.user_settings FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings" 
  ON public.user_settings FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings" 
  ON public.user_settings FOR UPDATE 
  USING (auth.uid() = user_id);

-- Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_contacts_updated_at BEFORE UPDATE ON public.emergency_contacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON public.user_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for performance
CREATE INDEX idx_emergency_contacts_user_id ON public.emergency_contacts(user_id);
CREATE INDEX idx_emergency_contacts_type ON public.emergency_contacts(contact_type);
CREATE INDEX idx_emergency_contacts_active ON public.emergency_contacts(is_active);
CREATE INDEX idx_update_history_user_id ON public.update_history(user_id);
CREATE INDEX idx_update_history_created_at ON public.update_history(created_at DESC);
```

## 3. Enable Authentication Providers

### Google OAuth
1. Go to Authentication → Providers → Google
2. Enable Google provider
3. Add your OAuth credentials from [Google Cloud Console](https://console.cloud.google.com)
4. Add authorized redirect URIs:
   - `https://your-project-id.supabase.co/auth/v1/callback`
   - `com.skilla.emergencyApp://login-callback` (for mobile deep linking)

### Facebook OAuth
1. Go to Authentication → Providers → Facebook
2. Enable Facebook provider
3. Add your OAuth credentials from [Facebook Developers](https://developers.facebook.com)
4. Add authorized redirect URIs:
   - `https://your-project-id.supabase.co/auth/v1/callback`
   - `com.skilla.emergencyApp://login-callback`

### Anonymous Sign-in
1. Go to Authentication → Providers → Anonymous
2. Enable Anonymous sign-ins

## 4. Add Environment Variables to Flutter

Create a file: `lib/core/constants/supabase_config.dart`

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

**⚠️ IMPORTANT**: Add `lib/core/constants/supabase_config.dart` to `.gitignore` to keep credentials safe!

## 5. Google Places API Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable "Places API" and "Geocoding API"
3. Create an API key
4. Restrict the key:
   - iOS: Add bundle ID `com.skilla.emergencyApp`
   - Android: Add package name + SHA-1 certificate fingerprint

AIzaSyAMTsOIjwCINeoW9han6n-0cXjKnitzqDg

5. Create file: `lib/core/constants/google_config.dart`

```dart
class GoogleConfig {
  static const String placesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
}
```

**⚠️ IMPORTANT**: Add `lib/core/constants/google_config.dart` to `.gitignore`!

## 6. iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<!-- Location Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby emergency services</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We update emergency contacts based on your location in the background</string>

<!-- Contacts Permission -->
<key>NSContactsUsageDescription</key>
<string>We need access to save emergency contacts (POLICE, HOSPITAL, FIRE STATION) to your phone</string>

<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>processing</string>
</array>

<!-- URL Schemes for OAuth -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.skilla.emergencyApp</string>
    </array>
  </dict>
</array>
```

## 7. Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.WRITE_CONTACTS"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>

<!-- Deep linking for OAuth -->
<activity>
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
      android:scheme="com.skilla.emergencyApp"
      android:host="login-callback" />
  </intent-filter>
</activity>
```

## 8. Install Dependencies

```bash
flutter pub get
cd ios && pod install && cd ..
```

## 9. Test Connection

Run the app and check if Supabase initializes successfully!

## Database Schema Visualization

```
┌─────────────────┐
│   auth.users    │ (Supabase managed)
│   - id (PK)     │
│   - email       │
└────────┬────────┘
         │
         ├─────────────────────┐
         │                     │
┌────────▼────────┐   ┌────────▼─────────────────┐
│     users       │   │  emergency_contacts       │
│  - id (FK)      │   │  - id (PK)                │
│  - email        │   │  - user_id (FK)           │
│  - display_name │   │  - contact_type           │
└─────────────────┘   │  - name                   │
                      │  - phone_number           │
                      │  - address                │
                      │  - latitude/longitude     │
                      │  - place_id               │
                      │  - is_ai_generated        │
                      └────────┬──────────────────┘
                               │
                      ┌────────▼────────────┐
                      │  update_history     │
                      │  - id (PK)          │
                      │  - user_id (FK)     │
                      │  - contact_id (FK)  │
                      │  - old_phone_number │
                      │  - new_phone_number │
                      │  - update_reason    │
                      └─────────────────────┘

┌─────────────────┐
│  user_settings  │
│  - user_id (PK) │
│  - update_interval_minutes │
│  - auto_update_enabled     │
│  - location_radius_km      │
└─────────────────┘
```

## Contact Type Mapping

The app will create **3 fixed phone contacts**:

| Contact Name | `contact_type` | Example Number | Siri Command |
|-------------|----------------|----------------|--------------|
| **POLICE** | `POLICE` | 911 or local | "Hey Siri, call POLICE" |
| **HOSPITAL** | `HOSPITAL` | Emergency dept | "Hey Siri, call HOSPITAL" |
| **FIRE STATION** | `FIRE_STATION` | Fire dept | "Hey Siri, call FIRE STATION" |

Custom user contacts use `contact_type = 'CUSTOM'`.
