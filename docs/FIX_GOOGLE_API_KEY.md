# Fixing Google Places API Key Error

## Error Message
```
This IP, site or mobile application is not authorized to use this API key.
Request received from IP address 116.86.108.213, with empty referer
```

## Root Cause
You're using **Places API (New)** which requires different authentication than the legacy Places API. The new API uses:
- Different endpoint URLs (places.googleapis.com)
- Field masks instead of query parameters
- Different authentication headers

Your current code is using the **legacy Places API** endpoints, which won't work with the new API key!

---

## ⚠️ IMPORTANT: You Have Two Options

### Option A: Use Legacy Places API (Easier - Recommended for Now)

**This is the quickest fix since your code is already written for the legacy API.**

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to: **APIs & Services → Library**
3. Search for **"Places API"** (NOT "Places API (New)")
4. Click on **"Places API"** (the old one)
5. Click **"Enable"**
6. Go to **APIs & Services → Credentials**
7. Create a new API key OR edit your existing key
8. Under **API restrictions**:
   - Select **"Restrict key"**
   - Enable: **Places API** (legacy)
   - Enable: **Maps SDK for iOS** (if needed)
9. Under **Application restrictions**:
   - Select **"None"** for testing OR
   - Select **"iOS apps"** and add: `com.skilla.emergencyApp`
10. Click **Save**
11. Update your API key in `google_config.dart`

**This will work immediately with your current code!**

---

### Option B: Migrate to Places API (New) (More Work)

**If you want to use the new API, your code needs significant changes.**

The new API requires:
- Different base URL: `https://places.googleapis.com/v1/`
- HTTP headers with `X-Goog-Api-Key` and `X-Goog-FieldMask`
- Different request/response format
- JSON POST requests instead of GET

I can help you migrate the code if you want, but Option A is faster.

---

## Solution: Configure API Key Restrictions (For Legacy Places API)

### Option 1: Remove Restrictions (Quick Fix for Development)

**⚠️ WARNING: Only use this for development/testing. NOT recommended for production!**

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to: **APIs & Services → Credentials**
4. Find your API key and click **Edit** (pencil icon)
5. Under **Application restrictions**:
   - Select **"None"** (allows requests from any source)
6. Click **Save**
7. Wait 2-5 minutes for changes to propagate
8. Try the app again

---

### Option 2: Restrict to iOS App (Recommended for Production)

**This is the secure, production-ready approach:**

#### Step 1: Get your iOS Bundle ID
Your bundle ID is: `com.skilla.emergencyApp`

#### Step 2: Configure API Key for iOS
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to: **APIs & Services → Credentials**
4. Find your API key and click **Edit**
5. Under **Application restrictions**:
   - Select **"iOS apps"**
6. Click **"Add an item"**
7. Enter your bundle identifier: `com.skilla.emergencyApp`
8. Click **"Done"**
9. Click **"Save"**
10. Wait 2-5 minutes for changes to propagate

#### Step 3: Test
- Run the app on your iPhone
- Try to search for emergency contacts
- Should work now!

---

### Option 3: Restrict to Multiple Platforms (iOS + Android)

If you plan to support Android too:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Edit your API key
3. Under **Application restrictions**:
   - Select **"Android apps"** or **"iOS apps"** depending on what you want first
4. For iOS:
   - Add bundle ID: `com.skilla.emergencyApp`
5. For Android (future):
   - Add package name: `com.skilla.emergency_app`
   - Add your SHA-1 certificate fingerprint

**Note**: You might need separate API keys for iOS and Android, or use "HTTP referrers" restriction type.

---

## Alternative: Use HTTP Referrers (Not Recommended for Mobile)

This approach is designed for web apps but can work:

1. Edit your API key
2. Under **Application restrictions**:
   - Select **"HTTP referrers (web sites)"**
3. Add referrer: `*` (allows all)
4. Click **Save**

⚠️ **Not ideal for mobile apps** - use iOS/Android restrictions instead.

---

## Verify API is Enabled

