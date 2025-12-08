# SOS Status Tracking and Fisherman Notifications Setup

## Overview
This SQL script creates a comprehensive system for tracking SOS alert status changes and automatically notifying fishermen when their SOS alert status changes to "on_the_way" or "resolved".

## Features

### 1. SOS Alert Status Tracking
- Adds `on_the_way_at` timestamp column to `sos_alerts` table
- Automatically updates timestamps when status changes
- Tracks when rescue team is dispatched and when alert is resolved

### 2. Fisherman Notifications System
- Creates `fisherman_notifications` table to store notifications
- Automatically creates notifications when SOS alert status changes
- Supports multiple notification types: `sos_on_the_way`, `sos_resolved`, `sos_active`, `weather`, `safety`, `system`, `admin_action`
- Tracks read/unread status for notifications

### 3. Automatic Notifications
- **On The Way**: When admin marks SOS alert as "on_the_way", fisherman receives notification
- **Resolved**: When admin marks SOS alert as "resolved", fisherman receives notification
- Notifications include admin name, timestamp, and location details

## Database Schema

### Updated Tables

#### `sos_alerts` (Updated)
- Added `on_the_way_at` timestamp column
- Tracks when rescue team was dispatched

#### `fisherman_notifications` (New)
```sql
- id: uuid (Primary Key)
- fisherman_uid: uuid (Fisherman UUID)
- fisherman_email: text (Fisherman email for anonymous alerts)
- fisherman_display_id: text (Fisherman display ID)
- sos_alert_id: text (Reference to SOS alert)
- notification_type: text (Type of notification)
- title: text (Notification title)
- message: text (Notification message)
- is_read: boolean (Read status)
- created_at: timestamp (Creation timestamp)
- read_at: timestamp (Read timestamp)
- notification_data: jsonb (Additional data)
```

## How It Works

### 1. Status Change Flow

When an admin updates an SOS alert status:

1. **Admin Action**: Admin marks SOS alert as "on_the_way" or "resolved"
2. **Trigger Fired**: Database trigger automatically fires
3. **Notification Created**: System creates notification for fisherman
4. **Fisherman Notified**: Fisherman sees notification in their notifications screen

### 2. Notification Creation

The system automatically:
- Gets SOS alert details (fisherman info, location, etc.)
- Gets admin name from `admin_notification_actions` table
- Creates notification with appropriate title and message
- Stores notification in `fisherman_notifications` table

### 3. Notification Types

- **sos_on_the_way**: "Rescue Team is On The Way"
- **sos_resolved**: "SOS Alert Resolved"
- **sos_active**: General SOS alert notifications
- **weather**: Weather alerts
- **safety**: Safety notifications
- **system**: System notifications
- **admin_action**: Admin action notifications

## Installation

### Step 1: Run the SQL Script
Run the `sos_status_tracking_and_notifications.sql` script in your Supabase SQL editor.

### Step 2: Verify Installation
Check that:
- `on_the_way_at` column exists in `sos_alerts` table
- `fisherman_notifications` table is created
- Triggers are created and active
- RLS policies are enabled

### Step 3: Test the System
1. Create a test SOS alert
2. Update status to "on_the_way"
3. Check that notification is created
4. Update status to "resolved"
5. Check that notification is created

## Usage Examples

### Update SOS Alert Status (Triggers Notification)
```sql
-- Mark SOS alert as "on the way"
UPDATE public.sos_alerts
SET status = 'on_the_way'
WHERE id = 'sos_alert_123';

-- Mark SOS alert as "resolved"
UPDATE public.sos_alerts
SET status = 'resolved'
WHERE id = 'sos_alert_123';
```

### Get Fisherman Notifications
```sql
-- Get all notifications for a fisherman
SELECT * FROM public.fisherman_notifications
WHERE fisherman_uid = 'fisherman-uuid-here'
ORDER BY created_at DESC;

-- Get unread notifications
SELECT * FROM public.fisherman_notifications
WHERE fisherman_uid = 'fisherman-uuid-here'
  AND is_read = false
ORDER BY created_at DESC;
```

### Mark Notifications as Read
```sql
-- Mark single notification as read
SELECT public.mark_notification_as_read('notification-uuid-here');

-- Mark all notifications as read
SELECT public.mark_all_notifications_as_read('fisherman-uuid-here');
```

### Get Unread Count
```sql
-- Get unread notifications count
SELECT * FROM public.fisherman_unread_notifications_count
WHERE fisherman_uid = 'fisherman-uuid-here';
```

## Integration with Application

### 1. Update SOS Alert Status
When admin updates SOS alert status in the application:
```dart
// Update status in database
await databaseService.updateSOSAlertStatus(alertId, 'on_the_way');
// Trigger will automatically create notification
```

### 2. Fetch Notifications
In the fisherman notifications screen:
```dart
// Get notifications from database
final notifications = await databaseService.getFishermanNotifications(fishermanUid);
```

### 3. Mark as Read
When fisherman views notification:
```dart
// Mark notification as read
await databaseService.markNotificationAsRead(notificationId);
```

## Security

### Row Level Security (RLS)
- Fishermen can only view their own notifications
- Service role can insert notifications (via triggers)
- Fishermen can update their own notifications (mark as read)

### Permissions
- Authenticated users can SELECT, INSERT, UPDATE their own notifications
- Service role has full access for trigger operations
- Anonymous users have limited access (for anonymous SOS alerts)

## Troubleshooting

### Notifications Not Created
1. Check that trigger is created: `SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_fisherman_status_change';`
2. Check that function exists: `SELECT * FROM pg_proc WHERE proname = 'notify_fisherman_status_change';`
3. Check SOS alert status: `SELECT status FROM sos_alerts WHERE id = 'alert_id';`

### Notifications Not Showing
1. Check RLS policies: `SELECT * FROM pg_policies WHERE tablename = 'fisherman_notifications';`
2. Check fisherman_uid: `SELECT fisherman_uid FROM sos_alerts WHERE id = 'alert_id';`
3. Check notifications: `SELECT * FROM fisherman_notifications WHERE sos_alert_id = 'alert_id';`

## Notes

- Notifications are automatically created when status changes
- Admin name is retrieved from `admin_notification_actions` table
- If no admin action found, default "Coast Guard" is used
- Notifications include location details and timestamps
- System supports both authenticated and anonymous fishermen















