# 🚨 Emergency App

A Flutter-based emergency contact management app that automatically updates your phone's emergency contacts (POLICE, HOSPITAL, FIRE STATION) based on your GPS location.

## 🎯 Overview

This app solves the problem of outdated emergency contacts by automatically finding and updating the nearest emergency services based on your current location. It syncs directly to your phone's native contacts, making them accessible to Siri, Google Assistant, and emergency calling features.

### Key Features

- 📍 **Location-Aware**: Automatically detects your GPS location
- 🔄 **Auto-Update**: Updates contacts when you move >5km
- 📞 **Native Integration**: Syncs to phone contacts for Siri/Google Assistant access
- 🔐 **Secure Authentication**: Google OAuth, Facebook OAuth, or Anonymous sign-in
- ⚡ **Background Service**: Works autonomously with configurable intervals (15min-24hrs)
- 🗺️ **Google Places API**: Finds verified emergency services with phone numbers
- � **Custom Contacts**: Add your own emergency contacts with 3 input methods (GPS, Map Picker, Text Address)
- 🎯 **Smart Selection**: Compares Google Places vs Custom contacts, selects nearest one
- �📊 **Update History**: Track all contact changes
- ⚙️ **Customizable Settings**: Control update frequency, search radius, and auto-update behavior

## 🏗️ Architecture

### Backend
- **Supabase**: PostgreSQL database + Authentication + Real-time subscriptions
- **Google Places API (Legacy)**: Emergency service discovery with phone numbers

### State Management
- **Provider Pattern**: 6 providers for clean state management
  - `AuthProvider`: User authentication & profile
  - `LocationProvider`: GPS tracking & permissions
  - `EmergencyProvider`: Emergency service search & management with smart selection
  - `ContactSyncProvider`: Phone contact synchronization
  - `BackgroundServiceProvider`: Autonomous update scheduling
  - `CustomContactProvider`: Custom emergency contact management

### Services Layer
- `SupabaseService`: Database CRUD operations
- `AuthService`: Authentication wrapper
- `LocationService`: GPS tracking, permissions, distance calculations
- `GeocodingService`: Coordinate ↔ address conversion
- `PlacesService`: Google Places API integration
- `ContactSyncService`: Phone contact management
- `BackgroundService`: WorkManager task scheduler
- `CustomContactService`: Custom contact CRUD + smart selection logic

## 📱 How It Works

### Standard Mode (Google Places)
1. **User Signs In**: Google/Facebook OAuth or Anonymous authentication
2. **Location Detection**: App requests GPS permissions and gets current coordinates
3. **Emergency Search**: Searches Google Places API for nearest:
   - POLICE (police stations)
   - HOSPITAL (hospitals with emergency services)
   - FIRE STATION (fire departments)
4. **Phone Sync**: Creates/updates 3 contacts in native phone contacts
5. **Background Updates**: WorkManager runs periodic checks (configurable interval)
6. **Movement Detection**: Updates contacts when user moves >5km from last location
7. **History Tracking**: Logs all changes to Supabase database

### Custom Contacts Mode (New!)
1. **Add Custom Contact**: Navigate to "Manage" from dashboard
2. **Choose Input Method**:
   - 📍 **Current GPS**: Uses your exact location + reverse geocoding
   - 🗺️ **Map Picker**: Drag a marker on Google Maps to select location
   - ⌨️ **Text Address**: Type address, app converts to coordinates
3. **Save to Database**: Contact saved with `is_custom` flag
4. **Smart Selection**: When refreshing contacts, app:
   - Fetches Google Places results
   - Fetches your custom contacts
   - Calculates distance from your location to each option
   - Selects and saves the nearest one (Google or Custom)
5. **Visual Indicator**: Custom contacts show blue "Custom" badge on dashboard

## 🗄️ Database Schema

