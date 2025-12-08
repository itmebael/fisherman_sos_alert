-- Admin Notification Actions Tracking Table
-- This table tracks all admin actions performed on SOS notifications/alerts
-- Run this in your Supabase SQL editor

-- 1. Create the admin_notification_actions table
CREATE TABLE public.admin_notification_actions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sos_alert_id text NOT NULL,
  admin_user_id uuid NOT NULL,
  admin_email text,
  admin_name text,
  action_type text NOT NULL,
  action_description text,
  previous_status text,
  new_status text,
  action_timestamp timestamp with time zone NOT NULL DEFAULT now(),
  ip_address inet,
  user_agent text,
  notes text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admin_notification_actions_pkey PRIMARY KEY (id),
  CONSTRAINT admin_notification_actions_sos_alert_id_fkey 
    FOREIGN KEY (sos_alert_id) REFERENCES public.sos_alerts (id) ON DELETE CASCADE,
  CONSTRAINT admin_notification_actions_action_type_check 
    CHECK (action_type IN ('view_location', 'mark_on_the_way', 'mark_resolved', 'view_details', 'export_data', 'print_report'))
);

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_admin_notification_actions_sos_alert_id 
ON public.admin_notification_actions (sos_alert_id);

CREATE INDEX IF NOT EXISTS idx_admin_notification_actions_admin_user_id 
ON public.admin_notification_actions (admin_user_id);

CREATE INDEX IF NOT EXISTS idx_admin_notification_actions_action_type 
ON public.admin_notification_actions (action_type);

