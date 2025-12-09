# Vercel 404 Diagnostic Guide

## Current Error
"Failed to load resource: the server responded with a status of 404"

## Most Likely Causes

### 1. Dashboard Settings Not Updated (90% probability)
**Fix:** Update Vercel Dashboard Settings → General:
- Framework Preset: `Other`
- Output Directory: `build/web`
- Build Command: (empty)
- Install Command: (empty)

### 2. Files Not in Git (5% probability)
**Check:**
```bash
git ls-files build/web/index.html
git ls-files build/web/flutter.js
git ls-files build/web/main.dart.js
```

**Fix:** If missing, commit them:
```bash
git add build/web
git commit -m "Add build files"
git push
```

### 3. Wrong Output Directory (5% probability)
**Check:** Vercel Dashboard → Settings → General → Output Directory
**Should be:** `build/web` (exactly, no quotes, no trailing slash)

## Diagnostic Steps

### Step 1: Check Vercel Build Logs
1. Go to Vercel Dashboard → Deployments
2. Click latest deployment
3. Click "Build Logs" tab
4. Look for:
   - "Output directory not found"
   - "No files found"
   - "Build completed successfully"

### Step 2: Check What Files Are Deployed
1. Go to Vercel Dashboard → Deployments
2. Click latest deployment
3. Look for "Source" section
4. Check if it shows files from `build/web`

### Step 3: Test Direct File Access
Try accessing these URLs directly:
- `https://fisherman-sos-alert.vercel.app/index.html`
- `https://fisherman-sos-alert.vercel.app/flutter.js`
- `https://fisherman-sos-alert.vercel.app/main.dart.js`

**Expected:**
- `/index.html` → Should load (or redirect)
- `/flutter.js` → Should return JavaScript file
- `/main.dart.js` → Should return JavaScript file

**If all return 404:**
- Dashboard settings are wrong
- Files aren't being deployed

**If some work:**
- Routing issue (vercel.json problem)

### Step 4: Check Browser Console
1. Open browser DevTools (F12)
2. Go to "Network" tab
3. Reload page
4. Look for which files return 404:
   - `flutter.js` → Static file serving issue
   - `main.dart.js` → Static file serving issue
   - `assets/...` → Static file serving issue
   - `index.html` → Routing issue

## Quick Fixes

### Fix 1: Update Dashboard Settings (Do This First!)
1. Vercel Dashboard → Settings → General
2. Set exactly:
   ```
   Framework Preset: Other
   Output Directory: build/web
   Build Command: (empty)
   Install Command: (empty)
   ```
3. Save
4. Redeploy without cache

### Fix 2: Verify Files Are Committed
```bash
# Check if files exist
git ls-files build/web/index.html

# If missing, add them
git add build/web
git commit -m "Add build files for deployment"
git push
```

### Fix 3: Force Redeploy
1. Vercel Dashboard → Deployments
2. Click "⋯" on latest deployment
3. Click "Redeploy"
4. **UNCHECK** "Use existing Build Cache"
5. Click "Redeploy"

## Common Mistakes

❌ **Wrong:** Output Directory = `build/web/` (trailing slash)
✅ **Correct:** Output Directory = `build/web`

❌ **Wrong:** Output Directory = `./build/web` (relative path)
✅ **Correct:** Output Directory = `build/web`

❌ **Wrong:** Build Command = `flutter build web`
✅ **Correct:** Build Command = (empty - use pre-built files)

❌ **Wrong:** Framework Preset = Auto-detect
✅ **Correct:** Framework Preset = Other

## Still Not Working?

1. **Check deployment source:**
   - Vercel Dashboard → Deployments → Latest
   - Check "Source" → Should show commit hash
   - Verify commit includes `build/web` files

2. **Check file structure:**
   ```bash
   git show HEAD:build/web/index.html | head -5
   ```
   Should show HTML content

3. **Contact Vercel Support:**
   - Include deployment URL
   - Include build logs
   - Include vercel.json content
   - Include dashboard settings screenshot