### Tables
```sql
-- User profiles
users (
  id UUID PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  provider TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

-- Emergency contacts
emergency_contacts (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  contact_type TEXT, -- 'police', 'hospital', 'fire_station'
  name TEXT,
  phone_number TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  place_id TEXT,
  is_ai_generated BOOLEAN,
  is_custom BOOLEAN DEFAULT false, -- NEW: Marks user-added contacts
  is_active BOOLEAN,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)

-- Update history
update_history (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  update_type TEXT, -- 'manual', 'automatic', 'background'
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  address TEXT,
  contacts_updated INTEGER,
  success BOOLEAN,
  error_message TEXT,
  created_at TIMESTAMP
)

-- User settings
user_settings (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  auto_update_enabled BOOLEAN DEFAULT true,
  update_interval_minutes INTEGER DEFAULT 60,
  search_radius_km DOUBLE PRECISION DEFAULT 10.0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- iOS 12.0+ / Android 6.0+
- Supabase account
- Google Cloud account (for Places API)
- Facebook Developer account (optional, for Facebook OAuth)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/jemaineosia/emergency_app.git
   cd emergency_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at https://supabase.com
   - Run the SQL schema from `docs/SUPABASE_SETUP.md`
   - Create `lib/core/constants/supabase_config.dart`:
     ```dart
     class SupabaseConfig {
       static const String supabaseUrl = 'YOUR_SUPABASE_URL';
       static const String supabaseAnonKey = 'YOUR_ANON_KEY';
     }
     ```

4. **Configure Google Places API**
   - Enable Places API (Legacy) in Google Cloud Console
   - Create an API key with iOS app restrictions
   - Create `lib/core/constants/google_config.dart`:
     ```dart
     class GoogleConfig {
       static const String placesApiKey = 'YOUR_PLACES_API_KEY';
       static const double defaultSearchRadius = 10000; // 10km
     }
     ```

5. **Configure OAuth (Optional)**
   - Set up Google OAuth in Google Cloud Console
   - Set up Facebook OAuth in Facebook Developer Console
   - Update iOS/Android OAuth configurations

6. **Run the app**
   ```bash
   flutter run
   ```

### Detailed Setup Guides

- [Supabase Setup](docs/SUPABASE_SETUP.md)
- [Google Places API Configuration](docs/FIX_GOOGLE_API_KEY.md)
- [Quick Start Guide](docs/QUICK_START.md)
- [Testing Checklist](docs/TESTING_CHECKLIST.md)

## 🔑 Environment Variables

Create these files (they're gitignored for security):

**`lib/core/constants/supabase_config.dart`**
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

**`lib/core/constants/google_config.dart`**
```dart
class GoogleConfig {
  static const String placesApiKey = 'AIza...';
  static const double defaultSearchRadius = 10000;
}
```

## 📋 Features Breakdown

### ✅ Completed Features

- [x] User authentication (Google, Facebook, Anonymous)
- [x] GPS location tracking with permissions
- [x] Google Places API integration
- [x] Emergency service search (Police, Hospital, Fire Station)
- [x] Phone contact synchronization
- [x] Background service with WorkManager
- [x] Configurable update intervals (15min-24hrs)
- [x] Movement-based updates (>5km threshold)
- [x] Update history tracking
- [x] Settings screen
- [x] Dashboard UI
- [x] Error handling and logging
- [x] **Custom emergency contacts** (Manual entry with 3 input methods)
- [x] **Smart selection algorithm** (Google vs Custom distance comparison)
- [x] **Interactive map picker** (Google Maps marker for location selection)
- [x] **Geocoding integration** (Address ↔ Coordinates conversion)
- [x] **Distance-based sorting** (Contacts sorted by proximity)
- [x] **Visual indicators** (Blue "Custom" badge on user-added contacts)

### 🎯 Future Enhancements

- [ ] Migrate to Places API (New) for better features
- [ ] Add map view showing all emergency services on dashboard
- [ ] International phone number formatting
- [ ] Offline mode with cached contacts
- [ ] Push notifications for contact updates
- [ ] Multi-language support
- [ ] Emergency calling shortcuts
- [ ] Contact sharing features
- [ ] Analytics dashboard
- [ ] Import/export custom contacts
- [ ] Custom contact categories (beyond police/hospital/fire)

## 🧪 Testing

Run the comprehensive testing checklist:

```bash
# See docs/TESTING_CHECKLIST.md for detailed steps
```

### Key Test Areas

1. **Authentication** (10 min): Google, Facebook, Anonymous sign-in
2. **Permissions** (5 min): Location (always/when-in-use), Contacts, Phone
3. **Contact Discovery** (10 min): Search for all 3 emergency types
4. **Phone Sync** (10 min): Verify native contacts created
5. **Custom Contacts** (15 min): Test all 3 input methods (GPS, Map, Text)
6. **Smart Selection** (10 min): Add custom contact closer than Google, verify it wins
7. **Settings** (5 min): Configure intervals, radius, auto-update
8. **Background Service** (15-30 min): Test autonomous updates
9. **Update History** (5 min): Verify logging
10. **Edge Cases** (10 min): No GPS, no results, API errors

## 📦 Dependencies

### Core
- `flutter_riverpod` / `provider` - State management
- `supabase_flutter` - Backend & Auth
- `http` - HTTP requests

### Location & Maps
- `geolocator` (12.0.0) - GPS tracking
- `geocoding` (3.0.0) - Address lookups
- `google_places_flutter` - Places API (legacy)
- `google_maps_flutter` (^2.5.0) - Interactive map picker for custom contacts

### Contacts & Permissions
- `flutter_contacts` (1.1.9) - Phone contact management
- `permission_handler` (11.0.1) - Runtime permissions

### Background Tasks
- `workmanager` (0.5.2) - Background job scheduler

### Authentication
- `google_sign_in` - Google OAuth
- `flutter_facebook_auth` - Facebook OAuth

## 🔒 Security & Privacy

- ✅ API keys gitignored (never committed to repo)
- ✅ Row-Level Security (RLS) policies on all Supabase tables
- ✅ OAuth tokens securely stored
- ✅ Location data only used for emergency service search
- ✅ No tracking or analytics (privacy-first)
- ✅ All contact data stored locally on device
- ✅ Minimal data retention (only what's necessary)

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS      | ✅ Tested | Requires iOS 14.0+ (updated for Google Maps) |
| Android  | ✅ Ready | Requires Android 6.0+ (API 23+) |
| Web      | ⚠️ Limited | No contact sync, no background service, no map picker |
| macOS    | ⚠️ Limited | No contact sync |
| Windows  | ❌ Not supported | No contact APIs |
| Linux    | ❌ Not supported | No contact APIs |

## 🐛 Known Issues

### Google Places API
- **Issue**: `INVALID_REQUEST` error
- **Solution**: Cannot use both `radius` and `rankby=distance` parameters together. Code uses `radius` only.

### iOS Deployment Target
- **Issue**: Google Maps Flutter requires iOS 14.0+
- **Solution**: Updated `ios/Podfile` and `ios/Flutter/AppFrameworkInfo.plist` to iOS 14.0

### iOS Background Updates
- **Issue**: Background updates may be limited by iOS battery optimization
- **Workaround**: Configure longer intervals (60min+) for better reliability

### Contact Permissions
- **Issue**: Some Android devices require multiple permission prompts
- **Workaround**: App handles permission flow automatically

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Jemaine Osia**
- GitHub: [@jemaineosia](https://github.com/jemaineosia)

## 🙏 Acknowledgments

- Google Places API for emergency service data
- Supabase for backend infrastructure
- Flutter community for excellent packages
- All contributors and testers

## 📞 Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check the [Testing Checklist](docs/TESTING_CHECKLIST.md)
- Review [Troubleshooting Guide](docs/FIX_GOOGLE_API_KEY.md)

## 🔄 Version History

### v2.1.0 (Current - October 2025)
- ✨ **Custom Emergency Contacts**: Add your own contacts manually
- 🗺️ **3 Input Methods**: Current GPS, Interactive Map Picker, Text Address
- 🎯 **Smart Selection**: Compares Google vs Custom, selects nearest
- 📏 **Distance Calculations**: Haversine formula for accurate proximity
- 🏷️ **Visual Indicators**: Blue "Custom" badge on user-added contacts
- 📱 **iOS 14.0+ Support**: Updated for Google Maps Flutter compatibility
- 🔧 **Bug Fixes**: Layout overflow fixes, API compatibility updates

### v2.0.0 (September 2025)
- Complete rewrite from voice-activated to location-based
- Switched from Firebase to Supabase
- Integrated Google Places API
- Added background service
- Added phone contact synchronization
- OAuth-only authentication (removed email/password)

### v1.0.0 (Deprecated - 2024)
- Voice-activated emergency calling
- Firebase backend
- iOS wake word detection (discontinued due to iOS limitations)

---

**Made with ❤️ for emergency preparedness**
