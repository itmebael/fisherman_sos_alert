# 🚨 URGENT: Fix 404 Error on Vercel

## Immediate Steps to Fix

### Step 1: Update Vercel Dashboard Settings

1. Go to: **https://vercel.com/dashboard**
2. Select your project: **fisherman-sos-alert**
3. Go to: **Settings** → **General**
4. Set these EXACT values:

   ```
   Framework Preset: Other
   Build Command: (DELETE everything - leave completely blank)
   Output Directory: build/web
   Install Command: (DELETE everything - leave completely blank)
   Root Directory: (leave empty)
   ```

5. Click **Save**

### Step 2: Redeploy

1. Go to **Deployments** tab
2. Click the **⋯** (three dots) on the latest deployment
3. Click **Redeploy**
4. Check **"Use existing Build Cache"** → **UNCHECK IT** (deploy without cache)
5. Click **Redeploy**

### Step 3: Verify

Wait 1-2 minutes, then visit: **https://fisherman-sos-alert.vercel.app**

---

## Why This Happens

Vercel Dashboard settings **OVERRIDE** `vercel.json`. Even though your `vercel.json` is correct, if the dashboard has wrong/empty settings, Vercel can't find your files.

**Priority Order:**
1. Dashboard Settings (HIGHEST - overrides everything)
2. vercel.json file
3. Auto-detection (LOWEST)

---

## Verification Checklist

After updating dashboard settings, verify:

- [ ] Framework Preset = "Other"
- [ ] Build Command = (empty/blank)
- [ ] Output Directory = "build/web" (exactly, no quotes)
- [ ] Install Command = (empty/blank)
- [ ] Root Directory = (empty)
- [ ] Redeployed without cache
- [ ] Site loads without 404

---

## If Still Not Working

1. **Check if files are in git:**
   ```bash
   git ls-files build/web/index.html
   ```
   Should show: `build/web/index.html`

2. **Verify vercel.json is committed:**
   ```bash
   git ls-files vercel.json
   ```

3. **Check deployment logs:**
   - Go to Vercel Dashboard → Deployments → Click latest deployment
   - Check "Build Logs" tab
   - Look for "Output directory not found" errors

4. **Test locally:**
   ```bash
   cd build/web
   python -m http.server 8000
   ```
   Visit: http://localhost:8000
   - If this works, issue is Vercel config
   - If this fails, issue is with build files

---

## Quick Test Command

After fixing dashboard settings, you can trigger a new deployment:

```bash
git commit --allow-empty -m "Trigger Vercel redeploy"
git push
```

This creates an empty commit that triggers Vercel to redeploy with new settings.

