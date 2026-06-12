# Coast Guard Account Setup Guide

## Overview

This guide explains how to create coast guard admin accounts **without hardcoding credentials** in the database.

---

## Files Created

1. **coastguards_setup.sql** - Creates the coastguards table and provides account creation templates
2. **remove_hardcoded_data.sql** - Creates configuration table and removes hardcoded email defaults
3. **update_triggers_remove_hardcoded.sql** - Updates trigger functions to use dynamic admin info
4. **fix_fishermen_rls_for_admin.sql** - Fixes RLS policies to allow coast guard to see fishermen

---

## Step-by-Step Setup

### Step 1: Run the Setup Scripts (in order)

Execute these scripts in your **Supabase SQL Editor**:

```
1. coastguards_setup.sql           → Creates coastguards table
2. remove_hardcoded_data.sql       → Creates configuration system
3. update_triggers_remove_hardcoded.sql → Updates triggers
4. fix_fishermen_rls_for_admin.sql → Allows admin to view fishermen
```

### Step 2: Create a Coast Guard User in Supabase Auth

1. Go to **Supabase Dashboard**
2. Click **Authentication** → **Users**
3. Click **Create new user**
4. Fill in:
   - **Email**: commander@coastguard.gov
   - **Password**: (create a temporary password - user should change on first login)
5. Click **Create user**
6. **Copy the User ID (UUID)** that appears

Example User ID: `550e8400-e29b-41d4-a716-446655440001`

### Step 3: Add Coast Guard to Database

Run this SQL (replace the values in brackets):

```sql
INSERT INTO public.coastguards (
  id,
  email,
  first_name,
  last_name,
  full_name,
  phone,
  agency_name,
  rank_position,
  user_type,
  is_active,
  created_at
)
VALUES (
  '550e8400-e29b-41d4-a716-446655440001',   -- UUID from Step 2
  'commander@coastguard.gov',
  'Juan',
  'Dela Cruz',
  'Juan Dela Cruz',
  '+63917000000',
  'Bureau of Fisheries and Aquatic Resources',
  'Station Commander',
  'coastguard',
  true,
  now()
);
```

### Step 4: Test the Account

1. Open the app on your device/emulator
2. Go to Login screen
3. Enter:
   - Email: `commander@coastguard.gov`
   - Password: (the temporary password from Step 2)
4. If first login, user should be prompted to change password

---

## Key Features

✅ **No Hardcoded Passwords**
- Passwords are managed by Supabase Auth, not hardcoded in SQL

✅ **Dynamic Default Admin Info**
- System automatically uses the first active coast guard
- Falls back to app_config values if no coast guard exists
- Can be changed without code modifications

✅ **Flexible Configuration**
- Default contact names and phone numbers stored in `app_config` table
- Can be updated at any time via SQL or app interface

✅ **Proper RLS Policies**
- Coast guards can see all fishermen
- Fishermen can only see their own data
- Service role has full access

---

## Common Tasks

### Create Multiple Coast Guard Accounts

Repeat Steps 2-3 for each coast guard:

```sql
-- Commander 1
INSERT INTO public.coastguards (id, email, first_name, last_name, full_name, agency_name, rank_position, user_type, is_active) 
VALUES ('uuid-here', 'commander1@coastguard.gov', 'Juan', 'Dela Cruz', 'Juan Dela Cruz', 'BFAR', 'Station Commander', 'coastguard', true);

-- Commander 2
INSERT INTO public.coastguards (id, email, first_name, last_name, full_name, agency_name, rank_position, user_type, is_active) 
VALUES ('uuid-here', 'commander2@coastguard.gov', 'Maria', 'Santos', 'Maria Santos', 'PNP-ACG', 'Officer in Charge', 'coastguard', true);
```

### Deactivate a Coast Guard Account

```sql
UPDATE public.coastguards
SET is_active = false, updated_at = now()
WHERE email = 'commander@coastguard.gov';
```

### Delete a Coast Guard Account

```sql
-- Step 1: Delete from database
DELETE FROM public.coastguards
WHERE email = 'commander@coastguard.gov';

-- Step 2: ALSO delete from Supabase Auth (Dashboard > Authentication > Users)
```

### Change Default Contact Info

```sql
UPDATE public.app_config
SET config_value = 'Your New Name'
WHERE config_key = 'default_coast_guard_contact_name';

UPDATE public.app_config
SET config_value = '+63-NEW-PHONE'
WHERE config_key = 'default_coast_guard_contact_phone';
```

### View All Coast Guard Accounts

```sql
SELECT 
  id,
  email,
  full_name,
  agency_name,
  rank_position,
  is_active,
  created_at
FROM public.coastguards
ORDER BY created_at DESC;
```

### View System Configuration

```sql
SELECT * FROM public.system_configuration;
```

---

## Security Best Practices

❌ **DO NOT:**
- Store passwords in SQL files
- Hardcode email addresses in code
- Share password files via email or chat

✅ **DO:**
- Use Supabase Auth for password management
- Store config in database tables
- Use environment variables for sensitive values
- Rotate passwords regularly
- Use strong, unique passwords for each account

---

## How the System Works

```
1. User signs in with email/password (via Supabase Auth)
2. App checks `coastguards` table for matching email
3. User type is set to 'coastguard'
4. Admin dashboard checks RLS policies
5. Coast guard can now view all fishermen and SOS alerts
6. When admin marks SOS as resolved:
   - System calls get_default_admin_info()
   - Sends notification with admin's name (not hardcoded)
7. Fisherman receives notification
```

---

## Troubleshooting

### "Email already exists" error
→ User already has a Supabase Auth account. Check with admin.

### Coast guard can't see fishermen
→ Run `fix_fishermen_rls_for_admin.sql` again to ensure RLS policies are in place.

### Notifications show "Coast Guard" instead of admin name
→ No active coast guard found. Either:
  - Create a coast guard account (Steps 2-3)
  - Or update `app_config` with default name

### Can't login after account creation
→ Check:
  1. User exists in Supabase Auth (Dashboard > Authentication > Users)
  2. Entry exists in `coastguards` table with matching email
  3. Coastguard is_active = true

---

## Additional Resources

- [Supabase Authentication Docs](https://supabase.com/docs/guides/auth)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Managing Users in Supabase](https://supabase.com/docs/guides/auth/managing-user-data)

---

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review the SQL scripts for comments and examples
3. Check Supabase logs for detailed error messages
4. Verify all scripts were executed in the correct order
