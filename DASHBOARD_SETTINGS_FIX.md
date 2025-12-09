# 🔧 Fix Vercel Dashboard Settings - Step by Step

## Current Issue
Your deployment shows "Ready" but returns 404 because **Dashboard Settings override vercel.json**.

## Fix Steps (Do This Now)

### Step 1: Navigate to Settings
1. In your Vercel dashboard (where you see "fisherman-sos-alert")
2. Click the **"Settings"** tab (in the navigation bar)
3. Click **"General"** in the left sidebar

### Step 2: Update These Settings EXACTLY

Find these fields and set them:

#### Framework Preset
- **Current:** (might be auto-detected or empty)
- **Change to:** `Other`
- **How:** Click dropdown, select "Other"

#### Build Command
- **Current:** (might have something or be empty)
- **Change to:** (DELETE everything, leave completely blank)
- **How:** Click the field, select all text, delete it, leave empty

#### Output Directory
- **Current:** (might be empty or wrong)
- **Change to:** `build/web`
- **How:** Type exactly: `build/web` (no quotes, no trailing slash)

#### Install Command
- **Current:** (might have something)
- **Change to:** (DELETE everything, leave completely blank)
- **How:** Click the field, select all text, delete it, leave empty

#### Root Directory
- **Current:** (probably empty)
- **Change to:** (leave empty - this is correct)

### Step 3: Save
- Click **"Save"** button at the bottom

### Step 4: Redeploy
1. Go back to **"Deployments"** tab
2. Find the latest deployment (the one showing "Ready")
3. Click the **"⋯"** (three dots) menu on the right
4. Click **"Redeploy"**
5. **IMPORTANT:** Make sure **"Use existing Build Cache"** is **UNCHECKED**
6. Click **"Redeploy"**

### Step 5: Wait and Test
- Wait 1-2 minutes for deployment to complete
- Visit: **https://fisherman-sos-alert.vercel.app**
- Should now load your app instead of 404!

---

## Visual Guide

Your Settings → General page should look like this:

```
┌─────────────────────────────────────┐
│ Framework Preset: [Other        ▼] │
│ Build Command:   [                 ] │ ← Empty!
│ Output Directory: [build/web      ] │ ← Exactly this!
│ Install Command:  [               ] │ ← Empty!
│ Root Directory:   [               ] │ ← Empty (OK)
└─────────────────────────────────────┘
```

---

## Why This Works

Vercel uses this priority:
1. **Dashboard Settings** (HIGHEST - overrides everything) ← This is the problem
2. vercel.json file ← Your file is correct, but ignored
3. Auto-detection (LOWEST)

Once you set Dashboard Settings correctly, Vercel will find `build/web/index.html` and serve it.

---

## Quick Verification

After saving settings, you can verify by:
1. Going to Settings → General
2. Checking that Output Directory shows: `build/web`
3. Checking that Build Command is empty
4. Checking that Framework Preset is "Other"

---

## If Still Not Working

1. **Check Build Logs:**
   - Go to Deployments → Click latest deployment → "Build Logs"
   - Look for "Output directory not found" errors

2. **Verify Files in Git:**
   ```bash
   git ls-files build/web/index.html
   ```
   Should show: `build/web/index.html`

3. **Test Locally:**
   ```bash
   cd build/web
   python -m http.server 8000
   ```
   Visit: http://localhost:8000
   - If this works → Issue is Vercel config
   - If this fails → Issue is with build files

