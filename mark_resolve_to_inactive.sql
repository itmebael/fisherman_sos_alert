-- Update trigger function to set status to 'inactive' when marking as resolved
-- This replaces the 'resolved' status with 'inactive' status

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
                RAISE WARNING 'Failed to create notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    -- Handle "inactive" status (when marking as resolved)
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
        notification_title := 'Alert Marked as Inactive';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' has marked your SOS alert as inactive. The rescue operation is being processed.';
        
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
                -- Don't fail the trigger if notification creation fails
                RAISE WARNING 'Failed to create notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    -- Handle "rescued" status (optional - if you want to mark as rescued after inactive)
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
                RAISE WARNING 'Failed to create notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    -- Handle "resolved" status (for backward compatibility - converts to inactive)
    IF NEW.status = 'resolved' AND (OLD.status IS NULL OR OLD.status != 'resolved') THEN
        -- Automatically convert 'resolved' to 'inactive'
        NEW.status = 'inactive';
        
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
        
        -- Set notification details for inactive status
        notification_type := 'sos_inactive';
        notification_title := 'Alert Marked as Inactive';
        notification_message := COALESCE(admin_name, 'Coast Guard') || ' has marked your SOS alert as inactive. The rescue operation is being processed.';
        
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
                RAISE WARNING 'Failed to create notification for alert %: %', NEW.id, SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Ensure the trigger exists
DROP TRIGGER IF EXISTS trigger_notify_fisherman_status_change ON public.sos_alerts;

CREATE TRIGGER trigger_notify_fisherman_status_change
BEFORE UPDATE ON public.sos_alerts
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.notify_fisherman_status_change();

COMMENT ON FUNCTION public.notify_fisherman_status_change() IS 'Trigger function that handles status changes and creates notifications. When status is set to resolved, it automatically converts to inactive.';









