# SOS Alert Database Integration

## Overview
The SOS Alert System is fully integrated with the `sos_alerts` table in the database. When a fisherman clicks the SOS button, the system automatically saves all relevant data to the database with proper denormalization of fisherman information.

## Database Schema
The system uses the following table structure:

```sql
CREATE TABLE public.sos_alerts (
  id text not null,
  latitude double precision not null,
  longitude double precision not null,
  message text null,
  status text not null default 'active'::text,
  created_at timestamp with time zone not null default now(),
  resolved_at timestamp with time zone null,
  fisherman_uid uuid null,
  fisherman_display_id text null,
  fisherman_first_name text null,
  fisherman_middle_name text null,
  fisherman_last_name text null,
  fisherman_name text null,
  fisherman_email text null,
  fisherman_phone text null,
  fisherman_user_type text null,
  fisherman_address text null,
  fisherman_fishing_area text null,
  fisherman_emergency_contact_person text null,
  fisherman_profile_picture_url text null,
  fisherman_profile_image_url text null,
  constraint sos_alerts_pkey primary key (id)
);
```

## How It Works

### 1. SOS Button Click Flow
When a fisherman clicks the SOS button:

1. **Location Retrieval**: System gets current GPS coordinates
2. **User Authentication**: Verifies fisherman is logged in
3. **Fisherman Verification**: Ensures fisherman exists in database
4. **Alert Creation**: Creates SOS alert with all required data
5. **Database Storage**: Saves alert with denormalized fisherman data
6. **Notification**: Sends alert to Coast Guard

### 2. Data Denormalization
The system automatically denormalizes fisherman data into the `sos_alerts` table:

- **fisherman_uid**: Primary fisherman ID
- **fisherman_display_id**: Human-readable fisherman ID
- **fisherman_first_name**: First name
- **fisherman_middle_name**: Middle name
- **fisherman_last_name**: Last name
- **fisherman_name**: Full name
- **fisherman_email**: Email address
- **fisherman_phone**: Phone number
- **fisherman_user_type**: User type (fisherman)
- **fisherman_address**: Home address
- **fisherman_fishing_area**: Fishing area
- **fisherman_emergency_contact_person**: Emergency contact
- **fisherman_profile_picture_url**: Profile picture URL
- **fisherman_profile_image_url**: Profile image URL

### 3. Alert Status Management
The system supports multiple alert statuses:

- **active**: Initial status when alert is created
- **acknowledged**: Coast Guard has acknowledged the alert
- **in_progress**: Rescue operation is in progress
- **resolved**: Alert has been resolved
- **cancelled**: Alert was cancelled

### 4. Key Features

#### Automatic Fisherman Creation
If a fisherman doesn't exist in the database, the system automatically creates a record using the authenticated user's information.

#### Real-time Updates
The system provides real-time streams for:
- Active SOS alerts
- Alert status changes
- New alerts

#### Error Handling
Comprehensive error handling includes:
- Database connection testing
- Location service validation
- User authentication verification
- Network connectivity checks

## Code Implementation

### SOS Button Widget
```dart
// Located in: lib/widgets/fisherman/sos_button.dart
class SOSButton extends StatefulWidget {
  // Handles SOS button tap and confirmation dialog
  // Calls SOSProvider.sendSOSAlert() when confirmed
}
```

### SOS Provider
```dart
// Located in: lib/providers/sos_provider.dart
class SOSProvider with ChangeNotifier {
  Future<void> sendSOSAlert({String? description}) async {
    // 1. Get current user
    // 2. Get GPS location
    // 3. Ensure fisherman exists in database
    // 4. Create SOS alert model
    // 5. Save to database via DatabaseService
    // 6. Send notification to Coast Guard
  }
}
```

### Database Service
```dart
// Located in: lib/services/database_service.dart
class DatabaseService {
  Future<bool> createSOSAlert({
    required String fishermanId,
    required double latitude,
    required double longitude,
    String? message,
  }) async {
    // 1. Fetch fisherman details
    // 2. Create alert data with denormalized fisherman info
    // 3. Insert into sos_alerts table
    // 4. Return success status
  }
}
```

## Testing

### Manual Testing
Run the test file to verify the complete flow:

```bash
dart test_sos_alert_creation.dart
```

This test verifies:
- Database connection
- Location services
- Fisherman creation
- SOS alert creation
- Database storage
- Data retrieval
- Status updates

### Integration Points

1. **Location Service**: Gets GPS coordinates
2. **Auth Service**: Manages user authentication
3. **Database Service**: Handles all database operations
4. **Notification Service**: Sends alerts to Coast Guard

## Database Indexes

The system includes optimized indexes for performance:

```sql
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status_created_at 
ON public.sos_alerts USING btree (status, created_at desc);
```

## Security Considerations

- All database operations use Supabase's built-in security
- User authentication is required for SOS alerts
- Location data is encrypted in transit
- Fisherman data is denormalized for performance and offline access

## Monitoring and Analytics

The system tracks:
- Alert creation timestamps
- Resolution times
- Geographic distribution of alerts
- Response times
- Success rates

## Future Enhancements

- Real-time map integration
- Push notifications
- Historical alert analysis
- Automated response workflows
- Integration with emergency services APIs























