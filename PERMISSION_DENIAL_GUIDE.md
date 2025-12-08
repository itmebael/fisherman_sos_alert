# Permission Denial Guide

## Issue: Location Permission Denied

When you see `Location permission after request: PermissionStatus.denied`, this means the user has denied location permission. Here's how to handle this:

### ✅ **What the App Now Does:**

1. **Shows Clear Error Message**: "Location permission is required to send SOS alerts"
2. **Provides Settings Button**: "Open Settings" button to go to app settings
3. **Manual Location Input**: If GPS fails, user can enter coordinates manually
4. **Better User Experience**: Clear guidance on what to do next

### 🔧 **For Users - How to Fix:**

#### **Option 1: Grant Permission in Settings**
1. Click "Open Settings" button in the error message
2. Go to "Permissions" or "App Permissions"
3. Find "Location" permission
4. Set it to "Allow" or "While using app"
5. Return to the app and try SOS button again

#### **Option 2: Manual Location Entry**
1. If permission is still denied, the app will show a dialog
2. Enter your latitude and longitude manually
3. You can find coordinates using:
   - Google Maps (right-click on your location)
   - GPS apps on your phone
   - Online coordinate finders

### 📱 **Device-Specific Instructions:**

#### **Android:**
1. Go to Settings > Apps > Fisherman SOS Alert
2. Tap "Permissions"
3. Enable "Location" permission
4. Return to app

#### **iOS:**
1. Go to Settings > Privacy & Security > Location Services
2. Find "Fisherman SOS Alert"
3. Set to "While Using App" or "Always"
4. Return to app

### 🚨 **Emergency Fallback:**

If location permission is permanently denied:
1. The app will show a manual location input dialog
2. Enter your coordinates manually
3. SOS alert will still be sent to emergency services
4. Include a note that location was manually entered

### 🔍 **Testing the Fix:**

1. **Deny permission** when prompted
2. **Click SOS button** - should show error with settings button
3. **Grant permission** in device settings
4. **Try SOS button again** - should work normally
5. **Or use manual entry** if permission still denied

### ✅ **Expected Behavior:**

- **Permission Granted**: SOS button works normally with GPS
- **Permission Denied**: Clear error message with settings button
- **Manual Entry**: Dialog to enter coordinates manually
- **No Crashes**: App handles all scenarios gracefully

### 🎯 **For Developers:**

The app now handles:
- `PermissionStatus.denied` - Shows settings button
- `PermissionStatus.permanentlyDenied` - Shows settings button
- GPS failure - Shows manual entry dialog
- Invalid coordinates - Shows validation error
- All scenarios gracefully without crashes

The SOS button will work in all scenarios, ensuring emergency alerts can always be sent!
