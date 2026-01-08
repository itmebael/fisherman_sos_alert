# Resolve Flow Implementation - Inactive → Rescued

## Overview
When an SOS alert is marked as resolved, it now follows a two-step process:
1. **Inactive**: Alert is first marked as "inactive"
2. **Rescued**: Alert is then marked as "rescued"

The dashboard fetches alerts with status "rescued" to display rescue statistics.

## Changes Made

### 1. Database Service (`lib/services/database_service.dart`)
- **Updated `getTotalRescuedCount()`**: Now queries alerts with status `'rescued'` instead of `'resolved'`
- **Updated `getRescueStatistics()`**: Now queries alerts with status `'rescued'` instead of `'resolved'`
- **Added `markAsInactiveThenRescued()`**: New method that:
  - First sets alert status to `'inactive'`
  - Then sets alert status to `'rescued'`
  - Saves casualties and injured counts
  - Creates notifications for the fisherman

### 2. Rescue Notifications Page (`lib/screens/admin/rescue_notifications_page.dart`)
- **Updated `_markAsResolved()`**: Now calls `markAsInactiveThenRescued()` instead of `updateSOSAlertStatus()`
- **Added Provider import**: Imports `AdminProviderSimple` to refresh dashboard data
- **Dashboard refresh**: Automatically refreshes dashboard data after marking as rescued
- **Status display**: Added support for `'inactive'` and `'rescued'` statuses with appropriate colors and icons

### 3. Status Colors and Icons
- **Inactive**: Gray color (`#718096`), pause circle icon
- **Rescued**: Green color (`#38A169`), check circle icon
- Status messages updated to reflect the new flow

### 4. Database Trigger (`update_resolve_flow_to_inactive_rescued.sql`)
- Updated trigger function to handle:
  - `'inactive'` status: Creates notification for fisherman
  - `'rescued'` status: Creates notification with rescue completion message
  - Maintains backward compatibility with `'resolved'` status

## Status Flow

```
active → on_the_way → inactive → rescued
```

1. **active**: Initial emergency alert
2. **on_the_way**: Rescue team dispatched
3. **inactive**: Alert being processed (intermediate state)
4. **rescued**: Rescue operation completed

## Dashboard Integration

The dashboard now:
- Fetches alerts with status `'rescued'` for rescue statistics
- Displays total rescued count from `'rescued'` alerts
- Shows casualties and injured counts from rescued alerts
- Automatically refreshes when an alert is marked as rescued

## SQL Files to Execute

1. **`add_casualties_injured_columns.sql`**: Adds casualties and injured columns
2. **`add_weather_column_to_reports.sql`**: Adds weather_data column
3. **`update_resolve_flow_to_inactive_rescued.sql`**: Updates trigger function

## Testing Checklist

- [ ] Mark an alert as resolved
- [ ] Verify alert status changes to "inactive" first
- [ ] Verify alert status changes to "rescued" 
- [ ] Verify dashboard shows updated rescue count
- [ ] Verify statistics popup shows correct data
- [ ] Verify fisherman receives notification
- [ ] Verify casualties and injured are saved correctly









