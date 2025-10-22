# Testing Checklist

## Pre-Testing Setup

### 1. API Configuration
- [ ] Add Google Places API key to `lib/core/constants/google_config.dart`
- [ ] Add Supabase URL and anon key to `lib/core/constants/supabase_config.dart`
- [ ] Verify `.gitignore` includes both config files

### 2. Supabase Setup
- [ ] Database tables created (users, emergency_contacts, update_history, user_settings)
- [ ] RLS policies enabled
- [ ] Google OAuth configured in Supabase dashboard
- [ ] Facebook OAuth configured in Supabase dashboard
- [ ] Anonymous sign-in enabled

### 3. Device Setup
- [ ] Physical iPhone connected (iOS 13+)
- [ ] Location services enabled on device
- [ ] Internet connection active

---

## Testing Flow

### Phase 1: Authentication (5-10 minutes)

#### Google Sign-In
- [ ] Launch app → Login screen appears
- [ ] Tap "Continue with Google"
- [ ] Google OAuth flow opens
- [ ] Select Google account
- [ ] Redirects back to app
- [ ] Dashboard appears
- [ ] User profile created in Supabase
- [ ] Default settings created (60 min interval, 10km radius)

#### Sign Out & Sign In Again
- [ ] Open Settings → Tap "Sign Out"
- [ ] Confirm sign out dialog
- [ ] Returns to Login screen
- [ ] Sign in with same Google account
- [ ] Dashboard appears with existing data

#### Facebook Sign-In (Optional)
- [ ] Sign out
- [ ] Tap "Continue with Facebook"
- [ ] Facebook OAuth flow
- [ ] Verify profile creation

#### Anonymous Sign-In
- [ ] Sign out
- [ ] Tap "Continue as Guest"
- [ ] Dashboard appears
- [ ] Anonymous user created

---

### Phase 2: Permissions (5 minutes)

#### Location Permission
- [ ] Dashboard shows "Location not available"
- [ ] Tap "Enable Location" button
- [ ] iOS permission dialog appears
- [ ] Grant "While Using App" or "Always" permission
- [ ] Current location appears on dashboard
- [ ] Address resolves and displays

#### Contacts Permission
- [ ] Will be requested when first syncing contacts
- [ ] Note: May be tested in Phase 3

---

### Phase 3: Emergency Contact Discovery (10 minutes)

#### Initial Contact Search
- [ ] On Dashboard, pull down to refresh OR tap "Update Now" FAB
- [ ] Location permission granted (if not already)
- [ ] Loading indicator appears
- [ ] Google Places API searches for:
  - [ ] Nearest police station
  - [ ] Nearest hospital
  - [ ] Nearest fire station
- [ ] All 3 contacts found (or error message if not)
- [ ] Contact cards appear on dashboard:
  - [ ] 🚓 POLICE with phone & address
  - [ ] 🏥 HOSPITAL with phone & address
  - [ ] 🚒 FIRE STATION with phone & address
- [ ] Verify phone numbers are valid
- [ ] Verify addresses are correct

#### Database Verification
- [ ] Check Supabase dashboard → emergency_contacts table
- [ ] 3 rows created for current user
- [ ] All fields populated (phone_number, address, lat/lon, place_id)
- [ ] is_ai_generated = true
- [ ] is_active = true

---

### Phase 4: Phone Contact Sync (10 minutes)

#### Contact Permission
- [ ] After finding emergency services, contacts permission requested
- [ ] Grant permission to access contacts
- [ ] Sync completes successfully

#### Verify Phone Contacts
- [ ] Open iPhone Contacts app
- [ ] Search for "POLICE"
  - [ ] Contact exists
  - [ ] Phone number matches dashboard
  - [ ] Note includes "Emergency contact - Auto-updated by Emergency App"
- [ ] Search for "HOSPITAL"
  - [ ] Contact exists
  - [ ] Phone number matches
- [ ] Search for "FIRE STATION"
  - [ ] Contact exists
  - [ ] Phone number matches

#### Test Siri Integration
- [ ] Say "Hey Siri, call POLICE"
- [ ] Siri should recognize contact and attempt to call
- [ ] Cancel before actual call connects
- [ ] Repeat for HOSPITAL and FIRE STATION

---

### Phase 5: Settings Configuration (5 minutes)

#### Open Settings
- [ ] From Dashboard → Tap Settings icon (⚙️)
- [ ] Settings screen appears

#### Modify Auto-Update Toggle
- [ ] Toggle "Automatic Updates" OFF
- [ ] Tap "Save"
- [ ] Success message appears
- [ ] Verify in Supabase: user_settings.auto_update_enabled = false

#### Adjust Update Interval
- [ ] Toggle "Automatic Updates" ON
- [ ] Slide "Update Interval" to 30 minutes
- [ ] Tap "Save"
- [ ] Verify in Supabase: user_settings.update_interval_minutes = 30

#### Adjust Search Radius
- [ ] Slide "Search Radius" to 20 km
- [ ] Tap "Save"
- [ ] Verify in Supabase: user_settings.location_radius_km = 20

---

### Phase 6: Background Service (15-30 minutes)

