-- Update trigger function to handle inactive -> rescued flow
-- This ensures notifications are sent when alerts are marked as rescued

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
        -- Update on_the_way_at timestamp if not already set
        IF NEW.on_the_way_at IS NULL THEN
            NEW.on_the_way_at = now();
        END IF;
        
        -- Get admin name from the most recent admin action
        BEGIN
            SELECT 
                ana.admin_name,
                ana.admin_email
            INTO admin_name, admin_email
            FROM public.admin_notification_actions ana
            WHERE ana.sos_alert_id = NEW.id
              AND ana.action_type = 'mark_on_the_way'
            ORDER BY ana.action_timestamp DESC
            LIMIT 1;
        EXCEPTION
            WHEN OTHERS THEN
                admin_name := NULL;
                admin_email := NULL;
        END;
        
        -- Set notification details
        notification_type := 'sos_on_the_way';
        notification_title := 'Rescue Team En Route';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' has dispatched a rescue team. Help is on the way!';
        
        -- Create notification
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
                -- Don't fail the trigger if notification creation fails
                NULL;
        END;
    END IF;
    
    -- Handle "inactive" status
    IF NEW.status = 'inactive' AND (OLD.status IS NULL OR OLD.status != 'inactive') THEN
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
                admin_name := NULL;
                admin_email := NULL;
        END;
        
        -- Set notification details
        notification_type := 'sos_inactive';
        notification_title := 'Alert Processing';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' is processing your rescue. Status will be updated shortly.';
        
        -- Create notification (optional, can be skipped for inactive)
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
                NULL;
        END;
    END IF;
    
    -- Handle "rescued" status
    IF NEW.status = 'rescued' AND (OLD.status IS NULL OR OLD.status != 'rescued') THEN
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
                admin_name := NULL;
                admin_email := NULL;
        END;
        
        -- Set notification details
        notification_type := 'sos_rescued';
        notification_title := 'Rescue Completed';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' has completed your rescue. You are safe now!';
        
        -- Create notification
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
                    'resolved_at', NEW.resolved_at,
                    'casualties', NEW.casualties,
                    'injured', NEW.injured
                )
            );
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    END IF;
    
    -- Handle "resolved" status (for backward compatibility)
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
                admin_name := NULL;
                admin_email := NULL;
        END;
        
        -- Set notification details
        notification_type := 'sos_resolved';
        notification_title := 'SOS Alert Resolved';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' has marked your SOS alert as "Resolved". You are safe now!';
        
        -- Create notification
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
                NULL;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;




