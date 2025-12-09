# Fixing Vercel "Something went wrong" Error

## The Problem
Vercel is showing: "Something went wrong. There was an issue displaying the content."

## Solution Steps

### Step 1: Verify Vercel Dashboard Settings

1. Go to https://vercel.com/dashboard
2. Click on your project: `fisherman-sos-alert`
3. Go to **Settings** → **General**
4. **CRITICAL SETTINGS** - Make sure these are set:

   - **Framework Preset**: `Other` or `None` (NOT auto-detected)
   - **Build Command**: Leave **EMPTY/BLANK**
   - **Output Directory**: `build/web` (exactly this, no trailing slash)
   - **Install Command**: Leave **EMPTY/BLANK**
   - **Root Directory**: Leave empty (or `.`)

5. **Save** the settings

### Step 2: Verify Files Are Deployed

Check that `build/web` files are in your repository:

```bash
git ls-files build/web/ | head -10
```

You should see files like:
- `build/web/index.html`
- `build/web/main.dart.js`
- `build/web/flutter.js`

### Step 3: Force Redeploy

1. In Vercel Dashboard → **Deployments**
2. Find the latest deployment
3. Click **...** → **Redeploy**
4. Or trigger a new deployment by making a small change and pushing

### Step 4: Check Deployment Logs

1. Go to your deployment in Vercel
2. Click on the deployment
3. Check **Build Logs** tab
4. Look for errors about:
   - Missing `build/web` directory
   - Wrong output directory
   - Build command failures

### Step 5: Alternative - Use Vercel CLI

If dashboard doesn't work, try CLI:

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

## Common Issues

### Issue: "Output Directory not found"
**Solution**: Make sure `build/web` is committed to git:
```bash
git add -f build/web/
git commit -m "Add web build"
git push
```

### Issue: Build command running
**Solution**: In Vercel Settings → General, set Build Command to empty/blank

### Issue: Framework auto-detection
**Solution**: Set Framework Preset to "Other" or "None"

### Issue: Files not in repository
**Solution**: 
1. Build locally: `flutter build web --release`
2. Add to git: `git add -f build/web/`
3. Commit: `git commit -m "Add web build"`
4. Push: `git push`

## Verification Checklist

- [ ] `build/web/index.html` exists in git
- [ ] `build/web/main.dart.js` exists in git  
- [ ] `build/web/flutter.js` exists in git
- [ ] Vercel Settings → Output Directory = `build/web`
- [ ] Vercel Settings → Build Command = empty
- [ ] Vercel Settings → Framework = Other/None
- [ ] Latest deployment shows files being uploaded

## Still Not Working?

1. **Check Vercel Build Logs** - Look for specific error messages
2. **Try creating a new Vercel project** - Import your GitHub repo fresh
3. **Contact Vercel Support** - They can check your project settings

## Quick Test

To verify your build works locally:

```bash
cd build/web
python -m http.server 8000
```

Then visit `http://localhost:8000` - if it works locally, the issue is Vercel configuration.


