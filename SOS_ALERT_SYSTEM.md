# SOS Alert System Documentation

## Overview
The SOS Alert System is designed to allow fishermen to send emergency alerts with their GPS location to the Salbar_Mangirisda Coast Guard. When a fisherman clicks the SOS button, the system captures their current GPS coordinates and stores the data in the Supabase database.

## Database Schema
The system uses the following table structure in Supabase:

```sql
CREATE TABLE public.sos_alerts (
  id text NOT NULL,
  fisherman_id uuid NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  message text NULL,
  status text NOT NULL DEFAULT 'active'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  resolved_at timestamp with time zone NULL,
  CONSTRAINT sos_alerts_pkey PRIMARY KEY (id),
  CONSTRAINT sos_alerts_fisherman_id_fkey FOREIGN KEY (fisherman_id) REFERENCES fishermen (id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status_created_at ON public.sos_alerts USING btree (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_fisherman ON public.sos_alerts USING btree (fisherman_id);
```

## System Components

### 1. SOS Alert Model (`lib/models/sos_alert_model.dart`)
- Represents the SOS alert data structure
- Handles JSON serialization/deserialization
- Matches the database schema exactly

### 2. Location Service (`lib/services/location_service.dart`)
- Handles GPS location acquisition
- Includes retry mechanism for reliable location capture
- Provides high-accuracy GPS data for emergency situations

### 3. Database Service (`lib/services/database_service.dart`)
- Manages SOS alert creation and storage
- Handles database operations with Supabase
- Includes error handling and logging

### 4. SOS Provider (`lib/providers/sos_provider.dart`)
- Manages the SOS alert workflow
- Coordinates between location service and database
- Handles user authentication and fisherman record management

### 5. SOS Button Widget (`lib/widgets/fisherman/sos_button.dart`)
- Provides the user interface for sending SOS alerts
- Includes confirmation dialog and visual feedback
- Handles user interactions and error display

## How It Works

### 1. User Interaction
1. Fisherman opens the app and navigates to the home screen
2. Fisherman sees a large, animated SOS button
3. Fisherman taps the SOS button

### 2. Confirmation Process
1. A confirmation dialog appears asking if they want to send an emergency alert
2. The dialog explains that the alert will be sent to Salbar_Mangirisda Coast Guard
3. User can either cancel or confirm the SOS alert

### 3. GPS Location Capture
1. If confirmed, the system requests location permissions
2. The location service attempts to get the current GPS coordinates
3. If location is not available, it retries up to 3 times with 2-second delays
4. High-accuracy GPS data is captured with a 10-second timeout

### 4. Data Storage
1. The system ensures the fisherman exists in the database
2. If not, it creates a new fisherman record
3. An SOS alert record is created with:
   - Unique ID (timestamp-based)
   - Fisherman ID (UUID)
   - GPS coordinates (latitude, longitude)
   - Optional message
   - Status set to 'active'
   - Current timestamp
   - Resolved timestamp set to null

### 5. Database Operations
1. The alert data is inserted into the `sos_alerts` table
2. The system verifies the insertion was successful
3. Real-time updates are available through Supabase subscriptions

### 6. Coast Guard Notification
1. The system simulates sending the alert to the coast guard
2. A success notification is shown to the fisherman
3. The alert is now visible to admin users in real-time

## Key Features

### GPS Accuracy
- Uses high-accuracy GPS positioning
- Includes retry mechanism for unreliable connections
- Provides accuracy information in meters
- Times out after 10 seconds to prevent hanging

### Error Handling
- Comprehensive error handling for location services
- Database connection testing before operations
- User-friendly error messages
- Graceful fallbacks for failed operations

### Real-time Updates
- Uses Supabase real-time subscriptions
- Admin dashboard updates automatically
- No need to refresh to see new alerts

### Data Integrity
- Foreign key constraints ensure data consistency
- Proper data types for GPS coordinates
- Timestamp tracking for audit trails
- Status management for alert lifecycle

## Testing

The system includes comprehensive tests covering:
- Model serialization/deserialization
- GPS coordinate validation
- Database operations
- Error handling scenarios
- Philippines-specific coordinate validation

## Security Considerations

- Location permissions are properly requested
- User authentication is verified before sending alerts
- Database operations include proper error handling
- No sensitive data is logged in production

## Performance Optimizations

- Database indexes on frequently queried fields
- Efficient GPS location capture with timeouts
- Retry mechanisms prevent unnecessary delays
- Real-time updates reduce polling overhead

## Future Enhancements

- Integration with actual coast guard systems
- Push notifications for admin users
- Map visualization of SOS alerts
- Historical alert tracking and analytics
- Integration with weather data
- Automatic alert escalation based on time

## Troubleshooting

### Common Issues
1. **Location not available**: Check device GPS settings and permissions
2. **Database connection failed**: Verify internet connection and Supabase configuration
3. **Alert not appearing**: Check database logs and user authentication

### Debug Information
The system provides detailed logging for:
- GPS location capture attempts
- Database operations
- Error conditions
- User interactions

## API Endpoints

The system uses the following Supabase operations:
- `INSERT` into `sos_alerts` table
- `SELECT` from `sos_alerts` with joins to `fishermen` and `boats`
- `UPDATE` for alert status changes
- Real-time subscriptions for live updates

## Dependencies

- `geolocator`: GPS location services
- `supabase_flutter`: Database operations
- `provider`: State management
- `permission_handler`: Location permissions
- `flutter_map`: Map visualization (for admin)

This system provides a robust, reliable way for fishermen to send emergency alerts with their precise GPS location to the coast guard, ensuring quick response times in emergency situations.

