# White Screen Debug Guide

## If You See White Screen

### Step 1: Open Browser Console
1. Press **F12** (or Right-click → Inspect)
2. Go to **Console** tab
3. Look for **red error messages**

### Step 2: Check Common Errors

**Error: "flutter.js not found"**
- Solution: Files aren't being served correctly
- Check: Network tab → Look for failed requests to `flutter.js`

**Error: "_flutter is undefined"**
- Solution: flutter.js didn't load
- Check: Network tab → Verify `flutter.js` loaded successfully

**Error: "Failed to initialize engine"**
- Solution: main.dart.js might have errors
- Check: Console for specific error details

**No errors but white screen**
- Solution: App might be loading but not rendering
- Check: Network tab → Verify all files loaded (200 status)

### Step 3: Check Network Tab
1. Press **F12** → **Network** tab
2. Refresh the page
3. Look for:
   - ✅ `index.html` - should be 200
   - ✅ `flutter.js` - should be 200
   - ✅ `main.dart.js` - should be 200
   - ❌ Any 404 errors

### Step 4: Verify Files Are Loading

Check these URLs directly:
- https://fisherman-sos-alert.vercel.app/index.html
- https://fisherman-sos-alert.vercel.app/flutter.js
- https://fisherman-sos-alert.vercel.app/main.dart.js

All should load (not 404).

## What I Just Fixed

1. ✅ Added loading indicator in HTML (not just JavaScript)
2. ✅ Increased timeout to 10 seconds
3. ✅ Added console logging for debugging
4. ✅ Better error messages with debug info
5. ✅ Ensured loading container stays visible

## After Deployment

The app should:
- Show loading spinner immediately
- Display error message if Flutter fails to load
- Show console logs for debugging

## Still White Screen?

1. **Check Console** (F12) - What errors do you see?
2. **Check Network Tab** - Are files loading?
3. **Try Hard Refresh** - Ctrl+Shift+R
4. **Try Incognito Mode** - Rule out cache issues
5. **Check Vercel Logs** - Are files being deployed?

## Share Debug Info

If still not working, share:
- Console errors (F12 → Console)
- Network tab errors (F12 → Network)
- Vercel deployment logs

