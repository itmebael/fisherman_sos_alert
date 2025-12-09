# BantayDagat - Mobile Rescue And Location Tracking System

A Flutter application for emergency alert systems and location tracking, designed for both mobile and web platforms.

## Features

- **Admin Panel**: Coast Guard administrators can manage users, view reports, and monitor rescue operations
- **Fisherman Interface**: Fishermen can access their accounts through the web interface
- **Supabase Authentication**: Secure login system with role-based access control
- **Cross-Platform**: Works on mobile devices and web browsers

## Authentication System

### Admin Users (Coast Guard)
- **Login Method**: Through the mobile app login form
- **Access**: Full admin dashboard with user management, reports, and system settings
- **Restriction**: Only users with `userType: 'coastguard'` can access the admin panel

### Fisherman Users
- **Login Method**: Through web browser (external link)
- **Access**: Fisherman-specific features through web interface
- **Mobile App**: Shows information about accessing web login

## Supabase Integration

The app uses Supabase for:
- **Authentication**: User login and session management
- **Database**: PostgreSQL database for user data storage and management
- **Real-time**: Real-time updates for SOS alerts and notifications

## Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Supabase Configuration**
   - Update `lib/supabase_config.dart` with your Supabase project credentials
   - Supabase project should have Authentication and Database enabled

3. **Run the Application**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── constants/          # App constants, colors, routes
├── models/            # Data models
├── providers/         # State management with Provider
├── screens/           # UI screens
│   ├── admin/        # Admin panel screens
│   ├── fisherman/    # Fisherman screens
│   └── common/       # Shared screens (login, splash)
├── services/          # Business logic and Supabase services
├── utils/             # Utility functions
└── widgets/           # Reusable UI components
```

## Web Deployment

### Deploying to Vercel

The Flutter web app can be easily deployed to Vercel. Follow these steps:

#### Prerequisites
1. Install Flutter SDK (if not already installed)
2. Install Vercel CLI: `npm i -g vercel`
3. Ensure you have a Vercel account (sign up at [vercel.com](https://vercel.com))

#### Deployment Steps

**Option 1: Using Vercel CLI (Recommended)**

1. **Build the Flutter web app locally** (optional, Vercel will do this automatically):
   ```bash
   flutter build web --release
   ```

2. **Deploy to Vercel**:
   ```bash
   vercel
   ```
   
   Follow the prompts:
   - Set up and deploy? **Yes**
   - Which scope? Select your account
   - Link to existing project? **No** (for first deployment)
   - Project name? Enter a name or press Enter for default
   - Directory? Press Enter (uses current directory)
   - Override settings? **No**

3. **For production deployment**:
   ```bash
   vercel --prod
   ```

**Option 2: Using Vercel Dashboard**

1. **Push your code to GitHub/GitLab/Bitbucket**

2. **Go to [vercel.com](https://vercel.com) and sign in**

3. **Click "Add New Project"**

4. **Import your Git repository**

5. **Configure the project**:
   - Framework Preset: **Other**
   - Build Command: `flutter build web --release`
   - Output Directory: `build/web`
   - Install Command: `flutter pub get` (if needed)

6. **Add Environment Variables** (if needed):
   - Go to Project Settings → Environment Variables
   - Add any required environment variables

7. **Click "Deploy"**

#### Configuration Files

The project includes:
- `vercel.json` - Vercel configuration for Flutter web apps
- `.vercelignore` - Files to exclude from deployment

#### Important Notes

- **Flutter SDK**: Vercel will automatically detect and use Flutter if available in the build environment
- **Build Time**: First build may take 5-10 minutes as Flutter SDK needs to be installed
- **Supabase**: Make sure your Supabase credentials in `lib/supabase_config.dart` are correct for production
- **CORS**: Ensure your Supabase project allows requests from your Vercel domain

#### Troubleshooting

If the build fails:
1. Check that Flutter SDK is available in the build environment
2. Verify all dependencies are listed in `pubspec.yaml`
3. Check Vercel build logs for specific errors
4. Ensure `vercel.json` is correctly configured

#### Custom Domain

After deployment, you can add a custom domain:
1. Go to your project in Vercel dashboard
2. Navigate to Settings → Domains
3. Add your custom domain and follow DNS configuration instructions

## Security Features

- Role-based access control
- Admin-only mobile app access
- Secure Supabase authentication
- Input validation and sanitization

## Dependencies

- **Supabase**: Flutter client for authentication and database
- **State Management**: Provider
- **UI**: Material Design components
- **Location**: Geolocator for GPS tracking
- **Maps**: Google Maps integration
- **URL Handling**: url_launcher for external links

## License

This project is proprietary and confidential.
