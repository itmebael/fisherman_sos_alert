# Live GPS Location Tracking Feature

## Overview
This feature enables real-time GPS location tracking for fishermen and displays their live locations on a map for both admin/coastguard and fishermen to view.

## Features Implemented

### 1. Database Table (`live_locations_table.sql`)
- Created `live_locations` table to store real-time GPS locations
- Includes fisherman information, coordinates, accuracy, speed, heading, altitude
- Has Row Level Security (RLS) policies for data access control
- Includes an upsert function for efficient location updates

### 2. Live Location Service (`lib/services/live_location_service.dart`)
- Automatically tracks fisherman GPS location
- Updates location every 30 seconds or when moved 10+ meters
- Handles location stream updates in real-time
- Manages periodic backup updates
- Starts/stops tracking automatically when map screen opens/closes

### 3. Database Service Updates (`lib/services/database_service.dart`)
- `updateLiveLocation()` - Updates or inserts fisherman location
- `getLiveLocations()` - Fetches all active live locations
- `getLiveLocationsStream()` - Real-time stream of live locations
- `stopLocationTracking()` - Stops tracking for a fisherman

### 4. Map Widget Updates (`lib/widgets/admin/map_widget_simple.dart`)
- Added live location markers on the map
- Blue markers for recent locations (< 5 minutes)
- Grey markers for older locations
- Clickable markers to view location details
- Real-time updates via Supabase stream

### 5. Screen Updates

#### Fisherman Map Screen (`lib/screens/fisherman/fisherman_map_screen.dart`)
- Automatically starts live location tracking when screen opens
- Stops tracking when screen closes
- Shows fisherman's own location and other fishermen's locations
- Displays admin/coastguard locations

#### Admin Map Screen (`lib/screens/admin/admin_map.dart`)
- Views all fishermen's live locations
- Views SOS alerts
- Views admin/coastguard locations
- Can track admin location if needed (optional)

## How to Use

### For Fishermen:
1. Open the "Map & Location" screen
2. Live location tracking starts automatically
3. Your location is shared with admin and other fishermen
4. See all other fishermen's locations on the map
5. Tracking stops when you leave the map screen

### For Admin/Coastguard:
1. Open the "Maritime Map" screen
2. View all fishermen's live locations (blue markers)
3. Click on a marker to see location details
4. See SOS alerts (red markers)
5. Monitor rescue operations in real-time

## Database Setup

Run the SQL script to create the table:
```sql
-- Execute live_locations_table.sql in your Supabase SQL editor
```

This will:
- Create the `live_locations` table
- Set up indexes for performance
- Configure RLS policies
- Create the upsert function

## Marker Colors

- **Blue markers** - Recent live fisherman locations (< 5 minutes old)
- **Grey markers** - Older live fisherman locations (> 5 minutes old)
- **Red markers** - SOS alerts
- **Green markers** - Admin/Coastguard locations
- **Orange marker** - Searched location

## Technical Details

### Update Frequency
- Location updates every 30 seconds
- Or when fisherman moves 10+ meters
- Updates only if significant movement or time elapsed

### Privacy & Security
- RLS policies ensure fishermen can only update their own location
- Admin can view all locations
- Anonymous users can view locations (for public maps if needed)

### Performance
- Efficient upsert operations
- Indexed queries for fast lookups
- Real-time updates via Supabase streams
- Minimal battery impact with smart update intervals

## Future Enhancements

Potential improvements:
- Location history tracking
- Geofencing alerts
- Route tracking
- Battery usage optimization
- Location sharing permissions
- Export location data

## Notes

- Live location tracking requires location permissions
- Updates happen in the background
- Tracking stops automatically when app is closed or map screen is left
- Locations older than 5 minutes are shown as inactive (grey)











