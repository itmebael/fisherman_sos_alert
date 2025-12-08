-- =============================================
-- SOS Status Tracking and Fisherman Notifications
-- =============================================
-- This script creates tables and triggers for tracking SOS alert status changes
-- and automatically notifying fishermen when their SOS alert status changes to 
-- "on_the_way" or "resolved"

-- 1. Update sos_alerts table to add on_the_way_at timestamp
-- =============================================
ALTER TABLE public.sos_alerts 
ADD COLUMN IF NOT EXISTS on_the_way_at timestamp with time zone;

-- Add comment for documentation
COMMENT ON COLUMN public.sos_alerts.on_the_way_at IS 'Timestamp when the alert was marked as "on the way"';

-- Create index for on_the_way_at
CREATE INDEX IF NOT EXISTS idx_sos_alerts_on_the_way_at 
ON public.sos_alerts (on_the_way_at) 
WHERE on_the_way_at IS NOT NULL;

-- 2. Create fisherman_notifications table
-- =============================================
CREATE TABLE IF NOT EXISTS public.fisherman_notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  fisherman_uid uuid,
  fisherman_email text,
  fisherman_display_id text,
  sos_alert_id text NOT NULL,
  notification_type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  read_at timestamp with time zone,
  notification_data jsonb,
  CONSTRAINT fisherman_notifications_pkey PRIMARY KEY (id),
  CONSTRAINT fisherman_notifications_sos_alert_id_fkey 
    FOREIGN KEY (sos_alert_id) REFERENCES public.sos_alerts (id) ON DELETE CASCADE,
  CONSTRAINT fisherman_notifications_type_check 
    CHECK (notification_type IN ('sos_on_the_way', 'sos_resolved', 'sos_active', 'weather', 'safety', 'system', 'admin_action'))
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_fisherman_notifications_fisherman_uid 
ON public.fisherman_notifications (fisherman_uid) 
WHERE fisherman_uid IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_fisherman_notifications_fisherman_email 
ON public.fisherman_notifications (fisherman_email) 
WHERE fisherman_email IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_fisherman_notifications_sos_alert_id 
ON public.fisherman_notifications (sos_alert_id);

CREATE INDEX IF NOT EXISTS idx_fisherman_notifications_type 
ON public.fisherman_notifications (notification_type);

CREATE INDEX IF NOT EXISTS idx_fisherman_notifications_is_read 
ON public.fisherman_notifications (is_read);