#### Enable Background Updates
- [ ] Settings → "Automatic Updates" ON
- [ ] "Update Interval" set to minimum (15 min for testing)
- [ ] Save settings
- [ ] Dashboard → Background Service card shows "Enabled"

#### Test Background Task Trigger
**Note**: Actual background testing requires waiting or location change

Option A: Wait for scheduled update
- [ ] Leave app running in background
- [ ] Wait 15+ minutes
- [ ] Check update_history table for new entries

Option B: Simulate location change
- [ ] Use Xcode → Debug → Simulate Location
- [ ] Change to a location >5km away
- [ ] Trigger background task (or wait for next scheduled run)
- [ ] Verify contacts updated if new services found

Option C: Manual immediate trigger
- [ ] Dashboard → Tap "Update Now" after changing settings
- [ ] Verify contacts update based on new radius

---

### Phase 7: Update History (5 minutes)

#### View Update History
- [ ] Dashboard → Tap History icon (🕒)
- [ ] Update History screen appears
- [ ] If no updates yet, shows "No Update History"

#### After Contact Update
- [ ] Perform a contact update (change location or radius)
- [ ] Return to Update History
- [ ] New entry appears showing:
  - [ ] Update reason
  - [ ] Old phone number → New phone number (if changed)
  - [ ] Old address → New address (if changed)
  - [ ] GPS coordinates
  - [ ] Timestamp

---

### Phase 8: Edge Cases & Error Handling (10 minutes)

#### No Internet Connection
- [ ] Turn off WiFi and cellular data
- [ ] Try to refresh contacts
- [ ] Error message appears: "No internet connection"
- [ ] App doesn't crash

#### Location Services Disabled
- [ ] iOS Settings → Privacy → Location → Emergency App → Never
- [ ] Return to app
- [ ] Try to refresh contacts
- [ ] Error message appears requesting location permission
- [ ] App doesn't crash

#### No Emergency Services Nearby
- [ ] Set very small radius (1 km) in rural area
- [ ] Try to refresh contacts
- [ ] Error message: "Could not find all emergency services"
- [ ] App doesn't crash

#### Invalid API Key
- [ ] Temporarily set wrong Google Places API key
- [ ] Try to refresh contacts
- [ ] Error message appears
- [ ] App doesn't crash

---

## Expected Results Summary

### After Complete Testing:

**Supabase Database:**
```
users table: 1 row (your user)
emergency_contacts table: 3 rows (POLICE, HOSPITAL, FIRE STATION)
user_settings table: 1 row (interval, radius, auto_update)
update_history table: N rows (one per contact update)
```

**iPhone:**
```
Contacts app: 3 contacts (POLICE, HOSPITAL, FIRE STATION)
Each with current phone numbers that auto-update
```

**App Functionality:**
```
✅ OAuth authentication working
✅ Location tracking active
✅ Emergency services found via Google Places
✅ Contacts synced to phone
✅ Siri can call emergency contacts by name
✅ Background updates scheduled
✅ Settings persist and affect behavior
✅ Update history tracks all changes
```

---

## Common Issues & Solutions

### Issue: "Location permission denied"
**Solution**: iOS Settings → Privacy → Location Services → Emergency App → While Using the App or Always

### Issue: "Contacts permission denied"
**Solution**: iOS Settings → Privacy → Contacts → Emergency App → Enable

### Issue: "No emergency services found"
**Solution**: 
- Increase search radius in Settings
- Verify internet connection
- Check Google Places API key is valid
- Ensure location is in populated area

### Issue: "Background updates not working"
**Solution**:
- Verify auto_update_enabled = true in settings
- Check iOS background refresh is enabled
- Ensure app has "Always" location permission for background updates
- WorkManager requires minimum 15 minute intervals

### Issue: "OAuth redirect not working"
**Solution**:
- Verify deep link scheme in Info.plist matches Supabase config
- Check OAuth redirect URLs in Google/Facebook console
- Ensure com.skilla.emergencyApp://login-callback is configured

---

## Performance Benchmarks

**Expected Performance:**
- Initial contact search: 3-5 seconds
- Contact sync to phone: 1-2 seconds
- Settings save: < 1 second
- History load: < 1 second
- Background update: 5-10 seconds

**Battery Impact:**
- With 60-minute interval: Minimal (< 1% per day)
- With 15-minute interval: Low (< 5% per day)

---

## Test Completion Checklist

- [ ] All authentication methods tested
- [ ] All permissions granted and working
- [ ] Emergency contacts found and displayed
- [ ] Phone contacts created and verified
- [ ] Siri integration tested
- [ ] Settings saved and applied
- [ ] Background service enabled
- [ ] Update history populated
- [ ] Edge cases handled gracefully
- [ ] No crashes encountered
- [ ] App performs within expected benchmarks

---

## Next Steps After Testing

1. **Production Deployment**
   - Remove debug flags
   - Optimize API keys (restrict by app bundle ID)
   - Enable Supabase row-level security
   - Set up error logging (Sentry, Firebase Crashlytics)

2. **App Store Preparation**
   - Create app icons
   - Write App Store description
   - Take screenshots
   - Create privacy policy
   - Request App Store review

3. **Feature Enhancements** (Optional)
   - Add custom emergency contacts
   - Emergency SOS button
   - Share location with family
   - Offline mode with cached contacts
   - Multiple languages support