CREATE INDEX IF NOT EXISTS idx_admin_notification_actions_timestamp 
ON public.admin_notification_actions (action_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_admin_notification_actions_admin_email 
ON public.admin_notification_actions (admin_email);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.admin_notification_actions ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
-- Allow authenticated users to insert admin actions
CREATE POLICY "Allow authenticated users to insert admin actions" ON public.admin_notification_actions
    FOR INSERT 
    TO authenticated 
    WITH CHECK (true);

-- Allow authenticated users to select admin actions
CREATE POLICY "Allow authenticated users to select admin actions" ON public.admin_notification_actions
    FOR SELECT 
    TO authenticated 
    USING (true);

-- Allow authenticated users to update admin actions (for corrections)
CREATE POLICY "Allow authenticated users to update admin actions" ON public.admin_notification_actions
    FOR UPDATE 
    TO authenticated 
    USING (true)
    WITH CHECK (true);

-- Allow service role full access (for system operations)
CREATE POLICY "Allow service role full access" ON public.admin_notification_actions
    FOR ALL 
    TO service_role 
    USING (true)
    WITH CHECK (true);

-- 5. Add comments for documentation
COMMENT ON TABLE public.admin_notification_actions IS 'Tracks all admin actions performed on SOS notifications/alerts';
COMMENT ON COLUMN public.admin_notification_actions.id IS 'Unique identifier for the admin action record';
COMMENT ON COLUMN public.admin_notification_actions.sos_alert_id IS 'Reference to the SOS alert that was acted upon';
COMMENT ON COLUMN public.admin_notification_actions.admin_user_id IS 'UUID of the admin user who performed the action';
COMMENT ON COLUMN public.admin_notification_actions.admin_email IS 'Email of the admin user (for easy identification)';
COMMENT ON COLUMN public.admin_notification_actions.admin_name IS 'Name of the admin user (for easy identification)';
COMMENT ON COLUMN public.admin_notification_actions.action_type IS 'Type of action performed: view_location, mark_on_the_way, mark_resolved, view_details, export_data, print_report';
COMMENT ON COLUMN public.admin_notification_actions.action_description IS 'Human-readable description of the action';
COMMENT ON COLUMN public.admin_notification_actions.previous_status IS 'Status of the SOS alert before the action';
COMMENT ON COLUMN public.admin_notification_actions.new_status IS 'Status of the SOS alert after the action';
COMMENT ON COLUMN public.admin_notification_actions.action_timestamp IS 'When the action was performed';
COMMENT ON COLUMN public.admin_notification_actions.ip_address IS 'IP address of the admin user (for audit trail)';
COMMENT ON COLUMN public.admin_notification_actions.user_agent IS 'Browser/client information (for audit trail)';
COMMENT ON COLUMN public.admin_notification_actions.notes IS 'Additional notes or comments about the action';

-- 6. Create a view for easy reporting
CREATE OR REPLACE VIEW public.admin_action_summary AS
SELECT 
    ana.id,
    ana.sos_alert_id,
    sa.fisherman_name,
    sa.fisherman_email,
    sa.latitude,
    sa.longitude,
    ana.admin_name,
    ana.admin_email,
    ana.action_type,
    ana.action_description,
    ana.previous_status,
    ana.new_status,
    ana.action_timestamp,
    ana.notes
FROM public.admin_notification_actions ana
LEFT JOIN public.sos_alerts sa ON ana.sos_alert_id = sa.id
ORDER BY ana.action_timestamp DESC;

-- 7. Create a function to log admin actions (for easy use in application)
CREATE OR REPLACE FUNCTION public.log_admin_action(
    p_sos_alert_id text,
    p_admin_user_id uuid,
    p_admin_email text,
    p_admin_name text,
    p_action_type text,
    p_action_description text DEFAULT NULL,
    p_previous_status text DEFAULT NULL,
    p_new_status text DEFAULT NULL,
    p_ip_address inet DEFAULT NULL,
    p_user_agent text DEFAULT NULL,
    p_notes text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    action_id uuid;
BEGIN
    INSERT INTO public.admin_notification_actions (
        sos_alert_id,
        admin_user_id,
        admin_email,
        admin_name,
        action_type,
        action_description,
        previous_status,
        new_status,
        ip_address,
        user_agent,
        notes
    ) VALUES (
        p_sos_alert_id,
        p_admin_user_id,
        p_admin_email,
        p_admin_name,
        p_action_type,
        p_action_description,
        p_previous_status,
        p_new_status,
        p_ip_address,
        p_user_agent,
        p_notes
    ) RETURNING id INTO action_id;
    
    RETURN action_id;
END;
$$;

-- 8. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.admin_notification_actions TO authenticated;
GRANT SELECT ON public.admin_action_summary TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_admin_action TO authenticated;

-- 9. Example usage queries (commented out)
-- 
-- -- Log an admin action when marking SOS as "on the way"
-- SELECT public.log_admin_action(
--     'sos_alert_123',
--     'admin-uuid-here',
--     'admin@coastguard.gov',
--     'John Admin',
--     'mark_on_the_way',
--     'Marked SOS alert as "On the Way" - rescue team dispatched',
--     'active',
--     'on_the_way',
--     '192.168.1.100'::inet,
--     'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
--     'Rescue boat CG-001 dispatched'
-- );
--
-- -- Get all actions for a specific SOS alert
-- SELECT * FROM public.admin_notification_actions 
-- WHERE sos_alert_id = 'sos_alert_123' 
-- ORDER BY action_timestamp DESC;
--
-- -- Get admin action summary with fisherman details
-- SELECT * FROM public.admin_action_summary 
-- WHERE sos_alert_id = 'sos_alert_123';
--
-- -- Get all actions by a specific admin
-- SELECT * FROM public.admin_notification_actions 
-- WHERE admin_email = 'admin@coastguard.gov' 
-- ORDER BY action_timestamp DESC;
--
-- -- Get action statistics by type
-- SELECT 
--     action_type,
--     COUNT(*) as action_count,
--     COUNT(DISTINCT sos_alert_id) as unique_alerts_acted_upon
-- FROM public.admin_notification_actions 
-- GROUP BY action_type 
-- ORDER BY action_count DESC;