CREATE INDEX IF NOT EXISTS idx_fisherman_notifications_created_at 
ON public.fisherman_notifications (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_fisherman_notifications_fisherman_unread 
ON public.fisherman_notifications (fisherman_uid, is_read, created_at DESC) 
WHERE fisherman_uid IS NOT NULL AND is_read = false;

-- Add comments for documentation
COMMENT ON TABLE public.fisherman_notifications IS 'Notifications for fishermen about SOS alerts and other important updates';
COMMENT ON COLUMN public.fisherman_notifications.id IS 'Unique identifier for the notification';
COMMENT ON COLUMN public.fisherman_notifications.fisherman_uid IS 'UUID of the fisherman (if authenticated)';
COMMENT ON COLUMN public.fisherman_notifications.fisherman_email IS 'Email of the fisherman (for anonymous alerts)';
COMMENT ON COLUMN public.fisherman_notifications.fisherman_display_id IS 'Display ID of the fisherman';
COMMENT ON COLUMN public.fisherman_notifications.sos_alert_id IS 'Reference to the SOS alert';
COMMENT ON COLUMN public.fisherman_notifications.notification_type IS 'Type of notification: sos_on_the_way, sos_resolved, sos_active, weather, safety, system, admin_action';
COMMENT ON COLUMN public.fisherman_notifications.title IS 'Title of the notification';
COMMENT ON COLUMN public.fisherman_notifications.message IS 'Message content of the notification';
COMMENT ON COLUMN public.fisherman_notifications.is_read IS 'Whether the notification has been read';
COMMENT ON COLUMN public.fisherman_notifications.created_at IS 'When the notification was created';
COMMENT ON COLUMN public.fisherman_notifications.read_at IS 'When the notification was read';
COMMENT ON COLUMN public.fisherman_notifications.notification_data IS 'Additional data in JSON format';

-- 3. Enable Row Level Security (RLS)
-- =============================================
ALTER TABLE public.fisherman_notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Allow fishermen to view their own notifications
CREATE POLICY "Allow fishermen to view their own notifications" ON public.fisherman_notifications
    FOR SELECT 
    TO authenticated 
    USING (
        fisherman_uid = auth.uid() 
        OR fisherman_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    );

-- Allow service role to insert notifications
CREATE POLICY "Allow service role to insert notifications" ON public.fisherman_notifications
    FOR INSERT 
    TO service_role 
    WITH CHECK (true);

-- Allow authenticated users to update their own notifications (mark as read)
CREATE POLICY "Allow fishermen to update their own notifications" ON public.fisherman_notifications
    FOR UPDATE 
    TO authenticated 
    USING (
        fisherman_uid = auth.uid() 
        OR fisherman_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        fisherman_uid = auth.uid() 
        OR fisherman_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    );

-- Allow anonymous users to view notifications by email (for anonymous SOS alerts)
CREATE POLICY "Allow anonymous users to view notifications by email" ON public.fisherman_notifications
    FOR SELECT 
    TO anon 
    USING (true);  -- Note: You may want to restrict this further based on your security requirements

-- 4. Create function to create fisherman notification
-- =============================================
CREATE OR REPLACE FUNCTION public.create_fisherman_notification(
    p_sos_alert_id text,
    p_notification_type text,
    p_title text,
    p_message text,
    p_notification_data jsonb DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    notification_id uuid;
    alert_record RECORD;
    v_fisherman_uid uuid;
    v_fisherman_email text;
    v_fisherman_display_id text;
BEGIN
    -- Get SOS alert details - handle case where alert might not exist
    BEGIN
        SELECT 
            fisherman_uid,
            fisherman_email,
            fisherman_display_id,
            fisherman_name,
            status
        INTO alert_record
        FROM public.sos_alerts
        WHERE id = p_sos_alert_id;
        
        -- If alert doesn't exist, log and return NULL
        IF NOT FOUND THEN
            RAISE WARNING 'SOS alert not found: %', p_sos_alert_id;
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Error fetching SOS alert %: %', p_sos_alert_id, SQLERRM;
            RETURN NULL;
    END;
    
    -- Extract fisherman identifiers (can be NULL)
    v_fisherman_uid := alert_record.fisherman_uid;
    v_fisherman_email := alert_record.fisherman_email;
    v_fisherman_display_id := alert_record.fisherman_display_id;
    
    -- At least one fisherman identifier should be present
    -- If all are NULL, we can't create a notification (no way to identify fisherman)
    IF v_fisherman_uid IS NULL AND v_fisherman_email IS NULL AND v_fisherman_display_id IS NULL THEN
        RAISE WARNING 'Cannot create notification for alert %: no fisherman identifier found', p_sos_alert_id;
        RETURN NULL;
    END IF;
    
    -- Create notification (fisherman fields can be NULL, but at least one should be set)
    BEGIN
        INSERT INTO public.fisherman_notifications (
            fisherman_uid,
            fisherman_email,
            fisherman_display_id,
            sos_alert_id,
            notification_type,
            title,
            message,
            notification_data,
            is_read,
            created_at
        ) VALUES (
            v_fisherman_uid,
            v_fisherman_email,
            v_fisherman_display_id,
            p_sos_alert_id,
            p_notification_type,
            p_title,
            p_message,
            p_notification_data,
            false,
            now()
        ) RETURNING id INTO notification_id;
        
        RETURN notification_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Error creating notification for alert %: %', p_sos_alert_id, SQLERRM;
            RETURN NULL;
    END;
END;
$$;

-- 5. Create trigger function to notify fisherman when status changes to "on_the_way"
-- =============================================
CREATE OR REPLACE FUNCTION public.notify_fisherman_on_the_way()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    admin_name text;
    admin_email text;
BEGIN
    -- Check if status changed to "on_the_way"
    IF NEW.status = 'on_the_way' AND (OLD.status IS NULL OR OLD.status != 'on_the_way') THEN
        -- Update on_the_way_at timestamp
        NEW.on_the_way_at = now();
        
        -- Get admin name from the most recent admin action
        SELECT 
            ana.admin_name,
            ana.admin_email
        INTO admin_name, admin_email
        FROM public.admin_notification_actions ana
        WHERE ana.sos_alert_id = NEW.id
          AND ana.action_type = 'mark_on_the_way'
        ORDER BY ana.action_timestamp DESC
        LIMIT 1;
        
        -- If no admin action found, use default
        IF admin_name IS NULL THEN
            admin_name := 'Coast Guard';
            admin_email := 'coastguard@salbar-mangirisda.gov';
        END IF;
        
        -- Create notification for fisherman
        PERFORM public.create_fisherman_notification(
            NEW.id,
            'sos_on_the_way',
            'Rescue Team is On The Way',
            COALESCE(admin_name, 'Coast Guard') || ' has marked your SOS alert as "On The Way". Help is on the way!',
            jsonb_build_object(
                'sos_alert_id', NEW.id,
                'status', NEW.status,
                'admin_name', admin_name,
                'admin_email', admin_email,
                'latitude', NEW.latitude,
                'longitude', NEW.longitude,
                'on_the_way_at', NEW.on_the_way_at
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- 6. Create trigger function to notify fisherman when status changes to "resolved"
-- =============================================
CREATE OR REPLACE FUNCTION public.notify_fisherman_resolved()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    admin_name text;
    admin_email text;
BEGIN
    -- Check if status changed to "resolved"
    IF NEW.status = 'resolved' AND (OLD.status IS NULL OR OLD.status != 'resolved') THEN
        -- Update resolved_at timestamp if not already set
        IF NEW.resolved_at IS NULL THEN
            NEW.resolved_at = now();
        END IF;
        
        -- Get admin name from the most recent admin action
        SELECT 
            ana.admin_name,
            ana.admin_email
        INTO admin_name, admin_email
        FROM public.admin_notification_actions ana
        WHERE ana.sos_alert_id = NEW.id
          AND ana.action_type = 'mark_resolved'
        ORDER BY ana.action_timestamp DESC
        LIMIT 1;
        
        -- If no admin action found, use default
        IF admin_name IS NULL THEN
            admin_name := 'Coast Guard';
            admin_email := 'coastguard@salbar-mangirisda.gov';
        END IF;
        
        -- Create notification for fisherman
        PERFORM public.create_fisherman_notification(
            NEW.id,
            'sos_resolved',
            'SOS Alert Resolved',
            COALESCE(admin_name, 'Coast Guard') || ' has marked your SOS alert as "Resolved". You are safe now!',
            jsonb_build_object(
                'sos_alert_id', NEW.id,
                'status', NEW.status,
                'admin_name', admin_name,
                'admin_email', admin_email,
                'latitude', NEW.latitude,
                'longitude', NEW.longitude,
                'resolved_at', NEW.resolved_at
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- 7. Create combined trigger function for both status changes
-- =============================================
CREATE OR REPLACE FUNCTION public.notify_fisherman_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    admin_name text;
    admin_email text;
    notification_title text;
    notification_message text;
    notification_type text;
BEGIN
    -- Handle "on_the_way" status
    IF NEW.status = 'on_the_way' AND (OLD.status IS NULL OR OLD.status != 'on_the_way') THEN
        -- Update on_the_way_at timestamp
        NEW.on_the_way_at = now();
        
        -- Get admin name from the most recent admin action
        SELECT 
            ana.admin_name,
            ana.admin_email
        INTO admin_name, admin_email
        FROM public.admin_notification_actions ana
        WHERE ana.sos_alert_id = NEW.id
          AND ana.action_type = 'mark_on_the_way'
        ORDER BY ana.action_timestamp DESC
        LIMIT 1;
        
        -- Set notification details
        notification_type := 'sos_on_the_way';
        notification_title := 'Rescue Team is On The Way';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' has marked your SOS alert as "On The Way". Help is on the way!';
        
        -- Create notification (don't fail if notification creation fails)
        BEGIN
            PERFORM public.create_fisherman_notification(
                NEW.id,
                notification_type,
                notification_title,
                notification_message,
                jsonb_build_object(
                    'sos_alert_id', NEW.id,
                    'status', NEW.status,
                    'admin_name', COALESCE(admin_name, 'Coast Guard'),
                    'admin_email', COALESCE(admin_email, 'coastguard@salbar-mangirisda.gov'),
                    'latitude', NEW.latitude,
                    'longitude', NEW.longitude,
                    'on_the_way_at', NEW.on_the_way_at
                )
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error but don't prevent status update
                RAISE WARNING 'Failed to create notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    -- Handle "resolved" status
    IF NEW.status = 'resolved' AND (OLD.status IS NULL OR OLD.status != 'resolved') THEN
        -- Update resolved_at timestamp if not already set
        IF NEW.resolved_at IS NULL THEN
            NEW.resolved_at = now();
        END IF;
        
        -- Get admin name from the most recent admin action
        BEGIN
            SELECT 
                ana.admin_name,
                ana.admin_email
            INTO admin_name, admin_email
            FROM public.admin_notification_actions ana
            WHERE ana.sos_alert_id = NEW.id
              AND ana.action_type = 'mark_resolved'
            ORDER BY ana.action_timestamp DESC
            LIMIT 1;
        EXCEPTION
            WHEN OTHERS THEN
                -- If we can't get admin info, use defaults
                admin_name := NULL;
                admin_email := NULL;
        END;
        
        -- Set notification details
        notification_type := 'sos_resolved';
        notification_title := 'SOS Alert Resolved';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' has marked your SOS alert as "Resolved". You are safe now!';
        
        -- Create notification (don't fail if notification creation fails)
        BEGIN
            PERFORM public.create_fisherman_notification(
                NEW.id,
                notification_type,
                notification_title,
                notification_message,
                jsonb_build_object(
                    'sos_alert_id', NEW.id,
                    'status', NEW.status,
                    'admin_name', COALESCE(admin_name, 'Coast Guard'),
                    'admin_email', COALESCE(admin_email, 'coastguard@salbar-mangirisda.gov'),
                    'latitude', NEW.latitude,
                    'longitude', NEW.longitude,
                    'resolved_at', NEW.resolved_at
                )
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error but don't prevent status update
                RAISE WARNING 'Failed to create notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

-- 8. Create trigger on sos_alerts table
-- =============================================
DROP TRIGGER IF EXISTS trigger_notify_fisherman_status_change ON public.sos_alerts;

CREATE TRIGGER trigger_notify_fisherman_status_change
    BEFORE UPDATE ON public.sos_alerts
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE FUNCTION public.notify_fisherman_status_change();

-- 9. Create function to mark notification as read
-- =============================================
CREATE OR REPLACE FUNCTION public.mark_notification_as_read(
    p_notification_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.fisherman_notifications
    SET 
        is_read = true,
        read_at = now()
    WHERE id = p_notification_id
      AND (
          fisherman_uid = auth.uid() 
          OR fisherman_email IN (
              SELECT email FROM auth.users WHERE id = auth.uid()
          )
      );
    
    RETURN FOUND;
END;
$$;

-- 10. Create function to mark all notifications as read for a fisherman
-- =============================================
CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read(
    p_fisherman_uid uuid DEFAULT NULL,
    p_fisherman_email text DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    updated_count integer;
BEGIN
    UPDATE public.fisherman_notifications
    SET 
        is_read = true,
        read_at = now()
    WHERE is_read = false
      AND (
          (p_fisherman_uid IS NOT NULL AND fisherman_uid = p_fisherman_uid)
          OR (p_fisherman_email IS NOT NULL AND fisherman_email = p_fisherman_email)
          OR (p_fisherman_uid IS NULL AND p_fisherman_email IS NULL AND (
              fisherman_uid = auth.uid() 
              OR fisherman_email IN (
                  SELECT email FROM auth.users WHERE id = auth.uid()
              )
          ))
      );
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$;

-- 11. Create view for unread notifications count
-- =============================================
CREATE OR REPLACE VIEW public.fisherman_unread_notifications_count AS
SELECT 
    fisherman_uid,
    fisherman_email,
    fisherman_display_id,
    COUNT(*) as unread_count
FROM public.fisherman_notifications
WHERE is_read = false
GROUP BY fisherman_uid, fisherman_email, fisherman_display_id;

-- 12. Grant necessary permissions
-- =============================================
GRANT SELECT, INSERT, UPDATE ON public.fisherman_notifications TO authenticated;
GRANT SELECT ON public.fisherman_unread_notifications_count TO authenticated;
-- Grant execute permission on create_fisherman_notification function to authenticated users
-- This allows admins to call the function which has SECURITY DEFINER and bypasses RLS
GRANT EXECUTE ON FUNCTION public.create_fisherman_notification(text, text, text, text, jsonb) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.mark_notification_as_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_as_read TO authenticated;

-- Add RLS policy to allow authenticated users (admins) to insert notifications directly
-- This is a fallback if the function doesn't work, but the function (SECURITY DEFINER) is preferred
DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON public.fisherman_notifications;
CREATE POLICY "Allow authenticated users to insert notifications" ON public.fisherman_notifications
    FOR INSERT 
    TO authenticated 
    WITH CHECK (true);  -- Allow all authenticated users to insert (admins can create notifications for fishermen)

-- 13. Example usage queries (commented out)
-- =============================================
-- 
-- -- Update SOS alert status to "on_the_way" (this will trigger notification)
-- UPDATE public.sos_alerts
-- SET status = 'on_the_way'
-- WHERE id = 'sos_alert_123';
--
-- -- Update SOS alert status to "resolved" (this will trigger notification)
-- UPDATE public.sos_alerts
-- SET status = 'resolved'
-- WHERE id = 'sos_alert_123';
--
-- -- Get all notifications for a fisherman
-- SELECT * FROM public.fisherman_notifications
-- WHERE fisherman_uid = 'fisherman-uuid-here'
-- ORDER BY created_at DESC;
--
-- -- Get unread notifications for a fisherman
-- SELECT * FROM public.fisherman_notifications
-- WHERE fisherman_uid = 'fisherman-uuid-here'
--   AND is_read = false
-- ORDER BY created_at DESC;
--
-- -- Mark a notification as read
-- SELECT public.mark_notification_as_read('notification-uuid-here');
--
-- -- Mark all notifications as read for a fisherman
-- SELECT public.mark_all_notifications_as_read('fisherman-uuid-here');
--
-- -- Get unread notifications count
-- SELECT * FROM public.fisherman_unread_notifications_count
-- WHERE fisherman_uid = 'fisherman-uuid-here';

-- =============================================
-- END OF SCRIPT philippinecoastguard@2025 notify pop up
-- =============================================