**CRITICAL: Make sure you enable the LEGACY Places API, not the new one!**

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to: **APIs & Services → Library**
3. Search for **"Places API"** (you'll see two options):
   - ✅ **Places API** (the legacy one) - **ENABLE THIS ONE**
   - ❌ **Places API (New)** - Don't use this (requires code changes)
4. Click on **"Places API"** (legacy)
5. Make sure it shows **"API ENABLED"**
6. If not, click **Enable**

Also enable:
- **Geocoding API** - for address lookups ✓
- **Maps SDK for iOS** (optional) - if you add maps later

**Why?** Your code is written for the legacy API. The new API has completely different endpoints and authentication.

---

## Update Your Config File

Make sure your API key is correctly set in:
`lib/core/constants/google_config.dart`

```dart
class GoogleConfig {
  static const String placesApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
  static const double defaultSearchRadius = 10000; // 10km in meters
}
```

**Important**: 
- Don't use spaces or quotes around the key
- Copy the full key from Google Cloud Console
- The key should start with `AIza...`

---

## Test API Key Directly

You can test your API key in a browser to verify it works:

```
https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=37.7749,-122.4194&radius=5000&type=police&key=YOUR_API_KEY
```

Replace:
- `YOUR_API_KEY` with your actual key
- `37.7749,-122.4194` with any coordinates

**Expected Response**:
- If working: JSON with `"status": "OK"` and results
- If restricted: `"status": "REQUEST_DENIED"` with error message

---

## Common Issues & Solutions

### Issue: "INVALID_REQUEST" error
**Solution**: 
- **Cannot use both `radius` and `rankby=distance` together**
- The code has been fixed to use only `radius`
- This limits search to within 10km and returns up to 20 results
- Google will automatically sort by prominence/distance

### Issue: "API key not valid"
**Solution**: 
- Verify you copied the entire key
- Check for extra spaces or characters
- Make sure the key is from the correct Google Cloud project

### Issue: "This API project is not authorized"
**Solution**:
- Enable Places API in Google Cloud Console
- Wait a few minutes after enabling
- Check billing is enabled on your Google Cloud project

### Issue: "You have exceeded your daily request quota"
**Solution**:
- Check your quota in Google Cloud Console
- Places API has free tier: 5,000 requests/month
- Consider upgrading if you exceed limits

### Issue: Still getting IP restriction error after 5+ minutes
**Solution**:
- Clear app cache and reinstall
- Try using a different API key
- Create a new API key with no restrictions
- Verify your Google Cloud project has billing enabled

---

## Quick Fix for Immediate Testing

If you need to test RIGHT NOW:

1. Create a **new API key** in Google Cloud Console
2. Set **NO restrictions** on the new key
3. Update `google_config.dart` with the new key
4. Hot reload or restart the app
5. Test emergency contact search

**Then** go back and add proper iOS restrictions for production.

---

## Billing Note

**Google Places API Pricing** (as of 2024):
- First 5,000 requests/month: **FREE**
- Additional requests: ~$0.017 per request
- Set up billing alerts to avoid surprises

For this app:
- Initial search: 3 requests (POLICE, HOSPITAL, FIRE STATION)
- Details API: 3 additional requests (to get phone numbers)
- Background updates: 6 requests per update
- With hourly updates: ~4,320 requests/month (within free tier!)

---

## Recommended Final Configuration

For production:

1. **Create TWO API keys**:
   - **Key 1**: iOS-only (for your app)
     - Restriction: iOS apps
     - Bundle ID: com.skilla.emergencyApp
   
   - **Key 2**: Android-only (for future)
     - Restriction: Android apps
     - Package name + SHA-1

2. **Enable Required APIs**:
   - Places API ✓
   - Geocoding API ✓

3. **Set Quotas**:
   - Places API: Start with default free tier
   - Set up billing alerts at $10, $50

4. **Security**:
   - Never commit API keys to Git (already in .gitignore ✓)
   - Use environment-specific keys (dev/prod)
   - Rotate keys periodically

---

## After Fixing

Once you've updated the API key restrictions:

1. Wait 2-5 minutes
2. Kill the app completely (don't just hot reload)
3. Rebuild and run: `flutter run -d YOUR_DEVICE_ID`
4. Try searching for emergency contacts
5. Check debug console for any new errors

---

## Need More Help?

If still not working:

1. **Check debug logs** in Xcode or terminal for exact error
2. **Verify API key** by testing in browser first
3. **Check Google Cloud Console** → APIs & Services → Dashboard for error details
4. **Ensure billing is enabled** (required even for free tier)

The error message shows your IP: `116.86.108.213` - this suggests the API request is working but being blocked by restrictions. Following Option 1 or 2 above should fix it!

---

## Migration Guide: Legacy Places API → Places API (New)

**Only follow this if you want to use the new API. Otherwise, stick with legacy!**

### Why Migrate?
- Better performance
- More features (like EV charging stations)
- Future-proof (legacy API will eventually be deprecated)
- Better pricing (some operations are cheaper)

### What Changes Are Needed?

#### 1. Different Base URL
```dart
// OLD (Legacy):
'https://maps.googleapis.com/maps/api/place/nearbysearch/json'

// NEW:
'https://places.googleapis.com/v1/places:searchNearby'
```

#### 2. Different Authentication
```dart
// OLD: API key in query parameter
final url = Uri.parse(baseUrl).replace(queryParameters: {
  'key': apiKey,
  // ... other params
});
final response = await http.get(url);

// NEW: API key in header
final response = await http.post(
  Uri.parse(baseUrl),
  headers: {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.nationalPhoneNumber',
  },
  body: jsonEncode({
    'locationRestriction': {
      'circle': {
        'center': {'latitude': lat, 'longitude': lng},
        'radius': radius,
      }
    },
    'includedTypes': ['police'],
    'maxResultCount': 1,
  }),
);
```

#### 3. Different Response Format
```dart
// OLD: results array
final place = data['results'][0];
final name = place['name'];
final phone = place['formatted_phone_number'];

// NEW: places array with nested structure
final place = data['places'][0];
final name = place['displayName']['text'];
final phone = place['nationalPhoneNumber'];
```

### Migration Steps

If you want to migrate (I can help with this):

1. **Update API restrictions** in Google Cloud Console
   - Enable "Places API (New)" instead of legacy
   - Configure iOS app restrictions

2. **Rewrite places_service.dart**
   - Change all endpoints
   - Use POST instead of GET
   - Add proper headers
   - Update response parsing

3. **Update error handling**
   - New API has different error codes
   - Better error messages

4. **Test thoroughly**
   - Verify all 3 search types work
   - Check phone number formatting
   - Validate distance calculations

**Estimated Time**: 2-3 hours

Let me know if you want to migrate - I can rewrite the entire `places_service.dart` file for the new API!
