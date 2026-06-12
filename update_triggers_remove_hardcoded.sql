-- =============================================
-- UPDATE TRIGGER FUNCTIONS - REMOVE HARDCODED DEFAULTS
-- =============================================
-- This script updates the existing trigger functions to use get_default_admin_info()
-- instead of hardcoded 'coastguard@salbar-mangirisda.gov'

-- 1. UPDATE notify_fisherman_on_the_way() TRIGGER
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
        
        -- If no admin action found, use dynamic default from get_default_admin_info()
        IF admin_name IS NULL THEN
            SELECT da.admin_name, da.admin_email
            INTO admin_name, admin_email
            FROM public.get_default_admin_info() da;
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

-- 2. UPDATE notify_fisherman_resolved() TRIGGER
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
        
        -- If no admin action found, use dynamic default from get_default_admin_info()
        IF admin_name IS NULL THEN
            SELECT da.admin_name, da.admin_email
            INTO admin_name, admin_email
            FROM public.get_default_admin_info() da;
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

-- 3. UPDATE notify_fisherman_status_change() TRIGGER (main combined trigger)
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
        
        -- If not found, get dynamic default
        IF admin_name IS NULL THEN
            SELECT da.admin_name, da.admin_email
            INTO admin_name, admin_email
            FROM public.get_default_admin_info() da;
        END IF;
        
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
                    'admin_email', COALESCE(admin_email, 'admin@coastguard.gov'),
                    'latitude', NEW.latitude,
                    'longitude', NEW.longitude,
                    'on_the_way_at', NEW.on_the_way_at
                )
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error but don't prevent status update
                RAISE WARNING 'Failed to create on_the_way notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    -- Handle "resolved" status
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
        
        -- If not found, get dynamic default
        IF admin_name IS NULL THEN
            SELECT da.admin_name, da.admin_email
            INTO admin_name, admin_email
            FROM public.get_default_admin_info() da;
        END IF;
        
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
                    'admin_email', COALESCE(admin_email, 'admin@coastguard.gov'),
                    'latitude', NEW.latitude,
                    'longitude', NEW.longitude,
                    'resolved_at', NEW.resolved_at
                )
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Log error but don't prevent status update
                RAISE WARNING 'Failed to create resolved notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

-- =============================================
-- SUMMARY OF CHANGES
-- =============================================
--
-- ✅ Updated notify_fisherman_on_the_way() - now uses get_default_admin_info()
-- ✅ Updated notify_fisherman_resolved() - now uses get_default_admin_info()
-- ✅ Updated notify_fisherman_status_change() - now uses get_default_admin_info()
--
-- All hardcoded 'coastguard@salbar-mangirisda.gov' values have been replaced
-- with dynamic calls to get_default_admin_info() which:
--   1. Tries to get the first active coast guard from the coastguards table
--   2. Falls back to app_config values if no coast guard is found
--   3. Can be changed without code modifications
--
