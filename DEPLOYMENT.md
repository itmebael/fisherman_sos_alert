# Deployment Guide - Vercel

This guide will help you deploy your Flutter web application to Vercel.

## Quick Start

### Method 1: Vercel CLI (Fastest)

```bash
# Install Vercel CLI globally
npm install -g vercel

# Login to Vercel
vercel login

# Deploy (first time)
vercel

# Deploy to production
vercel --prod
```

### Method 2: GitHub Integration (Recommended for CI/CD)

1. Push your code to GitHub
2. Go to [vercel.com](https://vercel.com)
3. Click "Add New Project"
4. Import your GitHub repository
5. Vercel will auto-detect Flutter and configure the build

## Build Configuration

The project is pre-configured with `vercel.json`:

- **Build Command**: `flutter build web --release`
- **Output Directory**: `build/web`
- **Framework**: Flutter Web (SPA)

## Environment Variables

If you need to set environment variables:

1. Go to Vercel Dashboard → Your Project → Settings → Environment Variables
2. Add variables like:
   - `SUPABASE_URL` (if using env vars instead of hardcoded)
   - `SUPABASE_ANON_KEY` (if using env vars instead of hardcoded)

**Note**: Currently, Supabase credentials are in `lib/supabase_config.dart`. For production, consider using environment variables.

## Build Requirements

- **Flutter SDK**: Vercel will install Flutter automatically during build
- **Node.js**: Required for Vercel CLI (not needed for GitHub integration)
- **Build Time**: First build takes ~5-10 minutes (subsequent builds are faster)

## Post-Deployment Checklist

- [ ] Verify the app loads correctly
- [ ] Test authentication/login
- [ ] Test SOS alert functionality
- [ ] Verify Supabase connection
- [ ] Check browser console for errors
- [ ] Test on mobile devices
- [ ] Set up custom domain (optional)

## Troubleshooting

### Build Fails

1. **Check Flutter SDK**: Ensure Flutter is available in build environment
   - Vercel should auto-detect, but verify in build logs

2. **Check Dependencies**: Ensure all packages in `pubspec.yaml` are compatible
   ```bash
   flutter pub get
   flutter pub upgrade
   ```

3. **Check Build Logs**: Review Vercel build logs for specific errors

### App Doesn't Load

1. **Check Browser Console**: Look for JavaScript errors
2. **Verify Supabase Config**: Ensure credentials are correct
3. **Check CORS Settings**: Verify Supabase allows your Vercel domain
4. **Check Network Tab**: Verify all assets are loading

### Routing Issues

- The `vercel.json` includes SPA routing configuration
- All routes should redirect to `index.html`
- If routes don't work, check `vercel.json` rewrites section

## Performance Optimization

The `vercel.json` includes:
- Cache headers for static assets (JS, CSS, images)
- Immutable caching for Flutter assets
- Security headers (XSS protection, frame options)

## Monitoring

After deployment:
- Monitor Vercel Analytics (if enabled)
- Check Supabase dashboard for API usage
- Monitor error logs in Vercel dashboard

## Rollback

If something goes wrong:
1. Go to Vercel Dashboard → Deployments
2. Find the previous working deployment
3. Click "..." → "Promote to Production"

## Support

For issues:
- Vercel Docs: https://vercel.com/docs
- Flutter Web: https://flutter.dev/web
- Check build logs in Vercel dashboard


