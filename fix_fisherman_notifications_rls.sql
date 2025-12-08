-- Fix RLS Policy for fisherman_notifications table
-- Run this in your Supabase SQL editor to allow authenticated users (admins) to insert notifications
-- =============================================

-- 1. Grant execute permission on create_fisherman_notification function to authenticated users
-- =============================================
GRANT EXECUTE ON FUNCTION public.create_fisherman_notification(text, text, text, text, jsonb) TO authenticated;

-- 2. Add RLS policy to allow authenticated users (admins) to insert notifications
-- =============================================
DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON public.fisherman_notifications;
CREATE POLICY "Allow authenticated users to insert notifications" ON public.fisherman_notifications
    FOR INSERT 
    TO authenticated 
    WITH CHECK (true);  -- Allow all authenticated users to insert (admins can create notifications for fishermen)

-- 3. Verify the policy was created
-- =============================================
-- SELECT * FROM pg_policies WHERE tablename = 'fisherman_notifications';

-- 4. Test the function
-- =============================================
-- SELECT public.create_fisherman_notification(
--     'sos_alert_id_here',
--     'sos_on_the_way',
--     'Rescue Team is On The Way',
--     'Coast Guard has marked your SOS alert as "On The Way". Help is on the way!',
--     '{"admin_name": "Coast Guard", "latitude": 11.7753, "longitude": 124.8861}'::jsonb
-- );















