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

The web interface for fishermen can be deployed to any web hosting service.

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
