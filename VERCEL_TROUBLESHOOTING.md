# Vercel 404 Error Troubleshooting

If you're still getting a 404 error after deployment, try these steps:

## Step 1: Verify Vercel Project Settings

1. Go to your Vercel Dashboard: https://vercel.com/dashboard
2. Select your project: `fisherman-sos-alert`
3. Go to **Settings** → **General**
4. Check these settings:
   - **Framework Preset**: Should be **Other** or **None**
   - **Build Command**: Should be **empty** or blank
   - **Output Directory**: Should be **`build/web`**
   - **Install Command**: Can be empty

## Step 2: Check Deployment Logs

1. Go to your project in Vercel Dashboard
2. Click on the latest deployment
3. Check the **Build Logs** tab
4. Look for errors or warnings

## Step 3: Verify Files Are Deployed

In the deployment logs, you should see files being uploaded. Check if `build/web/index.html` is listed.

## Step 4: Manual Verification

Run these commands to verify everything is correct:

```bash
# Check if build/web exists locally
ls build/web/index.html

# Check if files are in git
git ls-files build/web/ | head -10

# Verify vercel.json
cat vercel.json
```

## Step 5: Alternative Configuration

If the current setup doesn't work, try this alternative `vercel.json`:

```json
{
  "version": 2,
  "public": false,
  "outputDirectory": "build/web"
}
```

## Step 6: Force Redeploy

1. In Vercel Dashboard, go to your project
2. Click **Deployments**
3. Find the latest deployment
4. Click **...** → **Redeploy**

## Step 7: Check Vercel CLI

If you have Vercel CLI installed, verify the project:

```bash
vercel inspect
```

## Common Issues

### Issue: Build/web not found
**Solution**: Make sure `build/web` is committed to git:
```bash
git add -f build/web/
git commit -m "Add web build"
git push
```

### Issue: Wrong output directory
**Solution**: In Vercel Dashboard → Settings → General, set Output Directory to `build/web`

### Issue: Build command running
**Solution**: Remove any build command from Vercel settings (leave it empty)

### Issue: Framework detection
**Solution**: Set Framework Preset to **Other** or **None** in Vercel settings

## Still Not Working?

1. Check Vercel's deployment logs for specific errors
2. Verify your repository is correctly connected to Vercel
3. Try creating a new Vercel project and importing your repository again
4. Contact Vercel support with your deployment logs

## Quick Test

To test if your build works locally:

```bash
cd build/web
python -m http.server 8000
```

Then visit `http://localhost:8000` - if it works locally, the issue is with Vercel configuration.

